from ultralytics import YOLO
import torch
import os

def train_model():
    # 1. Identify device (GPU if available, else CPU)
    device = '0' if torch.cuda.is_available() else 'cpu'
    print(f"Using device: {device}")

    # 2. Load the last checkpoint to RESUME training
    last_checkpoint = 'runs/detect/infrastructure_gpu_full/weights/last.pt'
    if os.path.exists(last_checkpoint):
        print("Found existing checkpoint! Resuming training...")
        model = YOLO(last_checkpoint)
        resume_flag = True
    else:
        print("Starting fresh training...")
        model = YOLO('yolov8n.pt')
        resume_flag = False

    # 3. Start training
    project_dir = 'runs/detect'
    run_name = 'infrastructure_gpu_full'

    print("Resuming Training Process...")
    results = model.train(
        data='data/data.yaml',       # Path to your data.yaml
        epochs=20,                   # Set to your new target
        imgsz=640,                   # High resolution for cracks
        batch=8,                     # Reduced for Laptop GPU memory
        device='0',                  # Use RTX 4050
        workers=2,                   # Prevents MemoryError on Windows
        project=project_dir,         # Where to save results
        name=run_name,               # Name of this training run
        exist_ok=True,               # Overwrite if name exists
        pretrained=True,             # Start with pretrained weights
        optimizer='auto',            # Automatically choose optimizer
        cache=False,                 # DO NOT cache 10k images in RAM
        resume=resume_flag           # RESUME if possible
    )

    print(f"Training Complete! Results saved to {os.path.join(project_dir, run_name)}")

if __name__ == "__main__":
    train_model()
