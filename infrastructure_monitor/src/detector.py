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
            
            detections.append({
                "damage_type": class_name,
                "confidence": round(conf, 2),
                "bbox": [round(x, 1) for x in xyxy]
            })
            
        return annotated_img_rgb, detections

    def predict_video(self, video_path):
        """Processes video frame by frame for damage detection."""
        pass # To be implemented
