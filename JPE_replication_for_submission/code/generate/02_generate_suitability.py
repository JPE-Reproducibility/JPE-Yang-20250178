#!/usr/bin/env python3
from pathlib import Path
import os
import random
import numpy as np, pandas as pd, pycountry

ROOT = Path(os.environ.get("JPE_GENERATE_ROOT") or Path(__file__).resolve().parents[2])
RAW  = ROOT / "data" / "raw" / "suitability_resource"
OUT  = ROOT / "confidential-data-not-for-publication" / "Analysis" / "intermediate_and_other_data"
AV2  = ROOT / "confidential-data-not-for-publication" / "Analysis" / "analysis_v2.dta"
CT, IT = 0.25, 0.20
YEARS = [f"{y} [YR{y}]" for y in range(2003, 2014)]

def two(a3):
    try:
        return pycountry.countries.get(alpha_3=a3).alpha_2
    except (AttributeError, KeyError, LookupError):
        return None

def process_WDI_data(WDI):
    W = WDI.copy()
    W.replace("..", np.nan, inplace=True)
    W.dropna(subset=["Country Code"], inplace=True)
    W["country_2digit"] = W["Country Code"].apply(two)
    W.loc[W["Country Name"] == "Kosovo", "country_2digit"] = "YY"
    return W.dropna(subset=["country_2digit"])

def process_indicator_assignment(path):
    MtV = pd.read_excel(path).fillna(0)
    valc = MtV.columns.difference(["Series Name", "Series Code"])
    MtV["t"] = MtV[valc].sum(axis=1)
    MtV = MtV[MtV["t"] > 0].drop(columns="t").drop_duplicates(subset=["Series Code"])
    return MtV

def indicator_reshaping(W, MtV):
    W = W.merge(MtV[["Series Code"]], on="Series Code", how="inner")
    W[YEARS] = W[YEARS].astype(float)
    W["avg"] = W[YEARS].mean(axis=1, skipna=True)
    W = W[["country_2digit", "Series Code", "avg"]].drop_duplicates(subset=["Series Code", "country_2digit"])
    return W.pivot(index="country_2digit", columns="Series Code", values="avg").reset_index()

def filtering(ind, target, ct, it):
    ind = ind[ind.isna().mean(axis=1) <= ct]
    ind = ind.loc[:, ind.isna().mean(axis=0) <= it]
    tmask = ind[ind.country_2digit == target].isna().any()
    ind = ind.loc[:, ~tmask]
    return ind, list(ind.columns.difference(["country_2digit"]))

def normalization(ind, cols):
    ind = ind.copy()
    ind[cols] = ind[cols].apply(lambda x: x.fillna(x.mean()))
    mu = ind[cols].mean()
    sd = ind[cols].std(ddof=0).replace(0, 1.0)
    ind[cols] = (ind[cols] - mu) / sd
    return ind

def process_country(scaled, ind_list, MtV, target):
    MtV_used = MtV[MtV["Series Code"].isin(ind_list)]
    P = scaled.copy()
    tgt = P[P.country_2digit == target]
    for col in P.columns.difference(["country_2digit"]):
        P[col] = np.sqrt((P[col] - tgt[col].iloc[0]) ** 2)
    P = P[P.country_2digit != target]
    out = pd.DataFrame(P["country_2digit"])
    for mm in MtV_used.columns.difference(["Series Name", "Series Code"]):
        vl = MtV_used[MtV_used[mm] == 1]["Series Code"].tolist()
        out[mm + " SuitSc"] = P[vl].mean(axis=1).values
    return out

def generate_wdi_gdp_pc_matched(WDI_raw, country_used):
    rename = {"Country Name": "CountryName", "Country Code": "CountryCode",
              "Series Name": "SeriesName", "Series Code": "SeriesCode"}
    rename.update({f"{y} [YR{y}]": f"YR{y}" for y in range(2000, 2014)})
    g = WDI_raw[WDI_raw["Series Name"] == "GDP per capita (constant 2015 US$)"].rename(columns=rename).copy()

    g = g.drop(columns=[c for c in g.columns if "[YR" in str(c)])
    yr = [f"YR{y}" for y in range(2000, 2014)]
    g[yr] = g[yr].replace("..", np.nan).astype(float)

    g["mean_gdp_pc"] = g[[f"YR{y}" for y in range(2003, 2014)]].mean(axis=1, skipna=True).astype(np.float32)
    g["country_2digit"] = g["CountryCode"].apply(two).astype(str)
    g.loc[g["CountryCode"] == "NAM", "country_2digit"] = "NA"
    g = g.dropna(subset=["country_2digit"])
    cu = country_used.copy()
    cu["country_2digit"] = cu["country_2digit"].astype(str)
    out = g.merge(cu, on="country_2digit", how="inner")
    OUT.mkdir(parents=True, exist_ok=True)
    out.to_stata(OUT / "wdi_gdp_pc_matched.dta", version=114)
    print(f"wrote wdi_gdp_pc_matched.dta -> shape {out.shape}")

def generate_all_country_marketmap(WDI, cu):
    MtV  = process_indicator_assignment(RAW / "indicators_WDI_MtV_corrected.xlsx")
    resh = indicator_reshaping(WDI, MtV)
    cw   = pd.read_stata(RAW / "country_crosswalk.dta")
    name_of = dict(zip(cw["country_2digit"], cw["hqcountry"]))

    parts = []
    for target in sorted(resh["country_2digit"].unique()):
        try:
            filt, cols = filtering(resh, target, CT, IT)
            if (filt["country_2digit"] == target).sum() == 0 or not cols:
                continue
            scaled = normalization(filt, cols)
            score  = process_country(scaled, cols, MtV, target)
            score["relative_to"] = target
            parts.append(score)
        except Exception:
            continue
    allc = pd.concat(parts, ignore_index=True).merge(cu, on="country_2digit", how="inner")

    OUT.mkdir(parents=True, exist_ok=True)
    allc.to_stata(OUT / "suitability_score_all_countries_corrected.dta", write_index=False, version=114)
    print(f"wrote suitability_score_all_countries_corrected.dta -> shape {allc.shape}")

    suit_cols = [c for c in allc.columns if c.endswith(" SuitSc")]
    long = allc.melt(id_vars=["hqcountry", "relative_to"], value_vars=suit_cols,
                     var_name="marketmap", value_name="s_s_2")
    long["marketmap"] = long["marketmap"].str.replace(" SuitSc", "", regex=False)
    long["ref"] = long["relative_to"].map(name_of)
    long = long.dropna(subset=["ref"])
    long = long[long["hqcountry"] != ""]
    long["ref"] = long["ref"].str.replace("[^A-Za-z0-9]", "", regex=True).str[:10]
    wide = (long.pivot_table(index=["hqcountry", "marketmap"], columns="ref", values="s_s_2", aggfunc="first")
                .reset_index())
    wide.columns.name = None
    wide = wide.rename(columns={c: f"s_s_2_{c}" for c in wide.columns if c not in ("hqcountry", "marketmap")})
    wide = wide.sort_values(["marketmap", "hqcountry"]).reset_index(drop=True)
    OUT.mkdir(parents=True, exist_ok=True)
    wide.to_stata(OUT / "suitability_all_country_marketmap_corrected.dta", write_index=False, version=114)
    print(f"wrote suitability_all_country_marketmap_corrected.dta -> shape {wide.shape}")

ZPOOL_COUNTRIES = [
    "AE", "AF", "AL", "AM", "AO", "AR", "AS", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BJ",
    "BM", "BN", "BO", "BR", "BS", "BW", "BY", "BZ", "CA", "CD", "CH", "CI", "CL", "CM", "CN", "CO", "CR", "CV",
    "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "ET", "FI", "FR", "GB", "GD",
    "GE", "GH", "GI", "GL", "GR", "GT", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IQ", "IR", "IS",
    "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KN", "KR", "KW", "KY", "KZ", "LB", "LC", "LI", "LK", "LS", "LT",
    "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MM", "MN", "MT", "MU", "MW", "MX", "MY", "MZ",
    "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NZ", "OM", "PA", "PE", "PF", "PH", "PK", "PL", "PS", "PT", "PY",
    "QA", "RO", "RS", "RU", "RW", "SA", "SC", "SD", "SE", "SG", "SI", "SK", "SL", "SN", "SV", "SY", "SZ", "TD",
    "TH", "TL", "TN", "TR", "TT", "TZ", "UA", "UG", "US", "UY", "VC", "VE", "VG", "VN", "YY", "ZA", "ZM", "ZW",
]

NEGATIVE_INDICATORS = [
    "EN.ATM.PM25.MC.M3", "IC.REG.DURS", "IC.REG.PROC", "SH.DYN.MORT", "SH.DYN.NMRT",
    "SH.SGR.IRSK.ZS", "SH.TBS.INCD", "SH.STA.MMRT", "SH.STA.TRAF.P5",
    "SL.UEM.TOTL.FE.ZS", "SL.UEM.TOTL.ZS", "SN.ITK.DEFC.ZS", "SP.DYN.IMRT.IN",
]

def generate_combined_z(WDI, MtV):
    market_map_names = ["AgTech", "AI ML", "Blockchain",
                        "Carbon and Emissions Tech", "DevOps", "EdTech", "Enterprise Health",
                        "Fintech", "FoodTech", "InfoSec", "Insurtech", "IoT", "MobilityTech",
                        "Retail HealthTech", "Supply Chain Tech"]
    resh = indicator_reshaping(WDI, MtV)
    _, cn_cols = filtering(resh, "CN", CT, IT)
    MtV = MtV[MtV["Series Code"].isin(cn_cols)]

    W = WDI[WDI["country_2digit"].isin(ZPOOL_COUNTRIES)]
    year_cols = [c for c in W.columns if "[YR" in str(c)]
    long = W.melt(id_vars=["Country Code", "Series Code", "Country Name", "Series Name", "country_2digit"],
                  value_vars=year_cols, var_name="year", value_name="value")
    long["year"] = long["year"].str[:4]
    long["value"] = long["value"].astype(float)
    long.loc[long["Series Code"].isin(NEGATIVE_INDICATORS), "value"] *= -1

    combined = pd.DataFrame()
    for mm in market_map_names:
        series = MtV[MtV[mm] == 1]["Series Code"].tolist()
        wide = (long[long["Series Code"].isin(series)]
                .pivot(index=["country_2digit", "year"], columns="Series Code", values="value")
                .reset_index())
        zc = wide.columns.difference(["country_2digit", "year"])

        wide[zc] = wide[zc].apply(lambda x: (x - x.dropna().mean()) / x.dropna().std(ddof=0))
        if combined.empty:
            combined = wide[["country_2digit", "year"]].copy()
        combined[f"Z_scores_{mm}"] = wide[zc].mean(axis=1, skipna=True)
    combined["year"] = combined["year"].astype(int)
    OUT.mkdir(parents=True, exist_ok=True)
    import warnings as _w
    with _w.catch_warnings():
        _w.simplefilter("ignore")
        combined.to_stata(OUT / "Combined_Z_score_results_allyears.dta", version=114)
    print(f"wrote Combined_Z_score_results_allyears.dta -> shape {combined.shape}")

def generate_gdp_pp_2015usd(cw):
    yrs = list(range(2000, 2020))
    g = pd.read_excel(RAW / "WDI_full.xlsx")
    g = g[g["Series Code"] == "NY.GDP.PCAP.KD"].rename(columns={f"{y} [YR{y}]": y for y in yrs}).copy()
    for y in yrs:
        g[y] = pd.to_numeric(g[y].replace("..", np.nan), errors="coerce")
    g.loc[g["Country Name"] == "Kosovo", "country_2digit"] = "YY"
    g.loc[g["Country Code"] == "NAM", "country_2digit"] = "NA"
    g["country_2digit"] = g["country_2digit"].astype(str)
    g = g[g["country_2digit"].str.strip().ne("") & g["country_2digit"].ne("nan")].copy()

    pre, post = [y for y in yrs if y <= 2013], [y for y in yrs if y > 2013]

    mpre  = g[pre].mean(axis=1, skipna=True)
    mpost = g[post].mean(axis=1, skipna=True)
    mall  = g[yrs].mean(axis=1, skipna=True)
    m2013 = g[2013].astype(float)

    def above(s, t): return ((s > t) | s.isna()).astype(np.float32)
    g["gdp_pp_preperiod_above_china"]  = above(mpre,  4269.235)
    g["gdp_pp_postperiod_above_china"] = above(mpost, 8815.618)
    g["gdp_pp_above_china"]            = above(mall,  5633.15)
    g["gdp_pp_in_2013_above_china"]    = above(m2013, 7056.423)

    g["gdp_pp_2015usd_mean_preperiod"]  = mpre.astype(np.float32)
    g["gdp_pp_2015usd_mean_postperiod"] = mpost.astype(np.float32)
    g["gdp_pp_2015usd_mean"]            = mall.astype(np.float32)
    g["gdp_pp_2015usd_in_2013"]         = m2013.astype(np.float32)

    xs = np.sort(g["gdp_pp_2015usd_in_2013"].dropna().values); n = len(xs); cps = []
    for p in range(10, 100, 10):
        r = p * n / 100.0
        cps.append((xs[int(round(r)) - 1] + xs[int(round(r))]) / 2 if abs(r - round(r)) < 1e-9
                   else xs[int(np.ceil(r)) - 1])
    dec = (np.searchsorted(np.array(cps), g["gdp_pp_2015usd_in_2013"].values, side="left") + 1).astype(float)
    dec[g["gdp_pp_2015usd_in_2013"].isna().values] = np.nan
    g["gdp_pp_2015usd_in_2013_decile"] = dec

    g = g.merge(cw, on="country_2digit", how="left")
    g["hqcountry"] = g["hqcountry"].where(g["hqcountry"].notna() & g["hqcountry"].ne(""), g["Country Name"])
    cols = ["gdp_pp_2015usd_mean_preperiod", "gdp_pp_2015usd_mean_postperiod", "gdp_pp_2015usd_mean",
            "gdp_pp_2015usd_in_2013", "gdp_pp_preperiod_above_china", "gdp_pp_postperiod_above_china",
            "gdp_pp_above_china", "gdp_pp_in_2013_above_china", "gdp_pp_2015usd_in_2013_decile", "hqcountry"]
    g[cols].to_stata(OUT / "gdp_pp_2015usd.dta", write_index=False, version=114)
    print(f"wrote gdp_pp_2015usd.dta -> shape {g[cols].shape}")

def generate_indicator_dropped(WDI, cu):
    MtV  = process_indicator_assignment(RAW / "indicators_WDI_MtV_corrected.xlsx")

    pool = MtV["Series Code"].tolist()
    OUT.mkdir(parents=True, exist_ok=True)
    for N in (1, 2, 3, 4):
        parts = []
        for seed in range(500):
            random.seed(seed)
            dropped = random.sample(pool, N)
            temp    = MtV[~MtV["Series Code"].isin(dropped)]
            resh    = indicator_reshaping(WDI, temp)
            filt, cols = filtering(resh, "CN", 0.25, 0.20)
            scaled  = normalization(filt, cols)
            score   = process_country(scaled, cols, temp, "CN")
            score["relative_to"] = "CN"
            score["seed"] = seed
            parts.append(score)
        stack = pd.concat(parts, ignore_index=True).merge(cu, on="country_2digit", how="inner")
        stack.to_stata(OUT / f"china_suitability_score_{N}_indicator_dropped_corrected.dta",
                       write_index=False, version=114)
        print(f"wrote china_suitability_score_{N}_indicator_dropped_corrected.dta -> shape {stack.shape}")

def main():
    WDI_raw = pd.read_excel(RAW / "WDI_full.xlsx")
    WDI = process_WDI_data(WDI_raw)

    a = pd.read_stata(AV2, columns=["hqcountry"]).drop_duplicates(subset=["hqcountry"])
    cw = pd.read_stata(RAW / "country_crosswalk.dta")
    cu = a.merge(cw, on="hqcountry", how="left")
    cu.loc[cu.hqcountry == "Kosovo", "country_2digit"] = "YY"

    generate_wdi_gdp_pc_matched(WDI_raw, cu)
    generate_gdp_pp_2015usd(cw)
    generate_combined_z(WDI, process_indicator_assignment(RAW / "indicators_WDI_MtV_corrected.xlsx"))

    OUT.mkdir(parents=True, exist_ok=True)

    VARIANTS = [
        ("corrected",                 "indicators_WDI_MtV_corrected.xlsx",                0.25, 0.20, [("CN", "china"), ("US", "us")]),
        ("gpt_assigned",              "indicators_WDI_MtV_gpt_assigned.xlsx",             0.25, 0.20, [("CN", "china")]),
        ("from_existing_no_trade2",   "indicators_WDI_MtV_from_existing_no_trade2.xlsx",  0.25, 0.20, [("CN", "china"), ("US", "us")]),
        ("from_scratch_allassigned",  "indicators_WDI_MtV_from_scratch_allassigned.xlsx", 0.35, 0.20, [("CN", "china"), ("US", "us")]),
        ("corrected_drop20country",   "indicators_WDI_MtV_corrected.xlsx",                0.20, 0.20, [("CN", "china"), ("US", "us")]),
        ("corrected_drop30country",   "indicators_WDI_MtV_corrected.xlsx",                0.30, 0.20, [("CN", "china"), ("US", "us")]),
        ("corrected_drop15indicator", "indicators_WDI_MtV_corrected.xlsx",                0.25, 0.15, [("CN", "china"), ("US", "us")]),
        ("corrected_drop25indicator", "indicators_WDI_MtV_corrected.xlsx",                0.25, 0.25, [("CN", "china"), ("US", "us")]),
    ]
    for suffix, mtvfile, ct, it, targets in VARIANTS:
        MtV = process_indicator_assignment(RAW / mtvfile)
        resh = indicator_reshaping(WDI, MtV)
        for target, prefix in targets:
            filt, cols = filtering(resh, target, ct, it)
            scaled = normalization(filt, cols)
            score = process_country(scaled, cols, MtV, target)
            score["relative_to"] = target
            final = (score.merge(cu, on="country_2digit", how="inner")
                          .sort_values("country_2digit").reset_index(drop=True))

            final.to_stata(OUT / f"{prefix}_suitability_score_all_{suffix}.dta",
                           write_index=False, version=114)
            print(f"wrote {prefix}_suitability_score_all_{suffix}.dta -> shape {final.shape}")

    generate_indicator_dropped(WDI, cu)
    generate_all_country_marketmap(WDI, cu)

if __name__ == "__main__":
    main()
