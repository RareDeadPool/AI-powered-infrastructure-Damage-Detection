from ultralytics import YOLO

# Step 3 & 4: PT to TFLite (FP16)
print("Starting Step 3/4: Converting to TFLite with FP16 quantization...")

model = YOLO("models/final_model.pt")

try:
    # format='tflite'
    # half=True for FP16 quantization
    # int8=False (explicitly use float/half)
    path = model.export(format="tflite", imgsz=640, half=True)
    print(f"DONE: TFLite model saved at: {path}")
except Exception as e:
    print(f"ERROR during TFLite export: {str(e)}")
