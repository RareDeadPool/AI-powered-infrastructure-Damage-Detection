from ultralytics import YOLO

def train_custom_model():
    print("🚀 Starting YOLOv8 Training...")
    
    # 1. Load an Instance Segmentation model
    model = YOLO("yolov8n-seg.pt")
    
    # 2. Train the segmentation model on polygon dataset
    results = model.train(
        data="data/data.yaml", 
        epochs=15, # Adjusted based on previous successful training
        imgsz=640,
        batch=16,
        name="pipeline_segmentation_model"
    )
    
    print("✅ Training Complete!")
    print("Your trained model weights are saved at: 'runs/segment/pipeline_segmentation_model/weights/best.pt'")
    
if __name__ == "__main__":
    train_custom_model()
