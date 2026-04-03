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
def load_detector():
    # In a real scenario, this would be a custom trained model for damage detection.
    # Using yolov8n.pt will just identify general objects (cars, persons), but it proves the pipeline.
    return DamageDetector("models/best.pt")

detector = load_detector()
report_gen = ReportGenerator()

st.title("🏗️ Infrastructure Damage Detection")
st.markdown("Analyze images of roads, bridges, and pipelines to identify structural issues.")

# Sidebar for settings
with st.sidebar:
    st.header("Settings")
    confidence_threshold = st.slider("Confidence Threshold", 0.0, 1.0, 0.25, 0.05)
    st.markdown("---")
    st.info("System uses YOLOv8 for real-time edge detection and analysis.")
    st.warning("Note: Currently using the base YOLOv8 model for demonstration. A custom trained model (e.g., best.pt) should be connected to detect real-world damage like 'potholes' or 'cracks'.")

uploaded_file = st.file_uploader("Upload an image...", type=["jpg", "jpeg", "png"])

if uploaded_file is not None:
    # Process image
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("Original Image")
        # Read and display uploaded image
        image = Image.open(uploaded_file).convert("RGB")
        st.image(image, use_container_width=True)
        
    with st.spinner("Analyzing image for damages..."):
        # Predict using YOLO
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
        
    # Generate reports dynamically 
    st.subheader("Generate Reports")
    
    # Save the annotated image temporarily for the PDF report attachment
    temp_img_path = os.path.join("data", f"temp_{uuid.uuid4().hex}.jpg")
    img_to_save = Image.fromarray(annotated_img_rgb)
    img_to_save.save(temp_img_path)
    
    col_btn1, col_btn2 = st.columns(2)
    
    csv_path = os.path.join("reports", "inspection_report.csv")
    pdf_path = os.path.join("reports", "inspection_report.pdf")
    
    with col_btn1:
        report_gen.generate_csv_report(detections, csv_path)
        with open(csv_path, "rb") as file:
            st.download_button(
                label="📥 Download CSV Report",
                data=file,
                file_name="inspection_report.csv",
                mime="text/csv"
            )
            
    with col_btn2:
        report_gen.generate_pdf_report(detections, temp_img_path, pdf_path)
        with open(pdf_path, "rb") as file:
            st.download_button(
                label="📄 Download PDF Report",
                data=file,
                file_name="inspection_report.pdf",
                mime="application/pdf"
            )
