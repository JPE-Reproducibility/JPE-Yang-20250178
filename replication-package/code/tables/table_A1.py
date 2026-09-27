from __future__ import annotations

import os
from pathlib import Path

import openpyxl
import pandas as pd

os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ROOT = Path(__file__).resolve().parents[2]
GIM = ROOT / "data" / "raw" / "other_data_resource"
GIM_CONF = ROOT / "confidential-data-not-for-publication" / "Raw" / "other_data_resource"
PUBLISHED = GIM / "tableA1_published_values.csv"
COUNTRY_DATASET = GIM_CONF / "CountryDataset.2024019.supplemented.xlsx"
VCPC_FILE = GIM_CONF / "tableA1_VCpc.xlsx"
OUT = ROOT / "output" / "tables" / "tableA1.csv"
AUDIT = ROOT / "output" / "intermediate" / "tableA1_source_audit.csv"
OUT.parent.mkdir(parents=True, exist_ok=True)
AUDIT.parent.mkdir(parents=True, exist_ok=True)

COUNTRY_MAP = {
    "South Korea": "Korea, Rep.",
    "Russia": "Russian Federation",
    "Egypt": "Egypt, Arab Rep.",
}

def _num(value):
    try:
        if value in ("", None, "N/A", "NA"):
            return None
        if pd.isna(value):
            return None
        return float(value)
    except (TypeError, ValueError):
        return None

def _round_or_blank(value, digits: int):
    if value is None:
        return None
    return round(value, digits)

def _round_or_fallback(value, digits: int, fallback):
    rounded = _round_or_blank(value, digits)
    if rounded is not None:
        return rounded
    return fallback if _num(fallback) is not None else None

def _source_label(value, fallback) -> str:
    if value is not None:
        return "CountryDataset.2024019.supplemented"
    if _num(fallback) is not None:
        return "published fallback: CountryDataset.2024019.supplemented missing"
    return "missing"

def _require(path: Path) -> None:
    if not path.exists():
        raise FileNotFoundError(f"Missing Table A1 input: {path}")
    if path.stat().st_size == 0:
        raise ValueError(f"Table A1 input is empty: {path}")

def load_countrydataset() -> pd.DataFrame:
    _require(COUNTRY_DATASET)
    raw = pd.read_excel(COUNTRY_DATASET, sheet_name="CountryTable", header=0, engine="openpyxl")
    if "CountryName" not in raw.columns:
        raise ValueError("CountryDataset CountryTable is missing CountryName.")

    total_rows = raw.index[raw["CountryName"].eq("Total")].tolist()
    if total_rows:
        raw = raw.loc[: total_rows[0] - 1].copy()
    raw = raw.dropna(subset=["CountryName"]).copy()
    raw["CountryName"] = raw["CountryName"].astype(str).str.strip()
    return raw

def _country_row(country_table: pd.DataFrame, country: str) -> pd.Series:
    country_name = COUNTRY_MAP.get(country, country)
    matches = country_table[country_table["CountryName"].eq(country_name)]
    if len(matches) != 1:
        raise ValueError(f"Expected one CountryDataset row for {country} ({country_name}), found {len(matches)}.")
    return matches.iloc[0]

def _share(country_table: pd.DataFrame, row: pd.Series, prefix: str, year: int) -> float | None:
    col = f"{prefix}{year}"
    if col not in country_table.columns:
        return None
    numerator = _num(row[col])
    denominator = pd.to_numeric(country_table[col], errors="coerce").sum(min_count=1)
    if numerator is None or pd.isna(denominator) or denominator == 0:
        return None
    return 100.0 * numerator / float(denominator)

def load_vcpc() -> dict[str, float]:
    wb = openpyxl.load_workbook(VCPC_FILE, data_only=True, read_only=True)
    out = {}
    for row in wb.worksheets[0].iter_rows(min_row=2, values_only=True):
        country = row[0]
        value = row[7] if len(row) > 7 else None
        if country is not None and _num(value) is not None:
            out[str(country).strip()] = float(value)
    wb.close()
    return out

pub = pd.read_csv(PUBLISHED, keep_default_na=False)
country_table = load_countrydataset()
vcpc = load_vcpc()

rows = []
audit_rows = []
for _, r in pub.iterrows():
    country = r["country"]
    source_country = COUNTRY_MAP.get(country, country)
    year = int(_num(r["emergence_year"]))
    country_row = _country_row(country_table, country)
    vcpc_value = vcpc.get(country) if _num(r["vc_pc_2011usd"]) is not None else None

    gdp_raw = _num(country_row[f"GDPpc{year}"])
    pct_vc_raw = _share(country_table, country_row, "VC", year)
    pct_pubs_raw = _share(country_table, country_row, "ScientificPublications", year)
    pct_rd_raw = _share(country_table, country_row, "imprd", year)
    pct_patents_raw = _share(country_table, country_row, "Patents", year)

    gdp = _round_or_fallback(gdp_raw, 0, r["gdp_pc_2011usd"])
    vcpc_out = _round_or_blank(vcpc_value, 2)
    pct_vc = _round_or_fallback(pct_vc_raw, 2, r["pct_world_vc"])
    pct_pubs = _round_or_fallback(pct_pubs_raw, 2, r["pct_world_pubs"])
    pct_rd = _round_or_fallback(pct_rd_raw, 2, r["pct_world_rd"])
    pct_patents = _round_or_fallback(pct_patents_raw, 2, r["pct_us_patents"])

    rows.append(
        [
            country,
            year,
            int(gdp) if _num(gdp) is not None else gdp,
            vcpc_out,
            pct_vc,
            pct_pubs,
            pct_rd,
            pct_patents,
        ]
    )
    audit_rows.append(
        {
            "country": country,
            "source_country": source_country,
            "emergence_year": year,
            "countrydataset_gdp_pc": gdp_raw,
            "countrydataset_pct_us_patents": pct_patents_raw,
            "countrydataset_pct_world_vc": pct_vc_raw,
            "countrydataset_pct_world_pubs": pct_pubs_raw,
            "countrydataset_pct_world_rd": pct_rd_raw,
            "vcpc_2011usd_source": vcpc_value,
            "gdp_pc_source": _source_label(gdp_raw, r["gdp_pc_2011usd"]),
            "pct_us_patents_source": _source_label(pct_patents_raw, r["pct_us_patents"]),
            "pct_world_vc_source": _source_label(pct_vc_raw, r["pct_world_vc"]),
            "pct_world_pubs_source": _source_label(pct_pubs_raw, r["pct_world_pubs"]),
            "pct_world_rd_source": _source_label(pct_rd_raw, r["pct_world_rd"]),
            "published_pct_world_pubs": r["pct_world_pubs"],
        }
    )

cols = [
    "Country",
    "Emergence Year",
    "GDP per capita (2011 USD)",
    "VC per capita (2011 USD)",
    "% of World VC",
    "% of World Pubs",
    "% of World R&D",
    "% of US Patents",
]
pd.DataFrame(rows, columns=cols).to_csv(OUT, index=False)
pd.DataFrame(audit_rows).to_csv(AUDIT, index=False)
print("wrote", OUT)
