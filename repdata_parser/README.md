# 리플레이 명령 파서

Adobe AIR SDK의 `FileStream.readObject()`(AMF3)와 `ByteArray.uncompress()`(zlib)를 사용합니다. 새 `.2020`의 `FOFOPAINT` 헤더 뒤 압축 데이터와 기존 `repdata`/구형 `.2020` 객체 스트림을 읽습니다. 압축을 푼 리플레이가 `FRC1`이면 명령 코덱을 먼저 풀어 AMF3으로 복원합니다. AIR의 `compress()`/`uncompress()` 왕복도 검증합니다.

```powershell
cd E:\fofopaint-source\repdata\_parser
.\run.ps1 'C:\Users\cube4\AppData\Roaming\fofoPaint\Local Store\2801\repdata'
.\run.ps1 'F:\그림백업\낙서모음\23\queue\2\[2026-09-08]_UkoHZ4xn.2020' '.\output\real-sample'
.\run.ps1 'D:\example\drawing.2020' 'E:\fofopaint-source\repdata\_parser\output\drawing'
.\run.ps1 '.\output\repdata\repdata.txt' '.\output\repdata' # TXT 수정 후 HTML 재생성
```

기본 출력은 `output/<입력 이름>/` 아래의 `<입력 이름>.txt`와 `index.html`입니다. 텍스트는 한 객체당 한 줄, `시작 프레임: JSON 명령 세트 배열` 형식입니다. 프레임 번호는 1부터 시작하며 각 원본 명령이 한 프레임을 차지합니다. 모든 명령 이름과 인수를 출력하며, 알려진 명령만 추리는 필터는 없습니다. `lineStyle*`에 내장된 시작 좌표는 시각화를 위해 파생 `moveTo`로 추가하고, `drawDone*`까지 한 스트로크로 묶습니다. `tempDone*`과 연속된 `lineStyle*`은 같은 스트로크에 남습니다. 파생 `moveTo`는 원본 프레임 수에 포함되지 않습니다. HTML은 저장된 텍스트를 다시 읽어 생성합니다.

HTML은 프레임 객체를 30개씩 표시합니다. 화면 양옆의 화살표로 페이지를 바꿉니다. 명령 앞의 `(숫자)`는 해당 명령의 프레임 번호입니다. 명령 상자에 마우스를 올리면 밝아지고, 상자를 클릭하거나 Enter/Space를 누를 때마다 인수가 펼쳐지고 접힙니다. 검색창에는 프레임 번호를 입력하고 Enter를 누르면 됩니다. 해당 프레임의 개별 명령 상자로 이동하고 그 상자를 어두운 노란색으로 강조합니다. HTML 레이아웃은 `viewer-template.html`에서 수정할 수 있습니다.

`samples/`와 `output/`은 로컬 검증 자료입니다. 원본 그림과 리플레이 데이터는 수정하지 않습니다. 현재 제공된 `repdata` 샘플에는 `lineStyle5`, `lineTo`, `drawDone5`, `mirror`가 있으며, 그 밖의 명령은 들어오는 파일에서 그대로 읽어 출력합니다.

제공된 실제 `.2020` 샘플에서는 788개 객체와 49,817개 원본 명령을 읽었으며, 30개 객체씩 27페이지로 표시합니다.
