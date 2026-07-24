from __future__ import annotations

import sys
import warnings
from pathlib import Path

import matplotlib.pyplot as plt
import seaborn as sns
from scipy.stats import gaussian_kde

import os
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "code" / "auxiliary"))
import paths

import pandas as pd

warnings.filterwarnings("ignore", category=UnicodeWarning)

EMERALD = (131 / 255, 162 / 255, 158 / 255)
META = ["hqcountry", "relative_to", "country_2digit"]

PANELS = {
    "AgTech": "figureA9a.pdf",
    "Fintech": "figureA9b.pdf",
}
COUNTRIES = [
    "Brazil", "India", "Indonesia", "Nigeria",
    "Afghanistan", "Vietnam", "Canada", "Mexico", "Turkey",
]

def build_demeaned() -> pd.DataFrame:
    df = pd.read_stata(
        paths.SUITABILITY_OUTPUT_DIR / "china_suitability_score_all_corrected.dta"
    )
    df_used = pd.read_stata(
        paths.STATA_DATA_DIR / "regression_corrected_120623.dta"
    )[["hqcountry"]].drop_duplicates()
    df = df.merge(df_used, on="hqcountry", how="inner")

    df.columns = [c.replace("_SuitSc", "") for c in df.columns]

    for col in list(df.columns):
        if col in META:
            continue
        df[f"{col}_val"] = df[col].max() - df[col]
        df.drop(col, axis=1, inplace=True)
    df.columns = [c.replace("_val", "") for c in df.columns]

    sectors = [c for c in df.columns if c not in META]

    for col in sectors:
        total_sum = df[sectors].sum(axis=1)
        df[f"{col}_loo_mean"] = (total_sum - df[col]) / (len(sectors) - 1)
        df[f"{col}_diff"] = df[col] - df[f"{col}_loo_mean"]
        df.rename(columns={col: f"{col}_origin"}, inplace=True)
        df.rename(columns={f"{col}_diff": col}, inplace=True)
    return df

def plot_sector(df: pd.DataFrame, seg: str, out_name: str) -> None:
    kde = gaussian_kde(df[seg])

    plt.figure(figsize=(32, 24))
    sns.histplot(df[seg], bins=20, kde=False, stat="density", color=EMERALD)
    sns.kdeplot(df[seg], linewidth=3, color="green")

    for country in COUNTRIES:
        score = df.loc[df["hqcountry"] == country, seg]
        if score.empty:
            continue
        density_value = kde(score)
        plt.scatter(score, density_value, color="blue", s=50)

        if (seg == "AgTech" and country in ("Brazil", "Afghanistan")) or (
            seg == "EdTech" and country == "Mexico"
        ):
            plt.text(score, density_value, country, fontsize=50, ha="right", va="top")
        else:
            plt.text(
                score, density_value, country, fontsize=50, ha="left", va="bottom"
            )

    plt.xlabel(
        "Appropriateness Score with China after Subtracting Leave-One-Out Mean",
        fontsize=50,
    )
    plt.ylabel("Density", fontsize=50)
    plt.xticks(fontsize=50)
    plt.yticks(fontsize=50)
    plt.tight_layout()

    out = paths.FIGURE_DIR / out_name
    plt.savefig(out)
    plt.close()
    print(f"Saved {out}")

def main() -> None:
    sns.set_style("whitegrid")
    df = build_demeaned()
    for seg, out_name in PANELS.items():
        plot_sector(df, seg, out_name)

if __name__ == "__main__":
    main()
