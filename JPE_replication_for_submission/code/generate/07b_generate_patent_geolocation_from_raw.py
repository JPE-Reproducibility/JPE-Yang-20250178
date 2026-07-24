#!/usr/bin/env python3
import os
import re
from pathlib import Path
import pandas as pd

ROOT = Path(os.environ.get("JPE_GENERATE_ROOT") or Path(__file__).resolve().parents[2])
PV   = ROOT / "data" / "raw" / "patent_resource"
INT  = ROOT / "confidential-data-not-for-publication" / "Analysis" / "intermediate_and_other_data"
INT.mkdir(parents=True, exist_ok=True)
NA = dict(keep_default_na=False, na_values=[])

loc = pd.read_csv(PV / "g_location_disambiguated.tsv", sep="\t", dtype=str, **NA)
pat = pd.read_csv(PV / "g_patent.tsv", sep="\t", usecols=["patent_id", "patent_type", "patent_date"], dtype=str, **NA)
pat = pat[pat.patent_type == "utility"].copy()
pat["patent_id"] = pat["patent_id"].str.strip()
loc["location_id"] = loc["location_id"].astype(str).str.strip()

def geolocate(seq_file, seq_col, id_col, extra, out_name):
    df = pd.read_csv(PV / seq_file, sep="\t", dtype=str, **NA).sort_values("patent_id")
    df = df[(df[seq_col] == "0") & (df["location_id"].notna()) & (df["location_id"] != "")]
    df["patent_id"] = df["patent_id"].astype(str).str.strip()
    df["location_id"] = df["location_id"].astype(str).str.strip()
    m = pat.merge(df, on="patent_id", how="left").merge(loc, on="location_id", how="left")
    cols = ["patent_id", "patent_type", "patent_date", id_col] + extra +\
           ["location_id", "disambig_city", "disambig_state", "disambig_country", "latitude", "longitude"]
    m[cols].to_csv(INT / out_name, index=False)
    print(f"{out_name}: {len(m):,} rows")

geolocate("g_inventor_disambiguated.tsv", "inventor_sequence", "inventor_id", [], "patent_geolocating_inventors.csv")
geolocate("g_assignee_disambiguated.tsv", "assignee_sequence", "assignee_id", ["assignee_type"], "patent_geolocating_assignees.csv")

d = loc.rename(columns={"disambig_city": "city", "disambig_state": "state", "disambig_country": "country"})
d = d.drop(columns=[c for c in ("state_fips", "county_fips") if c in d.columns])
d["city0"] = d["city"].fillna("").str.lower().apply(lambda s: re.sub(r"[^a-z0-9]", "", s))
d["state_2digit"] = d["state"].fillna("").str.lower().apply(lambda s: re.sub(r"[^a-z]", "", s))
d["country_2digit"] = d["country"].fillna("").str.lower().apply(lambda s: re.sub(r"[^a-z]", "", s))
d = d.drop_duplicates(["country_2digit", "state_2digit", "city0"], keep="first")
d["location_clean"] = d["country_2digit"] + d["state_2digit"] + d["city0"]
d["latitude"] = pd.to_numeric(d["latitude"], errors="coerce").astype("float32")
d["longitude"] = pd.to_numeric(d["longitude"], errors="coerce").astype("float32")
d = d[["location_id", "city", "state", "country", "latitude", "longitude", "county",
       "city0", "state_2digit", "country_2digit", "location_clean"]]
d.to_stata(INT / "patent_location_dict.dta", write_index=False, version=118)
print(f"patent_location_dict.dta: {len(d):,} rows")
print("DONE 07b -> patent geolocation layers in intermediate_and_other_data/")
