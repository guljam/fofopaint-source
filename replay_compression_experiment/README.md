# 리플레이 명령 압축 실험

## 저장 경로

`FileManager.saveFOFOFile()`은 작업 파일 `repdata`의 AMF3 객체 스트림과 첫/마지막 이미지의 픽셀 바이트 4개, 참조 이미지의 픽셀 바이트 1개를 Worker로 보냅니다. Worker는 이 6개 바이트 배열을 **각각** zlib으로 압축합니다. `ReplayController.writeReplayFile()`은 `FOFOPAINT`(9바이트), 압축 리플레이 길이(4바이트), 압축 리플레이, 이어서 AMF3 이미지 레코드를 씁니다. 이미지 레코드의 `ByteArray` 필드에는 이미 압축된 픽셀 바이트가 들어갑니다. 파일 전체를 마지막에 다시 압축하는 단계는 없습니다.

불러올 때는 `FileManager.loadFOFOFile()`이 리플레이 블록을 풀어 `repdata`에 기록하고, 별도로 저장된 이미지의 픽셀 바이트를 풉니다. 재생과 딥 언도는 `repdata`의 객체별 파일 위치를 사용하므로, 작업 파일에는 계속 일반 AMF3 객체 스트림을 기록해야 합니다.

## 새 FRC1 변환

`ReplayDataCodec`은 리플레이 블록의 `lineTo` 명령만 특수 처리합니다. 좌표를 1, 100, 1000배 한 값이 정수이고 **원래 Number로 정확히 되돌아오는 경우**에만 정수로 바꾸어 앞 좌표와의 차이 또는 절대값을 가변 길이 정수로 기록합니다. 그 외 좌표는 IEEE 754 double로 기록합니다. `lineStyle5`를 포함한 나머지 명령은 AMF3으로 기록하며, `lineStyle5`의 시작 좌표를 다음 `lineTo`의 예측값으로 사용합니다. 배열의 명령 순서와 객체 경계는 보존합니다.

Worker는 FRC1 결과와 기존 AMF3 스트림을 각각 zlib으로 압축하고 **작은 쪽만** 파일에 기록합니다. FRC1 블록은 zlib을 푼 뒤 `FRC1` 매직을 확인해 AMF3 객체 스트림으로 복원합니다. 기존 파일은 변경 없이 읽힙니다. 새 블록을 저장한 파일은 FRC1을 모르는 과거 앱 버전에서 읽을 수 없습니다.

## 재현

AIR SDK 경로는 `D:\adobe_air_sdk_manager\AIRSDK_51.3.4`입니다.

```powershell
& 'D:\adobe_air_sdk_manager\AIRSDK_51.3.4\bin\amxmlc.bat' '-source-path+=E:\fofopaint-source\src' '-output=E:\fofopaint-source\replay_compression_experiment\CodecBenchmark.swf' 'E:\fofopaint-source\replay_compression_experiment\CodecBenchmark.as'
& 'D:\adobe_air_sdk_manager\AIRSDK_51.3.4\bin\adl.exe' -nodebug 'E:\fofopaint-source\replay_compression_experiment\CodecBenchmark-app.xml' 'E:\fofopaint-source\replay_compression_experiment' -- 'E:\fofopaint-source\repdata_parser\samples\repdata' 'E:\fofopaint-source\repdata_parser\output\real-sample\[2026-09-08]_UkoHZ4xn.2020.txt'
```

두 번째 입력은 원본 `.2020` 파일이 아니라 파서가 출력한 명령 텍스트입니다. 벤치마크가 합성 `moveTo`를 제외하고 객체별 명령을 다시 AMF3으로 만든 것입니다. 따라서 실제 사용자의 큰 저장 파일 전체에 대한 압축률은 별도로 측정해야 합니다.

| 입력 | 명령 객체 | 원본 AMF3 | 기존 zlib | FRC1 + zlib | 리플레이 블록 절감 |
|---|---:|---:|---:|---:|---:|
| 제공된 `repdata` | 14 | 2,325 | 827 | 549 | 33.6% |
| 재구성한 큰 샘플 | 788 | 1,099,023 | 306,655 | 131,073 | 57.3% |

## `lineTo2` 상대 좌표 실험

`CodecBenchmark.as`는 원본 AMF3 객체 스트림을 읽어 `lineStyle5`의 좌표(`command[5]`, `command[6]`)를 `moveTo` 시작점으로 취급합니다. 실제 `repdata`에는 별도 `moveTo` 명령이 없으며, 파서 텍스트의 `moveTo`는 표시를 위해 만들어진 명령입니다. 각 후속 `lineTo(x, y)`를 직전 점으로부터의 이동량 `lineTo2(x - previousX, y - previousY)`로 바꾸고, **기존 `ByteArray.compress()` zlib만** 적용했습니다. 객체별 명령 배열은 그대로 유지합니다. `lineTo2`는 현재 앱의 재생 명령이 아니라 비교용 표현입니다.

| 입력 | 원래 AMF3 + zlib | 모든 `lineTo2` + zlib | 정확히 복원되는 `lineTo2`만 + zlib | 무손실 상대 방식 절감 |
|---|---:|---:|---:|---:|
| 제공된 `repdata` | 827 | 657 | 657 | 20.6% |
| 재구성한 큰 샘플 | 306,655 | 212,460 | 212,465 | 30.7% |

단위는 바이트입니다. 큰 샘플의 모든 좌표를 차이로 바꾸면 역변환에서 95,812개 좌표 중 1개가 부동소수점 반올림 때문에 원본과 달랐습니다. 최대 오차는 약 `8.67e-18`입니다. 무손실 변형은 `previous + (current - previous) == current`를 확인하여 이 경우만 `lineTo2`로 쓰고, 나머지는 기존 `lineTo` 절대 좌표로 남깁니다. 복원한 명령 배열의 값은 원본과 일치함을 검사했습니다.

이 실험에서는 무손실 `lineTo2` + zlib(212,465바이트)이 FRC1 + zlib(131,073바이트)보다 큽니다. 따라서 상대 명령만으로 저장 형식을 교체하지 않았습니다.

압축된 리플레이 블록을 zlib으로 한 번 더 감쌀 때 큰 샘플의 기존 블록은 306,655→306,457바이트(198바이트 절감), FRC1 블록은 131,073→131,119바이트(46바이트 증가)였습니다. 이 숫자는 이미지가 포함되지 않은 리플레이 블록만의 결과입니다.

큰 샘플에서 원본 49,817개 명령 중 47,906개가 `lineTo`였습니다. 벤치마크는 객체와 명령을 다시 읽어 좌표 및 중첩 배열 값을 비교하고, 0개 명령·음수·소수·정밀 좌표·부호 있는 0·큰 좌표·알 수 없는 명령을 별도로 검사합니다. 새 형식 파일을 만든 뒤 `repdata_parser`로 다시 읽어 기존 파서 출력 텍스트와 일치하는 것도 확인했습니다.

측정된 저장 CPU 비용은 큰 샘플에서 기존 zlib 약 100ms, FRC1 변환 약 54ms와 그 결과의 zlib 약 11ms입니다. Worker의 실제 선택 로직은 양쪽을 모두 만들기 때문에 이 샘플에서 약 165ms가 듭니다. 이미지 압축 비용은 이 수치에 포함되지 않습니다.

이미 압축된 이미지 바이트와 리플레이 바이트를 다시 zlib으로 감싸는 전체 압축은 위와 별개입니다. 현재 포맷에서는 전체 압축 단계가 없으며, 추가 zlib은 읽기/쓰기 호환성을 바꾸고 이미지 데이터에 대한 절감이 작을 가능성이 큽니다. 실제 이미지가 포함된 `.2020` 파일로 전체 크기와 속도를 측정한 후 결정하는 편이 안전합니다.
