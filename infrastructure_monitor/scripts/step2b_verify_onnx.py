import onnx
import onnxruntime as ort
import numpy as np

# Step 2b: Verify ONNX
print("Starting Step 2b: Verifying ONNX model...")
onnx_path = "models/final_model.onnx"

try:
    # 1. Structural Check
    onnx_model = onnx.load(onnx_path)
    onnx.checker.check_model(onnx_model)
    print("DONE: ONNX structure is valid.")

    # 2. Functional Check (Inference)
    session = ort.InferenceSession(onnx_path)
    input_details = session.get_inputs()[0]
    input_shape = input_details.shape
    
    # Generate dummy input matching specified shape (batch, channels, height, width)
    # YOLOv8 default is typically [1, 3, 640, 640]
    dummy_input = np.random.randn(1, 3, 640, 640).astype(np.float32)
    
    outputs = session.run(None, {input_details.name: dummy_input})
    print(f"DONE: Inference successful! Output tensor shape: {outputs[0].shape}")
    
except Exception as e:
    print(f"ERROR during verification: {str(e)}")
