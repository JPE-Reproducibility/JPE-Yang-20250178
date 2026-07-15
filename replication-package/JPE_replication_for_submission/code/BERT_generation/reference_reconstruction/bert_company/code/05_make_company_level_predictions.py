import argparse
from pathlib import Path

import pandas as pd

from bert_pipeline_lib import load_company_header, write_empty_csv


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--inputdir", default="inputdata")
    parser.add_argument("--outputdir", default="outputdata")
    parser.add_argument("--company-file", default="pbcompanies.csv")
    parser.add_argument("--max-slots", type=int, default=12)
    parser.add_argument("--overwrite", action="store_true")
    args = parser.parse_args()

    outputdir = Path(args.outputdir)
    prediction_path = outputdir / "predicted_positive_v2.csv"
    outfile = outputdir / "company_level_predictions_v2.csv"
    if outfile.exists() and not args.overwrite:
        raise FileExistsError(f"{outfile} already exists. Use --overwrite or a new --outputdir.")
    if outfile.exists():
        outfile.unlink()

    columns = ["companyid", "hqcountry"]
    company_header = load_company_header(args.inputdir, args.company_file)
    usecols = [column for column in columns if column in company_header]
    companies = pd.read_csv(Path(args.inputdir) / args.company_file, usecols=usecols).drop_duplicates("companyid")

    predicted = pd.read_csv(prediction_path)
    if predicted.empty:
        fieldnames = ["companyid", "hqcountry"]
        for slot in range(1, args.max_slots + 1):
            fieldnames.extend([f"fullname{slot}", f"marketmap{slot}", f"segment{slot}", f"subsegment{slot}"])
        write_empty_csv(outfile, fieldnames)
        print(f"Wrote empty {outfile}")
        return

    predicted["num_subseg"] = predicted.groupby("companyid").cumcount() + 1
    predicted = predicted[predicted["num_subseg"] <= args.max_slots].copy()

    base = predicted[["companyid"]].drop_duplicates().merge(companies, on="companyid", how="left")
    if "hqcountry" not in base.columns:
        base["hqcountry"] = ""

    wide = base.copy()
    for slot in range(1, args.max_slots + 1):
        slot_rows = predicted[predicted["num_subseg"] == slot][
            ["companyid", "fullname", "marketmap", "segment", "subsegment"]
        ].copy()
        slot_rows = slot_rows.rename(columns={
            "fullname": f"fullname{slot}",
            "marketmap": f"marketmap{slot}",
            "segment": f"segment{slot}",
            "subsegment": f"subsegment{slot}",
        })
        wide = wide.merge(slot_rows, on="companyid", how="left")

    fieldnames = ["companyid", "hqcountry"]
    for slot in range(1, args.max_slots + 1):
        fieldnames.extend([f"fullname{slot}", f"marketmap{slot}", f"segment{slot}", f"subsegment{slot}"])
    wide[fieldnames].to_csv(outfile, index=False)
    print(f"Wrote {len(wide)} companies to {outfile}")


if __name__ == "__main__":
    main()
