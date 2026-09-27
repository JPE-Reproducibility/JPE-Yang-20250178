"""Reproduce the three frozen `patent_sector_labels_*.dta` files.

These files (shipped in the package under `Raw/BERT_prediction_resource/`) are NOT written by any
original author script -- they are column subsets/renames of the `positive_results_*` patent
prediction files. This helper scripts that step. All three reproduce the frozen output exactly
(verified against the shipped files):

    patent_sector_labels_grantyear.dta      <- positive_results_100k.csv
        keep: patent_id, file->sector, disambig_country, patent_date        [verbatim; verified identical]
    patent_sector_labels_new_grantyear.dta  <- positive_results_100k_new.dta
        keep: patent_id, file->sector, patent_year, disambig_country        [verbatim; verified identical]
    patent_sector_labels_new100k.dta        <- positive_results_100k_new.dta
        sector = lowercased `file` (alphanumeric, digits kept); keep [patent_id, sector], unique; RESTRICTED to
        patents that appear as CITING patents in g_us_patent_citation.tsv where BOTH the citing and
        cited patent are located (utility + assignee_sequence==0 + non-null disambig_country).
        [verified: reproduces all 84,179 patents / 451,328 rows exactly]

The new100k restriction is the same "both-endpoints-located citation" logic the package's
06a_generate_patent_citations_from_raw.py uses. It streams the ~9 GB g_us_patent_citation.tsv, so it is the
one slow step here; it is skipped automatically if the raw citation data is not present.

Config (environment variables; defaults are the author's original layout):
    EXPENSIVE_ML_ROOT : the EntTemplates folder containing Analysis/
    OUTPUT_DIR        : where the .dta files are written (default: ./patent_sector_labels_out)
"""
import os
import re
from pathlib import Path

import pandas as pd

ENT_ROOT = Path(os.environ.get(
    "EXPENSIVE_ML_ROOT",
    "PATH_TO_ENTTEMPLATES_DATA_ROOT",
))
SRC_DIR = ENT_ROOT / "Analysis" / "python_BERT" / "data_patent"
PV_DIR = ENT_ROOT / "Analysis" / "python_Patent" / "data"   # PatentsView bulk TSVs
OUT_DIR = Path(os.environ.get("OUTPUT_DIR", "patent_sector_labels_out"))


def _norm_id(series):
    return series.astype(str).str.strip().str.replace(r"\.0$", "", regex=True)


def _alnum_lower(series):
    # lowercase, keep alphanumerics (the frozen sector keeps digits, e.g. "...web3security")
    return series.astype(str).str.replace(r"[^A-Za-z0-9]", "", regex=True).str.lower()


# --- the two verbatim column-subset files ----------------------------------------------------
VERBATIM = {
    "patent_sector_labels_grantyear.dta": (
        "positive_results_100k.csv", ["patent_id", "file", "disambig_country", "patent_date"]),
    "patent_sector_labels_new_grantyear.dta": (
        "positive_results_100k_new.dta", ["patent_id", "file", "patent_year", "disambig_country"]),
}


def _read(path, columns):
    if path.suffix.lower() == ".csv":
        return pd.read_csv(path, usecols=columns)
    return pd.read_stata(path, columns=columns)


def located_utility_patents():
    """patent_id set: utility patents whose first assignee (sequence 0) has a located country."""
    gp = pd.read_csv(PV_DIR / "g_patent.tsv", sep="\t", usecols=["patent_id", "patent_type"], dtype=str)
    putil = set(gp[gp.patent_type == "utility"].patent_id.str.replace(" ", "", regex=False))
    gl = pd.read_csv(PV_DIR / "g_location_disambiguated.tsv", sep="\t",
                     usecols=["location_id", "disambig_country"], dtype=str).dropna(subset=["disambig_country"])
    loc_ids = set(gl.location_id)
    ga = pd.read_csv(PV_DIR / "g_assignee_disambiguated.tsv", sep="\t",
                     usecols=["patent_id", "assignee_sequence", "location_id"], dtype=str)
    ga = ga[(ga.assignee_sequence == "0") & ga.location_id.isin(loc_ids)]
    return set(ga.patent_id.str.replace(" ", "", regex=False)) & putil


def both_located_citing_patents(located):
    """Citing patent_ids from g_us_patent_citation where citing AND cited are both located."""
    citing = set()
    for ch in pd.read_csv(PV_DIR / "g_us_patent_citation.tsv", sep="\t",
                          usecols=["patent_id", "citation_patent_id"], dtype=str, chunksize=8_000_000):
        a = ch.patent_id.str.replace(" ", "", regex=False)
        b = ch.citation_patent_id.str.replace(" ", "", regex=False)
        citing.update(a[a.isin(located) & b.isin(located)].unique())
    return citing


def make_new100k():
    cit = PV_DIR / "g_us_patent_citation.tsv"
    if not cit.exists() or cit.stat().st_size == 0:
        print("[skip] patent_sector_labels_new100k.dta: raw g_us_patent_citation.tsv not available "
              "(needed for the both-endpoints-located citing restriction).")
        return
    print("[new100k] building located-citing patent set (streams ~9 GB g_us_patent_citation.tsv)...")
    keep = both_located_citing_patents(located_utility_patents())
    df = _read(SRC_DIR / "positive_results_100k_new.dta", ["patent_id", "file"])
    df["patent_id"] = _norm_id(df["patent_id"])
    df["sector"] = _alnum_lower(df["file"])
    df = df[df["patent_id"].isin(keep)][["patent_id", "sector"]].drop_duplicates()
    out = OUT_DIR / "patent_sector_labels_new100k.dta"
    df.to_stata(out, write_index=False)
    print(f"[ok] positive_results_100k_new.dta -> {out}  ({len(df):,} rows, {df.patent_id.nunique():,} patents)")


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for out_name, (src_name, columns) in VERBATIM.items():
        src = SRC_DIR / src_name
        if not src.exists() or src.stat().st_size == 0:
            print(f"[skip] source missing/empty: {src}")
            continue
        df = _read(src, columns).rename(columns={"file": "sector"})
        df.to_stata(OUT_DIR / out_name, write_index=False)
        print(f"[ok] {src_name} ({len(df):,} rows) -> {OUT_DIR / out_name}")
    make_new100k()


if __name__ == "__main__":
    main()
