notepad D:\github_clones\2020FlashPaint\versionInfo.txt
notepad D:\github_clones\2020FlashPaint\releasenote.txt
notepad D:\github_clones\2020FlashPaint\README.md

Powershell.exe -noprofile -executionpolicy bypass -file "_make_air_file.ps1"

git add .
git commit --file=cd D:\github_clones\2020FlashPaint\versionInfo.txt
git push

D:

cd github_clones\2020FlashPaint\
git add .
git commit --file=D:\github_clones\2020FlashPaint\versionInfo.txt
git push

gh release upload update2 E:\fofopaint-source\bin\fofoPaint.air --clobber
