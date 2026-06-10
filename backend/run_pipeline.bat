@echo off
REM run_pipeline.bat
REM Run from backend\ folder: run_pipeline.bat
REM Generates training CSV from DB then trains the habit model.

echo.
echo ========================================
echo  MindMate Model Pipeline
echo ========================================
echo.

cd /d "%~dp0"

echo [1/2] Generating training CSV from database...
python models\prepare_data.py
if errorlevel 1 (
    echo ERROR: prepare_data.py failed
    pause
    exit /b 1
)

echo.
echo [2/2] Training habit model...
python models\train_user_habit_model.py
if errorlevel 1 (
    echo ERROR: train_user_habit_model.py failed
    pause
    exit /b 1
)

echo.
echo ========================================
echo  Done! Model saved to models\users\
echo ========================================
pause