cd F:\ssdbackup\2020FlashPaint

notepad versionInfo.txt
notepad releasenote.txt

git add .
git commit --file=versionInfo.txt
git push

gh release upload setup F:\ssdbackup\fofopaint-source\bin\fofoPaint.exe --clobber
gh release upload update2 F:\ssdbackup\fofopaint-source\bin\fofoPaint.air --clobber