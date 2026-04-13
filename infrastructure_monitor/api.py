from fastapi import FastAPI, File, UploadFile, Form
from fastapi.responses import FileResponse, JSONResponse
import uvicorn
import os
import uuid
import json
from PIL import Image
import io

# Import the core modules from our infrastructure
from src.detector import DamageDetector
from src.report_generator import ReportGenerator

app = FastAPI(title="Infrastructure Monitor Backend API", description="API endpoints for the Flutter Mobile App")

# Create necessary folders if they don't exist
os.makedirs("data/api_uploads", exist_ok=True)
os.makedirs("reports/api_reports", exist_ok=True)

# Load the core model - adjust model_path to whichever model trained best!
MODEL_PATH = "models/pipe_model.pt"
if not os.path.exists(MODEL_PATH):
    MODEL_PATH = "yolov8n.pt"

detector = DamageDetector(model_path=MODEL_PATH)
report_gen = ReportGenerator()

@app.get("/")
def home():
    return {"message": "Infrastructure Monitor Backend is running!"}

@app.post("/api/analyze/image")
async def analyze_image(file: UploadFile = File(...)):
    """Receives an image from the Flutter app camera, scans it with YOLO, and returns the findings."""
    try:
        contents = await file.read()
        image = Image.open(io.BytesIO(contents)).convert("RGB")
        
        # Pass image to our YOLO AI engine
        annotated_img_rgb, detections = detector.predict_image(image, conf_threshold=0.25)
        
        # Save the result so the Flutter app can download the marked photo later
        incident_id = uuid.uuid4().hex[:8]
        output_path = f"data/api_uploads/incident_{incident_id}.jpg"
        
        # Save image utilizing PIL
        img_to_save = Image.fromarray(annotated_img_rgb)
        img_to_save.save(output_path)
        
        return {
            "status": "success",
            "incident_id": incident_id,
            "detections": detections,
            "message": f"Successfully analyzed image. Found {len(detections)} issues."
        }
    except Exception as e:
        return JSONResponse(status_code=500, content={"error": str(e)})

@app.get("/api/files/{incident_id}")
async def get_incident_image(incident_id: str):
    """Allows the Flutter app to download the highlighted result photo."""
    file_path = f"data/api_uploads/incident_{incident_id}.jpg"
    if os.path.exists(file_path):
        return FileResponse(file_path, media_type="image/jpeg")
    return JSONResponse(status_code=404, content={"error": "Image not found"})

@app.post("/api/report/generate")
async def generate_inspection_report(
    incident_id: str = Form(...),
    location_name: str = Form(...),
    detections_json: str = Form(...)  # Flutter passes the detections array as a JSON string
):
    """Combines the location name (e.g. 'Subhash Road') and detections into a final engineering PDF."""
    try:
        detections = json.loads(detections_json)
        image_path = f"data/api_uploads/incident_{incident_id}.jpg"
        
        # Create a customized title for the report
        inspection_title = f"Infrastructure Inspection Report - {location_name}"
        pdf_path = f"reports/api_reports/Inspection_{location_name.replace(' ', '_')}_{incident_id}.pdf"
        
        # Fire up our ReportGenerator!
        report_gen.generate_pdf_report(detections, image_path, pdf_path, inspection_title=inspection_title)
        
        # Immediately send the PDF binary back to the Flutter app as a download package
        return FileResponse(
            pdf_path, 
            media_type="application/pdf", 
            filename=f"Inspection_{location_name}.pdf"
        )
    except Exception as e:
        return JSONResponse(status_code=500, content={"error": str(e)})

if __name__ == "__main__":
    print("🚀 Firing up FastAPI Backend for Mobile App Integration...")
    uvicorn.run("api:app", host="0.0.0.0", port=8000, reload=True)
