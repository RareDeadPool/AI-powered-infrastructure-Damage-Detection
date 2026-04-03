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
        
        # Get annotated image (as numpy array, BGR)
        annotated_img_bgr = result.plot()
        annotated_img_rgb = cv2.cvtColor(annotated_img_bgr, cv2.COLOR_BGR2RGB)
        
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
            elif estimated_size_cm >= 15.0:
                severity = "🟠 Medium"
                priority = "Schedule Maintenance"
            else:
                severity = "🟢 Low"
                priority = "Monitor Status"
            
            detections.append({
                "Damage Type": class_name.title(),
                "Confidence": f"{round(conf * 100, 1)}%",
                "Est. Length (cm)": estimated_size_cm,
                "Severity": severity,
                "Action Priority": priority,
                "Bounding Box": [round(x, 1) for x in xyxy]
            })
            
        return annotated_img_rgb, detections

    def predict_video(self, video_path):
        """Processes video frame by frame for damage detection."""
        pass # To be implemented
