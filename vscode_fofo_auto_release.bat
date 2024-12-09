notepad F:\ssdbackup\2020FlashPaint\versionInfo.txt
notepad F:\ssdbackup\2020FlashPaint\releasenote.txt
notepad F:\ssdbackup\2020FlashPaint\README.md

Powershell.exe -noprofile -executionpolicy bypass -file "_make_air_file.ps1"

git add .
git commit --file=F:\ssdbackup\2020FlashPaint\versionInfo.txt
git push

cd F:\ssdbackup\2020FlashPaint
git add versionInfo.txt
git add releasenote.txt
git add README.md
git commit --file=versionInfo.txt
git push
gh release upload update2 F:\ssdbackup\fofopaint-source\bin\fofoPaint.air --clobber