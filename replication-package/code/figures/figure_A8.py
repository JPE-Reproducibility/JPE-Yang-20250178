from __future__ import annotations

import sys
import warnings
from pathlib import Path

import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

import os
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "code" / "auxiliary"))
import paths

import pandas as pd

warnings.filterwarnings("ignore", category=UnicodeWarning)

EMERALD = (131 / 255, 162 / 255, 158 / 255)

def main() -> None:
    sns.set_style("whitegrid")

    suit_china = pd.read_stata(
        paths.SUITABILITY_OUTPUT_DIR / "china_suitability_score_all_corrected.dta"
    )

    suit_china.columns = [c.replace("_SuitSc", "") for c in suit_china.columns]
    meta = ["hqcountry", "country_2digit", "relative_to"]
    for col in list(suit_china.columns):
        if col in meta:
            continue
        suit_china[f"{col}_val"] = suit_china[col].max() - suit_china[col]
        suit_china.drop(col, axis=1, inplace=True)
    suit_china.columns = [c.replace("_val", "") for c in suit_china.columns]

    suit_china.drop(["country_2digit", "relative_to"], axis=1, inplace=True)
    suit_china.set_index("hqcountry", inplace=True)

    sectors = list(suit_china.columns)
    max_distances = []
    for _, row in suit_china.iterrows():
        distances = [
            np.sqrt((row[s1] - row[s2]) ** 2)
            for s1 in sectors
            for s2 in sectors
            if s1 != s2
        ]
        max_distances.append(max(distances))

    plt.figure(figsize=(10, 8))
    plt.hist(max_distances, bins=20, color=EMERALD, linewidth=0.5)
    plt.xlabel("Max Euclidean Distance")
    plt.ylabel("Number of Countries")
    plt.grid(True, alpha=0.2)
    plt.xlim(0)
    for side in ["left", "bottom", "right", "top"]:
        plt.gca().spines[side].set_linewidth(0.5)

    out = paths.FIGURE_DIR / "figureA8.pdf"
    plt.savefig(out)
    plt.close()
    print(f"Saved {out}")

if __name__ == "__main__":
    main()
