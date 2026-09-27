from __future__ import annotations

import sys
import warnings
from pathlib import Path

import numpy as np
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D

import os
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "code" / "auxiliary"))
import paths

import pandas as pd

warnings.filterwarnings("ignore", category=UnicodeWarning)

EMERALD = (131 / 255, 162 / 255, 158 / 255)
START_COLOR = "#1f77b4"
END_COLOR = EMERALD
ARROW_COLOR = "grey"
MARKER_SIZE = 140
DPI = 300

COUNTRIES = ["Canada", "Japan", "South Korea", "Colombia", "Nigeria"]
SECTORS = ["EdTech"]

def build_merged() -> pd.DataFrame:
    df_reg = pd.read_stata(
        paths.STATA_DATA_DIR / "regression_corrected_120623.dta"
    )[["hqcountry", "subsegment1", "suitability_score_wdi"]].drop_duplicates(
        subset=["hqcountry", "subsegment1", "suitability_score_wdi"]
    )
    df_proj = pd.read_stata(paths.INTERMEDIATE_DATA_DIR / "suitability_gdp_component.dta")
    merged = df_reg.merge(
        df_proj, on=["hqcountry", "subsegment1"], how="inner"
    )
    merged["suitability_score_wdi_z"] = (
        merged["suitability_score_wdi"] - merged["suitability_score_wdi"].mean()
    ) / merged["suitability_score_wdi"].std()
    return merged[
        [
            "hqcountry",
            "subsegment1",
            "suitability_gdp_component_z",
            "suitability_residual_component_z",
            "suitability_score_wdi_z",
        ]
    ].drop_duplicates()

def main() -> None:
    df_merged = build_merged()

    fig, axes = plt.subplots(
        1, len(SECTORS), figsize=(12, 6), dpi=DPI, sharey=True
    )
    if len(SECTORS) == 1:
        axes = [axes]

    for ax, seg in zip(axes, SECTORS):
        seg_df = df_merged[df_merged["subsegment1"] == seg]
        seg_df = seg_df[seg_df["hqcountry"].isin(COUNTRIES)].copy()
        seg_df = (
            seg_df.set_index("hqcountry")
            .reindex(COUNTRIES)
            .dropna(
                subset=["suitability_score_wdi_z", "suitability_residual_component_z"]
            )
        )
        if seg_df.empty:
            ax.axis("off")
            continue
        positions = np.arange(len(seg_df))
        for pos, (country, row) in zip(positions, seg_df.iterrows()):
            y_start = row["suitability_score_wdi_z"]
            y_end = row["suitability_residual_component_z"]
            ax.scatter(pos, y_start, color=START_COLOR, s=MARKER_SIZE, marker="o")
            ax.scatter(pos, y_end, color=END_COLOR, s=MARKER_SIZE, marker="s")
            ax.annotate(
                "",
                xy=(pos, y_end),
                xytext=(pos, y_start),
                arrowprops=dict(arrowstyle="->", color=ARROW_COLOR, lw=2),
            )
            if country in ("Romania", "Nigeria"):
                ax.text(pos - 0.1, y_end, country, fontsize=15, ha="right", va="center")
            else:
                ax.text(pos + 0.1, y_end, country, fontsize=15, ha="left", va="center")
        ax.set_xticks(positions)
        ax.set_xticklabels(["" for _ in positions], fontsize=15)
        ax.set_xlabel("")
        ax.set_title(seg, fontsize=18)
        ax.grid(False)

    axes[0].set_ylabel("Z-Score", fontsize=18)
    for ax in axes:
        ax.tick_params(axis="y", labelsize=15)

    legend_handles = [
        Line2D([0], [0], marker="o", color="none", markerfacecolor=START_COLOR,
               markersize=MARKER_SIZE ** 0.5 / 2,
               label="Appropriateness Z-Score: Overall"),
        Line2D([0], [0], marker="s", color="none", markerfacecolor=END_COLOR,
               markersize=MARKER_SIZE ** 0.5 / 2,
               label="Appropriateness Z-Score: Horizontal Component"),
    ]
    fig.legend(
        handles=legend_handles, loc="lower center", ncol=3,
        bbox_to_anchor=(0.52, -0.1), fontsize=15,
    )
    plt.tight_layout()

    out = paths.FIGURE_DIR / "figureA10.pdf"
    plt.savefig(out, bbox_inches="tight")
    plt.close()
    print(f"Saved {out}")

if __name__ == "__main__":
    main()
