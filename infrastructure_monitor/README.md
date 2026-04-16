# Infrastructure Damage Detection

An AI-powered infrastructure damage detection system that analyzes images and videos of roads, bridges, and pipelines to identify structural issues such as potholes, cracks, and leaks using YOLOv8.

## Folder Structure

- `app.py`: Main Streamlit application
- `src/`: Source code including YOLO inference and reporting logic
- `models/`: Directory for YOLO model weights
- `reports/`: Generated PDF/CSV reports saved here
- `data/`: Sample inputs for testing

## How to Run

1. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
2. Run the Streamlit app:
   ```bash
   streamlit run app.py
   ```
