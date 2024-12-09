notepad F:\ssdbackup\2020FlashPaint\versionInfo.txt

git add .
git commit --file=F:\ssdbackup\2020FlashPaint\versionInfo.txt
git push

cd F:\ssdbackup\2020FlashPaint
git add versionInfo.txt
git commit --file=versionInfo.txt
git push
gh release upload setup F:\ssdbackup\fofopaint-source\bin\fofoPaint.exe --clobber
gh release upload update2 F:\ssdbackup\fofopaint-source\bin\fofoPaint.air --clobber