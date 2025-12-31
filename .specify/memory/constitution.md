# DirForge Constitution

## Core Principles

### I. Research-Activity First (Project-by-Activity)
All research work MUST be organized by research activity or project (project/grant/topic) rather than by document type alone.
Each project root MUST contain a short `README.md` and a machine-readable metadata file (`.integrity/project.yaml`) describing scope, owner, and key dates.
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
- `CODING_WORLD` (with `.integrity/world.yaml` for world-level metadata)
- `JOURNAL_WORLD` (with `.integrity/world.yaml` for world-level metadata)
- `LECTURE_WORLD` (with `.integrity/world.yaml` for world-level metadata)
- `LITERATURE_WORLD` (with `.integrity/world.yaml` for world-level metadata)
- `OFFICE_WORLD` (with `.integrity/world.yaml` for world-level metadata)
- `PRIVATE_WORLD` (with `.integrity/world.yaml` for world-level metadata)
- `RESEARCH_WORLD` (with `.integrity/world.yaml` for world-level metadata)

The workspace root (containing all worlds) MUST have `.integrity/workspace.yaml` with workspace-level configuration (workspace_name, world_types, constitution_version).
Each world MUST contain `.integrity/world.yaml` with world-specific configuration (world_type, creation_date, sync_policies).

### III.A The .integrity Directory System

The `.integrity/` directory is a centralized metadata and validation system used at every organizational level (workspace, world, project, study) to maintain data consistency, provenance tracking, and automated validation.

#### III.A.I Directory Structure and Hierarchy

The `.integrity/` system follows a hierarchical structure that mirrors the organizational levels:

**Workspace Level** (`/.integrity/`):
- `workspace.yaml` — workspace-wide configuration and metadata
- `checksums/` — workspace-level checksum validation files
- `manifests/` — workspace-level manifest indices and backups

**World Level** (`/<WORLD_TYPE>/.integrity/`):
- `world.yaml` — world-specific configuration and metadata
- `checksums/` — world-level checksum files for world-wide assets
- `manifests/` — world-level manifest indices and validation logs

**Project Level** (`/<WORLD_TYPE>/<PROJECT_ID>/.integrity/`):
- `project.yaml` — project-specific metadata (owner, contact, license, sync_policy)
- `checksums/` — project-level checksum files (.sha256, .sha512, .md5)
- `manifests/` — project manifest indices and backup copies for auditing

**Study Level** (`/RESEARCH_WORLD/<PROJECT_ID>/02_studies/<study_name>/.integrity/`) — RESEARCH_WORLD only:
- `study.yaml` — study-specific metadata (methodology, datasets, protocols, expected_outcomes)
- `checksums/` — study-specific checksum files for datasets
- `manifests/` — study-level manifest indices and validation logs

#### III.A.II File Specifications

**Metadata Files (.yaml)**:
- `workspace.yaml` — Contains workspace_name, world_types list, constitution_version, creation_date
- `world.yaml` — Contains world_type, creation_date, sync_policies, project_count (varies by world type)
- `project.yaml` — Contains owner, contact, license, sync_policy, project-specific metadata
- `study.yaml` — Contains methodology, datasets, protocols, expected_outcomes, research-specific metadata

**Checksum Subdirectory (`checksums/`)**:
- Stores cryptographic hash files for data validation
- Supported formats: `.sha256`, `.sha512`, `.md5`
- Files named to match corresponding datasets: `<dataset_name>.sha256`
- Referenced by manifests using relative paths: `checksum: ".integrity/checksums/dataset.sha256"`

**Manifests Subdirectory (`manifests/`)**:
- Stores backup copies of manifest files for auditing
- Contains manifest indices for large dataset tracking
- Validation logs and manifest verification results
- Optional subdirectory — created when external dataset manifests are used

#### III.A.III Access Policies and Security

- `.integrity/` directories are hidden by default (dot-prefix)
- Metadata files MUST be human-readable YAML format
- Checksum files MUST be automatically generated and validated
- NO credentials or sensitive information in any `.integrity/` files
- External dataset access credentials MUST reference secure credential stores

#### III.A.IV Integration with Manifest System

The `.integrity/` system integrates with the manifest policy (Section II) for external datasets:

- Large datasets stored externally MUST have manifest files (`<dataset>.manifest.yaml`) in project directories
- Manifests MUST reference checksums using `.integrity/checksums/` paths
- Manifest validation tools MUST verify checksum file existence and integrity
- Backup copies of manifests MAY be stored in `.integrity/manifests/` for auditing

#### III.A.V Automation and Tooling

The `.integrity/` system enables automated validation:

- Project scaffolders MUST create appropriate `.integrity/` directories and metadata files
- Validation tools MUST verify checksum integrity and manifest consistency
- Migration tools MUST preserve `.integrity/` data across version updates
- Backup systems MUST include `.integrity/` directories for complete restoration

**Rationale**: Centralized `.integrity/` system provides consistent metadata organization, enables automated validation, supports data provenance tracking, and maintains project integrity across all organizational levels while remaining hidden from day-to-day workflows.

#### III.I CODING_WORLD
This is the substructure of `CODING_WORLD`:
- `matlab/` (language-specific directory with project metadata)
- `python/` (language-specific directory with project metadata)
- `bash/` (language-specific directory with project metadata)
- `fortran/` (language-specific directory with project metadata)
- `latex/` (language-specific directory with project metadata)
- `clusters/` (cluster configuration directory)
- `github/` (repository management directory)
- `c/` (language-specific directory with project metadata)

Each language subdirectory contains individual coding projects. See Section III.A for complete `.integrity/` directory specifications at world, project, and organizational levels.

**Example structure:**

CODING_WORLD/
├── .integrity/
│   └── world.yaml
├── python/
│   ├── .integrity/
│   │   └── project.yaml
│   ├── ml_toolkit/
│   │   ├── .integrity/
│   │   │   └── project.yaml
│   │   ├── src/
│   │   ├── tests/
│   │   ├── docs/
│   │   └── requirements.txt
│   └── data_analysis/
│       ├── .integrity/
│       │   └── project.yaml
│       ├── notebooks/
│       ├── scripts/
│       └── environment.yml
├── matlab/
│   ├── .integrity/
│   │   └── project.yaml
│   └── signal_processing/
│       ├── .integrity/
│       │   └── project.yaml
│       ├── functions/
│       └── examples/
└── bash/
    ├── .integrity/
    │   └── project.yaml
    └── automation_scripts/
        ├── .integrity/
        │   └── project.yaml
        ├── deployment/
        └── monitoring/

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

See Section III.A for complete `.integrity/` directory specifications including project-specific metadata, checksums, and manifests.

**Identifier Conventions:**

- Primary authorship: Use paper title (e.g., `thermal_analysis`, `2024_seismic_modeling`)
- Co-author invites: Use paper title or project name (e.g., `2021_elastic_properties`, `international_consortium`)
- Journal service: Use `<JOURNAL_NAME>/<ID>` where ID can be:
  - Manuscript ID: `GEO-2025-0451`, `NGEO-2025-1234`
  - Reviewer batch: `REVIEWER_2024_Q4`, `REVIEWER_BATCH_01`
  - Editorial role: `ASSOCIATE_EDITOR_2024`, `SPECIAL_ISSUE_ML`

**Usage Examples:**

**Example structure:**

JOURNAL_WORLD/
├── .integrity/
│   ├── world.yaml
│   ├── checksums/
│   └── manifests/
├── 00_admin/
│   ├── .integrity/
│   │   ├── project.yaml
│   │   ├── checksums/
│   │   └── manifests/
│   ├── AGU_membership/
│   └── SEG_subscription/
├── 01_primary_authorship/
│   ├── thermal_conductivity_study/
│   │   ├── .integrity/
│   │   │   ├── project.yaml
│   │   │   ├── checksums/
│   │   │   └── manifests/
│   │   ├── 01_manuscript/
│   │   ├── 02_reviews/
│   │   └── 03_correspondence/
│   └── 2024_digital_rock_physics/
│       ├── .integrity/
│       │   ├── project.yaml
│       │   ├── checksums/
│       │   └── manifests/
│       ├── 01_manuscript/
│       ├── 02_reviews/
│       └── 03_correspondence/
├── 02_coauthor_invites/
│   ├── 2021_elastic_properties/
│   │   ├── .integrity/
│   │   │   ├── project.yaml
│   │   │   ├── checksums/
│   │   │   └── manifests/
│   │   ├── 01_manuscript/
│   │   ├── 02_reviews/
│   │   └── 03_correspondence/
│   └── international_consortium/
│       ├── .integrity/
│       │   ├── project.yaml
│       │   ├── checksums/
│       │   └── manifests/
│       ├── 01_manuscript/
│       ├── 02_reviews/
│       └── 03_correspondence/
└── 03_journal_service/
    ├── GEOPHYSICS/
    │   ├── GEO-2025-0451/
    │   │   ├── .integrity/
    │   │   │   ├── project.yaml
    │   │   │   ├── checksums/
    │   │   │   └── manifests/
    │   │   ├── 01_manuscript/
    │   │   ├── 02_reviews/
    │   │   └── 03_correspondence/
    │   └── REVIEWER_2024_Q4/
    │       ├── .integrity/
    │       │   ├── project.yaml
    │       │   ├── checksums/
    │       │   └── manifests/
    │       ├── 01_manuscript/
    │       ├── 02_reviews/
    │       └── 03_correspondence/
    ├── NATURE_GEOSCIENCE/
    │   └── REVIEWER_2024_Q4/
    │       ├── .integrity/
    │       │   ├── project.yaml
    │       │   ├── checksums/
    │       │   └── manifests/
    │       ├── 01_manuscript/
    │       ├── 02_reviews/
    │       └── 03_correspondence/
    └── JGR_SOLID_EARTH/
        └── ASSOC_EDITOR_2024/
            ├── .integrity/
            │   ├── project.yaml
            │   ├── checksums/
            │   └── manifests/
            ├── 01_manuscript/
            ├── 02_reviews/
            └── 03_correspondence/
            ├── 01_manuscript/
            ├── 02_reviews/
            └── 03_correspondence/
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

See Section III.A for complete `.integrity/` directory specifications including world-level and project-level metadata.

**Example structure:**

OFFICE_WORLD/
├── .integrity/
│   ├── world.yaml
│   ├── checksums/
│   └── manifests/
├── 00_admin/
│   ├── .integrity/
│   │   ├── project.yaml
│   │   ├── checksums/
│   │   └── manifests/
│   ├── inbox/
│   └── meeting_notes/
├── 01_finance/
│   ├── .integrity/
│   │   ├── project.yaml
│   │   ├── checksums/
│   │   └── manifests/
│   ├── 2025_budget/
│   ├── invoices/
│   └── funding_documents/
├── 02_hr_administration/
│   ├── .integrity/
│   │   ├── project.yaml
│   │   ├── checksums/
│   │   └── manifests/
│   ├── vacation_requests/
│   ├── business_trips/
│   └── faculty_meetings/
├── 03_faculty/
│   ├── .integrity/
│   │   ├── project.yaml
│   │   ├── checksums/
│   │   └── manifests/
│   ├── university_forms/
│   └── compliance_docs/
├── 04_inventory_equipment/
│   ├── .integrity/
│   │   ├── project.yaml
│   │   ├── checksums/
│   │   └── manifests/
│   ├── equipment_inventory.xlsx
│   ├── zeiss_manuals/
│   └── maintenance_schedules/
├── 05_software_licenses/
│   ├── .integrity/
│   │   ├── project.yaml
│   │   ├── checksums/
│   │   └── manifests/
│   ├── MATLAB_license.txt
│   ├── QGIS_documentation/
│   └── renewal_calendar.xlsx
└── 06_public_relations/
    ├── .integrity/
    │   ├── project.yaml
    │   ├── checksums/
    │   └── manifests/
    ├── press_releases/
    ├── interviews/
    └── media_contacts.yaml

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

See Section III.A for complete `.integrity/` directory specifications including privacy-level metadata and security considerations.
  
**Example structure:**

PRIVATE_WORLD/
├── .integrity/
│   ├── world.yaml
│   ├── checksums/
│   └── manifests/
├── 00_admin/
│   ├── .integrity/
│   │   ├── project.yaml
│   │   ├── checksums/
│   │   └── manifests/
│   ├── inbox/
│   └── meeting_notes/
├── 01_credentials/
│   ├── .integrity/
│   │   ├── project.yaml
│   │   ├── checksums/
│   │   └── manifests/
│   └── 1password_export_pointers.md
├── 02_id_contracts/
│   ├── .integrity/
│   │   ├── project.yaml
│   │   ├── checksums/
│   │   └── manifests/
│   ├── personal_contracts/
│   └── identification_documents/
├── 03_finance/
│   ├── .integrity/
│   │   ├── project.yaml
│   │   ├── checksums/
│   │   └── manifests/
│   ├── banks/
│   ├── bafoeg/
│   └── budget/
├── 04_documents/
│   ├── .integrity/
│   │   ├── project.yaml
│   │   ├── checksums/
│   │   └── manifests/
│   ├── scans/
│   ├── templates/
│   └── cv_versions/
├── 05_photos/
│   ├── .integrity/
│   │   ├── project.yaml
│   │   ├── checksums/
│   │   └── manifests/
│   ├── 01_raw/
│   ├── 02_lightroom_catalog/
│   ├── 03_exports/
│   └── 04_projects/
├── 06_movies/
│   ├── .integrity/
│   │   ├── project.yaml
│   │   ├── checksums/
│   │   └── manifests/
│   ├── handbrake/
│   ├── make_mkv/
│   ├── ready4plex/
│   └── gopro/
├── 07_hiking/
│   ├── .integrity/
│   │   ├── project.yaml
│   │   ├── checksums/
│   │   └── manifests/
│   ├── 2025-01_winter_trip/
│   │   └── 01_logs/
│   └── 2025-06_summer_expedition/
│       └── 01_logs/
├── 09_installers/
│   ├── .integrity/
│   │   ├── project.yaml
│   │   ├── checksums/
│   │   └── manifests/
│   ├── macos_installers/
│   ├── application_installers/
│   └── driver_packages/
└── 90_archive/
    ├── .integrity/
    │   ├── project.yaml
    │   ├── checksums/
    │   └── manifests/
    └── archived_documents/
  
#### III.V Research

Project identifier policy: Every project MUST be created with a pre-defined, stable PROJECT-ID that becomes the canonical directory name under RESEARCH_WORLD/ (for example RESEARCH_WORLD/<PROJECT-ID>/).

Each research activity or project under RESEARCH_WORLD/ MUST follow a consistent, numbered subfolder layout. Every project root MUST contain at minimum a README.md and `.integrity/project.yaml` (machine meta owner, contact, license, sync policy).

**World-level structure**:

- RESEARCH_WORLD/.integrity/world.yaml — world-level metadata (world_type: research, project_count, default_sync_policy)

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

- RESEARCH_WORLD/<PROJECT-ID>/.integrity/ — project-level validation and integrity artifacts centralized in this hidden directory

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

- 02_studies/<study_name>/.integrity/ — study-specific validation and integrity artifacts
  - Manifests in 02_data/ reference checksums as: checksum: ".integrity/checksums/dataset.sha256"

See Section III.A for complete `.integrity/` directory specifications including project-level and study-level metadata, checksums, and manifests.

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
├── .integrity/
│   ├── world.yaml
│   ├── checksums/
│   └── manifests/
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
│   │       ├── study.yaml
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
│   │       ├── study.yaml
│   │       ├── checksums/
│   │       └── manifests/
│   └── digital_twin_validation/
│       ├── 00_protocols/
│       ├── 01_code/
│       ├── 02_data/
│       ├── 03_outputs/
│       ├── 04_publication/
│       ├── 05_presentations/
│       └── .integrity/
│           ├── study.yaml
│           ├── checksums/
│           └── manifests/
└── .integrity/
    ├── project.yaml
    ├── checksums/
    └── manifests/

**Requirements:**

- Project creation MUST add README.md to the project root and project.yaml to .integrity/
- Project creation MUST also create the `01_project_management/` directory and include the standardized subdirectories listed above (`01_proposal/` with `01_draft/`, `02_submission/`, `03_review/`, `04_final/`, plus `02_finance/`, `03_reports/`, and `04_presentations/`). Tooling and templates SHOULD populate these when creating a new research project.
- Study creation MUST add README.md to the study root and study.yaml to .integrity/ describing the specific research question, methods, and expected outcomes
- Any dataset added to 02_data/ MUST include a metadata.yaml entry; checksums MUST be stored in .integrity/checksums/ and referenced from manifests. Manifests MUST be validated (see tooling suggestions)
- Large raw files SHOULD remain external to iCloud when necessary; keep a small YAML manifest in 02_data/ that points to the archival location and lists checksums

Rationale: This layout keeps provenance and administrative artifacts co-located with data and analysis, enables reproducible pipelines per study, prevents cross-study data contamination, and makes it straightforward to reference large external datasets via manifests while keeping the active, editable metadata in iCloud.

#### III.VI Lecture
Lecture projects: identifier, scaffolding, required artifacts

Lecture identifier policy: Every lecture project MUST be created with a pre-defined, stable `PROJECT-ID` (the "lecture-id") that becomes the canonical directory name under `LECTURE_WORLD/<lecture-id>/`. The lecture name supplied by the creator SHALL be converted to a lower_snake_case `lecture-id` by the scaffolder using a deterministic rule: convert to lower case, replace whitespace and runs of non-alphanumeric characters with single underscores, and remove leading/trailing underscores. Examples:

- "Digital Rock Physics" → `digital_rock_physics`
- "Computational Wave Propagation" → `computational_wave_propagation`

The scaffolder MUST create `LECTURE_WORLD/<lecture-id>/` and MUST display a confirmation message: `Lecture name converted to ID: <lecture-id>`. The `lecture-id` MUST use only characters in the set `a-z`, `0-9`, `_`, `-` and SHOULD include a short course code or term prefix for uniqueness (for example: `gphy101_fall2026`). Project creators are responsible for choosing a unique `lecture-id` within the workspace.

Minimum project files: every lecture root MUST contain at minimum `README.md` and appropriate metadata (see Section III.A for `.integrity/` specifications).

See Section III.A for complete `.integrity/` directory specifications including world-level and project-level metadata.

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

**Example structure:**

LECTURE_WORLD/
├── .integrity/
│   └── world.yaml
└── digital_rock_physics/
    ├── .integrity/
    │   └── project.yaml
    ├── README.md
    ├── 00_admin/
    │   ├── syllabus.md
    │   ├── schedule.xlsx
    │   └── contact_info.md
    ├── 01_code/
    │   ├── matlab_exercises/
    │   ├── python_notebooks/
    │   └── environment.yml
    ├── 02_data/
    │   ├── experimental_recordings/
    │   ├── recordings.manifest.yaml
    │   └── reference/
    ├── 03_slides/
    │   ├── lecture_01.tex
    │   ├── lecture_02.tex
    │   └── public/
    │       ├── lecture_01.pdf
    │       └── lecture_02.pdf
    ├── 04_manuscript/
    │   ├── main.tex
    │   ├── references.bib
    │   └── chapters/
    ├── 05_exercises/
    │   ├── problems/
    │   │   ├── exercise_01.md
    │   │   └── exercise_02.md
    │   ├── solutions/
    │   │   ├── exercise_01_solution.md
    │   │   └── exercise_02_solution.md
    │   ├── submissions/
    │   │   └── student_submissions/
    │   └── graded/
    │       └── graded_submissions/
    ├── 06_exams/
    │   ├── problems/
    │   │   ├── midterm_exam.pdf
    │   │   └── final_exam.pdf
    │   ├── solutions/
    │   │   ├── midterm_solution.pdf
    │   │   └── final_solution.pdf
    │   ├── submissions/
    │   │   └── student_exams/
    │   └── graded/
    │       └── graded_exams/
    └── 07_grades/
        ├── gradebook.xlsx
        └── rubrics/

**Example structure:**

LECTURE_WORLD/
├── .integrity/
│   └── world.yaml
└── digital_rock_physics/
    ├── .integrity/
    │   └── project.yaml
    ├── README.md
    ├── 00_admin/
    │   ├── syllabus.md
    │   ├── schedule.xlsx
    │   └── contact_info.md
    ├── 01_code/
    │   ├── matlab_exercises/
    │   ├── python_notebooks/
    │   └── environment.yml
    ├── 02_data/
    │   ├── experimental_recordings/
    │   ├── recordings.manifest.yaml
    │   └── reference/
    ├── 03_slides/
    │   ├── lecture_01.tex
    │   ├── lecture_02.tex
    │   └── public/
    │       ├── lecture_01.pdf
    │       └── lecture_02.pdf
    ├── 04_manuscript/
    │   ├── main.tex
    │   ├── references.bib
    │   └── chapters/
    ├── 05_exercises/
    │   ├── problems/
    │   │   ├── exercise_01.md
    │   │   └── exercise_02.md
    │   ├── solutions/
    │   │   ├── exercise_01_solution.md
    │   │   └── exercise_02_solution.md
    │   ├── submissions/
    │   │   └── student_submissions/
    │   └── graded/
    │       └── graded_submissions/
    ├── 06_exams/
    │   ├── problems/
    │   │   ├── midterm_exam.pdf
    │   │   └── final_exam.pdf
    │   ├── solutions/
    │   │   ├── midterm_solution.pdf
    │   │   └── final_solution.pdf
    │   ├── submissions/
    │   │   └── student_exams/
    │   └── graded/
    │       └── graded_exams/
    └── 07_grades/
        ├── gradebook.xlsx
        └── rubrics/

Rationale: This structure keeps lecture materials reproducible, protects student privacy and third-party rights, and makes large media manageable by referencing archival storage rather than syncing large binaries through iCloud.

### IV. Project-ID, Naming, Metadata, and Provenance
The `PROJECT-ID` MUST be specified at project creation time (scaffolder parameter or equivalent) and MUST follow the machine-friendly pattern: lower_snake_case ASCII (allowed characters: `a-z`, `0-9`, `_`, `-`). The `PROJECT-ID` SHOULD include a year prefix (YYYY) and a short user, grant, project title (examples: `2025_mb_thermal_model`, `2023_labx_inversion_v1`). Project creators MUST ensure `PROJECT-ID` uniqueness within the workspace.

- Numbering policy: use zero-padded numeric prefixes for top-level project subfolders. Prefer `01`..`09` initially to keep listings compact; if you need more slots, adopt `01`..`99` across projects to avoid reordering.

- Folder naming: use lower_snake_case (ASCII, no spaces) for all subfolders (examples: `01_project_management`, `04_data`).

- File naming: prefix time-scoped files and folders with ISO dates: `YYYY-MM-DD_description[_instrument]_[version]`.

- Required machine-readable meta: See Section III.A for complete `.integrity/` directory specifications including all required metadata files.

- Dataset requirements: Each dataset in data directories MUST have corresponding entries in `.integrity/checksums/`. External datasets referenced from iCloud MUST have a `*.manifest.yaml` in the appropriate data directory (see Section II for required manifest fields).

- Automation note: following these conventions enables simple validation and tooling that can parse metadata files, verify checksums, and expand manifests.

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
  - `templates/workspace.yaml.template` — workspace-level configuration template
  - `templates/world.yaml.template` — world-level configuration template
  - `templates/project.yaml.template` — project-level configuration template
  - `templates/study.yaml.template` — study-level configuration template
  - `templates/*.manifest.yaml.template` — dataset manifest templates
  - `templates/*.md.template` — documentation templates and boilerplate content
- `examples/` — actual working project demonstrations and usage examples only
  - Example scaffolds showing real project structures
  - Sample completed projects demonstrating best practices
  - Usage demonstrations for documentation purposes

Rationale: Clear separation between reusable templates/reference materials (`templates/`) and actual project demonstrations (`examples/`) improves maintainability and user understanding.

### IV.A YAML-Based Help System

The DirForge help system MUST use YAML-based content files for all help output, replacing hard-coded help text in bash functions. This approach provides maintainable, version-controlled, and easily extensible help documentation.

#### IV.A.I Help System Architecture

**Help Content Location:**
- All help content MUST be stored in YAML files within `templates/help/`
- Each command or world type MUST have a corresponding YAML file: `<command-name>.yaml` or `<world-type>-world.yaml`
- Help files MUST follow a standardized schema for consistent parsing and formatting

**Required Help Files:**
The following help files MUST be maintained in `templates/help/`:
- `global-help.yaml` — Main dirforge command help (`dirforge --help`)
- `init.yaml` — Init command help (`dirforge init --help`)
- `update.yaml` — Update command help (`dirforge update --help`)
- `validate-config.yaml` — Validate-config command help
- `list-configs.yaml` — List-configs command help
- `research-world.yaml` — Research world type help
- `lecture-world.yaml` — Lecture world type help
- `coding-world.yaml` — Coding world type help
- `journal-world.yaml` — Journal world type help
- `office-world.yaml` — Office world type help
- `private-world.yaml` — Private world type help
- `yaml-config-system.yaml` — YAML configuration system documentation

#### IV.A.II Help File Schema

Each help YAML file MUST conform to the following schema:

```yaml
# Help file schema for dirforge commands and world types
command: "dirforge <command> [options]"          # REQUIRED: command syntax
syntax: |                                        # REQUIRED: multi-line syntax documentation
  dirforge <command> [options]
  dirforge <command> --help

short_help:                                      # REQUIRED: brief summary for short help output
  summary: "Brief one-line description"
  usage: "dirforge <command> [options]"

description: |                                   # REQUIRED: detailed command description
  Multi-line description of the command purpose,
  use cases, and expected behavior.

sections:                                        # REQUIRED: organized content sections
  section_name:
    title: "Section Title"                       # REQUIRED: section heading
    content: |                                   # REQUIRED: section content
      Multi-line content with formatting.
      Can include bullet points, code examples, etc.

examples:                                        # REQUIRED: usage examples
  - title: "Example title"                       # REQUIRED: example description
    command: "dirforge create research --name 'My Project'"  # REQUIRED: command to run
    description: "What this example demonstrates"  # OPTIONAL: additional context

related_commands:                                # OPTIONAL: related commands
  - command: "dirforge create"
    description: "Create new projects"

see_also:                                        # OPTIONAL: additional documentation
  - "Section IV.B for world configuration details"
  - "templates/world-configs/ for configuration examples"

constitution_section: "§III.V"                   # REQUIRED: constitution reference
version: "1.1.0"                                # REQUIRED: help file version
updated: "2025-12-30"                            # REQUIRED: last update date
```

#### IV.A.III Help Content Guidelines

**Content Requirements:**
1. **Clarity**: Help text MUST be clear, concise, and actionable
2. **Examples**: Every command MUST include at least 2-3 practical usage examples
3. **Constitution References**: Help content MUST reference the relevant constitution section
4. **Version Tracking**: Help files MUST include version and update date metadata
5. **Consistency**: All help files MUST follow the same schema and formatting conventions

**Formatting Standards:**
- Use multi-line YAML blocks (|) for content sections to preserve formatting
- Include proper indentation and line breaks for readability
- Use backticks for command names and file paths in descriptions
- Structure examples with title, command, and description fields
- Keep short_help summaries under 100 characters

#### IV.A.IV Help System Implementation

**Parser Requirements:**
- Help parsing MUST use `yq` (YAML query tool) for robust YAML processing
- Parser MUST support both short (`--help`) and long (`--help-long`) help variants
- Parser MUST handle missing or malformed YAML files gracefully with fallback messages
- Parser MUST format output with proper headers, sections, and examples

**Display Requirements:**
- Short help MUST display: command, summary, usage, key options, and quick examples
- Long help MUST display: full description, all sections, comprehensive examples, related commands
- Help output MUST use terminal formatting (colors, bold, underlines) for readability
- Long help MUST use automatic pager integration for content longer than terminal height

**Fallback Mechanism:**
- Each help function MUST attempt YAML-based help first using `get_command_help`
- If YAML loading fails, functions MUST fall back to minimal hard-coded help text
- Fallback help MUST provide basic usage information and reference the YAML help system
- Error messages MUST clearly indicate when YAML help is unavailable

**Code Integration:**
Help functions in `lib/help.sh` MUST follow this pattern:

```bash
show_<command>_help() {
    local mode="${1:-short}"  # default to short
    
    if [ "$mode" = "short" ]; then
        # Try YAML first
        if get_command_help "<command-name>" "short" 2>/dev/null; then
            return 0
        fi
        
        # Fallback to minimal hard-coded help
        show_<command>_help_short "v1.1.0"
        return
    fi
    
    # Try YAML-based long help
    if get_command_help "<command-name>" "long" 2>/dev/null; then
        return 0
    fi
    
    # Fallback: show short help
    show_<command>_help_short "v1.1.0"
}
```

#### IV.A.V Help System Maintenance

**Update Process:**
1. When adding new commands: Create corresponding YAML file in `templates/help/`
2. When modifying functionality: Update relevant YAML help file with new information
3. When releasing versions: Update `version` and `updated` fields in all modified help files
4. When changing structure: Update `constitution_section` references as needed

**Validation:**
- Help files MUST be validated with `yq` before committing changes
- New help files MUST be tested with both `--help` and `--help-long` flags
- Help output MUST be verified for proper formatting and completeness
- Examples in help files MUST be tested for correctness

**Documentation:**
- Help file schema MUST be documented in `docs/yaml-parsing-api.md`
- Parser implementation MUST be documented in `lib/help_yaml_parser.sh`
- Migration from hard-coded help MUST follow procedures in `docs/migration-to-yaml-configs.md`

#### IV.A.VI Benefits and Rationale

**Separation of Concerns:**
- Help content is decoupled from implementation logic in bash scripts
- Content changes can be made without modifying code
- Help files can be edited by non-programmers

**Maintainability:**
- All help content is centralized in `templates/help/`
- Changes to help text don't require script modifications
- Version tracking is explicit in each help file

**Consistency:**
- Standardized schema ensures uniform help output
- Automated formatting provides consistent user experience
- Examples follow the same structure across all commands

**Extensibility:**
- New commands only require adding a YAML file
- Help content can be easily translated or customized
- Advanced features (search, filtering) can be added to parser

**Version Control:**
- Help content changes are tracked in git history
- Help file versions align with constitution versions
- Documentation updates are visible in commit logs

**Rationale**: YAML-based help system transforms dirforge documentation from scattered hard-coded strings into a maintainable, extensible content management system that improves user experience, simplifies updates, and enables future enhancements while keeping code clean and focused.

### IV.B World Configuration System (YAML-Driven Scaffolding)

The DirForge scaffolding system MUST use YAML-based configuration files to define and generate world structures dynamically, replacing hard-coded folder definitions in the main `dirforge` script. This approach enables flexible, maintainable, and extensible project structure definitions.

#### IV.B.I Configuration Architecture

**Configuration Location:**
- World configuration files MUST be stored in `templates/world-configs/` 
- Each world type MUST have one configuration file: `<world-type>.world.yaml` (e.g., `coding.world.yaml`, `research.world.yaml`)
- Configuration files MAY be supplemented with language-specific or context-specific variants (e.g., `coding.world.python.yaml` for Python-specific overrides)

**Supported World Types and Configuration Files:**
The following world configuration files MUST be maintained in `templates/world-configs/`:
- `coding.world.yaml` — CODING_WORLD structure and language-specific subfolders
- `research.world.yaml` — RESEARCH_WORLD project and study structures
- `journal.world.yaml` — JOURNAL_WORLD role-based organization
- `lecture.world.yaml` — LECTURE_WORLD course structure and educational materials
- `office.world.yaml` — OFFICE_WORLD administrative and non-project folders
- `private.world.yaml` — PRIVATE_WORLD personal and sensitive materials
- `literature.world.yaml` — LITERATURE_WORLD for research literature and reference management (future expansion)

#### IV.B.II World Configuration Schema

Each `<world-type>.world.yaml` file MUST conform to the following schema:

```yaml
# World configuration file schema
world_type: "<WORLD_TYPE>"                    # REQUIRED: e.g., CODING_WORLD, RESEARCH_WORLD
description: "Description of world purpose"   # REQUIRED: human-readable description
version: "1.1.0"                             # REQUIRED: configuration version
constitution_version: "1.1.0"                # REQUIRED: constitution version this config supports

# Global metadata
metadata:
  creation_template: "world.yaml.template"    # REQUIRED: template for world.yaml
  integrity_required: true                    # REQUIRED: whether .integrity/ directory is mandatory
  default_owner: "${USER}"                    # OPTIONAL: default owner (supports ${USER} expansion)

# Parent-level directories (created directly under WORLD_TYPE root)
parent_directories:
  - name: "<dir_name>"                        # REQUIRED: directory name
    description: "Purpose"                    # REQUIRED: description
    integrity: true                           # OPTIONAL: whether to create .integrity/ (default: false)
    project_scope: "world"                    # OPTIONAL: "world" or "project" level

# Subdirectory structures (templates for projects within parent directories)
subdirectories:
  - parent: "<parent_dir_name>"               # REQUIRED: parent directory name
    description: "Subdirectory template"      # REQUIRED: description
    structure:
      - name: "<subdir_name>"                 # REQUIRED: subdirectory name
        type: "folder|file"                   # REQUIRED: "folder" or "file"
        template: "<template_file>"           # CONDITIONAL: template file for files
        description: "Purpose"                # REQUIRED: description
        integrity: false                      # OPTIONAL: whether to create .integrity/ (default: false)
        children:                             # OPTIONAL: nested subdirectories
          - name: "<nested_dir>"
            description: "Nested purpose"
```

#### IV.B.III Configuration File Examples

**Example: `templates/world-configs/coding.world.yaml`**

```yaml
world_type: CODING_WORLD
description: "Coding projects organized by programming language"
version: "1.1.0"
constitution_version: "1.1.0"

metadata:
  creation_template: "world.yaml.template"
  integrity_required: true
  default_owner: "${USER}"

parent_directories:
  - name: "python"
    description: "Python projects"
    integrity: true
    project_scope: "world"
  - name: "matlab"
    description: "MATLAB projects"
    integrity: true
    project_scope: "world"
  - name: "bash"
    description: "Bash/Shell script projects"
    integrity: true
    project_scope: "world"
  - name: "fortran"
    description: "Fortran projects"
    integrity: true
    project_scope: "world"
  - name: "c"
    description: "C projects"
    integrity: true
    project_scope: "world"
  - name: "latex"
    description: "LaTeX documentation projects"
    integrity: true
    project_scope: "world"
  - name: "clusters"
    description: "Cluster configuration and management"
    integrity: false
    project_scope: "world"
  - name: "github"
    description: "Repository management and GitHub configuration"
    integrity: false
    project_scope: "world"

subdirectories: []  # Language directories are not subdivided further by config; projects define their own structure
```

**Example: `templates/world-configs/research.world.yaml`**

```yaml
world_type: RESEARCH_WORLD
description: "Research projects organized by research activity, with studies as primary units"
version: "1.1.0"
constitution_version: "1.1.0"

metadata:
  creation_template: "world.yaml.template"
  integrity_required: true
  default_owner: "${USER}"

# Project-level structure (top-level folders within RESEARCH_WORLD)
parent_directories:
  - name: "00_admin"
    description: "Project administrative artifacts, contracts, ethics approvals"
    integrity: true
    project_scope: "project"
  - name: "01_project_management"
    description: "Project proposals, reports, budgets, finance, presentations"
    integrity: true
    project_scope: "project"
  - name: "02_studies"
    description: "Container for all individual research studies"
    integrity: false
    project_scope: "project"

# Project-level 01_project_management subdirectories
subdirectories:
  - parent: "01_project_management"
    description: "Project management structure"
    structure:
      - name: "01_proposal"
        type: "folder"
        description: "Proposal lifecycle and submission materials"
        children:
          - name: "01_draft"
            description: "Working drafts and internal notes"
          - name: "02_submission"
            description: "Final submission files and receipts"
          - name: "03_review"
            description: "Reviewer responses and correspondence"
          - name: "04_final"
            description: "Final accepted proposal documents"
      - name: "02_finance"
        type: "folder"
        description: "Budgets, invoices, funding agreements"
      - name: "03_reports"
        type: "folder"
        description: "Periodic reports, deliverables, technical reports"
      - name: "04_presentations"
        type: "folder"
        description: "Project-wide slides and presentation materials"

# Study-level structure (within 02_studies/<study_name>/)
study_subdirectories:
  - name: "00_protocols"
    description: "Experimental protocols, instrument configurations"
    integrity: false
  - name: "01_code"
    description: "Analysis code, scripts, notebooks, environment.yml"
    integrity: false
  - name: "02_data"
    description: "Raw and processed datasets, metadata.yaml"
    integrity: false
  - name: "03_outputs"
    description: "Processed results, figures, tables"
    integrity: false
  - name: "04_publication"
    description: "Manuscript drafts, supplementary materials"
    integrity: false
    template: "research/04_publication"
  - name: "05_presentations"
    description: "Conference slides and presentation materials"
    integrity: false
    template: "research/05_presentations"
```

**Example: `templates/world-configs/journal.world.yaml`**

```yaml
world_type: JOURNAL_WORLD
description: "Journal activities organized by role: primary authorship, co-author invites, and journal service"
version: "1.1.0"
constitution_version: "1.1.0"

metadata:
  creation_template: "world.yaml.template"
  integrity_required: true
  default_owner: "${USER}"

parent_directories:
  - name: "00_admin"
    description: "Administrative materials, memberships, society correspondence"
    integrity: true
    project_scope: "project"
  - name: "01_primary_authorship"
    description: "Papers where you are lead or corresponding author"
    integrity: false
    project_scope: "project"
  - name: "02_coauthor_invites"
    description: "Collaborative authorship projects"
    integrity: false
    project_scope: "project"
  - name: "03_journal_service"
    description: "Peer review work and editorial duties"
    integrity: false
    project_scope: "project"

subdirectories:
  - parent: "01_primary_authorship"
    description: "Primary authorship project structure"
    structure:
      - name: "01_manuscript"
        type: "folder"
        description: "Manuscript drafts and revisions"
      - name: "02_reviews"
        type: "folder"
        description: "Peer review reports and responses"
      - name: "03_correspondence"
        type: "folder"
        description: "Editorial communications"
  - parent: "02_coauthor_invites"
    description: "Co-author project structure"
    structure:
      - name: "01_manuscript"
        type: "folder"
        description: "Manuscript drafts and contributions"
      - name: "02_reviews"
        type: "folder"
        description: "Review feedback"
      - name: "03_correspondence"
        type: "folder"
        description: "Collaboration communications"
  - parent: "03_journal_service"
    description: "Journal service project structure"
    structure:
      - name: "01_manuscript"
        type: "folder"
        description: "Papers under review"
      - name: "02_reviews"
        type: "folder"
        description: "Review reports and decisions"
      - name: "03_correspondence"
        type: "folder"
        description: "Editorial communications"
```

#### IV.B.IV Configuration Processing and Execution

**Loading and Parsing:**
- `dirforge` MUST load the appropriate `<world-type>.world.yaml` file when executing world or project creation commands
- YAML parsing MUST support variables and expansions (e.g., `${USER}` for current user, `${DATE}` for current date)
- Configuration loading MUST validate schema compliance and report errors clearly before proceeding

**Scaffold Generation:**
- When creating a new world or project, `dirforge` MUST:
  1. Load the corresponding `<world-type>.world.yaml` configuration
  2. Parse parent directories and subdirectory templates
  3. Create all specified directories in the correct hierarchy
  4. Generate `.integrity/` directories as specified in configuration
  5. Create metadata files (`.integrity/world.yaml`, `.integrity/project.yaml`, etc.) using templates
  6. Apply any language-specific overrides or customizations

**Extensibility and Customization:**
- Users MAY create custom world configuration files (e.g., `custom_world.world.yaml`) to define new world types
- `dirforge` MUST provide a command to validate custom configuration files: `dirforge validate-config <config_file>`
- Configuration files MAY inherit or extend base world configurations using an `extends:` field (future enhancement)

#### IV.B.V Integration with dirforge Command Structure

**Updated Command Syntax:**
The `dirforge` script follows clear command separation with init for workspace setup and create for entity creation:

```bash
# Initialize complete workspace with all world directories (workspace setup only)
dirforge init [path] [--auto]

# Create new research projects and studies within initialized workspace
dirforge create research --project "my_project" [--config templates/world-configs/research.world.yaml]

# Create new coding projects with language support
dirforge create coding --language python --project "my_library"

# Create lecture materials and course content
dirforge create lecture --course "CS101" --title "Course Title"

# Create journal activities with role-based structure
dirforge create journal primary --paper "Paper Title" --year 2025

# Validate a world configuration file
dirforge validate-config templates/world-configs/custom_world.world.yaml

# List available world configurations
dirforge list-configs
```

**Command Separation Principles:**
- `dirforge init` MUST handle workspace initialization ONLY - creates all world directories but no specific projects
- `dirforge create <entity-type>` MUST handle entity creation ONLY - creates specific projects within existing workspace
- Backward compatibility MUST be maintained during transition with deprecation warnings
- `init <entity-type>` syntax is deprecated but functional, redirecting to equivalent `create` commands

**Configuration Discovery:**
- `dirforge` MUST automatically discover all `<world-type>.world.yaml` files in `templates/world-configs/`
- Invalid or unparseable configuration files MUST generate clear error messages without halting other discovery

#### IV.B.VI Benefits and Rationale

**Separation of Concerns:**
- Folder structure definitions are now decoupled from implementation logic in the `dirforge` script
- Structure changes can be made by editing configuration files without modifying the main script

**Maintainability:**
- All world structures are centralized and consistent across world types
- Adding new world types requires only creating a new configuration file, not modifying `dirforge`
- Configuration files serve as authoritative documentation of expected structures

**User Customization:**
- Power users can define custom world configurations for specialized workflows
- Organizations can enforce standardized structures by providing pre-configured files

**Reproducibility and Auditability:**
- World structures are version-controlled alongside code
- Configuration versions enable tracking of structure evolution
- Easy to compare and validate structure consistency across projects

**Scalability:**
- Future extensions (e.g., template inheritance, conditional structures) can be added without breaking existing configurations
- Configuration schema can evolve independently of core `dirforge` logic

**Rationale**: YAML-driven configuration transforms DirForge from a hard-coded tool into a configurable scaffolding framework, enabling long-term maintainability, user customization, and organizational standardization while keeping the implementation clean and focused.

### Report Naming Convention
Report files generated for project tracking and status documentation MUST follow the date-only naming pattern:
- Format: `YYYYMMDD-<report-type>.md`
- Example: `20251209-status-checkup.md`
- Rationale: Date-only format (no time component) simplifies file management and ensures unique daily reports without time-based granularity

Reports MUST be stored in the `report/` directory and excluded from version control (`.gitignore` compliance).

### Testing Environment and Infrastructure
All testing for DirForge functionality MUST be conducted within a standardized testing environment to ensure consistency, maintainability, and comprehensive feature validation.

**Testing Location Requirements:**
- ALL test files and test directories MUST be located exclusively in `tests/` within the local repository root
- For DirForge development: `tests/` directory located at repository root (e.g., `/Users/[username]/Documents/CODING_WORLD/bash/dirforge/tests/`)
- NO test files or testing infrastructure SHALL be created outside this designated directory
- Private development paths or user-specific information MUST NOT be exposed in repository commits

**Test Directory Structure:**
The `tests/` directory MUST follow this mandatory structure:

```
tests/
├── run_tests.sh                         # Main test runner (discovers and executes all tests)
├── test-functions/                      # Individual feature test scripts
│   ├── test_<feature_name>_v<version>.sh # One test script per feature/functionality with version
│   ├── test_version_detection_v1.0.21.sh # Example: version detection tests (developed in v1.0.21)
│   ├── test_migration_logic_v1.0.21.sh   # Example: migration system tests (developed in v1.0.21)
│   └── test_world_type_aware_v1.0.21.sh  # Example: world-type awareness tests (developed in v1.0.21)
├── fixtures/                           # Test data and mock structures
│   ├── sample_projects/                # Sample project structures for testing
│   └── expected_outputs/               # Expected test outputs for validation
└── README.md                           # Testing documentation and guidelines
```

**Test Implementation Requirements:**

1. **Feature Coverage**: Every new feature or functionality added to DirForge MUST have a corresponding test script in `tests/test-functions/`

2. **Test Script Naming**: Test scripts MUST follow the pattern `test_<feature_name>_v<version>.sh` where `<feature_name>` describes the specific functionality being tested and `<version>` indicates the DirForge version when the test was developed (e.g., `test_version_detection_v1.0.21.sh`, `test_migration_logic_v1.0.21.sh`)

3. **Main Test Runner**: The `tests/run_tests.sh` script MUST:
   - Automatically discover all test scripts in `tests/test-functions/`
   - Execute each test script in a controlled environment
   - Provide consolidated pass/fail reporting
   - Support both individual test execution and full test suite runs
   - Clean up test artifacts after execution

4. **Test Script Standards**: Each individual test script MUST:
   - Be executable and self-contained
   - Use consistent exit codes (0 for pass, non-zero for fail)
   - Provide clear output indicating test results
   - Clean up any temporary files or directories created during testing
   - Include descriptive test names and failure messages

5. **Regression Testing**: The test infrastructure MUST validate that:
   - All previously implemented features continue to work after updates
   - New features do not break existing functionality
   - Migration logic preserves data integrity across version updates
   - All world types maintain proper structure and behavior

**Test Environment Isolation:**
- Tests MUST run in isolated temporary directories to prevent interference with development workspace
- Test fixtures MUST be self-contained and not rely on external dependencies
- Tests MUST NOT modify or access user's actual project directories during execution
- All test data MUST be cleaned up automatically after test completion

**Continuous Integration Requirements:**
- The complete test suite MUST pass before any code changes are considered complete
- New features MUST include corresponding tests before implementation is accepted
- Test failures MUST be investigated and resolved before proceeding with development

**Rationale**: Comprehensive testing infrastructure ensures DirForge reliability, prevents regression bugs, validates all functionality across updates, and maintains code quality standards. Centralized testing in `tests/` directory provides clear organization and prevents scattered test files throughout the codebase. Version tracking in test names enables prioritization of failing tests based on implementation timeline and feature criticality.

## Governance
- No contribution by other owners. Only main author: Martin Balcewicz
- No further commands needed.

Versioning policy (semantic):
- MAJOR: Incompatible governance changes, removals, or principle redefinitions.
- MINOR: New principle or materially expanded guidance.
- PATCH: Wording clarifications, typos, or non-semantic refinements.

**Version**: 1.1.0 | **Ratified**: 2025-12-15 | **Last Amended**: 2025-12-31