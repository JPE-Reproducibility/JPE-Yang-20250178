"""Prediction pipeline for patent sector models on HPC or local.

This script mirrors the filtering logic from the original
`patent_additional_prediction_500k_win.ipynb` notebook but:
- processes the full filtered dataset (no sampling)
- runs inference only (no training) against pre-trained SUBSEGMENT models
- supports slicing the sector list for multi-GPU SLURM jobs via environment variables

Environment variables (all optional unless noted):
- DATA_DIR: base data directory containing g_patent.tsv, g_assignee_disambiguated.tsv, g_location_disambiguated.tsv,
  matched_result.xlsx, predicted_positive_v2.csv. Default: ../../data relative to this file.
- OUTPUT_DIR: where predictions and intermediate filtered data are written. Default: ../../output/patent_predictions_full
- PATENT_MODEL_DIR: directory holding SUBSEGMENT-* folders with best_model weights. Default: ../../PatentSubsegmentFolders
- TOKENIZER_NAME: tokenizer to use (default bert-base-uncased)
- PRED_BATCH_SIZE: per-device batch size for inference (default 16)
- NUM_WORKERS: dataloader workers (default 2)
- SECTOR_OFFSET: 0-based starting index into sorted sector list (default 0)
- SECTOR_COUNT: number of sectors this job should handle from the offset (default all remaining)
- SECTORS_PER_TASK: how many sectors each SLURM task/GPU processes (default 4)
- CACHE_FILTERED: if set to 1, reuse filtered TSV if present; always writes the TSV when freshly computed.

This script relies on SLURM_LOCALID to shard sectors across tasks when launched via srun.
"""
from __future__ import annotations

import os
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, List

import numpy as np
import pandas as pd
import torch
from datasets import Dataset
from transformers import (
    AutoModelForSequenceClassification,
    AutoTokenizer,
    Trainer,
    TrainingArguments,
    set_seed,
)


def _env_int(name: str, default: int) -> int:
    val = os.environ.get(name)
    if val is None or val.strip() == "":
        return default
    try:
        return int(val)
    except Exception:
        return default


def _env_str(name: str, default: str) -> str:
    val = os.environ.get(name)
    return default if val is None or val.strip() == "" else val


def _env_path(name: str, default: Path) -> Path:
    return Path(_env_str(name, str(default))).expanduser().resolve()


@dataclass
class Paths:
    data_dir: Path
    output_dir: Path
    model_dir: Path
    tokenizer_name: str


@dataclass
class SectorSlice:
    offset: int
    count: int | None
    per_task: int
    local_id: int

    def bounds_for_task(self) -> tuple[int, int]:
        start = self.offset + self.local_id * self.per_task
        end = start + self.per_task
        if self.count is not None:
            end = min(end, self.offset + self.count)
        return start, end


def resolve_paths() -> Paths:
    script_dir = Path(__file__).resolve().parent
    project_root = script_dir.parent  # .../vc_china
    data_dir_default = project_root / "data"
    output_dir_default = project_root / "output" / "patent_predictions_full"
    # Models are nested one level deeper on HPC: data/PatentSubsegmentFolders/PatentSubsegmentFolders
    model_dir_default = data_dir_default / "PatentSubsegmentFolders" / "PatentSubsegmentFolders"
    tokenizer_name = _env_str("TOKENIZER_NAME", "bert-base-uncased")

    return Paths(
        data_dir=_env_path("DATA_DIR", data_dir_default),
        output_dir=_env_path("OUTPUT_DIR", output_dir_default),
        model_dir=_env_path("PATENT_MODEL_DIR", model_dir_default),
        tokenizer_name=tokenizer_name,
    )


def load_or_filter_data(paths: Paths, cache_filtered: bool = True) -> pd.DataFrame:
    filtered_path = paths.output_dir / "df_predicting_full.tsv"
    if cache_filtered and filtered_path.exists():
        print(f"[data] Loading cached filtered data from {filtered_path}")
        return pd.read_csv(filtered_path, sep="\t", low_memory=False)

    print("[data] Building filtered dataset from raw inputs...")
    g_patent = pd.read_csv(paths.data_dir / "g_patent.tsv", sep="\t", low_memory=False)
    g_patent = g_patent[g_patent["patent_type"] == "utility"]

    g_assignee = pd.read_csv(paths.data_dir / "g_assignee_disambiguated.tsv", sep="\t", low_memory=False)
    g_assignee = g_assignee[g_assignee["assignee_sequence"] == 0][
        ["patent_id", "assignee_id", "disambig_assignee_organization", "location_id"]
    ]
    g_patent = g_patent.merge(g_assignee, on="patent_id", how="inner")
    del g_assignee

    g_location = pd.read_csv(paths.data_dir / "g_location_disambiguated.tsv", sep="\t", low_memory=False)
    g_patent = g_patent.merge(g_location[["location_id", "disambig_country"]], on="location_id", how="left")
    del g_location

    pb_assignee = pd.read_excel(paths.data_dir / "matched_result.xlsx")
    pb_marketmap = pd.read_csv(paths.data_dir / "predicted_positive_v2.csv")
    pb_marketmap.sort_values(by=["companyid"], inplace=True)
    pb_marketmap["count_sector"] = pb_marketmap.groupby("companyid")["companyid"].transform("count")
    pb_marketmap["unique_segment"] = pb_marketmap["marketmap"] + pb_marketmap["segment"]
    pb_marketmap["count_segment"] = pb_marketmap.groupby("companyid")["unique_segment"].transform("nunique")
    pb_marketmap["count_marketmap"] = pb_marketmap.groupby("companyid")["marketmap"].transform("nunique")
    pb_marketmap = pb_marketmap[pb_marketmap["count_marketmap"] == 1]
    pb_marketmap = pd.merge(pb_marketmap, pb_assignee[["companyid", "assignee_id"]], on="companyid", how="inner")

    df_training = pd.merge(g_patent, pb_marketmap, on="assignee_id", how="inner")
    df_predicting = g_patent[~g_patent["patent_id"].isin(df_training["patent_id"])]
    print(f"[data] Total patents for predicting before country/date filters: {df_predicting.shape[0]}")

    df_predicting = df_predicting[df_predicting["disambig_country"] != "US"]
    print(f"[data] After removing US: {df_predicting.shape[0]}")

    df_predicting["patent_date"] = pd.to_datetime(df_predicting["patent_date"], errors="coerce")
    df_predicting = df_predicting[
        (df_predicting["patent_date"].dt.year >= 2000)
        & (df_predicting["patent_date"].dt.year <= 2019)
    ]
    print(f"[data] After date filter 2000-2019: {df_predicting.shape[0]}")

    df_predicting = df_predicting[~df_predicting["patent_abstract"].isnull()]
    print(f"[data] After abstract not-null: {df_predicting.shape[0]}")

    df_predicting = df_predicting[~df_predicting["disambig_country"].isnull()]
    df_predicting = df_predicting[df_predicting["patent_abstract"].astype(str).str.strip() != ""]
    print(f"[data] After non-empty abstract and non-null country: {df_predicting.shape[0]}")

    paths.output_dir.mkdir(parents=True, exist_ok=True)
    df_predicting.to_csv(filtered_path, sep="\t", index=False)
    print(f"[data] Saved filtered dataset to {filtered_path}")
    return df_predicting


def build_predict_dataset(df_predicting: pd.DataFrame, tokenizer, num_proc: int) -> Dataset:
    df_pred = df_predicting[["patent_id", "patent_abstract"]].copy()
    df_pred = df_pred.rename(columns={"patent_id": "appid", "patent_abstract": "abstract"})
    df_pred["appid"] = df_pred["appid"].astype(str)
    df_pred = df_pred[df_pred["abstract"].str.strip() != ""].reset_index(drop=True)

    print(f"[data] Preparing Hugging Face dataset with {len(df_pred)} rows")
    hf_ds = Dataset.from_pandas(df_pred, preserve_index=False)

    def _tokenize(batch):
        return tokenizer(batch["abstract"], padding="max_length", truncation=True, max_length=512)

    tokenized = hf_ds.map(_tokenize, batched=True, num_proc=max(1, num_proc), remove_columns=hf_ds.column_names)
    return tokenized, df_pred


def discover_sectors(model_dir: Path) -> List[Path]:
    candidates = [p for p in model_dir.glob("SUBSEGMENT-*") if (p / "best_model" / "model.safetensors").exists()]
    sectors = sorted(candidates, key=lambda p: p.name)
    print(f"[sectors] Discovered {len(sectors)} sector models under {model_dir}")
    return sectors


def slice_sectors(sectors: List[Path], slice_cfg: SectorSlice) -> List[Path]:
    start, end = slice_cfg.bounds_for_task()
    bounded_end = min(end, len(sectors))
    bounded_start = min(start, bounded_end)
    selected = sectors[bounded_start:bounded_end]
    print(
        f"[sectors] Task slice local_id={slice_cfg.local_id} offset={slice_cfg.offset} per_task={slice_cfg.per_task} -> "
        f"global indices [{bounded_start}, {bounded_end}) ({len(selected)} sectors)"
    )
    return selected


def run_sector_inference(
    sector_path: Path,
    predict_dataset: Dataset,
    df_pred: pd.DataFrame,
    output_dir: Path,
    batch_size: int,
    tokenizer_name: str,
    num_workers: int,
) -> Path:
    sector = sector_path.name.replace("SUBSEGMENT-", "")
    out_path = output_dir / f"{sector}_patent_positive_bert.csv"
    if out_path.exists():
        print(f"[predict] Skipping {sector}: output already exists at {out_path}")
        return out_path

    model_path = sector_path / "best_model"
    print(f"[predict] Loading model for sector {sector} from {model_path}")
    model = AutoModelForSequenceClassification.from_pretrained(model_path)

    tmp_dir = output_dir / "__hf_tmp" / sector
    tmp_dir.mkdir(parents=True, exist_ok=True)

    args = TrainingArguments(
        output_dir=str(tmp_dir),
        per_device_eval_batch_size=batch_size,
        dataloader_num_workers=max(1, num_workers),
        fp16=torch.cuda.is_available(),
        bf16=False,
        dataloader_pin_memory=True,
        remove_unused_columns=False,
        do_train=False,
        do_eval=False,
        predict_with_generate=False,
        logging_strategy="no",
        save_strategy="no",
        report_to="none",
    )

    trainer = Trainer(model=model, args=args)
    predictions = trainer.predict(predict_dataset)
    logits = predictions.predictions
    y_neg = logits[:, 0]
    y_pos = logits[:, 1]
    y_pred = np.argmax(logits, axis=-1)

    df_results = pd.DataFrame(
        {
            "appid": df_pred["appid"],
            "abstract": df_pred["abstract"],
            "pred_pos": y_pos,
            "pred_neg": y_neg,
            "positive": y_pred,
            "sector": sector,
        }
    )

    df_results.to_csv(out_path, index=False)
    print(f"[predict] Wrote predictions for {sector} to {out_path}")
    return out_path


def main() -> int:
    paths = resolve_paths()
    cache_filtered = _env_int("CACHE_FILTERED", 1) == 1
    batch_size = _env_int("PRED_BATCH_SIZE", 16)
    num_workers = _env_int("NUM_WORKERS", 2)
    sector_offset = _env_int("SECTOR_OFFSET", 0)
    sector_count = _env_int("SECTOR_COUNT", -1)
    sector_count = None if sector_count < 0 else sector_count
    sectors_per_task = _env_int("SECTORS_PER_TASK", 4)
    local_id = _env_int("SLURM_LOCALID", 0)
    slice_cfg = SectorSlice(
        offset=sector_offset,
        count=sector_count,
        per_task=sectors_per_task,
        local_id=local_id,
    )

    torch.set_num_threads(max(1, _env_int("OMP_NUM_THREADS", os.cpu_count() or 1)))
    torch.backends.cuda.matmul.allow_tf32 = True
    set_seed(42)

    paths.output_dir.mkdir(parents=True, exist_ok=True)

    df_predicting = load_or_filter_data(paths, cache_filtered=cache_filtered)
    tokenizer = AutoTokenizer.from_pretrained(paths.tokenizer_name)
    predict_dataset, df_pred = build_predict_dataset(df_predicting, tokenizer, num_proc=num_workers)

    sectors = discover_sectors(paths.model_dir)
    if len(sectors) == 0:
        print(f"[error] No sector models found under {paths.model_dir}", file=sys.stderr)
        return 1
    selected_sectors = slice_sectors(sectors, slice_cfg)
    if not selected_sectors:
        print("[info] No sectors assigned to this task; exiting.")
        return 0

    written: List[Path] = []
    for sector_path in selected_sectors:
        try:
            out_path = run_sector_inference(
                sector_path,
                predict_dataset,
                df_pred,
                paths.output_dir,
                batch_size,
                paths.tokenizer_name,
                num_workers,
            )
            written.append(out_path)
        except Exception as exc:  # noqa: BLE001
            print(f"[error] Failed sector {sector_path.name}: {exc}", file=sys.stderr)

    print(f"[done] Task complete. Wrote {len(written)} files.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
