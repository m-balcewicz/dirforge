<!-- 
SYNC IMPACT REPORT: Constitution Update v1.1.1 → v1.2.0
==========================================================

Version Change: 1.1.1 → 1.2.0 (MINOR bump)

Modified Principles:
- III. Data Lifecycle & Integrity: Updated to reflect hierarchical .integrity/ system evolution
- V. Administrative Separation & Access Control: Clarified with explicit command structure

Added Sections:
- VI. Command Structure and Workflow: Init/Create separation
- VII. Declarative Configuration System: YAML-based world structures
- VIII. Version Management and Compatibility: Template/versioning principles

Removed Sections:
- None (only reorganization of existing content)

Follow-up TODOs:
- [ ] Update all help templates to reference Constitution v1.2.0
- [ ] Add migration guide for v1.1.x → v1.2.0 projects
- [ ] Document template propagation safety restrictions in Section VII

Rationale for Bump: MINOR - New section added (Command Structure) and existing sections
materially expanded with YAML configuration system guidance. No backward-incompatible changes.
-->

# DirForge Constitution

## Core Principles

### I. Research-Activity First (Project-by-Activity)

All research work MUST be organized by research activity or project (project/grant/topic) rather than by document type alone.
Each project root MUST contain a short `README.md` and a machine-readable metadata file (`.integrity/project.yaml`) describing scope, owner, and key dates.

**Rationale**: Unifies administrative artifacts and scientific outputs so that deliverables, provenance, and responsibilities are co-located and discoverable.

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

**Rationale**: Prevents fragmentation and accidental edits across devices while enabling reproducible, backed-up research workflows.

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

#### III.A The .integrity Directory System

The `.integrity/` directory is a centralized metadata and validation system used at every organizational level (workspace, world, project, study) to maintain data consistency, provenance tracking, and automated validation.

##### III.A.I Directory Structure and Hierarchy

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

##### III.A.II File Specifications

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

##### III.A.III Access Policies and Security

- `.integrity/` directories are hidden by default (dot-prefix)
- Metadata files MUST be human-readable YAML format
- Checksum files MUST be automatically generated and validated
- NO credentials or sensitive information in any `.integrity/` files
- External dataset access credentials MUST reference secure credential stores

##### III.A.IV Integration with Manifest System

The `.integrity/` system integrates with the manifest policy (Section II) for external datasets:

- Large datasets stored externally MUST have manifest files (`<dataset>.manifest.yaml`) in project directories
- Manifests MUST reference checksums using `.integrity/checksums/` paths
- Manifest validation tools MUST verify checksum file existence and integrity
- Backup copies of manifests MAY be stored in `.integrity/manifests/` for auditing

##### III.A.V Automation and Tooling

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

**Example structure**:

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

**Role-Based Structure**:

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

**Identifier Conventions**:

- Primary authorship: Use paper title (e.g., `thermal_analysis`, `2024_seismic_modeling`)
- Co-author invites: Use paper title or project name (e.g., `2021_elastic_properties`, `international_consortium`)
- Journal service: Use `<JOURNAL_NAME>/<ID>` where ID can be:
  - Manuscript ID: `GEO-2025-0451`, `NGEO-2025-1234`
  - Reviewer batch: `REVIEWER_2024_Q4`, `REVIEWER_BATCH_01`
  - Editorial role: `ASSOCIATE_EDITOR_2024`, `SPECIAL_ISSUE_ML`

**Usage Examples**:

**Example structure**:

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

**Rationale**:

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

**Example structure**:

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

**Example structure**:

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

**Study organization rationale**:

Research projects often comprise multiple distinct studies (different experiments, sample batches, measurement campaigns, computational investigations, or analytical approaches). The 02_studies/ structure allows each study to be completely self-contained with its own:
- Experimental or computational protocols
- Code and analysis workflows
- Data and datasets
- Results and outputs
- Publication materials
- Data integrity validation

This prevents mixing data and results from different studies, enables independent reproducibility per study, and maintains clear provenance. Studies can be worked on in parallel, archived independently, or shared selectively.

**Example structure**:

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

**Requirements**:

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

**Example structure**:

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

Administrative, personal, and sensitive records MUST remain separate from research:
- `OFFICE_WORLD/` and `PRIVATE_WORLD/` remain the canonical locations for administrative and private files.
Project roots MUST separate administrative artifacts (`01_project_management/`) from scientific artifacts (`04_data/`, `05_data_analysis/`, `06_data_outputs`), and grant access accordingly.

**Rationale**: Protects privacy and simplifies compliance while keeping research outputs accessible.

## Command Structure and Workflow

The `dirforge` CLI enforces a clear separation between workspace initialization and entity creation:

### VI.A Workspace Initialization (`dirforge init`)

The `dirforge init` command creates workspace roots with all world directories:

- **Complete Workspace**: `dirforge init [path]` creates CODING_WORLD, JOURNAL_WORLD, LECTURE_WORLD, OFFICE_WORLD, PRIVATE_WORLD, RESEARCH_WORLD
- **Workspace-only Entities**: `dirforge init office|private` creates individual workspace roots for office/private worlds
- **Parent-only Mode**: `dirforge init <world-type>` creates only the parent directory (e.g., RESEARCH_WORLD/) without subfolders

All workspace initialization MUST create appropriate `.integrity/` directories and metadata files at the workspace level.

### VI.B Entity Creation (`dirforge create`)

The `dirforge create <entity>` command creates specific projects within existing workspaces:

- **Research Projects**: `dirforge create research --name "Project Name" [--study "First Study"]`
- **Lecture Projects**: `dirforge create lecture --name "Course Name"`
- **Coding Projects**: `dirforge create coding --language python --project "Project Name"`
- **Journal Projects**: Role-based organization with `--name`, `--first`, `--coauthor`, `--service` flags
  - Primary authorship: `dirforge create journal --name "Paper" --first`
  - Co-author collaboration: `dirforge create journal --name "Project" --coauthor`
  - Journal service: `dirforge create journal --name "Journal" --id "ID" --service`

Entity creation MUST only occur within existing workspace directories and MUST NOT create workspace roots.

### VI.C Backward Compatibility

Deprecated `dirforge init <entity>` syntax MUST continue to work with deprecation warnings:
- Automatic warnings guide users to `dirforge create <entity>` syntax
- Suppress warnings with `DIRFORGE_SUPPRESS_DEPRECATION=1` environment variable

**Rationale**: Clear separation prevents workspace corruption and provides a mental model for when to use each command.

## Declarative Configuration System

DirForge uses YAML-based configuration files for defining world structures:

### VII.A Configuration Files

All world structures MUST be defined in YAML configuration files under `templates/world-configs/`:
- `coding.world.yaml`, `research.world.yaml`, `lecture.world.yaml`
- `journal.world.yaml`, `office.world.yaml`, `private.world.yaml`, `literature.world.yaml`

Each configuration file MUST include a structured header with metadata tags:
- `@schema-version`: Template schema version
- `@template-version`: Independent template version (semver)
- `@world-type`: World type identifier
- `@last-updated`: ISO 8601 datestamp

### VII.B Variable Expansion

Configuration files MUST support variable expansion:
- `${USER}`: Current system username
- `${DATE}`: ISO 8601 UTC timestamp

### VII.C Template Propagation

Baseline templates MUST be automatically propagated to new scaffolds:
- `templates/git_template/.gitignore.template`
- `templates/vscode_template/settings.json.template`
- `templates/vscode_template/vscode.code-workspace.template`
- `templates/TeX_template/04_publication/` and `05_presentations/`

Safety restrictions MUST be enforced:
- Template sources MUST resolve under `templates/`
- Writes MUST be restricted to target roots
- Writes to `.integrity/` paths MUST be blocked
- Missing template sources MUST fail fast with explicit errors

### VII.D Custom World Types

Users MAY create custom world configurations following the schema:
- Define `world.type`, `metadata`, `parent_directories`, and `subdirectories`
- Validate with `dirforge validate-config <config-file>`
- Distribute as YAML files for team-wide use

**Rationale**: Declarative configuration enables reproducible, version-controlled workspace structures and supports custom world types without code changes.

## Version Management and Compatibility

### VIII.A Constitution Versioning

The constitution MUST track its version in all metadata files:
- Format: MAJOR.MINOR.PATCH (semantic versioning)
- MAJOR: Breaking changes to governance principles
- MINOR: New principles or material expansions
- PATCH: Clarifications, wording fixes

### VIII.B Template Versioning

Template files MUST use independent versioning from the constitution:
- Template versions tracked in `@template-version` header
- Semantic versioning allows template evolution without constitution bumps
- Template migrations documented separately from constitution updates

### VIII.C Backward Compatibility

The tool MUST maintain backward compatibility with deprecated syntax:
- Deprecation warnings guide users to new patterns
- `DIRFORGE_SUPPRESS_DEPRECATION=1` allows suppression for CI/CD
- Migration guides provided for each breaking change

### VIII.D Migration Safety

All updates MUST be additive-only (never delete or overwrite existing files):
- Atomic operations with transaction rollback on error
- Backup creation with `--backup` flag
- Dry-run preview with `--dry-run` flag

**Rationale**: Clear versioning principles prevent breaking changes and ensure smooth upgrades across project lifecycles.

## Governance

The DirForge Constitution supersedes all other organizational practices and development guidelines. All project scaffolding, directory structures, and metadata systems MUST comply with this constitution.

### Amendment Procedure

Constitution amendments require:
1. Proposal with rationale and impact analysis
2. Review period for community feedback
3. Version bump according to semantic versioning rules
4. Update to all documentation and help templates
5. Migration guide for breaking changes

### Versioning Policy

- Constitution version tracked in `.integrity/workspace.yaml` and all world metadata
- Template version independent from constitution (see Section VIII.B)
- Version consistency validated during scaffold generation

### Compliance Review

All PRs and code reviews MUST verify:
- Constitution compliance of new directory structures
- Proper use of `.integrity/` system
- Correct version references in help text and documentation

**Rationale**: Strong governance ensures consistency across all DirForge projects and prevents fragmentation of practices.

**Version**: 1.2.0 | **Ratified**: TODO(2026-09-14) | **Last Amended**: 2026-09-14
