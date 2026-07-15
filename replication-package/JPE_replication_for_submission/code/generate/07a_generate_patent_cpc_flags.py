#!/usr/bin/env python3
import os
from pathlib import Path
import numpy as np
import pandas as pd

ROOT = Path(os.environ.get("JPE_GENERATE_ROOT") or Path(__file__).resolve().parents[2])
RAW  = ROOT / "data" / "raw"
PV   = RAW / "patent_resource"
INT  = ROOT / "confidential-data-not-for-publication" / "Analysis" / "intermediate_and_other_data"
INT.mkdir(parents=True, exist_ok=True)
NA = dict(keep_default_na=False, na_values=[])

ncdf = pd.read_csv(INT / "citations_count.csv",
                   dtype={"patent_id": "int64", "num_citations": "int64"})

cpc = pd.read_csv(PV / "g_cpc_current.tsv", sep="\t",
                  usecols=["patent_id", "cpc_sequence", "cpc_class", "cpc_subclass", "cpc_type"],
                  dtype=str, **NA)
cpc = cpc[(cpc.cpc_type == "inventional") & (cpc.cpc_sequence == "0")][["patent_id", "cpc_class", "cpc_subclass"]]
ncite = ncdf.astype({"patent_id": str})
pat_cpc = pd.read_csv(PV / "g_patent.tsv", sep="\t",
                      usecols=["patent_id", "patent_date", "patent_type"], dtype=str, **NA)
gc = cpc.merge(ncite, on="patent_id", how="left")
gc["num_citations"] = gc["num_citations"].fillna(0).astype(int)
gc = gc.merge(pat_cpc, on="patent_id", how="left")
gc["patent_year"] = pd.to_numeric(gc["patent_date"].str[:4], errors="coerce")
gc = gc[gc.patent_type == "utility"]
qt = gc.groupby(["cpc_subclass", "patent_year"])["num_citations"].quantile([.99, .95, .90, .75, .50]).unstack()
qt.columns = [f"q{int(c*100)}" for c in qt.columns]
gc = gc.merge(qt, on=["cpc_subclass", "patent_year"], how="left")
for q in (99, 95, 90, 75, 50):
    gc[f"above_{q}%"] = (gc.num_citations > gc[f"q{q}"]).astype(int)
gc = gc[["patent_id", "num_citations", "cpc_class", "cpc_subclass", "patent_date", "patent_type",
         "patent_year", "above_99%", "above_95%", "above_90%", "above_75%", "above_50%"]]
gc.to_csv(INT / "patent_citation_cpc.csv", index=False)
print(f"patent_citation_cpc.csv: {len(gc):,} rows (Feb-2023 g_cpc + Nov-2023 num_citations)")
print("DONE 07a -> patent_citation_cpc.csv in intermediate_and_other_data/")
