import tensorflow as tf
import numpy as np
import cv2
import os

# Step 5: Test TFLite model
print("Starting Step 5: Testing TFLite model inference...")

model_path = "models/final_model_saved_model/final_model_float16.tflite"
image_path = "data/test/images/Corrosion_source_000078_png.rf.aba759210b324ee19fad0f05232b1e48.jpg"

if not os.path.exists(model_path):
    print(f"ERROR: Model not found at {model_path}")
    exit(1)

try:
    # 1. Load Interpreter
    interpreter = tf.lite.Interpreter(model_path=model_path)
    interpreter.allocate_tensors()

    # Get input/output details
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    print(f"DONE: TFLite model loaded.")
    print(f"Input Details: {input_details[0]['shape']}")
    print(f"Output Details: {output_details[0]['shape']}")

    # 2. Preprocess Image
    img = cv2.imread(image_path)
    if img is None:
        print(f"ERROR: Image not found at {image_path}")
        exit(1)
        
    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    img_resized = cv2.resize(img_rgb, (640, 640))
    img_normalized = img_resized.astype(np.float32) / 255.0
    img_input = np.expand_dims(img_normalized, axis=0) # [1, 640, 640, 3] or [1, 3, 640, 640]?
    
    # YOLOv8 TFLite usually expects [1, 640, 640, 3] (Channels last)
    # Check input shape
    if input_details[0]['shape'][1] == 3:
        # Channels first [1, 3, 640, 640]
        img_input = img_input.transpose(0, 3, 1, 2)

    # 3. Set Input Tensor
    interpreter.set_tensor(input_details[0]['index'], img_input)

    # 4. Invoke Inference
    interpreter.invoke()

    # 5. Get Results
    output_data = interpreter.get_tensor(output_details[0]['index'])
    print(f"DONE: Inference successful!")
    print(f"Output Shape: {output_data.shape}")
    
    # Simple check: max confidence in the output
    # YOLOv8 output for 5 classes is [1, 9, 8400] usually
    # (x, y, w, h, cls0, cls1, cls2, cls3, cls4)
    # Note: Sometimes the shapes are transposed in TFLite.
    
    print(f"First 5 elements of output: {output_data[0, :, 0]}")

except Exception as e:
    print(f"ERROR during testing: {str(e)}")
