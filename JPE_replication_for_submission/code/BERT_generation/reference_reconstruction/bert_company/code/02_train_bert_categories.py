import argparse
import inspect
from pathlib import Path

from datasets import Dataset, DatasetDict
from transformers import AutoModelForSequenceClassification, AutoTokenizer, Trainer, TrainingArguments, set_seed

from bert_pipeline_lib import (
    compute_binary_metrics,
    make_training_frames,
    read_manifest,
    load_market_map,
    select_categories,
    write_json,
)


def training_args_for(model_dir, stats_dir, args):
    kwargs = {
        "output_dir": str(model_dir),
        "num_train_epochs": args.num_train_epochs,
        "gradient_accumulation_steps": args.gradient_accumulation_steps,
        "per_device_train_batch_size": args.train_batch_size,
        "per_device_eval_batch_size": args.eval_batch_size,
        "logging_dir": str(stats_dir / "logs"),
        "logging_steps": args.logging_steps,
        "report_to": "none",
        "save_strategy": "no",
        "seed": args.seed,
    }
    signature = inspect.signature(TrainingArguments.__init__)
    if "eval_strategy" in signature.parameters:
        kwargs["eval_strategy"] = "epoch"
    else:
        kwargs["evaluation_strategy"] = "epoch"
    if args.use_mps and "use_mps_device" in signature.parameters:
        kwargs["use_mps_device"] = True
    return TrainingArguments(**kwargs)


def tokenize_frames(tokenizer, train_df, valid_df, test_df):
    datasets = DatasetDict({
        "train": Dataset.from_pandas(train_df, preserve_index=False),
        "valid": Dataset.from_pandas(valid_df, preserve_index=False),
        "test": Dataset.from_pandas(test_df, preserve_index=False),
    })

    def tokenize(batch):
        return tokenizer(batch["description"], padding="max_length", truncation=True)

    return datasets.map(tokenize, batched=True)


def train_one_category(row, market_map, args):
    fullname = row["fullname"]
    clean_name = row["clean_fullname"]
    model_dir = Path(args.outputdir) / "models" / f"SUBSEGMENT-{clean_name}"
    stats_dir = Path(args.outputdir) / "stats" / f"SUBSEGMENT-{clean_name}"

    if model_dir.exists() and any(model_dir.iterdir()) and not args.force:
        print(f"Skipping existing model: {model_dir}")
        return

    train_df, valid_df, test_df, split_summary = make_training_frames(
        market_map=market_map,
        fullname=fullname,
        seed=args.seed + int(row["category_index"]),
        adjacent_threshold=args.adjacent_threshold,
        negatives_per_segment=args.negatives_per_segment,
    )

    model_dir.mkdir(parents=True, exist_ok=True)
    stats_dir.mkdir(parents=True, exist_ok=True)
    write_json(stats_dir / "split_summary.json", split_summary)

    tokenizer = AutoTokenizer.from_pretrained(args.model_name)
    tokenized = tokenize_frames(tokenizer, train_df, valid_df, test_df)
    model = AutoModelForSequenceClassification.from_pretrained(args.model_name, num_labels=2)

    trainer = Trainer(
        model=model,
        args=training_args_for(model_dir, stats_dir, args),
        train_dataset=tokenized["train"],
        eval_dataset=tokenized["valid"],
        compute_metrics=lambda eval_pred: compute_binary_metrics(eval_pred.predictions, eval_pred.label_ids),
    )

    print(f"Training {int(row['category_index'])}: {fullname}")
    trainer.train()
    eval_results = trainer.evaluate(eval_dataset=tokenized["valid"])
    test_results = trainer.evaluate(eval_dataset=tokenized["test"])
    write_json(stats_dir / "eval_results.json", eval_results)
    write_json(stats_dir / "test_results.json", test_results)
    trainer.save_model(model_dir)
    tokenizer.save_pretrained(model_dir)
    print(f"Saved model to {model_dir}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--inputdir", default="inputdata")
    parser.add_argument("--outputdir", default="outputdata")
    parser.add_argument("--start-index", type=int, default=None)
    parser.add_argument("--end-index", type=int, default=None)
    parser.add_argument("--category", default=None)
    parser.add_argument("--model-name", default="bert-base-uncased")
    parser.add_argument("--num-train-epochs", type=float, default=5)
    parser.add_argument("--gradient-accumulation-steps", type=int, default=16)
    parser.add_argument("--train-batch-size", type=int, default=2)
    parser.add_argument("--eval-batch-size", type=int, default=8)
    parser.add_argument("--logging-steps", type=int, default=10)
    parser.add_argument("--adjacent-threshold", type=int, default=100)
    parser.add_argument("--negatives-per-segment", type=int, default=15)
    parser.add_argument("--seed", type=int, default=20240629)
    parser.add_argument("--use-mps", action="store_true")
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()

    set_seed(args.seed)
    market_map = load_market_map(args.inputdir)
    manifest = read_manifest(args.inputdir, args.outputdir)
    selected = select_categories(manifest, args.start_index, args.end_index, args.category)

    for _, row in selected.iterrows():
        train_one_category(row, market_map, args)


if __name__ == "__main__":
    main()
