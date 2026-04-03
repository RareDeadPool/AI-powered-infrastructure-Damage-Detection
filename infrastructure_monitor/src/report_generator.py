import pandas as pd
from fpdf import FPDF
import datetime
import os

class ReportGenerator:
    def __init__(self):
        pass

    def generate_csv_report(self, detection_data, output_path):
        """Generates a structured spreadsheet report from YOLO detections."""
        if not detection_data:
            # Handle empty detections
            df = pd.DataFrame(columns=["Damage Type", "Confidence", "Est. Length (cm)", "Severity", "Action Priority", "Bounding Box"])
        else:
            df = pd.DataFrame(detection_data)
        df.to_csv(output_path, index=False)
        return output_path
        
    def generate_pdf_report(self, detection_data, annotated_image_path, output_path):
        """Generates a structured PDF inspection report."""
        pdf = FPDF()
        pdf.add_page()
        pdf.set_font("Arial", 'B', 16)
        
        pdf.cell(190, 10, txt="Infrastructure Inspection Report", ln=1, align='C')
        pdf.set_font("Arial", '', 12)
        pdf.cell(190, 10, txt=f"Date: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}", ln=1, align='C')
        pdf.ln(10)
        
        # Add summary
        pdf.set_font("Arial", 'B', 14)
        pdf.cell(190, 10, txt="1. Summary of Detections", ln=1, align='L')
        pdf.set_font("Arial", '', 12)
        
        if len(detection_data) == 0:
            pdf.cell(190, 10, txt="No damage detected in this inspection.", ln=1, align='L')
        else:
            pdf.cell(190, 10, txt=f"Total issues detected: {len(detection_data)}", ln=1, align='L')
            pdf.ln(5)
            
            # Table header
            pdf.set_font("Arial", 'B', 10) # Smaller font to fit everything
            pdf.cell(35, 10, txt="Damage Type", border=1, align='C')
            pdf.cell(25, 10, txt="Confidence", border=1, align='C')
            pdf.cell(30, 10, txt="Est. Size(cm)", border=1, align='C')
            pdf.cell(40, 10, txt="Severity", border=1, align='C')
            pdf.cell(60, 10, txt="Action Priority", border=1, align='C')
            pdf.ln(10)
            
            pdf.set_font("Arial", '', 10)
            for item in detection_data:
                # Need to encode emojis manually or safely strip them for PDF as FPDF core lacks unicode emoji support
                safe_severity = item["Severity"].replace("🔴 ", "").replace("🟠 ", "").replace("🟢 ", "")
                
                pdf.cell(35, 10, txt=str(item["Damage Type"]), border=1, align='C')
                pdf.cell(25, 10, txt=str(item["Confidence"]), border=1, align='C')
                pdf.cell(30, 10, txt=str(item["Est. Length (cm)"]), border=1, align='C')
                pdf.cell(40, 10, txt=safe_severity, border=1, align='C')
                pdf.cell(60, 10, txt=str(item["Action Priority"]), border=1, align='C')
                pdf.ln(10)
                
        pdf.ln(10)
        
        # Add image
        if os.path.exists(annotated_image_path):
            pdf.set_font("Arial", 'B', 14)
            pdf.cell(190, 10, txt="2. Annotated Image", ln=1, align='L')

            # Adjust image width to fit the page 
            pdf.image(annotated_image_path, x=10, w=190)
            
        pdf.output(output_path)
        return output_path
