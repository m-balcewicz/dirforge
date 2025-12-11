# Feature Requests

Track feature requests and enhancement ideas for DirForge. Quick notes that can be converted into detailed specs later.

---

## Proposed

1. Create low-level automation for `dirforge init publication` to create base LaTeX manuscript structure
2. Create low-level automation for `dirforge init study` to scaffold research study structure:
  - `02_studies/<study_name>/00_protocols/`
  - `02_studies/<study_name>/01_code/`
  - `02_studies/<study_name>/02_data/`
  - `02_studies/<study_name>/03_outputs/`
  - `02_studies/<study_name>/04_publication/`
3. Create a consistent `--help` output. Therefore, we need to define which sections in each `--help` and `--help-long` should be shown. In the next step remove all intendations and keep the formatting somehow "simple".
---

## Under Review

_Features being evaluated for feasibility._

---

## Accepted

_Approved for implementation._

---

## Implemented

_Completed features with version info._

- **v1.0.20** (2025-12-11): Two-tier help system (--help short, --help-long detailed)
- **v1.0.20** (2025-12-11): Consistent flag naming (--name/-n across all world types)

---

## Rejected

_Not implementing. Include brief reason._

---

## Notes

- Use bullet points for quick feature ideas
- Add details when needed with sub-bullets
- Update version info when implemented