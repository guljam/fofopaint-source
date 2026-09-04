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
