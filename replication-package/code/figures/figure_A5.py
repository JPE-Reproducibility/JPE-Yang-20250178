from __future__ import annotations

import sys
import warnings
from pathlib import Path

import matplotlib.pyplot as plt

import os
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "code" / "auxiliary"))
import paths

import pandas as pd

warnings.filterwarnings("ignore")

EMERALD = (131 / 255, 162 / 255, 158 / 255)

ANNOTATIONS = [
    ("EdTech, Solutions\nfor Students,\nPrimary and\nSecondary", 0.74, (0.66, 0.92)),
    ("Mobility Tech,\nShipping Service\nProvider", 0.81, (0.80, 0.62)),
    ("Fintech,\nInvestment\nTools and\nPlatforms", 0.86, (0.92, 0.40)),
]

def compute_share() -> pd.Series:
    df = pd.read_stata(paths.INTERMEDIATE_DATA_DIR / "dealcount_v2.dta")
    df = df[(df["year"] <= 2019) & (df["year"] >= 2015)].copy()
    df = df.drop_duplicates(subset=["fullname", "year"])
    df = df[["fullname", "year", "dealcount_china", "dealcount_us"]]
    g = df.groupby("fullname", as_index=False).agg(
        dealcount_china=("dealcount_china", "mean"),
        dealcount_us=("dealcount_us", "mean"),
    )
    g["ChinaPlusUS"] = g["dealcount_us"] + g["dealcount_china"]
    g["share_china"] = g["dealcount_china"] / g["ChinaPlusUS"]
    return g["share_china"].dropna()

def main() -> None:
    share = compute_share()

    fig, ax = plt.subplots(figsize=(8, 6))
    ax.hist(share, bins=30, density=True, color=EMERALD, alpha=0.7)
    ax.set_xlabel("Share Chinese Deals Across Sectors")
    ax.set_ylabel("Density")
    ax.set_xlim(0, 1)
    ax.grid(True, linestyle="--", color="0.8", alpha=0.7)
    ax.set_axisbelow(True)

    ymax = ax.get_ylim()[1]
    for text, x_target, (tx_frac, ty_frac) in ANNOTATIONS:
        ax.annotate(
            text,
            xy=(x_target, 0.25),
            xytext=(tx_frac, ty_frac * ymax),
            color="#8b1a1a",
            fontsize=11,
            ha="center",
            va="top",
            arrowprops=dict(arrowstyle="->", color="#8b1a1a"),
        )

    fig.tight_layout()
    out = paths.FIGURE_DIR / "figureA5.pdf"
    fig.savefig(out, dpi=150)
    plt.close(fig)
    print(f"Saved {out}")

if __name__ == "__main__":
    main()
