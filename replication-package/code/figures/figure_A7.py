from __future__ import annotations

import sys
import warnings
from pathlib import Path

import matplotlib.pyplot as plt
import matplotlib.colors as mcolors
import matplotlib.patches as mpatches
import seaborn as sns

# the manuscript figure was rendered under seaborn's whitegrid style
# (light lat/lon gridlines, Arial-first font stack)
sns.set_style("whitegrid")

import os
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "code" / "auxiliary"))
import paths

import pandas as pd

warnings.filterwarnings("ignore", category=UnicodeWarning)

META = ["hqcountry", "country_2digit", "relative_to"]

SHAPEFILE = (
    ROOT / "data" / "raw" / "geocoding_resource"
    / "ne_10m_admin_0_countries"
    / "ne_10m_admin_0_countries.shp"
)

MARKETMAP_REPLACEMENTS = {
    "aiml": "AI_ML", "agtech": "AgTech", "blockchain": "Blockchain",
    "carbonandemissionstech": "Carbon_and_Emissions_Tech", "devops": "DevOps",
    "edtech": "EdTech", "enterprisehealth": "Enterprise_Health",
    "fintech": "Fintech", "foodtech": "FoodTech", "infosec": "InfoSec",
    "insurtech": "Insurtech", "iot": "IoT", "mobilitytech": "MobilityTech",
    "retailhealthtech": "Retail_HealthTech", "supplychaintech": "Supply_Chain_Tech",
}

def _rescale_and_sectors(suit: pd.DataFrame) -> tuple[pd.DataFrame, list[str]]:
    suit.columns = [c.replace("_SuitSc", "") for c in suit.columns]
    for col in list(suit.columns):
        if col in META:
            continue
        suit[f"{col}_val"] = suit[col].max() - suit[col]
        suit.drop(col, axis=1, inplace=True)
    suit.columns = [c.replace("_val", "") for c in suit.columns]
    sectors = [c for c in suit.columns if c not in META]
    return suit, sectors

def _weighted_mean_func(weights: pd.DataFrame):
    def wm(row):
        total = 0.0
        for _, market in weights.iterrows():
            col = market["marketmap"]
            if col in row and pd.notna(row[col]):
                total += row[col] * market["dealsize_weight"]
        return total
    return wm

def load_data():
    suit_china = pd.read_stata(
        paths.SUITABILITY_OUTPUT_DIR / "china_suitability_score_all_corrected.dta"
    )
    suit_us = pd.read_stata(
        paths.SUITABILITY_OUTPUT_DIR / "us_suitability_score_all_corrected.dta"
    )

    used = (
        pd.read_stata(paths.STATA_DATA_DIR / "regression_corrected_120623.dta")[
            ["hqcountry"]
        ]
        .drop_duplicates()
        .sort_values("hqcountry")
        .reset_index(drop=True)
    )
    used.loc[len(used)] = "United States"
    used.loc[len(used)] = "China"

    suit_china_used = suit_china.merge(used, on="hqcountry", how="inner")
    suit_us_used = suit_us.merge(used, on="hqcountry", how="inner")

    suit_china_used, sectors = _rescale_and_sectors(suit_china_used)
    suit_us_used, _ = _rescale_and_sectors(suit_us_used)

    suit_china_used["mean"] = suit_china_used[sectors].mean(axis=1)
    suit_us_used["mean"] = suit_us_used[sectors].mean(axis=1)

    analysis = pd.read_stata(paths.STATA_DATA_DIR / "analysis_v2.dta")
    weights = analysis.groupby("marketmap").agg({"dealsize": "sum"}).reset_index()
    weights["dealsize_weight"] = weights["dealsize"] / weights["dealsize"].sum()
    weights["marketmap"] = (
        weights["marketmap"].str.lower().str.replace("[^a-z]", "", regex=True)
    )
    weights["marketmap"] = weights["marketmap"].replace(MARKETMAP_REPLACEMENTS)

    wm = _weighted_mean_func(weights)
    suit_china_used["weighted_mean"] = suit_china_used.apply(wm, axis=1)
    suit_us_used["weighted_mean"] = suit_us_used.apply(wm, axis=1)

    suit_both_used = suit_china_used.merge(suit_us_used, on="hqcountry", how="inner")
    suit_both_used.columns = [c.replace("_x", "_china") for c in suit_both_used.columns]
    suit_both_used.columns = [c.replace("_y", "_us") for c in suit_both_used.columns]
    suit_both_used["weighted_mean_diff"] = (
        suit_both_used["weighted_mean_china"] - suit_both_used["weighted_mean_us"]
    )
    return suit_china_used, suit_both_used

def main() -> None:
    if not SHAPEFILE.exists():
        raise SystemExit(
            "Natural Earth admin-0 countries shapefile not found at\n"
            f"  {SHAPEFILE}\n"
            "World maps A7a/A7b cannot be drawn without it."
        )

    import geopandas as gpd

    suit_china_used, suit_both_used = load_data()

    world = gpd.read_file(SHAPEFILE)
    world = world[world["SOVEREIGNT"] != "Antarctica"]
    world_china = world.merge(
        suit_china_used, how="left", left_on="ISO_A2_EH", right_on="country_2digit"
    )
    world_diff = world.merge(
        suit_both_used, how="left",
        left_on="ISO_A2_EH", right_on="country_2digit_china",
    )

    def _quintile_fill(series, palette):
        q = pd.qcut(series, 5, labels=False, duplicates="drop")
        return q.map({i: c for i, c in enumerate(palette)}).fillna("white")

    # the manuscript's panel (a) uses this diverging blue-to-red scale
    colors = ["#08519c", "#b3d3e8", "#fee3e8", "#f86c78", "#b2000d"]
    fig, ax = plt.subplots(1, 1, figsize=(40, 17))
    world.boundary.plot(ax=ax, linewidth=1)
    world_china.plot(
        ax=ax, color=_quintile_fill(world_china["weighted_mean"], colors),
        edgecolor="black", linewidth=1,
    )
    labels = {0: "0-20%", 1: "21-40%", 2: "41-60%", 3: "61-80%", 4: "81-100%"}
    patches = [mpatches.Patch(color=c, label=labels[i]) for i, c in enumerate(colors)]
    patches.append(mpatches.Patch(facecolor="white", edgecolor="black", label="No Data"))
    ax.legend(handles=patches, bbox_to_anchor=(0.02, 0.04), loc="lower left", fontsize=26)
    ax.get_legend().set_title("Mean Appropriateness \nScore to China ", prop={"size": 30})
    plt.tight_layout()
    out_a = paths.FIGURE_DIR / "figureA7a.pdf"
    plt.savefig(out_a)
    plt.close()
    print(f"Saved {out_a}")

    colors = ["#08519c", "#b3d3e8", "#fee3e8", "#f86c78", "#b2000d"]
    diff_vals = suit_both_used["weighted_mean_diff"].dropna()
    edges = list(diff_vals.quantile([0.2, 0.4, 0.6, 0.8, 1.0]))
    fig, ax = plt.subplots(1, 1, figsize=(40, 17))
    world.boundary.plot(ax=ax, linewidth=1)
    world_diff.plot(
        ax=ax, color=_quintile_fill(world_diff["weighted_mean_diff"], colors),
        edgecolor="black", linewidth=1,
    )
    labels = {}
    for i in range(5):
        lower = edges[i - 1] if i != 0 else diff_vals.min()
        upper = edges[i]
        labels[i] = f"{i * 20}%-{(i + 1) * 20}% ({lower:.2f} to {upper:.2f})"
    patches = [mpatches.Patch(color=c, label=labels[i]) for i, c in enumerate(colors)]
    patches.append(mpatches.Patch(facecolor="white", edgecolor="black", label="No Data"))
    ax.legend(handles=patches, bbox_to_anchor=(0.02, 0.04), loc="lower left", fontsize=26)
    ax.get_legend().set_title(
        "Difference in Mean \nAppropriateness  Score \nto China and to U.S.",
        prop={"size": 30},
    )
    plt.tight_layout()
    out_b = paths.FIGURE_DIR / "figureA7b.pdf"
    plt.savefig(out_b)
    plt.close()
    print(f"Saved {out_b}")

if __name__ == "__main__":
    main()
