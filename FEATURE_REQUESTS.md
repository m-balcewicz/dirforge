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
4. Refactor the current use of `init` to only create the initial <world-type> structure. Add the command `create` for creating additional subdirectories, e.g.:
   - `dirforge init [path] [--auto]`
   - `dirforge create journal --name "thermal_analysis" --first`
5. Implement a more detailed structure on conferences. Needed is the dir on (1) a`abstract`, (2) `presentation` (3) `conference_paper`. Maybe it makes sense to merge (1) and (3) into `/writting` and keep `conference_paper` in the `JOURNAL_WORLD`.
6. Implement an `archive` function and send this directory into `90_archive`:
   - `dirforge archive <dir>
7. Implement an `update` function that will check the current directory structure and update the current one the the most recent update
   - Make sure not to delete existing files
8. Set and define some proper testing definitions in the constitution.md
9. Consider adding [DVC](https://doc.dvc.org) to the workflow
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