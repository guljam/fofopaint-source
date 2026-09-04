# fofoPaint extracted resources

This directory was generated without Adobe Animate from `fofoPaint.zip` and the
last Animate-built 27.13 SWF stored in Git history.

## Layout

- `bitmap/`: the eight bitmap library items, preserving the FLA library path.
- `xfl_library/`: all 467 named FLA library symbols as XFL XML, preserving the
  library folder structure. Windows case-only path collisions are retained with
  a `__case_variant_N` suffix and recorded in `manifests/case_collisions.json`.
- `xfl_metadata/`: document, publish, and brush metadata from the FLA.
- `jpexs_export/`: raw SWF tag exports. Shapes and texts are SVG; sprites and
  buttons are PNG; button folders contain `up`, `over`, `down`, and `hittest`.
- `by_linkage/`: rendered assets grouped by AS3 linkage class and direct instance
  name. For example, `by_linkage/TopMenuSet/children/captureButton__id_9/`.
- `source/fofoPaint-animate-27.13.swf`: the last resource-bearing Animate SWF
  recovered from Git, kept as the extraction source and visual reference.
- `manifests/`: hashes, symbol definitions, dependencies, instance matrices,
  linkage mappings, case-collision records, and the AIR SDK `swfdump` output.

## Important manifests

- `symbols.json`: FLA symbol type, frames, shapes, text, child instances, and
  placement matrices.
- `symbol_dependencies.csv`: parent/child FLA library relationships.
- `linkages.csv`: FLA linkage class mappings.
- `swf_instances.json`: compiled SWF character IDs mapped to linkage class and
  named direct instances.

The application source under `src/` has not been modified. These files are the
resource extraction and classification baseline for the later AIR SDK linking
work.

# **fofoPaint 추출 리소스**

이 디렉터리는 Adobe Animate를 사용하지 않고 `fofoPaint.zip`과 Git 기록에 저장된 마지막 Animate 빌드 27.13 SWF를 기반으로 생성되었습니다.

## **구성**

* `bitmap/`: FLA 라이브러리 경로를 그대로 유지한 8개의 비트맵 라이브러리 항목.

* `xfl_library/`: 이름이 지정된 FLA 라이브러리 심볼 467개를 XFL XML 형식으로 저장하며, 라이브러리 폴더 구조를 그대로 유지합니다. Windows에서 대소문자만 다른 경로가 충돌하는 경우 `__case_variant_N` 접미사를 붙여 보존하며, 해당 내용은 `manifests/case_collisions.json`에 기록됩니다.

* `xfl_metadata/`: FLA의 문서, 게시 및 브러시 메타데이터.

* `jpexs_export/`: 원본 SWF 태그 내보내기 파일. 도형과 텍스트는 SVG, 스프라이트와 버튼은 PNG 형식입니다. 버튼 폴더에는 `up`, `over`, `down`, `hittest`가 포함됩니다.

* `by_linkage/`: AS3 연결 클래스와 직접 지정된 인스턴스 이름별로 분류된 렌더링 리소스. 예: `by_linkage/TopMenuSet/children/captureButton__id_9/`.

* `source/fofoPaint-animate-27.13.swf`: Git에서 복구한 마지막 리소스 포함 Animate SWF로, 추출 원본 및 시각적 참조 자료로 보관됩니다.

* `manifests/`: 해시, 심볼 정의, 종속 관계, 인스턴스 행렬, 연결 매핑, 대소문자 충돌 기록 및 AIR SDK `swfdump` 출력 결과.

## **주요 매니페스트**

* `symbols.json`: FLA 심볼 유형, 프레임, 도형, 텍스트, 자식 인스턴스 및 배치 행렬.

* `symbol_dependencies.csv`: 부모/자식 FLA 라이브러리 관계.

* `linkages.csv`: FLA 연결 클래스 매핑.

* `swf_instances.json`: 컴파일된 SWF 문자 ID를 연결 클래스 및 이름이 지정된 직접 인스턴스와 매핑한 정보.

`src/` 아래의 애플리케이션 소스는 수정되지 않았습니다. 이 파일들은 이후 AIR SDK 연결 작업을 위한 리소스 추출 및 분류 기준 자료입니다.
