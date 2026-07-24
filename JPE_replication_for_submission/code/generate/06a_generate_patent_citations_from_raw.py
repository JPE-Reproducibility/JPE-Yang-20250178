#!/usr/bin/env python3
import os
from pathlib import Path
import numpy as np
import pandas as pd

ROOT = Path(os.environ.get("JPE_GENERATE_ROOT") or Path(__file__).resolve().parents[2])
RAW  = ROOT / "data" / "raw"
PV   = RAW / "patent_resource"
BERT = ROOT / "confidential-data-not-for-publication" / "Raw" / "BERT_prediction_resource"
INT  = ROOT / "confidential-data-not-for-publication" / "Analysis" / "intermediate_and_other_data"
INT.mkdir(parents=True, exist_ok=True)
NA = dict(keep_default_na=False, na_values=[])

def build_meta():
    pat = pd.read_csv(PV / "g_patent.tsv", sep="\t", usecols=["patent_id", "patent_type", "patent_date"], dtype=str, **NA)
    pat = pat[pat.patent_type == "utility"]
    pat["year"] = pat["patent_date"].str[:4]
    asg = pd.read_csv(PV / "g_assignee_disambiguated.tsv", sep="\t",
                      usecols=["patent_id", "assignee_sequence", "location_id"], dtype=str, **NA)
    asg = asg[asg.assignee_sequence == "0"][["patent_id", "location_id"]]
    loc = pd.read_csv(PV / "g_location_disambiguated.tsv", sep="\t",
                      usecols=["location_id", "disambig_country"], dtype=str, **NA)
    meta = (pat.merge(asg, on="patent_id", how="inner")
               .merge(loc, on="location_id", how="inner")
               .rename(columns={"disambig_country": "country"})
               .drop_duplicates("patent_id").set_index("patent_id"))
    return meta["country"], meta["year"], meta["patent_date"]

country, year, date = build_meta()
print(f"patent metadata: {len(country):,} located utility patents")

pos_g = set(pd.read_stata(BERT / "patent_sector_labels_grantyear.dta").patent_id.astype(str))
pos_n = set(pd.read_stata(BERT / "patent_sector_labels_new100k.dta").patent_id.astype(str))

appl = pd.read_csv(PV / "g_application.tsv", sep="\t", usecols=["patent_id", "filing_date"], dtype=str, **NA)
filing_year = appl.assign(fy=appl.filing_date.str[:4]).drop_duplicates("patent_id").set_index("patent_id")["fy"]

loc_g_parts, loc_n_parts = [], []
cited_counts = pd.Series(dtype="int64")
numcite_counts = pd.Series(dtype="int64")
for ch in pd.read_csv(PV / "g_us_patent_citation.tsv", sep="\t",
                      usecols=["patent_id", "citation_patent_id"], dtype=str, chunksize=8_000_000, **NA):
    dig = ch.citation_patent_id.str.replace(" ", "", regex=False)
    numcite_counts = numcite_counts.add(dig[dig.str.isdigit()].value_counts(), fill_value=0)
    ch["cc"] = ch.patent_id.map(country)
    ch["yc"] = ch.patent_id.map(year)
    ch["dc"] = ch.patent_id.map(date)
    ch["cd"] = ch.citation_patent_id.map(country)
    ch["yd"] = ch.citation_patent_id.map(year)
    ch["dd"] = ch.citation_patent_id.map(date)
    ch = ch[ch.cc.notna() & ch.cd.notna()]
    cited_counts = cited_counts.add(ch.citation_patent_id.value_counts(), fill_value=0)
    loc_g_parts.append(ch[ch.patent_id.isin(pos_g)])
    loc_n_parts.append(ch[ch.patent_id.isin(pos_n)])

g = pd.concat(loc_g_parts, ignore_index=True)
g = g[["patent_id", "citation_patent_id", "dc", "cc", "yc", "dd", "cd", "yd"]]
g.columns = ["patent_id", "citation_patent_id", "patent_date_citing", "country_citing", "year_citing",
             "patent_date_cited", "country_cited", "year_cited"]
g.to_stata(INT / "patent_citations_grantyear.dta", write_index=False, version=118)
print(f"patent_citations_grantyear.dta: {len(g):,} rows")

n = pd.concat(loc_n_parts, ignore_index=True)
n["filing_year_citing"] = n.patent_id.map(filing_year)
n = n[["patent_id", "citation_patent_id", "cc", "yc", "filing_year_citing", "cd"]]
n.columns = ["patent_id", "citation_patent_id", "country_citing", "grant_year_citing", "filing_year_citing", "country_cited"]
n.to_stata(INT / "patent_citations_new100k.dta", write_index=False, version=118)
print(f"patent_citations_new100k.dta: {len(n):,} rows")

cc = cited_counts.astype("int64").rename("count_citations").reset_index()
cc.columns = ["patent_id", "count_citations"]
cc.to_stata(INT / "patent_citation_count.dta", write_index=False, version=118)
print(f"patent_citation_count.dta: {len(cc):,} cited patents")

ncdf = numcite_counts.rename("num_citations").reset_index()
ncdf.columns = ["patent_id", "num_citations"]
ncdf["patent_id"] = pd.to_numeric(ncdf["patent_id"]).astype("int64")
ncdf = ncdf.groupby("patent_id", as_index=False, sort=True)["num_citations"].sum()
ncdf["num_citations"] = ncdf["num_citations"].astype("int64")
ncdf.to_csv(INT / "citations_count.csv", index=False)
print(f"citations_count.csv: {len(ncdf):,} cited patents (num_citations)")

print("DONE 06a -> located citations + citation_count + citations_count in intermediate_and_other_data/")
