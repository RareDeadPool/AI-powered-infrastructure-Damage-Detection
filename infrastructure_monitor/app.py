import streamlit as st
import os
import cv2
from PIL import Image
import uuid

# Import our custom modules from the source directory
from src.detector import DamageDetector
from src.report_generator import ReportGenerator

st.set_page_config(page_title="Infrastructure Damage Detection", page_icon="🏗️", layout="wide")

# Unified model path used across Streamlit and API
UNIFIED_MODEL_PATH = "models/final_model.pt"


# Initialize detector once and cache for performance
@st.cache_resource
def load_detector():
    if os.path.exists(UNIFIED_MODEL_PATH):
        return DamageDetector(UNIFIED_MODEL_PATH), True
    return DamageDetector("yolov8n.pt"), False

report_gen = ReportGenerator()

st.title("🏗️ Infrastructure Damage Detection")
st.markdown("Analyze images of roads, bridges, and pipelines to identify structural issues.")

# Sidebar for settings
with st.sidebar:
    st.header("Settings")

    confidence_threshold = st.slider("Confidence Threshold", 0.0, 1.0, 0.25, 0.05)
    use_enhancement = st.checkbox("✨ AI Image Optimization", value=True, help="Enhances brightness, contrast, and sharpness for better detection in low-light or blurry conditions.")
    st.markdown("---")
    st.info("System uses one unified YOLOv8 detection model for all infrastructure classes.")

# Load one unified model for all predictions
detector, is_custom_model = load_detector()

if not is_custom_model:
    st.sidebar.warning("⚠️ Unified weights not found at models/final_model.pt. Running fallback yolov8n.pt.")

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
            key_frames, detections = detector.predict_livestream(confidence_threshold, use_enhancement=use_enhancement)
            
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
    uploaded_file = st.file_uploader("Upload an infrastructure image or video...", type=["jpg", "jpeg", "png", "mp4", "avi"])

    if uploaded_file is not None:
        
        # ======== IMAGE PROCESSING ========
        if uploaded_file.type.startswith("image"):
            col1, col2 = st.columns(2)
            image = Image.open(uploaded_file).convert("RGB")
            
            with st.spinner("Analyzing image for damages..."):
                annotated_img_rgb, detections, enhanced_bgr = detector.predict_image(image, confidence_threshold, use_enhancement=use_enhancement)
                
            with col1:
                if use_enhancement:
                    st.subheader("Optimized Image (AI Enhanced)")
                    enhanced_rgb = cv2.cvtColor(enhanced_bgr, cv2.COLOR_BGR2RGB)
                    st.image(enhanced_rgb, use_container_width=True)
                else:
                    st.subheader("Original Image")
                    st.image(image, use_container_width=True)
                
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
                key_frames, detections = detector.predict_video(temp_video_path, confidence_threshold, use_enhancement=use_enhancement)
                
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
