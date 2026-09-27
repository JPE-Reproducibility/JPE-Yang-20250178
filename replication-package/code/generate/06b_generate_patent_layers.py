#!/usr/bin/env python3
import os
from pathlib import Path
import numpy as np
import pandas as pd

ROOT = Path(os.environ.get("JPE_GENERATE_ROOT") or Path(__file__).resolve().parents[2])
RAW  = ROOT / "data" / "raw"
PAT  = RAW / "patent_resource"
BERT = ROOT / "confidential-data-not-for-publication" / "Raw" / "BERT_prediction_resource"
INT  = ROOT / "confidential-data-not-for-publication" / "Analysis" / "intermediate_and_other_data"
INT.mkdir(parents=True, exist_ok=True)

XW = pd.read_stata(RAW / "suitability_resource" / "country_crosswalk.dta")[["country_2digit", "hqcountry"]]

def pid(df, *cols):
    for c in cols:
        df[c] = df[c].astype(str)
    return df

lab = pd.read_stata(BERT / "patent_sector_labels_grantyear.dta")
lab = lab.rename(columns={"sector": "fullname_raw"})
lab = lab[lab.groupby("fullname_raw")["patent_id"].transform("count") <= 99900].copy()
lab["fullname_raw"] = lab["fullname_raw"].str.lower()
lab["country_2digit"] = lab["disambig_country"].astype(str)
lab["year"] = pd.to_numeric(lab["patent_date"].astype(str).str[:4], errors="coerce")
cnt = (lab.groupby(["year", "country_2digit", "fullname_raw"]).size()
       .reset_index(name="count_predicted_patents"))
cnt = cnt[(cnt.country_2digit != "") & (cnt.year >= 2000) & (cnt.year <= 2019)]
cnt = cnt.merge(XW, on="country_2digit", how="inner").drop(columns="country_2digit")
cnt = cnt[["fullname_raw", "year", "count_predicted_patents", "hqcountry"]]
cnt["year"] = cnt["year"].astype(np.int32)
cnt.to_stata(INT / "patent_count_year_country.dta", write_index=False, version=118)
print(f"patent_count_year_country.dta: {len(cnt):,} rows")

loc_g = pid(pd.read_stata(INT / "patent_citations_grantyear.dta"), "patent_id")
lab_g = pid(pd.read_stata(BERT / "patent_sector_labels_grantyear.dta")[["patent_id", "sector"]], "patent_id")
lab_g["fullname_raw"] = lab_g["sector"].str.lower()
uc_g = loc_g.merge(lab_g[["patent_id", "fullname_raw"]], on="patent_id", how="inner")

def citing(uc, yearcol, cited, outcol):
    by = ["country_citing", yearcol, "country_cited", "fullname_raw"] if cited else ["country_citing", yearcol, "fullname_raw"]
    c = uc.groupby(by, observed=True).size().reset_index(name=outcol)
    if cited:
        c = c[c.country_cited == cited]
    c = c.rename(columns={"country_citing": "country_2digit"})
    c["year"] = pd.to_numeric(c[yearcol], errors="coerce")
    c = c[(c.year >= 2000) & (c.year <= 2019) & (c.country_2digit != "CN") & (c.country_2digit != "US")]
    keep = ["country_2digit", "year"] + (["country_cited"] if cited else []) + ["fullname_raw", outcol]
    c = c[keep]
    c["year"] = c["year"].astype(np.int32)
    return c

for cited, fn, col in [("CN", "citing_china_country_level", "count_citations_to_china"),
                        ("US", "citing_us_country_level", "count_citations_to_us"),
                        (None, "citing_world_level", "count_citations_to_world")]:
    out = citing(uc_g, "year_citing", cited, col)
    out.to_stata(INT / f"{fn}.dta", write_index=False, version=118)
    print(f"{fn}.dta: {len(out):,} rows")

loc_n = pid(pd.read_stata(INT / "patent_citations_new100k.dta"), "patent_id")
lab_n = pid(pd.read_stata(BERT / "patent_sector_labels_new100k.dta"), "patent_id").rename(columns={"sector": "fullname_raw"})
uc_n = loc_n.merge(lab_n[["patent_id", "fullname_raw"]], on="patent_id", how="inner")

for cited, fn, col in [("CN", "citing_china_country_level_new_100k", "count_citations_to_china"),
                       ("US", "citing_us_country_level_new_100k", "count_citations_to_us"),
                       (None, "citing_world_level_new_100k", "count_citations_to_world")]:
    out = citing(uc_n, "grant_year_citing", cited, col)
    out.to_stata(INT / f"{fn}.dta", write_index=False, version=118)
    print(f"{fn}.dta: {len(out):,} rows")

cw = pd.read_stata(BERT / "patent_sector_labels_grantyear.dta").rename(columns={"sector": "fullname_raw"})
cw["fullname_raw"] = cw["fullname_raw"].str.lower()
cw["country_2digit"] = cw["disambig_country"].astype(str)
cw["year"] = pd.to_numeric(cw["patent_date"].astype(str).str[:4], errors="coerce")
cw["patent_id"] = cw["patent_id"].astype(str)
wt = pd.read_stata(INT / "patent_citation_count.dta").rename(columns={"citation_patent_id": "patent_id"})
wt["patent_id"] = wt["patent_id"].astype(str)
cw = cw.merge(wt, on="patent_id", how="left")
cw["count_citations"] = cw["count_citations"].fillna(0) + 1
cwg = (cw.groupby(["year", "country_2digit", "fullname_raw"])["count_citations"].sum()
       .reset_index(name="count_predicted_patents_citation"))
cwg = cwg[(cwg.country_2digit != "") & (cwg.year >= 2000) & (cwg.year <= 2019)]
cwg = cwg.merge(XW, on="country_2digit", how="inner").drop(columns="country_2digit")
cwg["year"] = cwg["year"].astype(np.int32)
cwg.to_stata(INT / "patent_count_year_country_citation_weighted.dta", write_index=False, version=118)
print(f"patent_count_year_country_citation_weighted.dta: {len(cwg):,} rows")

ng = pd.read_stata(BERT / "patent_sector_labels_new_grantyear.dta").rename(columns={"sector": "fullname_raw"})
ng = ng[ng.groupby("fullname_raw")["patent_id"].transform("count") <= 99990].copy()
ng["fullname_raw"] = ng["fullname_raw"].str.lower()
ng["country_2digit"] = ng["disambig_country"].astype(str)
ng["year"] = pd.to_numeric(ng["patent_year"], errors="coerce")
ngg = ng.groupby(["year", "country_2digit", "fullname_raw"]).size().reset_index(name="count_predicted_patents")
ngg = ngg[(ngg.country_2digit != "") & (ngg.year >= 2000) & (ngg.year <= 2019)]
ngg = ngg.merge(XW, on="country_2digit", how="inner").drop(columns="country_2digit")
ngg = ngg[["fullname_raw", "year", "count_predicted_patents", "hqcountry"]]
ngg["year"] = ngg["year"].astype(np.int32)
ngg.to_stata(INT / "patent_count_year_country_new_grantyear.dta", write_index=False, version=118)
print(f"patent_count_year_country_new_grantyear.dta: {len(ngg):,} rows")

print("DONE 06b -> patent count/citing layers in intermediate_and_other_data/")
