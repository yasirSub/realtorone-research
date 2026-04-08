import pandas as pd
import sys
import os

file_path = r'f:\xcode\office wrok\realtorone\realtorone-research\Deal Room Data.xlsx'
if not os.path.exists(file_path):
    print(f"Error: File not found at {file_path}")
    sys.exit(1)

try:
    # Use openpyxl engine explicitly for xlsx
    df = pd.read_excel(file_path, engine='openpyxl')
    print("Columns:")
    print(df.columns.tolist())
    print("\nFirst 5 rows:")
    print(df.head().to_string())
except Exception as e:
    print(f"Error: {e}")
