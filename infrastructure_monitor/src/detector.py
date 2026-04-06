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
        
        # Get annotated image with native boxes but NO text labels
        annotated_img_bgr = result.plot(labels=False)
        
        # Extract detection info for the report
        detections = []
        boxes = result.boxes
        class_names = result.names
        
        for box in boxes:
            cls_id = int(box.cls[0].item())
            class_name = class_names[cls_id]
            conf = float(box.conf[0].item())
            xyxy = box.xyxy[0].tolist()
            
            # --- INTELLIGENT HEURISTICS MODULE ---
            width_px = xyxy[2] - xyxy[0]
            height_px = xyxy[3] - xyxy[1]
            max_dim = max(width_px, height_px)
            
            # Rough estimation: assume average camera height makes 1 pixel roughly 0.25 cm
            estimated_size_cm = round(max_dim * 0.25, 1)
            
            # Determine Severity and Priority Levels
            if estimated_size_cm >= 40.0:
                severity = "🔴 High"
                priority = "Immediate Repair"
                color = (0, 0, 255) # Red
            elif estimated_size_cm >= 15.0:
                severity = "🟠 Medium"
                priority = "Schedule Maintenance"
                color = (0, 165, 255) # Orange
            else:
                severity = "🟢 Low"
                priority = "Monitor Status"
                color = (0, 255, 0) # Green
                
            # Draw highly customized label over the box
            x1, y1 = int(xyxy[0]), int(xyxy[1])
            severity_clean = severity.split(" ")[1]
            label = f"{class_name.title()}: {severity_clean} ({estimated_size_cm}cm)"
            
            # Calculate text width/height for beautiful background rectangle
            (w, h), _ = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, 0.6, 2)
            cv2.rectangle(annotated_img_bgr, (x1, y1 - 25), (x1 + w, y1), color, -1)
            cv2.putText(annotated_img_bgr, label, (x1, y1 - 5), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 2)
            
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
                    
                    annotated_bgr = result.plot(labels=False)
                    
                    for box in result.boxes:
                        cls_id = int(box.cls[0].item())
                        class_name = result.names[cls_id]
                        conf = float(box.conf[0].item())
                        xyxy = box.xyxy[0].tolist()
                        
                        width_px = xyxy[2] - xyxy[0]
                        height_px = xyxy[3] - xyxy[1]
                        embedded_size_cm = round(max(width_px, height_px) * 0.25, 1)
                        
                        if embedded_size_cm >= 40.0:
                            severity = "🔴 High"
                            priority = "Immediate Repair"
                            color = (0, 0, 255)
                        elif embedded_size_cm >= 15.0:
                            severity = "🟠 Medium"
                            priority = "Schedule Maintenance"
                            color = (0, 165, 255)
                        else:
                            severity = "🟢 Low"
                            priority = "Monitor Status"
                            color = (0, 255, 0)
                            
                        # Custom Visual Overlay
                        x1, y1 = int(xyxy[0]), int(xyxy[1])
                        severity_clean = severity.split(" ")[1]
                        label = f"{class_name.title()}: {severity_clean} ({embedded_size_cm}cm)"
                        
                        (w, h), _ = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, 0.6, 2)
                        cv2.rectangle(annotated_bgr, (x1, y1 - 25), (x1 + w, y1), color, -1)
                        cv2.putText(annotated_bgr, label, (x1, y1 - 5), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 2)
                            
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
            
            # Extract visual array without generic tiny labels
            annotated_bgr = result.plot(labels=False)
            
            frame_detections = []
            for box in result.boxes:
                cls_id = int(box.cls[0].item())
                class_name = result.names[cls_id]
                conf = float(box.conf[0].item())
                xyxy = box.xyxy[0].tolist()
                
                width_px = xyxy[2] - xyxy[0]
                height_px = xyxy[3] - xyxy[1]
                embedded_size_cm = round(max(width_px, height_px) * 0.25, 1)
                
                if embedded_size_cm >= 40.0:
                    severity = "🔴 High"
                    priority = "Immediate Repair"
                    color = (0, 0, 255)
                elif embedded_size_cm >= 15.0:
                    severity = "🟠 Medium"
                    priority = "Schedule Maintenance"
                    color = (0, 165, 255)
                else:
                    severity = "🟢 Low"
                    priority = "Monitor Status"
                    color = (0, 255, 0)
                    
                # Engineer the bounding box labels to show Severity dynamically
                x1, y1 = int(xyxy[0]), int(xyxy[1])
                severity_clean = severity.split(" ")[1]
                label = f"{class_name.title()}: {severity_clean} ({embedded_size_cm}cm)"
                
                (w, h), _ = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, 0.6, 2)
                cv2.rectangle(annotated_bgr, (x1, y1 - 25), (x1 + w, y1), color, -1)
                cv2.putText(annotated_bgr, label, (x1, y1 - 5), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 2)
                
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
