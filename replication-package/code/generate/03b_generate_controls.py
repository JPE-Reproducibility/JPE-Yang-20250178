import os
import pandas as pd, numpy as np, pycountry
from pathlib import Path

ROOT = Path(os.environ.get("JPE_GENERATE_ROOT") or Path(__file__).resolve().parents[2])
TMP  = ROOT/"confidential-data-not-for-publication"/"Analysis"/"intermediate_and_other_data"
SUIT = ROOT/"data"/"raw"/"suitability_resource"
CTRL = ROOT/"data"/"raw"/"other_data_resource"

def two(a3):
    try: return pycountry.countries.get(alpha_3=a3).alpha_2
    except (AttributeError, KeyError, LookupError): return None

def gen_internet():
    W = pd.read_excel(SUIT/"WDI_full.xlsx", keep_default_na=False, na_values=[])
    W = W[W["Series Code"].isin(["IT.NET.USER.ZS", "IT.CEL.SETS.P2"])].copy()
    yc = [f"{y} [YR{y}]" for y in range(2000, 2020)]
    for c in yc:
        W[c] = pd.to_numeric(W[c].replace({"..": np.nan}), errors="coerce")
    W.loc[W["Country Name"] == "Kosovo", "country_2digit"] = "YY"
    W = W[W["country_2digit"].notna() & (W["country_2digit"] != "")]
    long = W.melt(id_vars=["country_2digit", "Series Code"], value_vars=yc, var_name="yr", value_name="v")
    long["year"] = long["yr"].str.extract(r"(\d{4})").astype(int)
    long["Series Code"] = long["Series Code"].map({"IT.CEL.SETS.P2": "PhoneUsrP100", "IT.NET.USER.ZS": "InternetPerct"})
    piv = long.pivot_table(index=["country_2digit", "year"], columns="Series Code", values="v", aggfunc="first")
    full = pd.MultiIndex.from_frame(long[["country_2digit", "year"]].drop_duplicates())
    out = piv.reindex(full).reset_index()
    out.columns.name = None
    out.to_stata(TMP/"internet_penetration.dta", write_index=False, version=114)
    return out

def gen_trade():
    df = pd.read_csv(CTRL/"Trade_Volume_Export_Import.csv", encoding="latin-1")
    df.columns = [c.strip().lower().replace(" ", "") for c in df.columns]
    df = df[df["period"] < 2020][["period","reporteriso","reporterdesc","flowdesc","partnerdesc","primaryvalue"]]
    p = df.pivot_table(index=["period","reporteriso","reporterdesc"], columns=["flowdesc","partnerdesc"],
                       values="primaryvalue", aggfunc="first")
    p.columns = ["value"+f+pt for f, pt in p.columns]
    p = p.reset_index()
    for v in ["valueExportChina","valueImportChina","valueExportWorld","valueImportWorld"]:
        p[v] = p[v]/1_000_000_000
    p["import_China_share"] = p["valueImportChina"]/p["valueImportWorld"]
    p["export_China_share"] = p["valueExportChina"]/p["valueExportWorld"]
    p["pre_period"] = p["period"] < 2014
    def bym(col, mask=None):
        s = p[col].where(mask) if mask is not None else p[col]
        return p.assign(_x=s).groupby("reporteriso")["_x"].transform("mean")
    p["mean_import_China_share_pre"] = bym("import_China_share", p.pre_period)
    p["mean_export_China_share_pre"] = bym("export_China_share", p.pre_period)
    p["mean_import_China_share_all"] = bym("import_China_share")
    p["mean_export_China_share_all"] = bym("export_China_share")
    keep = ["reporteriso","reporterdesc","mean_import_China_share_pre","mean_export_China_share_pre",
            "mean_import_China_share_all","mean_export_China_share_all"]
    q = p[keep].drop_duplicates()
    q = q[q["mean_import_China_share_pre"].notna()]
    q = q[q["reporterdesc"] != "Sudan (...2011)"]
    for a, b in [("im","import"),("ex","export")]:
        for w in ["pre","all"]:
            col = f"mean_{b}_China_share_{w}"
            med = q[col].median()
            q[f"median_{b}_China_share_{w}"] = med
            q[f"above_median_{a}_China_share_{w}"] = ((q[col] > med) | q[col].isna()).astype(int)
    q["country_2digit"] = q["reporteriso"].map(two)
    q = q[q["country_2digit"].notna()]
    q = q.drop(columns=["reporteriso"])
    q.to_stata(TMP/"trade_FDI_China_share.dta", write_index=False, version=114)
    return q

def gen_unpolity():
    pp = pd.read_stata(TMP/"populated_places.dta")[["ADM0_A3","ISO_A2"]].rename(columns={"ISO_A2":"country_2digit"}).drop_duplicates()
    cw = pd.read_stata(SUIT/"country_crosswalk.dta")
    m = pp.merge(cw, on="country_2digit", how="inner").rename(columns={"ADM0_A3":"country"})
    m = m[m["country_2digit"] != "RE"]
    up = pd.read_stata(CTRL/"un_polity_china.dta")
    r = m.merge(up, on="country", how="inner").drop(columns=["country","country_2digit"])
    r.to_stata(TMP/"un_polity_china_cleaned.dta", write_index=False, version=114)
    return r

if __name__ == "__main__":
    for name, fn in [("internet_penetration", gen_internet), ("trade_FDI_China_share", gen_trade), ("un_polity_china_cleaned", gen_unpolity)]:
        out = fn()
        print(f"OK {name}.dta  shape={out.shape}  cols={list(out.columns)[:8]}", flush=True)
