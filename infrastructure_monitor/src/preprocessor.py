import cv2
import numpy as np

class VisualOptimizer:
    """
    AI-inspired preprocessing pipeline to enhance image quality for infrastructure detection.
    Focuses on low-light enhancement, noise reduction, and edge contrast for cracks.
    """
    
    @staticmethod
    def enhance_image(image_bgr):
        if image_bgr is None:
            return None
            
        # 1. LOW LIGHT ENHANCEMENT (Adaptive Gamma Correction)
        # Calculates mean brightness and adjusts gamma dynamically
        gray = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2GRAY)
        mean_brightness = np.mean(gray)
        
        if mean_brightness < 100:  # Dark image
            gamma = 0.7  # Brighten
        elif mean_brightness > 180:  # Too bright
            gamma = 1.3  # Darken
        else:
            gamma = 1.0
            
        if gamma != 1.0:
            invGamma = 1.0 / gamma
            table = np.array([((i / 255.0) ** invGamma) * 255 for i in np.arange(0, 256)]).astype("uint8")
            image_bgr = cv2.LUT(image_bgr, table)

        # 2. CONTRAST OPTIMIZATION (CLAHE - Contrast Limited Adaptive Histogram Equalization)
        # This "AI-like" technique adapts to local textures, making cracks and leaks stand out.
        lab = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2LAB)
        l, a, b = cv2.split(lab)
        
        # Apply CLAHE to L-channel
        clahe = cv2.createCLAHE(clipLimit=2.5, tileGridSize=(8, 8))
        cl = clahe.apply(l)
        
        limg = cv2.merge((cl, a, b))
        enhanced = cv2.cvtColor(limg, cv2.COLOR_LAB2BGR)

        # 3. INTELLIGENT DENOISING
        # Removes sensor noise which can confuse the YOLO model during crack detection.
        denoised = cv2.fastNlMeansDenoisingColored(enhanced, None, 7, 7, 7, 21)

        # 4. EDGE SHARPENING
        # Makes structural damages like cracks sharper for the model's feature extractor.
        kernel = np.array([[-1,-1,-1], 
                          [-1, 9,-1],
                          [-1,-1,-1]])
        sharpened = cv2.filter2D(denoised, -1, kernel)
        
        # Blend sharpened with denoised to avoid over-exaggerated artifacts
        final_output = cv2.addWeighted(denoised, 0.7, sharpened, 0.3, 0)

        return final_output
