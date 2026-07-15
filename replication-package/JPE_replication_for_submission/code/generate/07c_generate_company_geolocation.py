#!/usr/bin/env python3
import os
import re
from pathlib import Path

import numpy as np
import pandas as pd
from unidecode import unidecode

ROOT = Path(os.environ.get("JPE_GENERATE_ROOT") or Path(__file__).resolve().parents[2])
RAW  = ROOT / "data" / "raw"
CONFRAW = ROOT / "confidential-data-not-for-publication" / "Raw"
GEO  = RAW / "geocoding_resource"
CORE = ROOT / "confidential-data-not-for-publication" / "Analysis"
INT  = CORE / "intermediate_and_other_data"
INT.mkdir(parents=True, exist_ok=True)

def alnum(s):
    return re.sub(r"[^a-z0-9]", "", str(s).lower())

def alpha(s):
    return re.sub(r"[^a-z]", "", str(s).lower())

cw_c = pd.read_excel(GEO / "crosswalk.xlsx", sheet_name="country")
cw_c = cw_c[cw_c["country_fullname"].notna() & (cw_c["country_fullname"] != "")].copy()
cw_c["country_simplename"] = cw_c["country_fullname"].apply(
    lambda x: (re.match(r"^(.+?)[\(,].*", str(x)) or [None, str(x)])[1]
)

HARD = {"KR": "South Korea", "TR": "Turkey", "GB": "United Kingdom", "US": "United States",
        "CG": "Republic of Congo", "VG": "British Virgin Islands", "CZ": "Czech Republic",
        "MO": "Macau", "RU": "Russia", "CW": "Curacao",
        "BQ": "Bonaire, Sint Eustatius and Saba", "BN": "Brunei", "CV": "Cape Verde",
        "TL": "East Timor", "CI": "Ivory Coast", "LA": "Laos", "MK": "Macedonia",
        "PF": "Polynesia", "RE": "Reunion", "VC": "Saint Vincent", "SZ": "Swaziland",
        "SY": "Syria", "GM": "The Gambia", "TC": "Turks and Caicos"}
for k, v in HARD.items():
    cw_c.loc[cw_c["country_2digit"] == k, "country_simplename"] = v
cw_c["country0"] = cw_c["country_simplename"].apply(alpha)
country_dict = cw_c[["country0", "country_2digit"]].drop_duplicates("country0")

cw_us = pd.read_excel(GEO / "crosswalk.xlsx", sheet_name="US")
cw_us["state0"] = cw_us["state"].apply(alpha)
state_dict = cw_us[["state0", "state_2digit"]].drop_duplicates("state0")

pb = pd.read_stata(CONFRAW / "pitchbook" / "pbcompanies.dta",
                   columns=["companyid", "hqcity", "hqstate_province", "hqcountry"])
pb = pb[(pb.hqcountry != "") & (pb.hqcity != "")].copy()
pb["country0"] = pb["hqcountry"].apply(alpha)
pb.loc[pb.country0 == "westbank", "country0"] = "palestine"
pb.loc[pb.country0 == "kosovo", "country0"] = "serbia"
pb.loc[pb.hqstate_province == "Virgin Islands", "hqstate_province"] = "US Virgin Islands"
pb["state0"] = np.where(pb.hqcountry == "United States", pb.hqstate_province.apply(alpha), "")
pb = pb.merge(country_dict, on="country0", how="left")
pb = pb.merge(state_dict, on="state0", how="left")
pb["country_2digit"] = pb["country_2digit"].fillna("").astype(str)
pb["state_2digit"] = pb["state_2digit"].fillna("").astype(str)
pb["hqcity_ascii"] = pb["hqcity"].astype(str).apply(unidecode)
pb["city0"] = pb["hqcity_ascii"].apply(alnum)
pb["location_clean"] = pb["country_2digit"].str.lower() + pb["state_2digit"].str.lower() + pb["city0"]
loc_id = pb

sm = pd.read_csv(GEO / "simplemaps.csv")
sm["state0"] = np.where(sm.iso2 == "US", sm["admin_name"].apply(alpha), "")
sm = sm.merge(state_dict, on="state0", how="left")
sm["state_2digit"] = sm["state_2digit"].fillna("").astype(str)
sm["city_ascii"] = sm["city_ascii"].astype(str)
sm.loc[sm.city_ascii == "Tel Aviv-Yafo", "city_ascii"] = "Tel Aviv"
sm["location_clean"] = (sm["iso2"].astype(str).str.lower()
                        + sm["state_2digit"].str.lower()
                        + sm["city_ascii"].str.lower()).apply(lambda s: re.sub(r"[^a-z0-9]", "", s))
sm = sm[~sm.location_clean.duplicated(keep=False)]
simplemaps = sm[["location_clean", "lat", "lng"]].copy()
simplemaps[["lat", "lng"]] = simplemaps[["lat", "lng"]].astype(np.float32)

ods = pd.read_csv(GEO / "opendatasoft.csv", sep=";", low_memory=False).rename(columns={
    "Geoname ID": "geonameid", "ASCII Name": "asciiname", "Country Code": "countrycode",
    "Admin1 Code": "admin1code", "Population": "population", "Coordinates": "coordinates"})
ods = ods[ods.population != 0].copy()
ods["country0"] = ods.countrycode.astype(str).str.lower()
ods["state0"] = np.where(ods.countrycode == "US", ods.admin1code.astype(str).str.lower(), "")
ods["city0"] = ods.asciiname.astype(str).apply(alnum)
ods["location_clean"] = ods.country0 + ods.state0 + ods.city0
ods = ods[~ods.location_clean.duplicated(keep=False)]
coord = ods.coordinates.astype(str).str.split(",", expand=True)
ods["lat"] = pd.to_numeric(coord[0], errors="coerce")
ods["lng"] = pd.to_numeric(coord[1], errors="coerce")
opendatasoft = ods[["location_clean", "lat", "lng"]].copy()

pld = pd.read_stata(INT / "patent_location_dict.dta",
                    columns=["location_clean", "latitude", "longitude"]).rename(
    columns={"latitude": "lat", "longitude": "lng"})
pld = pld[~pld.location_clean.duplicated(keep=False)]

av2c = set(pd.read_stata(CORE / "analysis_v2.dta", columns=["companyid"]).companyid.unique())
uni = loc_id[loc_id.companyid.isin(av2c)].copy()
uni = uni[~((uni.hqcountry == "") | (uni.hqcity == "")
            | ((uni.hqstate_province == "") & (uni.hqcountry == "United States")))]
uni = uni.drop_duplicates("companyid")[["companyid", "location_clean", "hqcountry"]]

def wave(df, gaz):
    m = df.merge(gaz, on="location_clean", how="left", indicator=True)
    hit = m[m._merge == "both"][["companyid", "location_clean", "lat", "lng", "hqcountry"]]
    miss = m[m._merge == "left_only"][["companyid", "location_clean", "hqcountry"]]
    return hit.copy(), miss.copy()

m1, nm1 = wave(uni, simplemaps)
m2, nm2 = wave(nm1, opendatasoft)
m3, nm3 = wave(nm2, pld)

matched = pd.concat([m1, m2, m3], ignore_index=True).rename(
    columns={"lat": "latitude", "lng": "longitude"})
matched = matched[["companyid", "location_clean", "hqcountry", "latitude", "longitude"]]
matched["latitude"] = matched["latitude"].astype(np.float64)
matched["longitude"] = matched["longitude"].astype(np.float64)

out = INT / "pbcompany_location_matched.dta"
matched.to_stata(out, write_index=False, version=114)
print(f"wrote {out}  ({len(matched):,} rows: match1={len(m1):,} match2={len(m2):,} "
      f"match3={len(m3):,}; unmatched={len(nm3):,})")
