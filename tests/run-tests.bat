@echo off
REM Fighting Force — Headless Test Runner
REM Runs GDScript tests via Godot headless mode

set GODOT=Z:\godot\godot.exe
set PROJECT_DIR=%~dp0..

echo [AMATRIS] Running headless tests for Fighting Force...
"%GODOT%" --path "%PROJECT_DIR%" --headless --script res://tests/run_tests.gd

if %ERRORLEVEL% NEQ 0 (
    echo [AMATRIS] Tests failed with exit code %ERRORLEVEL%
    exit /b %ERRORLEVEL%
)

echo [AMATRIS] Tests completed successfully.
exit /b 0
