# Unified YOLOv8 Detection Refactor (Single Model)

This guide explains how to move from multiple infrastructure-specific models to one unified model in this project.

## What Has Been Refactored in Code

- Unified model selector script added:
  - `scripts/select_and_promote_unified_model.py`
- Detection pipeline converted to pure bounding-box inference (no segmentation overlays):
  - `src/detector.py`
- Streamlit now loads one model path for all infrastructure classes:
  - `app.py`
- FastAPI now loads one model path for all infrastructure classes:
  - `api.py`

The unified runtime path is now:
- `models/final_model.pt`

---

## Step 1: Verify Candidate Runs and Pick Best Model

Run this from project root:

```bash
/Users/manastamboli/Documents/Manas/code/AI-powered-infrastructure-Damage-Detection/infrastructure_monitor/.venv/bin/python scripts/select_and_promote_unified_model.py
```

What it does:
- Scans `runs/detect/*`
- Reads each `results.csv`
- Picks the highest `metrics/mAP50-95(B)` model
- Reads classes from `weights/best.pt`
- Checks expected classes:
  - `pothole`
  - `road_crack`
  - `bridge_crack`
  - `pipeline_leak`
- Copies selected model to `models/final_model.pt` if validation passes
- Writes metadata to `models/final_model_meta.json`

If class coverage is incomplete, it fails fast by default and tells you what is missing.

---

## Step 2: If Needed, Force Promotion for Hackathon Demo

If you want to proceed quickly even when classes are incomplete:

```bash
/Users/manastamboli/Documents/Manas/code/AI-powered-infrastructure-Damage-Detection/infrastructure_monitor/.venv/bin/python scripts/select_and_promote_unified_model.py --allow-partial
```

Or choose a specific run manually:

```bash
/Users/manastamboli/Documents/Manas/code/AI-powered-infrastructure-Damage-Detection/infrastructure_monitor/.venv/bin/python scripts/select_and_promote_unified_model.py --run-name pipe_leak_model_v2 --allow-partial
```

---

## Step 3: Confirm Final Model Metadata

Inspect promoted model metadata:

```bash
cat models/final_model_meta.json
```

Confirm:
- `source_run`
- `best_metric_map50_95`
- `class_names`
- `missing_expected_classes`

---

## Step 4: Unified Inference Usage

No infrastructure-type model switching is used anymore.

- Streamlit:
  - Loads `models/final_model.pt`
  - Falls back to `yolov8n.pt` only if missing
- FastAPI:
  - Loads `models/final_model.pt`
  - Falls back to `yolov8n.pt` only if missing

---

## Step 5: Detection-Only Output Format

Segmentation-specific logic has been removed from `src/detector.py`.

Outputs are based on:
- Bounding boxes
- Class label
- Confidence
- Area-based severity/priority

Detection result format remains API/UI compatible:

```json
{
  "Damage Type": "Pothole",
  "Confidence": "87.3%",
  "Est. Length (cm)": "12.5% Area",
  "Severity": "🔴 High",
  "Action Priority": "Immediate Repair",
  "Bounding Box": [100.0, 150.0, 300.0, 450.0]
}
```

---

## Step 6: Quick Validation Tests

### A) Syntax/Import check

```bash
/Users/manastamboli/Documents/Manas/code/AI-powered-infrastructure-Damage-Detection/infrastructure_monitor/.venv/bin/python -m py_compile app.py api.py src/detector.py scripts/select_and_promote_unified_model.py
```

### B) Streamlit test

```bash
streamlit run app.py
```

Verify:
- Image upload works
- Video analysis works
- Webcam mode works
- Bounding boxes + labels are rendered
- CSV/PDF export still works
- No segmentation-mask errors are shown

### C) FastAPI test

```bash
python api.py
```

Then test endpoint:

```bash
curl -X POST "http://127.0.0.1:8000/api/analyze/image" -F "file=@data/test/images/sample.jpg"
```

Verify response includes:
- `status`
- `incident_id`
- `detections` list in expected structure

---

## Step 7: Required Class Coverage Reality Check

Based on current runs in this repository, many top runs are single-domain models (for example only pothole or only burst/corrosion).

If no run contains all required classes (`pothole`, `road_crack`, `bridge_crack`, `pipeline_leak`), you should retrain one multi-class detect model and then promote it using the same script.

Recommended retraining strategy:
1. Merge all labeled data into one YOLO detect dataset.
2. Use canonical class names exactly:
   - pothole
   - road_crack
   - bridge_crack
   - pipeline_leak
3. Train with YOLOv8 detect (`yolov8n.pt` or larger if needed).
4. Run promotion script again (without `--allow-partial`).

---

## Step 8: Rollback Plan (Safe)

If anything fails:
1. Keep old files in git history and branch.
2. Repoint model path in `app.py` and `api.py` to old per-domain files temporarily.
3. Restore old `src/detector.py` from previous commit.

This keeps refactor low-risk and reversible during hackathon development.
