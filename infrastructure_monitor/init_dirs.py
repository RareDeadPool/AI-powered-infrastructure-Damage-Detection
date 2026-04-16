# We need this to ensure the models and reports directories exist during runtime
import os

os.makedirs("models", exist_ok=True)
os.makedirs("reports", exist_ok=True)
os.makedirs("data", exist_ok=True)
