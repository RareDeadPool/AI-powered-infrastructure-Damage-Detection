import streamlit as st
import os
from PIL import Image
import numpy as np
import uuid

# Import our custom modules from the source directory
from src.detector import DamageDetector
from src.report_generator import ReportGenerator

st.set_page_config(page_title="Infrastructure Damage Detection", page_icon="🏗️", layout="wide")

# Initialize models and components and cache them for performance
@st.cache_resource
def load_detector(infra_choice):
    # Determine which model weights to load based on the Dropdown selection
    if infra_choice == "Roads (Potholes)":
        model_path = "models/road_model.pt" 
    elif infra_choice == "Pipelines (Leaks)":
        model_path = "models/pipe_model.pt"
    elif infra_choice == "Bridges (Cracks)":
        model_path = "models/bridge_model.pt"
    else:
        model_path = "yolov8n.pt"

    # Fallback check in case the user hasn't trained the specific model yet
    if not os.path.exists(model_path):
        return DamageDetector("yolov8n.pt"), False # False = using fallback
        
    return DamageDetector(model_path), True # True = using custom model

report_gen = ReportGenerator()

st.title("🏗️ Infrastructure Damage Detection")
st.markdown("Analyze images of roads, bridges, and pipelines to identify structural issues.")

# Sidebar for settings
with st.sidebar:
    st.header("Settings")
    
    # NEW: Dropdown to select what AI model to use!
    infra_type = st.selectbox(
        "Infrastructure Type",
        ["Roads (Potholes)", "Pipelines (Leaks)", "Bridges (Cracks)"]
    )
    
    confidence_threshold = st.slider("Confidence Threshold", 0.0, 1.0, 0.25, 0.05)
    st.markdown("---")
    st.info("System uses YOLOv8 for real-time edge detection and analysis.")

# Load the dynamic model based on the dropdown
detector, is_custom_model = load_detector(infra_type)

if not is_custom_model:
    st.sidebar.warning(f"⚠️ Custom AI Weights for '{infra_type}' not found! Place your trained .pt file in the models/ folder and rename it accordingly. (Running fallback base model in the meantime).")

input_method = st.radio("Choose Input Method:", ["Upload Image/Video", "Live Hardware Tracking (Webcam)"], horizontal=True)
st.markdown("---")

detections = []
display_detections = []
temp_img_path = ""

if input_method == "Live Hardware Tracking (Webcam)":
    st.subheader("🔴 Live Hardware Tracking")
    st.info("This uses your physical desktop webcam. When initiated, a hardware-accelerated pop-up window will open. Aim it at the defects!")
    st.warning("⚠️ Press the **'q'** key on your keyboard inside the Video pop-up window to STOP tracking and generate reports!")
    
    if st.button("▶️ Launch Hardware Tracker"):
        with st.spinner("Tracking Engine Live. Look at the pop-up window..."):
            key_frames, detections = detector.predict_livestream(confidence_threshold)
            
        st.markdown("---")
        st.subheader("Tracking Session Results")
        
        if len(detections) > 0:
            st.success(f"Tracking session terminated. Gathered {len(key_frames)} unique incidents!")
            
            display_detections = [{k: v for k, v in d.items() if k != "image_path"} for d in detections]
            st.dataframe(display_detections, use_container_width=True)
            
            st.subheader("Incident Gallery")
            cols = st.columns(3)
            for i, frame in enumerate(key_frames):
                cols[i % 3].image(frame, use_container_width=True, caption=f"Capture #{i+1}")
                
            temp_img_path = detections[0]["image_path"]
        else:
            st.success("Session terminated. Area clear, no incidents detected!")

else:
    uploaded_file = st.file_uploader(f"Upload an image or video of a {infra_type.split(' ')[0][:-1]}...", type=["jpg", "jpeg", "png", "mp4", "avi"])

    if uploaded_file is not None:
        
        # ======== IMAGE PROCESSING ========
        if uploaded_file.type.startswith("image"):
            col1, col2 = st.columns(2)
            
            with col1:
                st.subheader("Original Image")
                image = Image.open(uploaded_file).convert("RGB")
                st.image(image, use_container_width=True)
                
            with st.spinner("Analyzing image for damages..."):
                annotated_img_rgb, detections = detector.predict_image(image, confidence_threshold)
                
            with col2:
                st.subheader("Detections")
                st.image(annotated_img_rgb, caption=f"Found {len(detections)} object(s)", use_container_width=True)
                
            st.markdown("---")
            st.subheader("Analysis Results")
            
            if len(detections) > 0:
                st.dataframe(detections, use_container_width=True)
            else:
                st.success("No issues detected based on the current confidence threshold.")
                
            temp_img_path = os.path.join("data", f"temp_{uuid.uuid4().hex}.jpg")
            img_to_save = Image.fromarray(annotated_img_rgb)
            img_to_save.save(temp_img_path)
                
        # ======== VIDEO PROCESSING ========
        else:
            st.subheader("📹 Video Analysis: Intelligent Key-Frame Extraction")
            st.info("The AI is watching the video stream and extracting timestamps where damages occur. This takes a few moments...")
            
            temp_video_path = os.path.join("data", f"temp_video_{uuid.uuid4().hex}.mp4")
            with open(temp_video_path, "wb") as f:
                f.write(uploaded_file.getbuffer())
                
            with st.spinner("Scanning video stream..."):
                key_frames, detections = detector.predict_video(temp_video_path, confidence_threshold)
                
            st.markdown("---")
            st.subheader("Video Analysis Results")
            
            if len(detections) > 0:
                st.success(f"Video analysis complete! Extracted {len(key_frames)} key frames containing damage incidents.")
                
                display_detections = [{k: v for k, v in d.items() if k != "image_path"} for d in detections]
                st.dataframe(display_detections, use_container_width=True)
                
                st.subheader("Incident Gallery")
                cols = st.columns(3)
                for i, frame in enumerate(key_frames):
                    cols[i % 3].image(frame, use_container_width=True, caption=f"Incident #{i+1}")
                    
                temp_img_path = detections[0]["image_path"]
            else:
                st.success("Scan complete! No structural damage was found in the video recording.")
                temp_img_path = ""
                
            try:
                os.remove(temp_video_path)
            except:
                pass


# ======== UNIVERSAL REPORT GENERATOR ========
if len(detections) > 0:
    st.subheader("Generate Engineering Reports")
    
    col_btn1, col_btn2 = st.columns(2)
    csv_path = os.path.join("reports", "inspection_report.csv")
    pdf_path = os.path.join("reports", "inspection_report.pdf")
    
    with col_btn1:
        report_gen.generate_csv_report(detections, csv_path)
        with open(csv_path, "rb") as file:
            st.download_button(label="📥 Download CSV Report", data=file, file_name="inspection_report.csv", mime="text/csv")
            
    with col_btn2:
        if temp_img_path and os.path.exists(temp_img_path):
            report_gen.generate_pdf_report(detections, temp_img_path, pdf_path)
            with open(pdf_path, "rb") as file:
                st.download_button(label="📄 Download PDF Report", data=file, file_name="inspection_report.pdf", mime="application/pdf")
