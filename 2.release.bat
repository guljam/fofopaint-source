cd E:\2020FlashPaint

notepad versionInfo.txt
notepad releasenote.txt

git add .
git commit --file=versionInfo.txt
git push

gh release upload setup E:\fofopaint-source\bin\fofoPaint.exe --clobber
gh release upload update2 E:\fofopaint-source\bin\fofoPaint.air --clobber