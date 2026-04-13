from ultralytics import YOLO

def train_custom_model():
    print("🚀 Starting YOLOv8 Training...")
    
    # 1. Load an Instance Segmentation model
    model = YOLO("yolov8n-seg.pt")
    
    # 2. Train the segmentation model on polygon dataset
    results = model.train(
        data="data/data.yaml", 
        epochs=50, # Adjusted based on previous successful training
        imgsz=640,
        batch=16,
        name="pipeline_segmentation_model"
    )
    
    print("✅ Training Complete!")
    best_weights = f"runs/segment/pipeline_segmentation_model/weights/best.pt"
    print(f"Your trained model weights are saved at: '{best_weights}'")
    
    # NEW: Automatically update the app's pipe model
    import shutil
    os.makedirs("models", exist_ok=True)
    shutil.copy(best_weights, "models/pipe_model.pt")
    print("🚀 App Model Updated: 'models/pipe_model.pt' is now ready for use!")
    
if __name__ == "__main__":
    train_custom_model()
