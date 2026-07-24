import csv
import json
import random
import re
from datetime import datetime
from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split


REQUIRED_MARKET_COLUMNS = ["companyid", "marketmap", "segment", "subsegment", "description"]
REQUIRED_COMPANY_COLUMNS = ["companyid", "description"]


def clean_fullname(name):
    name = re.sub(r"[^\w\s]|_", "", str(name))
    return name.replace(" ", "")


def standardize_columns(df):
    rename = {
        "mapName": "marketmap",
        "mapname": "marketmap",
        "subSegment": "subsegment",
        "subsegmentname": "subsegment",
    }
    return df.rename(columns={old: new for old, new in rename.items() if old in df.columns})


def require_columns(df, required, path):
    missing = [column for column in required if column not in df.columns]
    if missing:
        raise ValueError(f"{path} is missing required columns: {missing}")


def load_market_map(inputdir, filename="pbmarketmap_v2.csv"):
    path = Path(inputdir) / filename
    if not path.exists():
        raise FileNotFoundError(f"Missing market-map input: {path}")
    df = standardize_columns(pd.read_csv(path))
    require_columns(df, REQUIRED_MARKET_COLUMNS, path)
    df = df[~df["description"].isna()].copy()
    df["description"] = df["description"].astype(str)
    df = df[df["description"].str.len() > 0].copy()
    df["fullname"] = df["marketmap"].astype(str) + "|" + df["segment"].astype(str) + "|" + df["subsegment"].astype(str)
    return df


def load_company_header(inputdir, filename="pbcompanies.csv"):
    path = Path(inputdir) / filename
    if not path.exists():
        raise FileNotFoundError(f"Missing company input: {path}")
    header = pd.read_csv(path, nrows=0)
    require_columns(header, REQUIRED_COMPANY_COLUMNS, path)
    return header.columns.tolist()


def category_manifest(market_map):
    manifest = (
        market_map
        .groupby(["marketmap", "segment", "subsegment", "fullname"], as_index=False, sort=True)
        .agg(count_TP=("companyid", "count"))
    )
    manifest["clean_fullname"] = manifest["fullname"].map(clean_fullname)
    manifest.insert(0, "category_index", range(len(manifest)))
    return manifest


def write_manifest(market_map, outputdir):
    outputdir = Path(outputdir)
    outputdir.mkdir(parents=True, exist_ok=True)
    manifest = category_manifest(market_map)
    manifest.to_csv(outputdir / "category_manifest.csv", index=False)
    return manifest


def read_manifest(inputdir, outputdir):
    path = Path(outputdir) / "category_manifest.csv"
    if path.exists():
        return pd.read_csv(path)
    return write_manifest(load_market_map(inputdir), outputdir)


def select_categories(manifest, start_index=None, end_index=None, category=None):
    selected = manifest.copy()
    if category:
        clean_category = clean_fullname(category)
        selected = selected[
            (selected["fullname"] == category)
            | (selected["clean_fullname"] == category)
            | (selected["clean_fullname"] == clean_category)
        ]
    if start_index is not None:
        selected = selected[selected["category_index"] >= start_index]
    if end_index is not None:
        selected = selected[selected["category_index"] < end_index]
    if selected.empty:
        raise ValueError("No categories selected. Check --start-index, --end-index, or --category.")
    return selected.sort_values("category_index").reset_index(drop=True)


def split_block(df, seed):
    if len(df) == 0:
        raise ValueError("Cannot split an empty block.")
    if len(df) >= 10:
        train, valid_test = train_test_split(df, test_size=0.2, random_state=seed)
        valid, test = train_test_split(valid_test, test_size=0.5, random_state=seed + 1)
        return train, valid, test
    shuffled = df.sample(frac=1, random_state=seed).reset_index(drop=True)
    if len(shuffled) == 1:
        return shuffled.copy(), shuffled.copy(), shuffled.copy()
    if len(shuffled) == 2:
        return shuffled.iloc[[0]].copy(), shuffled.iloc[[1]].copy(), shuffled.iloc[[1]].copy()
    return shuffled.iloc[2:].copy(), shuffled.iloc[[1]].copy(), shuffled.iloc[[0]].copy()


def make_training_frames(market_map, fullname, seed, adjacent_threshold=100, negatives_per_segment=15):
    df = market_map.copy()
    df["label"] = (df["fullname"] == fullname).astype(int)
    df["description"] = df["description"].astype(str).str.lower()

    category_rows = df[df["fullname"] == fullname]
    if category_rows.empty:
        raise ValueError(f"No positive examples for category: {fullname}")
    parent_segment = category_rows["segment"].iloc[0]

    adjacent_negatives = df[(df["label"] == 0) & (df["segment"] == parent_segment)]
    if len(adjacent_negatives) > adjacent_threshold:
        adjacent_negatives = adjacent_negatives.sample(
            n=adjacent_threshold,
            replace=True,
            random_state=seed,
        )

    all_negatives = df[df["label"] == 0]
    broad_negatives = (
        all_negatives
        .groupby("segment", group_keys=False)
        .apply(lambda block: block.sample(n=negatives_per_segment, replace=True, random_state=seed + 1))
    )

    negatives = (
        pd.concat([adjacent_negatives, broad_negatives], ignore_index=True)
        .drop_duplicates(subset=["companyid", "fullname"])
    )
    positives = df[df["label"] == 1]

    negative_train, negative_valid, negative_test = split_block(negatives, seed + 2)
    positive_train, positive_valid, positive_test = split_block(positives, seed + 3)

    keep = ["description", "label"]
    train = pd.concat([negative_train[keep], positive_train[keep]], ignore_index=True).sample(frac=1, random_state=seed + 4)
    valid = pd.concat([negative_valid[keep], positive_valid[keep]], ignore_index=True).sample(frac=1, random_state=seed + 5)
    test = pd.concat([negative_test[keep], positive_test[keep]], ignore_index=True).sample(frac=1, random_state=seed + 6)

    split_summary = {
        "fullname": fullname,
        "num_positive_examples": int(len(positives)),
        "num_negative_examples": int(len(negatives)),
        "train_rows": int(len(train)),
        "valid_rows": int(len(valid)),
        "test_rows": int(len(test)),
        "adjacent_negative_rows_before_threshold": int(len(df[(df["label"] == 0) & (df["segment"] == parent_segment)])),
        "negatives_per_segment": int(negatives_per_segment),
        "adjacent_threshold": int(adjacent_threshold),
    }
    return train.reset_index(drop=True), valid.reset_index(drop=True), test.reset_index(drop=True), split_summary


def compute_binary_metrics(logits, labels):
    predictions = np.argmax(logits, axis=-1)
    labels = np.asarray(labels)
    true_positive = int(((predictions == 1) & (labels == 1)).sum())
    false_positive = int(((predictions == 1) & (labels == 0)).sum())
    false_negative = int(((predictions == 0) & (labels == 1)).sum())
    accuracy = float((predictions == labels).mean()) if len(labels) else 0.0
    precision = true_positive / (true_positive + false_positive) if true_positive + false_positive else 0.0
    recall = true_positive / (true_positive + false_negative) if true_positive + false_negative else 0.0
    f1 = 2 * precision * recall / (precision + recall) if precision + recall else 0.0
    return {
        "accuracy": accuracy,
        "precision": precision,
        "recall": recall,
        "f1": f1,
    }


def write_json(path, payload):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, sort_keys=True)
        handle.write("\n")


def write_empty_csv(path, fieldnames):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()


def outputdir_for_run(outputdir, overwrite=False):
    outputdir = Path(outputdir)
    generated_entries = [
        path for path in outputdir.iterdir()
        if path.name not in {".gitkeep", "README.md"}
    ] if outputdir.exists() else []
    if generated_entries and not overwrite:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        return outputdir.with_name(f"{outputdir.name}_rerun_{timestamp}")
    return outputdir
