@echo off
cd C:\Consumer360

REM Step 1: Run Python pipeline
python main_pipeline.py

REM Step 2: Open Power BI report
start "" "C:\Program Files\Microsoft Power BI Desktop\bin\PBIDesktop.exe" "C:\Consumer360\Consumer360_Report.pbix"

REM Wait 120 seconds for refresh
timeout /t 120

taskkill /im PBIDesktop.exe /f
