import argparse
import subprocess
import sys
from pathlib import Path

from bert_pipeline_lib import outputdir_for_run


def run(script, root, args):
    subprocess.run([sys.executable, str(root / "code" / script)] + args, check=True)


def optional_range_args(args):
    out = []
    if args.start_index is not None:
        out += ["--start-index", str(args.start_index)]
    if args.end_index is not None:
        out += ["--end-index", str(args.end_index)]
    if args.category:
        out += ["--category", args.category]
    return out


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--inputdir", default=None)
    parser.add_argument("--outputdir", default=None)
    parser.add_argument("--start-index", type=int, default=None)
    parser.add_argument("--end-index", type=int, default=None)
    parser.add_argument("--category", default=None)
    parser.add_argument("--model-name", default="bert-base-uncased")
    parser.add_argument("--company-file", default="pbcompanies.csv")
    parser.add_argument("--overwrite", action="store_true")
    parser.add_argument("--force-models", action="store_true")
    parser.add_argument("--force-predictions", action="store_true")
    parser.add_argument("--skip-training", action="store_true")
    parser.add_argument("--skip-prediction", action="store_true")
    args = parser.parse_args()

    root = Path(__file__).resolve().parents[1]
    inputdir = Path(args.inputdir) if args.inputdir else root / "inputdata"
    outputdir = outputdir_for_run(Path(args.outputdir) if args.outputdir else root / "outputdata", args.overwrite)
    outputdir.mkdir(parents=True, exist_ok=True)

    common = ["--inputdir", str(inputdir), "--outputdir", str(outputdir)]
    run("01_prepare_manifest.py", root, common)

    selected = optional_range_args(args)
    if not args.skip_training:
        train_args = common + selected + ["--model-name", args.model_name]
        if args.force_models:
            train_args.append("--force")
        run("02_train_bert_categories.py", root, train_args)

    if not args.skip_prediction:
        predict_args = common + selected + ["--model-name", args.model_name, "--company-file", args.company_file]
        if args.force_predictions:
            predict_args.append("--force")
        run("03_predict_companies.py", root, predict_args)

    run("04_make_predicted_positive.py", root, common + ["--overwrite"])
    run("05_make_company_level_predictions.py", root, common + ["--company-file", args.company_file, "--overwrite"])
    print(f"Workflow complete. Outputs are in {outputdir}")


if __name__ == "__main__":
    main()
