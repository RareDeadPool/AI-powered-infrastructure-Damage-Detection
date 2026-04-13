from ultralytics import YOLO
import cv2
import os
import uuid
import time


class DamageDetector:
    def __init__(self, model_path="models/final_model.pt"):
        """Initialize the unified YOLO detection model."""
        self.model = YOLO(model_path)

    @staticmethod
    def _severity_from_area(area_pct):
        if area_pct >= 8.0:
            return "🔴 High", "Immediate Repair", (0, 0, 255)
        if area_pct >= 2.0:
            return "🟠 Medium", "Schedule Maintenance", (0, 165, 255)
        return "🟢 Low", "Monitor Status", (0, 255, 0)

    @staticmethod
    def _draw_box_with_label(image_bgr, xyxy, label, color):
        x1, y1, x2, y2 = [int(v) for v in xyxy]
        img_h, img_w = image_bgr.shape[:2]

        cv2.rectangle(image_bgr, (x1, y1), (x2, y2), color, 2)

        font_scale = 0.6
        thickness = 2
        (w, h), _ = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, font_scale, thickness)

        box_w = max(1, x2 - x1)
        if w > box_w:
            scale_factor = (box_w / w) * 0.9
            font_scale *= max(0.5, scale_factor)
            thickness = max(1, int(thickness * max(0.5, scale_factor)))
            (w, h), _ = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, font_scale, thickness)

        bg_x2 = min(x1 + w + 4, img_w - 1)
        bg_y2 = min(y1 + h + 8, img_h - 1)
        cv2.rectangle(image_bgr, (x1, y1), (bg_x2, bg_y2), color, -1)
        cv2.putText(
            image_bgr,
            label,
            (x1 + 2, min(y1 + h + 4, img_h - 5)),
            cv2.FONT_HERSHEY_SIMPLEX,
            font_scale,
            (255, 255, 255),
            thickness,
        )

    @staticmethod
    def _format_detection(class_name, conf, xyxy, area_pct, severity, priority):
        return {
            "Damage Type": class_name.title(),
            "Confidence": f"{round(conf * 100, 1)}%",
            "Est. Length (cm)": f"{area_pct}% Area",
            "Severity": severity,
            "Action Priority": priority,
            "Bounding Box": [round(float(x), 1) for x in xyxy],
        }

    def _process_boxes(self, result, image_bgr):
        detections = []
        boxes = result.boxes
        class_names = result.names
        img_h, img_w = image_bgr.shape[:2]

        for box in boxes:
            cls_id = int(box.cls[0].item())
            class_name = class_names[cls_id]
            conf = float(box.conf[0].item())
            xyxy = box.xyxy[0].tolist()

            width_px = max(1.0, xyxy[2] - xyxy[0])
            height_px = max(1.0, xyxy[3] - xyxy[1])
            area_pct = round(((width_px * height_px) / (img_w * img_h)) * 100, 1)

            severity, priority, color = self._severity_from_area(area_pct)
            severity_clean = severity.split(" ")[1]
            label = f"{class_name.title()}: {severity_clean} ({area_pct}%)"

            self._draw_box_with_label(image_bgr, xyxy, label, color)

            detections.append(
                self._format_detection(
                    class_name=class_name,
                    conf=conf,
                    xyxy=xyxy,
                    area_pct=area_pct,
                    severity=severity,
                    priority=priority,
                )
            )

        return detections

    def predict_image(self, image_source, conf_threshold=0.25):
        """Run YOLO on a single image and return annotated image + structured detections."""
        results = self.model.predict(source=image_source, conf=conf_threshold, verbose=False)
        result = results[0]

        annotated_img_bgr = result.orig_img.copy()
        detections = self._process_boxes(result, annotated_img_bgr)

        annotated_img_rgb = cv2.cvtColor(annotated_img_bgr, cv2.COLOR_BGR2RGB)
        return annotated_img_rgb, detections

    def predict_video(self, video_path, conf_threshold=0.25):
        """Process video and extract key incident frames using detection-only logic."""
        frame_dir = os.path.join("data", "video_frames")
        os.makedirs(frame_dir, exist_ok=True)

        cap = cv2.VideoCapture(video_path)
        fps = int(cap.get(cv2.CAP_PROP_FPS))
        if fps <= 0:
            fps = 30

        frame_skip = max(1, fps)
        key_frames = []
        all_detections = []
        frame_count = 0
        second_count = 0

        cooldown_seconds = 3
        last_logged_second = -999

        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break

            if frame_count % frame_skip == 0:
                second_count += 1
                results = self.model.predict(source=frame, conf=conf_threshold, verbose=False)
                result = results[0]

                if len(result.boxes) > 0 and (second_count - last_logged_second) >= cooldown_seconds:
                    last_logged_second = second_count

                    annotated_bgr = result.orig_img.copy()
                    frame_detections = self._process_boxes(result, annotated_bgr)

                    mins, secs = divmod(second_count, 60)
                    timestamp = f"{mins:02d}:{secs:02d}"
                    frame_filename = os.path.join(frame_dir, f"incident_{uuid.uuid4().hex[:6]}.jpg")

                    for item in frame_detections:
                        record = {
                            "Timestamp": timestamp,
                            **item,
                            "image_path": frame_filename,
                        }
                        all_detections.append(record)

                    cv2.imwrite(frame_filename, annotated_bgr)
                    key_frames.append(cv2.cvtColor(annotated_bgr, cv2.COLOR_BGR2RGB))

            frame_count += 1

        cap.release()
        return key_frames, all_detections

    def predict_livestream(self, conf_threshold=0.25):
        """Run real-time webcam inference using detection-only bounding box rendering."""
        frame_dir = os.path.join("data", "video_frames")
        os.makedirs(frame_dir, exist_ok=True)

        cap = cv2.VideoCapture(0)
        key_frames = []
        all_detections = []

        cooldown_seconds = 3
        last_logged_time = -999.0
        start_time = time.time()

        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break

            results = self.model.predict(source=frame, conf=conf_threshold, verbose=False)
            result = results[0]
            annotated_bgr = result.orig_img.copy()

            frame_detections = self._process_boxes(result, annotated_bgr)
            cv2.imshow("Live Threat Scanner (Press 'q' to Quit)", annotated_bgr)

            elapsed_seconds = time.time() - start_time
            if frame_detections and (elapsed_seconds - last_logged_time) >= cooldown_seconds:
                last_logged_time = elapsed_seconds
                mins, secs = divmod(int(elapsed_seconds), 60)
                timestamp = f"{mins:02d}:{secs:02d}"
                frame_filename = os.path.join(frame_dir, f"incident_{uuid.uuid4().hex[:6]}.jpg")

                cv2.imwrite(frame_filename, annotated_bgr)
                key_frames.append(cv2.cvtColor(annotated_bgr, cv2.COLOR_BGR2RGB))

                for item in frame_detections:
                    record = {
                        "Timestamp": timestamp,
                        **item,
                        "image_path": frame_filename,
                    }
                    all_detections.append(record)

            if cv2.waitKey(1) & 0xFF == ord('q'):
                break

        cap.release()
        cv2.destroyAllWindows()
        return key_frames, all_detections
