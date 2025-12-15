<!-- Sync Impact Report

- Version change: 1.0.20 -> 1.0.21
- Modified principles: III.II Journal — complete restructuring from journal-name organization to role-based organization
- Changed paths:
  - Old: `JOURNAL_WORLD/<JOURNAL_NAME>/<ID>/` with flexible ID patterns
  - New: `JOURNAL_WORLD/00_admin/`, `01_primary_authorship/`, `02_coauthor_invites/`, `03_journal_service/`
  - Each role directory contains project-specific subdirectories with standard `01_manuscript/`, `02_reviews/`, `03_correspondence/`
- Rationale:
  - Role-based organization improves workflow clarity and separates different academic activities
  - Clearer separation between lead authorship, collaborative work, and journal service
  - Aligns with user workflow patterns (author vs reviewer vs editor roles)
- Templates requiring updates:
  - `tools/dirforge`: ✅ updated to create role-based structure with new flag handling (--first, --coauthor, --service)
  - `lib/help.sh`: ✅ updated all constitution version references to v1.0.21
  - `templates/help/world_help_journal.txt`: ✅ updated with role-based examples and migration guidance
  - `README.md`: ✅ updated journal examples with new command syntax
  - `CHANGELOG.md`: ✅ added v1.0.21 entry with role-based journal changes
- Migration: Manual migration required for existing v1.0.20 JOURNAL_WORLD projects
- Breaking change: YES — structural reorganization required for journal projects

Previous changes (1.0.19 -> 1.0.20):
- Modified principles: None (usability enhancement only)
- Changed paths: None
- Rationale: 
  - Two-tier help system: short (`--help`) vs detailed (`--help-long`) for improved UX
  - Consistent flag naming: all world types now use `--name`/`-n` for creation
- Templates requiring updates:
  - `tools/dirforge`: ✅ updated CONSTITUTION_VERSION to v1.0.20
  - `lib/help.sh`: ✅ updated all constitution version references to v1.0.20
  - `README.md`: ✅ updated constitution references
  - `CHANGELOG.md`: ✅ added v1.0.20 entry with help system and flag naming changes
- Migration: No migration required - backward compatible (long flags still work)
- Breaking change: NO — `--title` removed but functionality replaced with `--name` (same semantics)

Previous changes (1.0.18 -> 1.0.19):
- Modified principles: None (usability enhancement only)
- Changed paths: None
- Rationale: Add short flag support (`-t`, `-p`, `-s`, `-n`, `-l`, `-j`, `-i`) for improved CLI ergonomics
- Templates requiring updates:
  - `README.md`: ✅ updated with short flag examples
  - `CHANGELOG.md`: ✅ updated with v1.0.19 entry
  - `tools/dirforge`: ✅ updated all world type parsers to accept short flags
  - `lib/help.sh`: ✅ updated constitution version references to v1.0.19
  - Help content templates: ⚠️ update examples to show short flag usage
- Migration: No migration required - backward compatible (long flags still work)
- Breaking change: NO — short flags are additive, all existing commands continue to work

Previous changes (1.0.17 -> 1.0.18):
- Modified principles: Error handling architecture
- Changed paths: None (code organization only)
- Rationale: Modular error handling system with `lib/error.sh` for consistent, maintainable error messages
- Templates requiring updates: `tools/dirforge`, installation scripts, CHANGELOG.md
- Migration: No user-facing changes - internal refactoring only
- Breaking change: NO

Previous changes (1.0.16 -> 1.0.17):
- Modified principles: III.V Research — introduce study-based organization with 02_studies/ container
- Changed paths:
  - Project-level: 02_admin/ → 00_admin/, 01_project_management/ unchanged
  - Removed: 03_design_protocols/, 04_data/, 05_data_analysis/, 06_data_outputs/, 07_publication/, 08_documentation/
  - Added: 02_studies/<study_name>/ with substructure 00-04 + .integrity/
- Rationale: Enable self-contained studies within projects for better organization, independent reproducibility, and clearer provenance
- Templates requiring updates: tools/dirforge, lib/help.sh, tests/test_init_outputs.sh, examples/research/, README.md
- Migration: Manual migration required for existing v1.0.16 projects (see Migration Guide)
- Breaking change: YES — structural incompatibility with v1.0.16

Previous changes (1.0.15 -> 1.0.16):
- Modified principles: III.V Research, III.VI Lecture — remove CONSTITUTION_CHECK.md requirement
- Removed sections:
  - `CONSTITUTION_CHECK.md` is no longer created by scaffolder or required for projects
  - Removed from minimum required files for both research and lecture projects
- Rationale: Manual checklist adds overhead without automated validation benefit; constitution compliance is enforced via `tools/manifest.sh` and project structure
- Templates requiring updates:
	- `tools/dirforge`: ✅ updated to remove CONSTITUTION_CHECK.md creation from init_research() and init_lecture()
	- `tests/test_init_outputs.sh`: ⚠️ update to remove CONSTITUTION_CHECK.md assertions
	- `examples/README.md`: ⚠️ update to remove CONSTITUTION_CHECK.md references

Previous changes (1.0.14 -> 1.0.15):
- Modified principles: III.VI Lecture — standardize grading workflow across exercises and exams
- Changed paths:
  - Exercises: Added `05_exercises/submissions/` and `05_exercises/graded/`; clarified `solutions/` is instructor-only
  - Exams: `06_exams/originals/` → `06_exams/problems/` and `06_exams/solutions/`; added `06_exams/submissions/` and `06_exams/graded/`
- Templates requiring updates:
	- `tools/dirforge`: ✅ updated to create consistent grading workflow (problems/solutions/submissions/graded) for both exercises and exams
	- Existing lecture projects: ⚠️ manual migration required if using old folder structure

Previous changes (1.0.13 -> 1.0.14):
- Modified principles: III.VI Lecture — enforce numbered folder convention for exercises, exams, grades
- Changed paths:
  - `exercises/` → `05_exercises/`
  - `exams/` → `06_exams/`
  - `grades/` → `07_grades/`
- Templates requiring updates:
	- `tools/dirforge`: ✅ updated to create `05_exercises/problems`, `05_exercises/solutions`, `06_exams`, `07_grades`
	- Existing lecture projects: ⚠️ manual migration required if using old `exercises/`, `exams/`, `grades/` paths

Previous changes (1.0.11 -> 1.0.12):
- Modified principles: III.V Research — introduce `.integrity/` directory for centralized validation artifacts
- Added sections: 
  - `.integrity/checksums/` — centralized checksum storage (replaces inline `checksums/` in `04_data/`)
  - `.integrity/manifests/` — optional manifest index/backup for auditing
- Removed sections: inline `checksums/` directory from `04_data/` (now centralized in `.integrity/`)
- Templates requiring updates:
	- `templates/project.yaml.template`: ⚠ update checksum references to `.integrity/checksums/`
	- `tools/dirforge`: ✅ updated scaffolder to create `.integrity/checksums/` and `.integrity/manifests/`
	- `tools/manifest.sh`: ✅ updated validator to expect checksums at `.integrity/checksums/`
	- `tests/fixtures/sample_manifest.yaml`: ✅ updated checksum path references
	- `.specify/templates/plan-template.md`: ✅ aligned (no changes needed)
	- `.specify/templates/spec-template.md`: ✅ aligned (no changes needed)
	- `.specify/templates/tasks-template.md`: ✅ aligned (no changes needed)
-->

# DirForge Constitution

## Core Principles

### I. Research-Activity First (Project-by-Activity)
All research work MUST be organized by research activity or project (project/grant/topic) rather than by document type alone.
Each project root MUST contain a short `README.md` and a machine-readable metadata file (`project.yaml`) describing scope, owner, and key dates.
Rationale: Unifies administrative artifacts and scientific outputs so that deliverables, provenance, and responsibilities are co-located and discoverable.

### II. Single Source of Truth & Sync Policy
`iCloud/Documents` (the user's `CODING_WORLD`, `RESEARCH_WORLD`, etc.) MUST be treated as the primary canonical storage for active documents that require cross-device sync. Local transient work directories are allowed for fast iteration but MUST be reconciled into iCloud-backed folders regularly.
Large immutable raw datasets that exceed iCloud quotas SHOULD be referenced from iCloud via YAML manifest files and stored in a designated archival store (external disk, institutional storage, or cloud bucket). Examples of such datasets include X-ray computed tomography (XCT/CT) volumes, seismic full-waveform datasets, and other high-volume instrument outputs. Each dataset referenced externally MUST have a YAML manifest file (`<dataset>.manifest.yaml`) in the project `04_Data/` directory that documents at minimum:

- `storage_location`: protocol and path (e.g., `smb://` or `rsync://`)
- `server_or_nas`: hostname or IP address of the server/NAS (IPv4/IPv6) and optional port
- `path_on_store`: full path to the dataset on the archival store
- `naming`: canonical filename convention used for the files in the dataset
- `checksum`: reference to checksum file or dataset-level checksum
- `access`: short access instructions and contact for permissions or credential retrieval

Manifests MUST be YAML (human-editable and support comments) and MUST NOT contain plaintext credentials (passwords, tokens, private keys). If access requires credentials, the manifest MUST include explicit instructions for credential retrieval and a reference to a secure credential store (for example: macOS Keychain, `pass`, institutional secrets manager) or the contact to request access. Backups (Time Machine or offsite copies) MUST exist for irreplaceable data.

Rationale: Prevents fragmentation and accidental edits across devices while enabling reproducible, backed-up research workflows.

### III. Data Lifecycle & Integrity
Parental structure: The top-level workspace folders remain as configured under `iCloud/Documents`: 
- `CODING_WORLD`
- `JOURNAL_WORLD`
- `LECTURE_WORLD`
- `LITERATURE_WORLD`
- `OFFICE_WORLD`
- `PRIVATE_WORLD`
- `RESEARCH_WORLD`

#### III.I CODING_WORLD
This is the substructure of `CODING_WORLD`:
- `matlab`
- `python`
- `bash`
- `fortran`
- `latex`
- `clusters`
- `github`
- `c`

#### III.II Journal
This is the substructure of `JOURNAL_WORLD` for all journal-related activities and publication workflows. The structure organizes work by **role** rather than by journal name, providing clearer separation between different types of academic activities:

**Role-Based Structure:**

- `JOURNAL_WORLD/00_admin/` — Manual organization for journal subscriptions, memberships, society correspondence, and general administrative materials not tied to specific papers or reviews

- `JOURNAL_WORLD/01_primary_authorship/` — Papers where you are the lead or corresponding author
  - Each project uses paper title as identifier (converted to lower_snake_case, optionally with year prefix)
  - Structure: `01_primary_authorship/<paper_id>/`
    - `01_manuscript/` — manuscript drafts, revisions, submission versions
    - `02_reviews/` — peer review reports, reviewer comments, revision responses
    - `03_correspondence/` — editorial communications, acceptance letters, submission receipts

- `JOURNAL_WORLD/02_coauthor_invites/` — Collaborative authorship projects where you are a co-author
  - Each project uses paper title or collaboration name as identifier
  - Structure: `02_coauthor_invites/<paper_id>/`
    - `01_manuscript/` — manuscript drafts and contributions
    - `02_reviews/` — review feedback and revision planning
    - `03_correspondence/` — collaboration communications and author agreements

- `JOURNAL_WORLD/03_journal_service/` — Peer review work and editorial duties
  - Organized by journal name, then by specific assignment
  - Structure: `03_journal_service/<journal_name>/<assignment_id>/`
    - `01_manuscript/` — papers under review (for peer review) or editorial consideration
    - `02_reviews/` — review reports, editorial decisions, reviewer feedback
    - `03_correspondence/` — editorial communications, review invitations, decision letters

**Identifier Conventions:**

- Primary authorship: Use paper title (e.g., `thermal_analysis`, `2024_seismic_modeling`)
- Co-author invites: Use paper title or project name (e.g., `2021_elastic_properties`, `international_consortium`)
- Journal service: Use `<JOURNAL_NAME>/<ID>` where ID can be:
  - Manuscript ID: `GEO-2025-0451`, `NGEO-2025-1234`
  - Reviewer batch: `REVIEWER_2024_Q4`, `REVIEWER_BATCH_01`
  - Editorial role: `ASSOCIATE_EDITOR_2024`, `SPECIAL_ISSUE_ML`

**Usage Examples:**

JOURNAL_WORLD/
├── 00_admin/
│   ├── AGU_membership/
│   └── SEG_subscription/
├── 01_primary_authorship/
│   ├── thermal_conductivity_study/
│   │   ├── 01_manuscript/
│   │   ├── 02_reviews/
│   │   └── 03_correspondence/
│   └── 2024_digital_rock_physics/
│       ├── 01_manuscript/
│       ├── 02_reviews/
│       └── 03_correspondence/
├── 02_coauthor_invites/
│   ├── 2021_elastic_properties/
│   │   ├── 01_manuscript/
│   │   ├── 02_reviews/
│   │   └── 03_correspondence/
│   └── international_consortium/
│       ├── 01_manuscript/
│       ├── 02_reviews/
│       └── 03_correspondence/
└── 03_journal_service/
    ├── GEOPHYSICS/
    │   ├── GEO-2025-0451/
    │   │   ├── 01_manuscript/
    │   │   ├── 02_reviews/
    │   │   └── 03_correspondence/
    │   └── REVIEWER_2024_Q4/
    │       ├── 01_manuscript/
    │       ├── 02_reviews/
    │       └── 03_correspondence/
    ├── NATURE_GEOSCIENCE/
    │   └── REVIEWER_2024_Q4/
    │       ├── 01_manuscript/
    │       ├── 02_reviews/
    │       └── 03_correspondence/
    └── JGR_SOLID_EARTH/
        └── ASSOC_EDITOR_2024/
            ├── 01_manuscript/
            ├── 02_reviews/
            └── 03_correspondence/

**Rationale:**

Role-based organization provides several advantages:
- **Clearer workflow separation**: Primary authorship, collaborative work, and journal service have distinct processes and timelines
- **Better scalability**: Easy to see all papers you're leading vs all review assignments
- **Improved organization**: Related activities grouped together (all your lead papers, all your reviews)
- **Future-proof**: Easy to add new role categories (e.g., `04_editorial_board/`, `05_special_issues/`)

#### III.III Office
This is the substructure of `OFFICE_WORLD` (project-independent office-level folders). Use `90_archive` for long-term archived content.
- `00_admin/` (optional) — quick inbox and transient admin notes (keep or omit)
- `01_finance/` — invoices, funding documents, budgets, non-sensitive payroll docs, proposals
- `02_hr_administration/` — vacation requests, business trip forms, faculty meetings, HR correspondence, employment documents
- `03_faculty/` — university forms, faculty paperwork, compliance documents, policy acknowledgments
- `04_inventory_equipment/` — NAS notes, equipment inventories, Zeiss and instrument info, manuals
- `05_software_licenses/` — software licenses, MATLAB/QGIS/ImageJ notes, software invoices
- `06_public_relations/` — press releases, interviews, PR items

#### III.IV Private
- `00_admin/` (optional) — quick inbox and transient admin notes (keep or omit)
- `01_credentials` – pointers only — do NOT store passwords; keep 1Password exports OUTSIDE (or better: do not export). Use 1Password app or encrypted store.
- `02_id_contracts/` — personal contracts, IDs, signed forms (encrypt)
- `03_finance/` — `banks`, `bafoeg`, `budget` records (sensitive — restrict access)
- `04_documents/` — `scans` and personal document storage
	- Also store personal templates and CVs here in dedicated subfolders:
	- `05_photos/01_raw/` — camera raw files (CR2/ARW/NEF)
	- `05_photos/02_lightroom_catalog/` — Lightroom Classic catalogs and settings (keep catalog backups outside iCloud if large)
	- `05_photos/03_exports/` — exported JPEGs/PNG for sharing
	- `05_photos/04_projects/` — per-shoot project folders
	- `06_movies/handbrake/`
	- `06_movies/make_mkv/`
	- `06_movies/ready4plex/`
	- `06_movies/gopro/`
- `07_hiking/` — hiking and outdoor activities (trip plans, GPX tracks, maps, field notes). Use subfolders:
	- `07_hiking/<YYYY-MM>_trip/01_logs/` — personal logs, notes, equipment checklists
- `09_installers/` — OS installers, offline application installers, driver packages, and installation notes (versioned). Use for reproducible reinstalls; avoid storing personal credentials in this folder.
- `90_archive/` — archived personal files (long-term)
  
#### III.V Research

Project identifier policy: Every project MUST be created with a pre-defined, stable PROJECT-ID that becomes the canonical directory name under RESEARCH_WORLD/ (for example RESEARCH_WORLD/<PROJECT-ID>/).

Each research activity or project under RESEARCH_WORLD/ MUST follow a consistent, numbered subfolder layout. Every project root MUST contain at minimum a README.md and a project.yaml (machine meta owner, contact, license, sync policy).

**Project-level structure** (top-level folders within RESEARCH_WORLD/<PROJECT-ID>/):

- RESEARCH_WORLD/<PROJECT-ID>/00_admin/ — contracts, agreements, permits, IRB/ethics approvals, data-sharing agreements, and access contacts (project-level administrative artifacts)

- RESEARCH_WORLD/<PROJECT-ID>/01_project_management/ — project proposals, grant applications, replies to reviews, project reports, budgets, milestones, deliverables, funding documents, and project-wide management artifacts
	- This directory MUST contain a set of standardized subdirectories to keep project-management artifacts organized and reproducible. The scaffolder and project templates SHOULD create these subfolders when initializing a new research project:
		- `01_proposal/` — proposal lifecycle and submission materials
			- `01_draft/` — working drafts and internal proposal notes
			- `02_submission/` — final submission files, submission receipts, and cover letters
			- `03_review/` — reviewer responses, review correspondence, and reviewer reports
			- `04_final/` — final accepted proposal documents and amendments
		- `02_finance/` — budgets, invoices, funding agreements, and expense records
		- `03_reports/` — periodic reports, deliverables, technical reports, and progress updates
		- `04_presentations/` — slides, meeting notes, and outreach materials related to the project

- RESEARCH_WORLD/<PROJECT-ID>/02_studies/ — container directory for all individual research studies within this project. Each study is self-contained with its own protocols, code, data, outputs, and publications. Study names MUST use lower_snake_case format.

- RESEARCH_WORLD/<PROJECT-ID>/.integrity/ — project-level validation and integrity artifacts (checksums, manifests index, validation logs). This hidden directory centralizes project-wide data validation files:
  - .integrity/checksums/ — project-level checksum files (.sha256, .sha512, .md5)
  - .integrity/manifests/ — optional index or backup copies of manifest files for auditing

**Study-level structure** (within 02_studies/<study_name>/):

Each study directory MUST follow this standard structure:

- 02_studies/<study_name>/00_protocols/ — experimental protocols, calibration notes, instrument configurations, acquisition checklists, and methodological documentation specific to this study

- 02_studies/<study_name>/01_code/ — analysis code, scripts, notebooks, and small derived data specific to this study. This folder SHOULD be version-controlled with Git. Include a .gitignore. Include environment.yml for conda environment specification.

- 02_studies/<study_name>/02_data/ — raw and processed datasets for this study, manifest files, and acquisition metadata. For large external datasets include a YAML manifest (<dataset>.manifest.yaml) which MUST follow the manifest policy in Section II.
  - When new raw data are ingested, add a metadata.yaml in this folder describing acquisition parameters
  - Don't provide any subdirectories, the user can decide on this own.

- 02_studies/<study_name>/03_outputs/ — processed datasets, figures, tables, processed exports, and release artifacts specific to this study. Archive released dataset versions in subdirectories with version numbers (e.g., v1.0/, v2.1/) with corresponding manifest files describing storage and provenance.
  - Don't provide any subdirectories, the user can decide on this own.

- 02_studies/<study_name>/04_publication/ — manuscript drafts, author notes, submission materials, and supplementary files specific to this study
  - Provide here a standard LaTeX style frame with "main.tex" and "references.bib"
  - Make a one-pager LaTeX document based on provided templates/latex/

- 02_studies/<study_name>/05_presentations/ — slides or powerpoints for conferences, project meetings or general purpose specific to this study
  - Provide here a standard LaTeX style based on beamer.
  - Make a one-pager LaTeX document based on provided templates/latex/

- 02_studies/<study_name>/.integrity/ — study-specific validation and integrity artifacts (checksums, manifests, validation logs):
  - .integrity/checksums/ — checksum files (.sha256, .sha512, .md5) for datasets in this study
  - .integrity/manifests/ — optional manifest index or backup for this study
  - Manifests in 02_data/ reference checksums as: checksum: ".integrity/checksums/dataset.sha256"

**Study organization rationale:**

Research projects often comprise multiple distinct studies (different experiments, sample batches, measurement campaigns, computational investigations, or analytical approaches). The 02_studies/ structure allows each study to be completely self-contained with its own:
- Experimental or computational protocols
- Code and analysis workflows
- Data and datasets
- Results and outputs
- Publication materials
- Data integrity validation

This prevents mixing data and results from different studies, enables independent reproducibility per study, and maintains clear provenance. Studies can be worked on in parallel, archived independently, or shared selectively.

**Example structure:**

RESEARCH_WORLD/2025_geotwins/
├── 00_admin/
│   ├── contracts/
│   ├── ethics/
│   └── data_sharing_agreements/
├── 01_project_management/
│   ├── proposals/
│   ├── reports/
│   └── budgets/
├── 02_studies/
│   ├── thermal_conductivity_study/
│   │   ├── 00_protocols/
│   │   │   ├── experimental_protocol.md
│   │   │   └── instrument_config.yaml
│   │   ├── 01_code/
│   │   │   ├── scripts/
│   │   │   ├── notebooks/
│   │   │   └── environment.yml
│   │   ├── 02_data/
│   │   │   ├── raw/
│   │   │   ├── processed/
│   │   │   └── metadata.yaml
│   │   ├── 03_outputs/
│   │   │   ├── figures/
│   │   │   └── results/
│   │   ├── 04_publication/
│   │   │   └── manuscript/
│   │   ├── 05_presentations/
│   │   │   └── slides/
│   │   └── .integrity/
│   │       ├── checksums/
│   │       └── manifests/
│   ├── ultrasonic_wave_propagation/
│   │   ├── 00_protocols/
│   │   ├── 01_code/
│   │   ├── 02_data/
│   │   ├── 03_outputs/
│   │   ├── 04_publication/
│   │   ├── 05_presentations/
│   │   └── .integrity/
│   └── digital_twin_validation/
│       ├── 00_protocols/
│       ├── 01_code/
│       ├── 02_data/
│       ├── 03_outputs/
│       ├── 04_publication/
│       ├── 05_presentations/
│       └── .integrity/
└── .integrity/
    ├── checksums/
    └── manifests/

**Requirements:**

- Project creation MUST add project.yaml and README.md to the project root
- Project creation MUST also create the `01_project_management/` directory and include the standardized subdirectories listed above (`01_proposal/` with `01_draft/`, `02_submission/`, `03_review/`, `04_final/`, plus `02_finance/`, `03_reports/`, and `04_presentations/`). Tooling and templates SHOULD populate these when creating a new research project.
- Study creation MUST add README.md to the study root describing the specific research question, methods, and expected outcomes
- Any dataset added to 02_data/ MUST include a metadata.yaml entry; checksums MUST be stored in .integrity/checksums/ and referenced from manifests. Manifests MUST be validated (see tooling suggestions)
- Large raw files SHOULD remain external to iCloud when necessary; keep a small YAML manifest in 02_data/ that points to the archival location and lists checksums

Rationale: This layout keeps provenance and administrative artifacts co-located with data and analysis, enables reproducible pipelines per study, prevents cross-study data contamination, and makes it straightforward to reference large external datasets via manifests while keeping the active, editable metadata in iCloud.

#### III.VI Lecture
Lecture projects: identifier, scaffolding, required artifacts

Lecture identifier policy: Every lecture project MUST be created with a pre-defined, stable `PROJECT-ID` (the "lecture-id") that becomes the canonical directory name under `LECTURE_WORLD/<lecture-id>/`. The lecture name supplied by the creator SHALL be converted to a lower_snake_case `lecture-id` by the scaffolder using a deterministic rule: convert to lower case, replace whitespace and runs of non-alphanumeric characters with single underscores, and remove leading/trailing underscores. Examples:

- "Digital Rock Physics" → `digital_rock_physics`
- "Computational Wave Propagation" → `computational_wave_propagation`

The scaffolder MUST create `LECTURE_WORLD/<lecture-id>/` and MUST display a confirmation message: `Lecture name converted to ID: <lecture-id>`. The `lecture-id` MUST use only characters in the set `a-z`, `0-9`, `_`, `-` and SHOULD include a short course code or term prefix for uniqueness (for example: `gphy101_fall2026`). Project creators are responsible for choosing a unique `lecture-id` within the workspace.

Minimum project files: every lecture root MUST contain at minimum `README.md` and `project.yaml` (machine meta `course_code`, `title`, `term`, `instructor`, `sync_policy`).

Mandatory folder layout (create all top-level folders even if empty):
- `00_admin/` — schedule, contact info, syllabus, quick links, README
- `01_code/` — notebooks, scripts, environments/requirements, autograder hooks
- `02_data/` — canonical small data and pointers to large archives
	- `02_data/experimental_recordings/` — processed, small copies of recordings for quick access
	- `02_data/recordings.manifest.yaml` — manifest pointing to archival storage for large recordings (see manifest policy)
	- `02_data/reference/` — figures and reference assets from other sources (use descriptive naming: `author_year_topic` or similar)
- `03_slides/` — slide sources (Beamer/.pptx) and exported PDFs in `public/`
- `04_manuscript/` — authoritative written lecture notes in LaTeX and expanded narrative (manuscript is the canonical, detailed description complementing slides)
- `05_exercises/` — exercise packages with grading workflow
	- `05_exercises/problems/` — problem statements and dataset fixtures
	- `05_exercises/solutions/` — solutions (instructor access only)
	- `05_exercises/submissions/` — student submissions
	- `05_exercises/graded/` — graded submissions with feedback
- `06_exams/` — exam materials with grading workflow
	- `06_exams/problems/` — exam problem statements and blank versions
	- `06_exams/solutions/` — exam solutions (instructor access only)
	- `06_exams/submissions/` — student exam submissions
	- `06_exams/graded/` — graded exams with feedback
- `07_grades/` — gradebook and rubrics

Recording and manifest requirements
- Large recordings MUST be stored externally (NAS, institutional bucket) and referenced by `02_data/recordings.manifest.yaml`. Each `recordings.manifest.yaml` MUST contain at minimum the manifest fields defined in Section II plus `retention_days` and `owner_contact`.
- Recording filename convention: `YYYY-MM-DD_<course_code>_<session>_<device>_vNN.ext` (example: `2026-03-15_gphy101_field_day_gopro1_v01.mp4`).
- Consent and privacy: if recordings contain identifiable students, signed consent forms MUST be stored in `02_data/consent/` and marked as encrypted; follow institutional policies for retention and sharing.

Exercises, lab practicals, and field exercises
- Organize exercises by language/type under `05_exercises/` (e.g., `05_exercises/matlab/`, `05_exercises/python/`, `05_exercises/lab_practicals/`, `05_exercises/field_exercises/`). Each exercise package SHOULD include a `README.md`, `problem.md`, any sample data under a `data/` subfolder, and an optional `tests/` harness for autograding.
- Solutions MUST be stored separately from public problem statements in the `solutions/` directory with appropriate access controls.

Rationale: This structure keeps lecture materials reproducible, protects student privacy and third-party rights, and makes large media manageable by referencing archival storage rather than syncing large binaries through iCloud.

### IV. Project-ID, Naming, Metadata, and Provenance
The `PROJECT-ID` MUST be specified at project creation time (scaffolder parameter or equivalent) and MUST follow the machine-friendly pattern: lower_snake_case ASCII (allowed characters: `a-z`, `0-9`, `_`, `-`). The `PROJECT-ID` SHOULD include a year prefix (YYYY) and a short user, grant, project title (examples: `2025_mb_thermal_model`, `2023_labx_inversion_v1`). Project creators MUST ensure `PROJECT-ID` uniqueness within the workspace.

- Numbering policy: use zero-padded numeric prefixes for top-level project subfolders. Prefer `01`..`09` initially to keep listings compact; if you need more slots, adopt `01`..`99` across projects to avoid reordering.

- Folder naming: use lower_snake_case (ASCII, no spaces) for all subfolders (examples: `01_project_management`, `04_data`).

- File naming: prefix time-scoped files and folders with ISO dates: `YYYY-MM-DD_description[_instrument]_[version]`.

- Required machine-readable meta
	- Project root MUST contain `README.md` and `project.yaml` (fields: `owner`, `contact`, `license`, `sync_policy`).
	- Each dataset in `04_data/` MUST have `metadata.yaml` and corresponding checksum files in `.integrity/checksums/` (`.sha256` or `.sha512`).
	- External datasets referenced from iCloud MUST have a `*.manifest.yaml` in `04_data/` (see Section II for required manifest fields). Manifests reference checksums using relative paths: `checksum: ".integrity/checksums/dataset.sha256"`.

- Automation note: following these conventions enables simple validation and tooling (scripts that parse `project.yaml`, verify `checksums.sha256`, and expand `*.manifest.yaml`).

Rationale: stable, machine-readable naming makes automation, discovery, and long-term reuse reliable across platforms and tools.

### V. Administrative Separation & Access Control
Administrative, personal, and sensitive records MUST remain separate from research 
- `OFFICE_WORLD/` and `PRIVATE_WORLD/` remain the canonical locations for administrative and private files.
Project roots MUST separate administrative artifacts (`01_project_management/`) from scientific artifacts (`04_data/`, `05_data_analysis/`, `06_data_outputs`), and grant access accordingly.
Rationale: Protects privacy and simplifies compliance while keeping research outputs accessible.

## Additional Constraints
Storage and operational constraints specific to macOS + iCloud:
- Avoid relying on filesystem features not supported by iCloud (e.g., complex symlink patterns) in project-critical paths.
- Keep regularly edited code (e.g., `CODING_WORLD`) under explicit version control (Git) in `iCloud/Documents` or in a local repo that is pushed to a remote; do NOT rely on iCloud history as the primary versioning mechanism.
- Large binary datasets SHOULD be referenced via manifests inside iCloud and stored externally when they exceed quotas.

Tooling preference:
- **Manifest format**: YAML is REQUIRED for dataset manifests (`*.manifest.yaml`).
- **Implementation approach**: prefer POSIX-compatible Bash scripts with `yq` for manifest operations to maximize portability on macOS and Linux. Use Python (single-file CLI) for tasks that require richer logic or cross-platform path handling. Consider Go for later single-binary distribution if broader Windows support without runtime deps is required.
- **Secrets**: Never store credentials in manifests; use platform credential stores (macOS Keychain, Windows Credential Manager), `pass`, or an institutional secrets manager. Manifests must reference these stores rather than containing secrets.

## Development & Data Workflow
Create a new directory workflow dependant on the topic (`CODING_WORLD`, `JOURNAL_WORLD`, `LECTURE_WORLD`, `LITERATURE_WORLD`, `OFFICE_WORLD`, `PRIVATE_WORLD`, `RESEARCH_WORLD`) + subdirectory (refere back to the subchapters of III. mentioned earlier in this consitution file). For each "topic" a single code will be execuded to ensure always the same subdirectory structure and workflow.
Further subdirectory details like:
- `RESEARCH_WORLD/01_project_managment/...`
- `RESEARCH_WORLD/05_data_analysis/...`
- etc.
will be definied in a later step. These will be details.

### Template and Auxiliary File Organization
All reusable templates, boilerplate content, and reference materials MUST be stored in the `templates/` directory structure:

- `templates/` — project templates, configuration files, and reference materials
  - `templates/help/` — help system output examples and reference documentation
  - `templates/*.yaml.template` — project configuration templates (project.yaml, manifest templates)
  - `templates/*.md.template` — documentation templates and boilerplate content
- `examples/` — actual working project demonstrations and usage examples only
  - Example scaffolds showing real project structures
  - Sample completed projects demonstrating best practices
  - Usage demonstrations for documentation purposes

Rationale: Clear separation between reusable templates/reference materials (`templates/`) and actual project demonstrations (`examples/`) improves maintainability and user understanding.

### Report Naming Convention
Report files generated for project tracking and status documentation MUST follow the date-only naming pattern:
- Format: `YYYYMMDD-<report-type>.md`
- Example: `20251209-status-checkup.md`
- Rationale: Date-only format (no time component) simplifies file management and ensures unique daily reports without time-based granularity

Reports MUST be stored in the `report/` directory and excluded from version control (`.gitignore` compliance).

## Governance
- No contribution by other owners. Only main author: Martin Balcewicz
- No further commands needed.

Versioning policy (semantic):
- MAJOR: Incompatible governance changes, removals, or principle redefinitions.
- MINOR: New principle or materially expanded guidance.
- PATCH: Wording clarifications, typos, or non-semantic refinements.

**Version**: 1.0.21 | **Ratified**: 2025-12-11 | **Last Amended**: 2025-12-11