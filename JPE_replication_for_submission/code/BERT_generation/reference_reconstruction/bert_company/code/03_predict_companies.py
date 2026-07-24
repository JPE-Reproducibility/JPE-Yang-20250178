import argparse
from pathlib import Path

import numpy as np
import pandas as pd
from datasets import Dataset
from transformers import AutoModelForSequenceClassification, AutoTokenizer, Trainer, TrainingArguments

from bert_pipeline_lib import load_company_header, read_manifest, select_categories


def prediction_args_for(model_dir, args):
    return TrainingArguments(
        output_dir=str(model_dir),
        per_device_eval_batch_size=args.prediction_batch_size,
        report_to="none",
    )


def predict_one_category(row, args):
    clean_name = row["clean_fullname"]
    model_dir = Path(args.outputdir) / "models" / f"SUBSEGMENT-{clean_name}"
    outfile = Path(args.outputdir) / "positive_v2" / f"{clean_name}_positive_bert.csv"

    if not model_dir.exists():
        raise FileNotFoundError(f"Model directory not found: {model_dir}")
    if outfile.exists() and not args.force:
        print(f"Skipping existing prediction file: {outfile}")
        return

    outfile.parent.mkdir(parents=True, exist_ok=True)
    if outfile.exists():
        outfile.unlink()

    try:
        tokenizer = AutoTokenizer.from_pretrained(model_dir)
    except Exception:
        tokenizer = AutoTokenizer.from_pretrained(args.model_name)
    model = AutoModelForSequenceClassification.from_pretrained(model_dir)
    trainer = Trainer(
        model=model,
        args=prediction_args_for(model_dir, args),
        tokenizer=tokenizer,
    )

    company_path = Path(args.inputdir) / args.company_file
    header_written = False
    usecols = [column for column in ["companyid", "description"] if column in load_company_header(args.inputdir, args.company_file)]

    print(f"Predicting {int(row['category_index'])}: {row['fullname']}")
    for chunk in pd.read_csv(company_path, usecols=usecols, chunksize=args.company_chunksize):
        chunk = chunk[~chunk["description"].isna()].copy()
        chunk["description"] = chunk["description"].astype(str)
        chunk = chunk[chunk["description"].str.len() > 0].copy()
        if chunk.empty:
            continue

        ds_out = chunk[["description", "companyid"]].reset_index(drop=True)
        ds_out["label"] = 0
        ds_out["description"] = ds_out["description"].str.lower()

        dataset = Dataset.from_pandas(ds_out, preserve_index=False)

        def tokenize(batch):
            return tokenizer(batch["description"], padding="max_length", truncation=True)

        tokenized = dataset.map(tokenize, batched=True)
        predictions = trainer.predict(tokenized).predictions
        out_df = pd.DataFrame({
            "pred_pos": predictions[:, 1],
            "pred_neg": predictions[:, 0],
            "positive": np.argmax(predictions, axis=-1),
            "description": ds_out["description"],
            "companyid": ds_out["companyid"],
        })
        out_df.to_csv(outfile, index=False, mode="a", header=not header_written)
        header_written = True

    print(f"Wrote predictions to {outfile}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--inputdir", default="inputdata")
    parser.add_argument("--outputdir", default="outputdata")
    parser.add_argument("--company-file", default="pbcompanies.csv")
    parser.add_argument("--start-index", type=int, default=None)
    parser.add_argument("--end-index", type=int, default=None)
    parser.add_argument("--category", default=None)
    parser.add_argument("--model-name", default="bert-base-uncased")
    parser.add_argument("--company-chunksize", type=int, default=50000)
    parser.add_argument("--prediction-batch-size", type=int, default=32)
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()

    manifest = read_manifest(args.inputdir, args.outputdir)
    selected = select_categories(manifest, args.start_index, args.end_index, args.category)
    load_company_header(args.inputdir, args.company_file)

    for _, row in selected.iterrows():
        predict_one_category(row, args)


if __name__ == "__main__":
    main()
