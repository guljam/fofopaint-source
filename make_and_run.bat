@echo off

rem 첫 번째 명령: Animate 실행
"C:\Program Files\Adobe\Adobe Animate 2022\Animate.exe" -s "E:\fofopaint-source\makeswf.jsfl"

rem 두 번째 명령: ADL 실행
"E:/AIRSDK_Windows_51.1.3/AIRSDK_Windows/bin/adl.exe" "E:/fofopaint-source/fofoPaint-app.xml" -nodebug
