from ultralytics import YOLO
import cv2
import numpy as np

class DamageDetector:
    def __init__(self, model_path="yolov8n.pt"):
        """Initialize the YOLO model."""
        # Note: Using yolov8n.pt (base model). In a real setting, you would load your custom weights path here.
        self.model = YOLO(model_path)
        
    def predict_image(self, image_source, conf_threshold=0.25):
        """Runs the YOLO model on an image and returns results."""
        results = self.model.predict(source=image_source, conf=conf_threshold)
        
        # We are processing one image at a time
        result = results[0]
        
        # We will manually draw highlighted boxes directly on a copy of the original image
        annotated_img_bgr = result.orig_img.copy()
        
        # Extract detection info for the report
        detections = []
        boxes = result.boxes
        class_names = result.names
        
        for i, box in enumerate(boxes):
            cls_id = int(box.cls[0].item())
            class_name = class_names[cls_id]
            conf = float(box.conf[0].item())
            xyxy = box.xyxy[0].tolist()
            
            # --- INTELLIGENT HEURISTICS MODULE ---
            width_px = xyxy[2] - xyxy[0]
            height_px = xyxy[3] - xyxy[1]
            img_h, img_w = annotated_img_bgr.shape[:2]
            
            # Robust estimation: compute relative area to handle distance
            area_pct = round(((width_px * height_px) / (img_w * img_h)) * 100, 1)
            estimated_size_cm = f"{area_pct}% Area"
            
            # Determine Severity and Priority Levels
            if area_pct >= 8.0:
                severity = "🔴 High"
                priority = "Immediate Repair"
                color = (0, 0, 255) # Red
            elif area_pct >= 2.0:
                severity = "🟠 Medium"
                priority = "Schedule Maintenance"
                color = (0, 165, 255) # Orange
            else:
                severity = "🟢 Low"
                priority = "Monitor Status"
                color = (0, 255, 0) # Green
                
            # Draw highlighted translucent block exactly inside the box
            x1, y1, x2, y2 = int(xyxy[0]), int(xyxy[1]), int(xyxy[2]), int(xyxy[3])
            
            # --- Optional Instance Segmentation Masking ---
            try:
                has_real_mask = False
                overlay = annotated_img_bgr.copy()
                
                if hasattr(result, 'masks') and result.masks is not None and len(result.masks.xy) > i:
                    mask_pts = result.masks.xy[i]
                    if len(mask_pts) > 0:
                        mask_pts = np.int32([mask_pts])
                        cv2.fillPoly(overlay, mask_pts, color)
                        has_real_mask = True
                
                if not has_real_mask:
                    roi = annotated_img_bgr[y1:y2, x1:x2]
                    gray_roi = cv2.cvtColor(roi, cv2.COLOR_BGR2GRAY)
                    gray_roi = cv2.GaussianBlur(gray_roi, (5, 5), 0)
                    
                    _, mask = cv2.threshold(gray_roi, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
                    contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
                    
                    if contours:
                        largest_contour = max(contours, key=cv2.contourArea)
                        shifted_contour = largest_contour + np.array([[x1, y1]])
                        cv2.drawContours(overlay, [shifted_contour], -1, color, -1)
                    else:
                        cv2.rectangle(overlay, (x1, y1), (x2, y2), color, -1)
            except Exception:
                overlay = annotated_img_bgr.copy()
                cv2.rectangle(overlay, (x1, y1), (x2, y2), color, -1)
            
            cv2.addWeighted(overlay, 0.5, annotated_img_bgr, 0.5, 0, annotated_img_bgr)
            cv2.rectangle(annotated_img_bgr, (x1, y1), (x2, y2), color, 2)
            
            # Keep text perfectly inside the box and image constraints
            severity_clean = severity.split(" ")[1]
            label = f"{class_name.title()}: {severity_clean} ({area_pct}%)"
            
            font_scale = 0.6
            thickness = 2
            (w, h), _ = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, font_scale, thickness)
            
            if w > (x2 - x1):
                font_scale = font_scale * ((x2 - x1) / w) * 0.9
                thickness = max(1, int(thickness * ((x2 - x1) / w)))
                (w, h), _ = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, font_scale, thickness)
            
            # Clamp the text background rectangle so it NEVER exceeds the right or bottom edge
            bg_x2 = min(x1 + w, img_w - 1)
            bg_y2 = min(y1 + h + 8, img_h - 1)
            cv2.rectangle(annotated_img_bgr, (x1, y1), (bg_x2, bg_y2), color, -1)
            cv2.putText(annotated_img_bgr, label, (x1, min(y1 + h + 4, img_h - 5)), cv2.FONT_HERSHEY_SIMPLEX, font_scale, (255, 255, 255), thickness)
            
            detections.append({
                "Damage Type": class_name.title(),
                "Confidence": f"{round(conf * 100, 1)}%",
                "Est. Length (cm)": estimated_size_cm,
                "Severity": severity,
                "Action Priority": priority,
                "Bounding Box": [round(x, 1) for x in xyxy]
            })
            
        annotated_img_rgb = cv2.cvtColor(annotated_img_bgr, cv2.COLOR_BGR2RGB)
        return annotated_img_rgb, detections

    def predict_video(self, video_path, conf_threshold=0.25):
        """Processes video frame by frame and extracts Key Frames with damage."""
        import cv2
        import os
        import uuid
        import time
        
        frame_dir = os.path.join("data", "video_frames")
        os.makedirs(frame_dir, exist_ok=True)
        
        cap = cv2.VideoCapture(video_path)
        fps = int(cap.get(cv2.CAP_PROP_FPS))
        if fps == 0: fps = 30
        
        # Analyze 1 frame per second to be extremely efficient and fast
        frame_skip = fps 
        
        key_frames = []
        all_detections = []
        frame_count = 0
        second_count = 0
        
        # Prevent the AI from aggressively logging the exact same pothole over 4 consecutive seconds
        cooldown_seconds = 3
        last_logged_second = -999
        
        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break
                
            if frame_count % frame_skip == 0:
                second_count += 1
                
                # YOLO Prediction on this single frame
                results = self.model.predict(source=frame, conf=conf_threshold, verbose=False)
                result = results[0]
                
                # If damage is spotted AND we aren't in a cooldown period...
                if len(result.boxes) > 0 and (second_count - last_logged_second) >= cooldown_seconds:
                    last_logged_second = second_count
                    
                    annotated_bgr = result.orig_img.copy()
                    
                    for i, box in enumerate(result.boxes):
                        cls_id = int(box.cls[0].item())
                        class_name = result.names[cls_id]
                        conf = float(box.conf[0].item())
                        xyxy = box.xyxy[0].tolist()
                        
                        width_px = xyxy[2] - xyxy[0]
                        height_px = xyxy[3] - xyxy[1]
                        img_h, img_w = annotated_bgr.shape[:2]
                        
                        area_pct = round(((width_px * height_px) / (img_w * img_h)) * 100, 1)
                        embedded_size_cm = f"{area_pct}% Area"
                        
                        if area_pct >= 8.0:
                            severity = "🔴 High"
                            priority = "Immediate Repair"
                            color = (0, 0, 255)
                        elif area_pct >= 2.0:
                            severity = "🟠 Medium"
                            priority = "Schedule Maintenance"
                            color = (0, 165, 255)
                        else:
                            severity = "🟢 Low"
                            priority = "Monitor Status"
                            color = (0, 255, 0)
                            
                        # Custom Circular/Ellipse Overlay
                        x1, y1, x2, y2 = int(xyxy[0]), int(xyxy[1]), int(xyxy[2]), int(xyxy[3])
                        severity_clean = severity.split(" ")[1]
                        label = f"{class_name.title()}: {severity_clean} ({area_pct}%)"
                        
                        try:
                            has_real_mask = False
                            overlay = annotated_bgr.copy()
                            
                            if hasattr(result, 'masks') and result.masks is not None and len(result.masks.xy) > i:
                                mask_pts = result.masks.xy[i]
                                if len(mask_pts) > 0:
                                    mask_pts = np.int32([mask_pts])
                                    cv2.fillPoly(overlay, mask_pts, color)
                                    has_real_mask = True
                            
                            if not has_real_mask:
                                roi = annotated_bgr[y1:y2, x1:x2]
                                gray_roi = cv2.cvtColor(roi, cv2.COLOR_BGR2GRAY)
                                gray_roi = cv2.GaussianBlur(gray_roi, (5, 5), 0)
                                
                                _, mask = cv2.threshold(gray_roi, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
                                contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
                                
                                if contours:
                                    largest_contour = max(contours, key=cv2.contourArea)
                                    shifted_contour = largest_contour + np.array([[x1, y1]])
                                    cv2.drawContours(overlay, [shifted_contour], -1, color, -1)
                                else:
                                    cv2.rectangle(overlay, (x1, y1), (x2, y2), color, -1)
                        except Exception:
                            overlay = annotated_bgr.copy()
                            cv2.rectangle(overlay, (x1, y1), (x2, y2), color, -1)
                            
                        cv2.addWeighted(overlay, 0.5, annotated_bgr, 0.5, 0, annotated_bgr)
                        cv2.rectangle(annotated_bgr, (x1, y1), (x2, y2), color, 2)
                        
                        font_scale = 0.6
                        thickness = 2
                        (w, h), _ = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, font_scale, thickness)
                        
                        if w > (x2 - x1):
                            font_scale = font_scale * ((x2 - x1) / w) * 0.9
                            thickness = max(1, int(thickness * ((x2 - x1) / w)))
                            (w, h), _ = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, font_scale, thickness)
                        
                        bg_x2 = min(x1 + w, img_w - 1)
                        bg_y2 = min(y1 + h + 8, img_h - 1)
                        cv2.rectangle(annotated_bgr, (x1, y1), (bg_x2, bg_y2), color, -1)
                        cv2.putText(annotated_bgr, label, (x1, min(y1 + h + 4, img_h - 5)), cv2.FONT_HERSHEY_SIMPLEX, font_scale, (255, 255, 255), thickness)
                            
                        # Format timestamp like 00:00:15
                        mins, secs = divmod(second_count, 60)
                        timestamp = f"{mins:02d}:{secs:02d}"
                        
                        frame_filename = os.path.join(frame_dir, f"incident_{uuid.uuid4().hex[:6]}.jpg")
                            
                        all_detections.append({
                            "Timestamp": timestamp,
                            "Damage Type": class_name.title(),
                            "Confidence": f"{round(conf * 100, 1)}%",
                            "Est. Length (cm)": embedded_size_cm,
                            "Severity": severity,
                            "Action Priority": priority,
                            "Bounding Box": [round(x, 1) for x in xyxy],
                            "image_path": frame_filename
                        })
                        
                    cv2.imwrite(frame_filename, annotated_bgr) # Save modified frame
                    annotated_rgb = cv2.cvtColor(annotated_bgr, cv2.COLOR_BGR2RGB)
                    key_frames.append(annotated_rgb)
                    
            frame_count += 1
            
        cap.release()
        return key_frames, all_detections

    def predict_livestream(self, conf_threshold=0.25):
        """Processes live camera feed using OpenCV with continuous hardware-accelerated display."""
        import cv2
        import os
        import uuid
        import time
        
        frame_dir = os.path.join("data", "video_frames")
        os.makedirs(frame_dir, exist_ok=True)
        
        # Open default webcam natively
        cap = cv2.VideoCapture(0)
        
        key_frames = []
        all_detections = []
        
        # Heuristics cooldown tracker
        cooldown_seconds = 3
        last_logged_time = -999
        start_time = time.time()
        
        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break
                
            # YOLO prediction on real-time stream
            results = self.model.predict(source=frame, conf=conf_threshold, verbose=False)
            result = results[0]
            
            # Manually overlay precision highlighted block
            annotated_bgr = result.orig_img.copy()
            
            frame_detections = []
            for i, box in enumerate(result.boxes):
                cls_id = int(box.cls[0].item())
                class_name = result.names[cls_id]
                conf = float(box.conf[0].item())
                xyxy = box.xyxy[0].tolist()
                
                width_px = xyxy[2] - xyxy[0]
                height_px = xyxy[3] - xyxy[1]
                img_h, img_w = annotated_bgr.shape[:2]
                
                area_pct = round(((width_px * height_px) / (img_w * img_h)) * 100, 1)
                embedded_size_cm = f"{area_pct}% Area"
                
                if area_pct >= 8.0:
                    severity = "🔴 High"
                    priority = "Immediate Repair"
                    color = (0, 0, 255)
                elif area_pct >= 2.0:
                    severity = "🟠 Medium"
                    priority = "Schedule Maintenance"
                    color = (0, 165, 255)
                else:
                    severity = "🟢 Low"
                    priority = "Monitor Status"
                    color = (0, 255, 0)
                    
                # Highlighted precision block inside the edges
                x1, y1, x2, y2 = int(xyxy[0]), int(xyxy[1]), int(xyxy[2]), int(xyxy[3])
                severity_clean = severity.split(" ")[1]
                label = f"{class_name.title()}: {severity_clean} ({area_pct}%)"
                
                try:
                    has_real_mask = False
                    overlay = annotated_bgr.copy()
                    
                    if hasattr(result, 'masks') and result.masks is not None and len(result.masks.xy) > i:
                        mask_pts = result.masks.xy[i]
                        if len(mask_pts) > 0:
                            mask_pts = np.int32([mask_pts])
                            cv2.fillPoly(overlay, mask_pts, color)
                            has_real_mask = True
                            
                    if not has_real_mask:
                        roi = annotated_bgr[y1:y2, x1:x2]
                        gray_roi = cv2.cvtColor(roi, cv2.COLOR_BGR2GRAY)
                        gray_roi = cv2.GaussianBlur(gray_roi, (5, 5), 0)
                        
                        _, mask = cv2.threshold(gray_roi, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
                        contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
                        
                        if contours:
                            largest_contour = max(contours, key=cv2.contourArea)
                            shifted_contour = largest_contour + np.array([[x1, y1]])
                            cv2.drawContours(overlay, [shifted_contour], -1, color, -1)
                        else:
                            cv2.rectangle(overlay, (x1, y1), (x2, y2), color, -1)
                except Exception:
                    overlay = annotated_bgr.copy()
                    cv2.rectangle(overlay, (x1, y1), (x2, y2), color, -1)
                    
                cv2.addWeighted(overlay, 0.5, annotated_bgr, 0.5, 0, annotated_bgr)
                cv2.rectangle(annotated_bgr, (x1, y1), (x2, y2), color, 2)
                
                font_scale = 0.6
                thickness = 2
                (w, h), _ = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, font_scale, thickness)
                if w > (x2 - x1):
                    font_scale = font_scale * ((x2 - x1) / w) * 0.9
                    thickness = max(1, int(thickness * ((x2 - x1) / w)))
                    (w, h), _ = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, font_scale, thickness)
                
                bg_x2 = min(x1 + w, img_w - 1)
                bg_y2 = min(y1 + h + 8, img_h - 1)
                cv2.rectangle(annotated_bgr, (x1, y1), (bg_x2, bg_y2), color, -1)
                cv2.putText(annotated_bgr, label, (x1, min(y1 + h + 4, img_h - 5)), cv2.FONT_HERSHEY_SIMPLEX, font_scale, (255, 255, 255), thickness)
                
                frame_detections.append({
                    "class_name": class_name,
                    "conf": conf,
                    "xyxy": xyxy,
                    "embedded_size_cm": embedded_size_cm,
                    "severity": severity,
                    "priority": priority
                })
            
            # Show live window popup WITH the new dynamic labels rendered
            cv2.imshow("Live Threat Scanner (Press 'q' to Quit)", annotated_bgr)
            
            current_time = time.time()
            elapsed_sys_seconds = current_time - start_time
            
            # Proceed to incident logging phase if cooled down
            if len(frame_detections) > 0 and (elapsed_sys_seconds - last_logged_time) >= cooldown_seconds:
                last_logged_time = elapsed_sys_seconds
                
                annotated_rgb = cv2.cvtColor(annotated_bgr, cv2.COLOR_BGR2RGB)
                frame_filename = os.path.join(frame_dir, f"incident_{uuid.uuid4().hex[:6]}.jpg")
                cv2.imwrite(frame_filename, annotated_bgr)
                
                for fd in frame_detections:
                    mins, secs = divmod(int(elapsed_sys_seconds), 60)
                    timestamp = f"{mins:02d}:{secs:02d}"
                        
                    all_detections.append({
                        "Timestamp": timestamp,
                        "Damage Type": fd["class_name"].title(),
                        "Confidence": f"{round(fd['conf'] * 100, 1)}%",
                        "Est. Length (cm)": fd["embedded_size_cm"],
                        "Severity": fd["severity"],
                        "Action Priority": fd["priority"],
                        "Bounding Box": [round(x, 1) for x in fd["xyxy"]],
                        "image_path": frame_filename
                    })
                    
                key_frames.append(annotated_rgb)
            
            # Quit key
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break
                
        cap.release()
        cv2.destroyAllWindows()
        return key_frames, all_detections
