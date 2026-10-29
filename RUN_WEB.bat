@echo off
title JLPT N5 Thi Thu - Chrome
cd /d "%~dp0"
set PATH=C:\Users\admin\develop\bin;%PATH%
echo [1/3] Them nen tang web ...
call flutter create --platforms=web --org com.manabihub --project-name jlpt_mock_test . >nul
echo [2/3] flutter pub get ...
call flutter pub get
echo [3/3] Mo app tren Chrome (nhan r de reload, q de thoat) ...
call flutter run -d chrome
pause
