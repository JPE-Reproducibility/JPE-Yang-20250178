from __future__ import annotations

import os
import sys
import warnings
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd

os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "code" / "auxiliary"))
import paths

warnings.filterwarnings("ignore")

COUNTRY_DATASET_FILE = paths.MANUAL_DIR_CONF / "CountryDataset.2024019.supplemented.xlsx"

REGIONS = ["US", "Developed ex US", "China", "Developing ex China"]
REGION_COLORS = {
    "US": "#4472c4",
    "Developed ex US": "#ed7d31",
    "China": "#ff0000",
    "Developing ex China": "#ffc000",
}
YEARS = list(range(2001, 2021))
DEVELOPED_EX_US_COUNTRIES = {
    "Australia",
    "Austria",
    "Belgium",
    "Canada",
    "Denmark",
    "Finland",
    "France",
    "Germany",
    "Greece",
    "Iceland",
    "Ireland",
    "Italy",
    "Japan",
    "Luxembourg",
    "Netherlands",
    "New Zealand",
    "Norway",
    "Portugal",
    "Spain",
    "Switzerland",
    "Turkiye",
    "United Kingdom",
}

def _require(path: Path) -> Path:
    if not path.exists():
        raise FileNotFoundError(f"Required Figure A1 input not found: {path}")
    if path.stat().st_size == 0:
        raise ValueError(f"Required Figure A1 input is empty: {path}")
    return path

def _country_group(country_name: str) -> str:
    if country_name == "United States":
        return "US"
    if country_name == "China":
        return "China"
    if country_name in DEVELOPED_EX_US_COUNTRIES:
        return "Developed ex US"
    return "Developing ex China"

def _country_level_rows(raw: pd.DataFrame) -> pd.DataFrame:
    if "CountryName" not in raw.columns:
        raise ValueError("CountryDataset CountryTable is missing CountryName.")

    country_table = raw.copy()
    total_rows = country_table.index[country_table["CountryName"].eq("Total")].tolist()
    if total_rows:
        country_table = country_table.loc[: total_rows[0] - 1].copy()

    country_table = country_table.dropna(subset=["CountryName"]).copy()
    country_table["CountryName"] = country_table["CountryName"].astype(str)
    country_table = country_table[country_table["CountryName"].str.strip() != ""].copy()
    country_table["country_group"] = country_table["CountryName"].map(_country_group)
    return country_table

def load_countrydataset_shares(path: Path, value_prefix: str, out_stem: str) -> pd.DataFrame:
    raw = pd.read_excel(path, sheet_name="CountryTable", header=0, engine="openpyxl")
    country_table = _country_level_rows(raw)

    year_shares = []
    for year in YEARS:
        value_col = f"{value_prefix}{year}"
        if value_col not in country_table.columns:
            raise ValueError(f"CountryDataset CountryTable is missing {value_col}.")
        values = country_table[["country_group", value_col]].copy()
        values[value_col] = pd.to_numeric(values[value_col], errors="coerce")
        grouped = values.groupby("country_group")[value_col].sum(min_count=1)
        missing_groups = [region for region in REGIONS if region not in grouped.index]
        if missing_groups:
            raise ValueError(f"Missing Figure A1 groups for {year}: {missing_groups}")
        total = grouped.reindex(REGIONS).sum()
        if not pd.notna(total) or total <= 0:
            raise ValueError(f"Non-positive Figure A1 total for {value_col}.")
        year_shares.append((grouped.reindex(REGIONS) / total * 100.0).rename(year))

    shares = pd.DataFrame(year_shares)
    shares.index = YEARS
    shares.to_csv(paths.INTERMEDIATE_DIR / f"{out_stem}_plotted_shares.csv")
    return shares

def stacked_area(shares: pd.DataFrame, out_name: str) -> None:
    fig, ax = plt.subplots(figsize=(7, 5))
    ax.stackplot(
        shares.index,
        [shares[r] for r in REGIONS],
        labels=REGIONS,
        colors=[REGION_COLORS[r] for r in REGIONS],
    )
    ax.set_xlim(shares.index.min(), shares.index.max())
    ax.set_ylim(0, 100)
    ax.set_yticks(range(0, 101, 10))
    ax.set_yticklabels([f"{v}%" for v in range(0, 101, 10)])
    ax.set_xticks(YEARS)
    ax.set_xticklabels(YEARS, rotation=90, fontsize=8)
    ax.margins(x=0)
    ax.legend(loc="upper center", bbox_to_anchor=(0.5, -0.14), ncol=4, frameon=False)
    fig.tight_layout()
    out = paths.FIGURE_DIR / out_name
    fig.savefig(out, dpi=150)
    plt.close(fig)
    print(f"Saved {out}")

def main() -> None:
    country_dataset_path = _require(COUNTRY_DATASET_FILE)
    print(f"Figure A1 input: {country_dataset_path}")
    rd = load_countrydataset_shares(country_dataset_path, "imprd", "figureA1a_rd")
    pub = load_countrydataset_shares(
        country_dataset_path,
        "ScientificPublications",
        "figureA1b_pubs",
    )
    stacked_area(rd, "figureA1a.pdf")
    stacked_area(pub, "figureA1b.pdf")

if __name__ == "__main__":
    main()
