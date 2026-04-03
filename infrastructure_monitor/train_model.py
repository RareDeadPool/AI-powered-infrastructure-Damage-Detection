from ultralytics import YOLO

def train_custom_model():
    print("🚀 Starting YOLOv8 Training...")
    
    # 1. Load a pretrained base model (recommended for transfer learning)
    model = YOLO("yolov8n.pt")
    
    # 2. Train the model using your custom dataset
    # You MUST update the 'data' path correctly to point to your dataset's data.yaml file
    # Ensure epochs are set to a reasonable number (e.g., 50-100) based on your dataset size
    # imgsz=640 is the standard image size for YOLOv8
    results = model.train(
        data="data.yaml", 
        epochs=50, 
        imgsz=640,
        batch=16,
        name="infrastructure_damage_model"
    )
    
    print("✅ Training Complete!")
    print("Your trained model weights are saved at: 'runs/detect/infrastructure_damage_model/weights/best.pt'")
    
if __name__ == "__main__":
    train_custom_model()
