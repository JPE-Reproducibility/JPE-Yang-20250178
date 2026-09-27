from __future__ import annotations

import os
from pathlib import Path

ROOT = Path(os.environ.get("REPLICATION_ROOT") or os.environ.get("JPE_GENERATE_ROOT")
            or Path(__file__).resolve().parents[2])

CONF_DIR = ROOT / "confidential-data-not-for-publication"
RAW_DIR = CONF_DIR / "Raw"
PUB_RAW_DIR = ROOT / "data" / "raw"
MANUAL_DIR = PUB_RAW_DIR / "other_data_resource"
MANUAL_DIR_CONF = RAW_DIR / "other_data_resource"
ANALYSIS_DIR = CONF_DIR / "Analysis"
INTERMEDIATE_DATA_DIR = ANALYSIS_DIR / "intermediate_and_other_data"

OUTPUT_DIR = ROOT / "output"
TABLE_DIR = OUTPUT_DIR / "tables"
FIGURE_DIR = OUTPUT_DIR / "figures"
INTERMEDIATE_DIR = OUTPUT_DIR / "intermediate"
LOG_DIR = OUTPUT_DIR / "logs"

STATA_INVARIANT_DIR = RAW_DIR

STATA_DATA_DIR = ANALYSIS_DIR
SUITABILITY_OUTPUT_DIR = INTERMEDIATE_DATA_DIR

for directory in [TABLE_DIR, FIGURE_DIR, INTERMEDIATE_DIR, LOG_DIR, ANALYSIS_DIR, INTERMEDIATE_DATA_DIR]:
    directory.mkdir(parents=True, exist_ok=True)
