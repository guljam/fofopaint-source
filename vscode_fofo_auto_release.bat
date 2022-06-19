notepad D:\2020FlashPaint\versionInfo.txt

Powershell.exe -noprofile -executionpolicy bypass -file "_make_air_file.ps1"
Powershell.exe -noprofile -executionpolicy bypass -file "_make_exe_file.ps1"

git add .
git commit --file=D:\2020FlashPaint\versionInfo.txt
git push

cd D:\2020FlashPaint
git add versionInfo.txt
git commit --file=versionInfo.txt
git push
gh release upload setup D:\fofopaint-source\bin\fofoPaint.exe --clobber
gh release upload update2 D:\fofopaint-source\bin\fofoPaint.air --clobber