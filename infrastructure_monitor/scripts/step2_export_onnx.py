from ultralytics import YOLO
import os

# Step 2: Export PyTorch to ONNX
print("🔍 Starting Step 2: PyTorch to ONNX...")
model_path = "models/final_model.pt"

if not os.path.exists(model_path):
    print(f"❌ Error: {model_path} not found!")
else:
    model = YOLO(model_path)
    # opset=12 is recommended for wide compatibility with older TFLite versions
    # simplify=True cleans up the graph structure
    path = model.export(format="onnx", opset=12, simplify=True, imgsz=640)
    print(f"✅ ONNX export complete! Saved at: {path}")
