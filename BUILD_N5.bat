@echo off
title JLPT N5 Thi Thu - build
cd /d D:\100.JLPT\jlpt_n5_mock_test
set PATH=C:\Users\admin\develop\bin;%PATH%
if not exist _build mkdir _build
del /q _build\*.txt _build\*.log 2>nul
echo [1/5] flutter create ...
echo CREATE> _build\status.txt
call flutter create --platforms=android,ios --org com.manabihub --project-name jlpt_mock_test . > _build\build.log 2>&1
echo CREATED %ERRORLEVEL%> _build\status.txt
echo [2/5] Doi Claude cau hinh native (ten app, icon, quyen TTS) ...
python -c "import sys" >nul 2>&1 && python tools\configure_native.py >> _build\build.log 2>&1 && echo ok> _build\configured.txt
:wait
if exist _build\configured.txt goto go
timeout /t 3 /nobreak >nul
goto wait
:go
echo [3/5] flutter pub get + analyze ...
call flutter pub get >> _build\build.log 2>&1
call flutter analyze --no-fatal-infos >> _build\build.log 2>&1
echo ANALYZE %ERRORLEVEL%>> _build\status.txt
echo [4/5] flutter test ...
call flutter test >> _build\build.log 2>&1
echo TEST %ERRORLEVEL%>> _build\status.txt
echo [5/5] flutter build apk --release ...
call flutter build apk --release >> _build\build.log 2>&1
echo BUILD %ERRORLEVEL%>> _build\status.txt
echo DONE>> _build\status.txt
echo.
echo Xong! Ket qua: _build\status.txt  -  APK: build\app\outputs\flutter-apk\app-release.apk
pause
