# AI-Powered Infrastructure Damage Detection: Project Overview

## 1) Project Summary

This project is an end-to-end infrastructure inspection system built around YOLOv8. It supports:

- Training custom models for infrastructure defects.
- Running desktop inference via a Streamlit app.
- Serving inference/report APIs via FastAPI.
- Integrating with a Flutter mobile app (currently API-first, with local TFLite hook points prepared).

Primary inspection targets in the current codebase:

- Roads (potholes)
- Pipelines (leaks/bursts/corrosion depending on dataset)
- Bridges (cracks)


## 2) High-Level Architecture

The project has three runtime paths:

1. Training Path
- Dataset in `data/` + config in `data/data.yaml`
- Training script in `train_model.py`
- Weights generated in `runs/` and copied into `models/`

2. Desktop App Path (Streamlit)
- UI in `app.py`
- Inference engine in `src/detector.py`
- Reporting in `src/report_generator.py`

3. Mobile Path (Flutter + FastAPI)
- Backend API in `api.py`
- Flutter app in `mobile_app/`
- Flutter currently uses API service and also includes a local on-device YOLO/TFLite service scaffold in `mobile_app/lib/services/yolo_vision_service.dart`


## 3) Repository Directory Guide

### Root Files

- `app.py`
  - Main Streamlit UI.
  - Lets user select infrastructure type, upload image/video, or run live webcam tracking.
  - Dynamically loads model from `models/` and falls back to `yolov8n.pt`.

- `api.py`
  - FastAPI backend for mobile integration.
  - Endpoints for image analysis, annotated image retrieval, and PDF report generation.

- `train_model.py`
  - Starts YOLOv8 segmentation training using `yolov8n-seg.pt` and `data/data.yaml`.
  - Writes training outputs to `runs/segment/...`.
  - Copies selected best model to `models/pipe_model.pt`.

- `init_dirs.py`
  - Creates required runtime folders: `models/`, `reports/`, `data/`.

- `requirements.txt`
  - Python dependencies for desktop/API path.

- `data.yaml` (root)
  - Additional dataset config variant (legacy/alternate).

- `yolov8n.pt`
  - Generic YOLOv8 detection base model (fallback in app/API).

- `yolov8n-seg.pt`
  - YOLOv8 segmentation base model used as training starting point.


### Key Folders

- `src/`
  - `detector.py`: Core inference class (`DamageDetector`) for image, video, and live webcam analysis.
    - Uses Ultralytics YOLO inference.
    - Applies heuristics for severity/priority from relative box area.
    - If segmentation masks are available, overlays polygon masks; otherwise falls back to contour/box visualization.
  - `report_generator.py`: CSV/PDF report generation.

- `models/`
  - Deployment-ready model weights referenced by app/API.
  - Current files:
    - `road_model.pt`
    - `pipe_model.pt`
    - `bridge_model.pt`

- `data/`
  - Training/validation/test dataset and labels.
  - Contains `data.yaml` used by training script and Roboflow metadata files.

- `runs/`
  - Training outputs from Ultralytics.
  - `runs/detect/...`: Detection experiments.
  - `runs/segment/...`: Segmentation experiments.
  - Each run typically includes `weights/best.pt`, `weights/last.pt`, plots, and `results.csv`.

- `reports/`
  - Generated inspection reports (CSV/PDF), including API-generated reports.

- `mobile_app/`
  - Flutter client app.
  - Includes screens for dashboard, project setup, camera inspection flow.
  - Service layer includes:
    - `api_service.dart` for FastAPI calls.
    - `yolo_vision_service.dart` as local TFLite/YOLO integration scaffold.


## 4) End-to-End Flow

### A) Training Flow

1. Prepare dataset in YOLO format under `data/`.
2. Set dataset config in `data/data.yaml`.
3. Run training via `train_model.py`.
4. Ultralytics saves checkpoints to `runs/segment/pipeline_segmentation_model*/weights/best.pt`.
5. Selected best model is copied to `models/pipe_model.pt` for application inference.


### B) Streamlit Inference Flow

1. User chooses infrastructure type in sidebar.
2. `app.py` maps selection to one of:
   - `models/road_model.pt`
   - `models/pipe_model.pt`
   - `models/bridge_model.pt`
3. `DamageDetector` runs YOLO prediction.
4. Results are post-processed:
   - Bounding boxes
   - Optional segmentation mask overlay when present
   - Severity and action priority scoring
5. UI displays detections and lets user download CSV/PDF reports.


### C) FastAPI + Flutter Flow

1. Flutter captures image and uploads to `/api/analyze/image`.
2. API runs detector on server and returns structured detections + incident ID.
3. Flutter can fetch annotated result image via `/api/files/{incident_id}`.
4. Flutter can request report generation via `/api/report/generate`.
5. API returns generated PDF report file.


### D) Flutter On-Device (Planned/Scaffolded)

- `mobile_app/lib/services/yolo_vision_service.dart` is prepared for direct TFLite YOLO inference.
- Current implementation is a stub/mock and should be replaced with real local model loading and prediction logic.
- This is the integration point for your future `model.tflite` pipeline.


## 5) Models Used in This Project

### Base Models

- `yolov8n.pt`
  - Base object detection model.
  - Used as fallback when custom task-specific weights are not found.

- `yolov8n-seg.pt`
  - Base segmentation model.
  - Used as initialization checkpoint for segmentation training.


### Task-Specific Application Models (`models/`)

- `road_model.pt`
  - Intended for road defect/pothole detection use case.

- `pipe_model.pt`
  - Intended for pipeline defects (leaks/bursts/corrosion depending on training data).
  - Used as default API model in `api.py`.

- `bridge_model.pt`
  - Intended for bridge crack detection use case.


### Historical/Experimental Trained Models (`runs/`)

The project contains multiple completed runs, including:

- Segmentation runs:
  - `runs/segment/pipeline_segmentation_model2/weights/best.pt`
  - `runs/segment/pipeline_segmentation_model3/weights/best.pt`
  - `runs/segment/pipeline_segmentation_model4/weights/best.pt`

- Detection runs:
  - `runs/detect/bridge_model/weights/best.pt`
  - `runs/detect/bridge_model2/weights/best.pt`
  - `runs/detect/bridge_model3/weights/best.pt`
  - `runs/detect/bridge_model4/weights/best.pt`
  - `runs/detect/infrastructure_damage_model/weights/best.pt`
  - `runs/detect/pipe_leak_model2/weights/best.pt`
  - `runs/detect/pipe_leak_model_v2/weights/best.pt`
  - `runs/detect/pipeline_dataset2_model2/weights/best.pt`
  - `runs/detect/corrosion_pipeline_model2/weights/best.pt`


## 6) Current State Notes

- The system blends detection and segmentation artifacts. `detector.py` supports segmentation mask overlays when masks are available.
- Streamlit model switching is dynamic by infrastructure type.
- API currently pins to `models/pipe_model.pt` (fallback to `yolov8n.pt` if missing).
- Flutter app includes both API-first flow and local TFLite integration placeholder.


## 7) Suggested Operational Workflow

1. Train and validate best model in `runs/`.
2. Promote chosen weight file to `models/` with stable naming.
3. Verify in Streamlit desktop app.
4. Verify via FastAPI endpoint.
5. Integrate converted TFLite model into `yolo_vision_service.dart` for offline inference.


## 8) Quick Start Commands

From project root:

```bash
python init_dirs.py
pip install -r requirements.txt
```

Run desktop app:

```bash
streamlit run app.py
```

Run backend API:

```bash
python api.py
```

Run training:

```bash
python train_model.py
```


## 9) Tech Stack

- AI/ML: Ultralytics YOLOv8
- CV/Image: OpenCV, Pillow
- Data/Reports: pandas, fpdf
- Desktop UI: Streamlit
- Backend API: FastAPI + Uvicorn
- Mobile Frontend: Flutter
