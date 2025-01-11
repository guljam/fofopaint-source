notepad F:\2020FlashPaint\versionInfo.txt
notepad F:\2020FlashPaint\releasenote.txt
notepad F:\2020FlashPaint\README.md

Powershell.exe -noprofile -executionpolicy bypass -file "_make_air_file.ps1"

git add .
git commit --file=F:\2020FlashPaint\versionInfo.txt
git push

F:\
git add 2020FlashPaint\versionInfo.txt
git add 2020FlashPaint\releasenote.txt
git add 2020FlashPaint\README.md
git commit --file=F:\2020FlashPaint\versionInfo.txt
git push
gh release upload update2 E:\fofopaint-source\bin\fofoPaint.air --clobber
