import os
import re
import platform

import pandas as pd
import numpy as np

import torch
from pathlib import Path
from transformers import Trainer, TrainingArguments, AutoTokenizer, AutoModelForSequenceClassification
from datasets import Dataset

import transformers, datasets
import logging, traceback, sys


# =========================
# Parameters (edit here)
# =========================
IS_MAC = platform.system() == "Darwin"
IS_WINDOWS = platform.system() == "Windows"

# Set base directories for each platform
# path parameterized: set env var BERT_WORK_ROOT to the BERT model/scratch store
BASE_DIR_MAC = Path(os.environ.get("BERT_WORK_ROOT", "PATH_TO_BERT_MODEL_STORE"))
BASE_DIR_WIN = Path(os.environ.get("BERT_WORK_ROOT", "PATH_TO_BERT_MODEL_STORE"))

# Auto-select based on platform
DIR = BASE_DIR_MAC if IS_MAC else BASE_DIR_WIN

# Subsegment index range to run predictions for [start, end)
START_INDEX = 207
END_INDEX = 210

# No explicit eval batch size to mirror original flow


def is_mps_available() -> bool:
    mps_attr = getattr(torch.backends, "mps", None)
    return (mps_attr is not None) and torch.backends.mps.is_available()


def subsegment_name_processing(name_str: str) -> str:
    name_str = re.sub(r'[^\w\s]|_', '', name_str)
    return name_str.replace(" ", "")


def predict_for_subsegment(i: int,
                           df_pb_company: pd.DataFrame,
                           df_market_map: pd.DataFrame,
                           df_subsegment: pd.DataFrame,
                           ls_subsegment: list[str],
                           base_dir: Path,
                           use_mps: bool) -> None:
    selected_subsegment = ls_subsegment[i]
    print('Predicting for ' + str(i) + ': ' + selected_subsegment)

    # Build outside prediction set
    df_pb_company = df_pb_company[df_pb_company['description'].str.len() > 0]
    ds_out = df_pb_company[['description', 'companyid']].reset_index(drop=True)
    ds_out['label'] = 0
    ds_out['description'] = ds_out['description'].str.lower()

    # Tokenizer and model
    tokenizer = AutoTokenizer.from_pretrained("bert-base-uncased")

    def tokenize_function(batch: dict) -> dict:
        return tokenizer(batch["description"], padding="max_length", truncation=True)

    out_dataset = Dataset.from_pandas(ds_out).map(tokenize_function, batched=True)

    model_dir = base_dir / "pbmarketmap_v2/model/SUBSEGMENT-{}".format(
        subsegment_name_processing(selected_subsegment)
    )

    if not model_dir.exists():
        raise FileNotFoundError(f"Model directory not found: {model_dir}")

    model = AutoModelForSequenceClassification.from_pretrained(model_dir)

    # Trainer for prediction (mirror original: minimal args)
    training_args = TrainingArguments(
        output_dir=model_dir,
        report_to="none",
        use_mps_device=use_mps,
    )

    trainer = Trainer(
        model=model,
        args=training_args,
        tokenizer=tokenizer,
    )

    # Predict
    predict_output = trainer.predict(out_dataset)
    logits = predict_output.predictions
    y_neg = logits[:, 0]
    y_pos = logits[:, 1]
    y_pred = np.argmax(logits, axis=-1)

    # Save predictions
    positive_dir = base_dir / "pbmarketmap_v2/positive"
    positive_dir.mkdir(parents=True, exist_ok=True)

    out_df = pd.DataFrame({
        'pred_pos': y_pos,
        'pred_neg': y_neg,
        'positive': y_pred,
        'description': ds_out['description'],
        'companyid': ds_out['companyid'],
    })

    outfile = positive_dir / "{}_positive_bert.csv".format(
        subsegment_name_processing(selected_subsegment)
    )
    out_df.to_csv(outfile, index=False)
    print(selected_subsegment + ' prediction finished -> ' + str(outfile))


if __name__ == "__main__":
    # Library versions
    print("Loaded library versions:")
    print(" torch", torch.__version__)
    print(" transformers", transformers.__version__)
    print(" datasets", datasets.__version__)

    try:
        import accelerate
        print(" accelerate", accelerate.__version__)
    except Exception:
        pass

    # Device info
    print("Platform:", platform.system())
    print("Using base directory:", DIR)
    print("MPS available:", is_mps_available())

    # Data loading
    df_pb_company = pd.read_csv(DIR / 'pbcompanies_new_additions.csv')
    df_market_map = pd.read_csv(DIR / 'pbmarketmap_v2.csv')

    # Prepare subsegment list
    df_market_map = df_market_map[~(df_market_map['description'].isna())]
    df_subsegment = df_market_map.groupby(["marketmap", "segment", "subsegment"], as_index=False)[["companyid"]].count()
    df_subsegment['fullname'] = df_subsegment['marketmap'] + '|' + df_subsegment['segment'] + '|' + df_subsegment['subsegment']
    df_market_map['fullname'] = df_market_map['marketmap'] + '|' + df_market_map['segment'] + '|' + df_market_map['subsegment']
    ls_subsegment = df_subsegment['fullname'].to_list()

    # Logging setup
    logging.basicConfig(filename=DIR / "predict_errors.log", level=logging.ERROR)
    error_list: list[int] = []
    finished_list: list[int] = []

    use_mps = IS_MAC and is_mps_available()

    for i in range(START_INDEX, END_INDEX):
        try:
            predict_for_subsegment(
                i=i,
                df_pb_company=df_pb_company,
                df_market_map=df_market_map,
                df_subsegment=df_subsegment,
                ls_subsegment=ls_subsegment,
                base_dir=DIR,
                use_mps=use_mps,
            )
            finished_list.append(i)
        except Exception as e:
            error_list.append(i)
            logging.error("Sub-segment %s failed\n%s", i, traceback.format_exc())
            print(f"Sub-segment {i} failed:", e, file=sys.stderr)

    print("Finished indices:", finished_list)
    print("Errored indices:", error_list)


