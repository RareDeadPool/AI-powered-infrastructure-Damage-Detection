from ultralytics import YOLO
import os

def train_building_model():
    print("🚀 Starting YOLOv8 Training for Building Cracks...")
    
    # Ensure a data.yaml path is set
    dataset_yaml = "data/building_cracks.yaml"
    if not os.path.exists(dataset_yaml):
        print(f"❌ Error: Dataset config {dataset_yaml} not found!")
        print("Please download a Building Cracks dataset (e.g. from Roboflow in YOLOv8 format) and place building_cracks.yaml in the data/ folder.")
        return

    # 1. Load the pre-trained YOLO instance segmentation model or resume from last checkpoint
    last_weights_path = "runs/segment/building_cracks_model/weights/last.pt"
    if os.path.exists(last_weights_path):
        print("🔄 Found existing checkpoint. Resuming training...")
        model = YOLO(last_weights_path)
        results = model.train(resume=True)
    else:
        print("🆕 Starting new training run...")
        model = YOLO("yolov8n-seg.pt")
        # 2. Train the model on the building cracks dataset
        results = model.train(
            data=dataset_yaml, 
            epochs=15, 
            imgsz=640,
            batch=16,
            name="building_cracks_model"
        )
    
    # 3. Save the weights to the models directory
    os.makedirs("models", exist_ok=True)
    best_weights_path = "runs/segment/building_cracks_model/weights/best.pt"
    target_weights_path = "models/building_model.pt"
    
    if os.path.exists(best_weights_path):
        import shutil
        shutil.copy(best_weights_path, target_weights_path)
        print(f"✅ Training Complete! Weights copied to {target_weights_path}. You can now select 'Buildings (Cracks)' in the app!")
    else:
        print("⚠️ Training completed, but couldn't locate best.pt!")

if __name__ == "__main__":
    train_building_model()
