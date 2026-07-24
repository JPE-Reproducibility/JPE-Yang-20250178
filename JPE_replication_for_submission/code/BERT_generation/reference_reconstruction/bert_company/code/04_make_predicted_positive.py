import argparse
import re
from pathlib import Path

import pandas as pd

from bert_pipeline_lib import load_market_map, category_manifest, write_empty_csv


FIELDNAMES = [
    "pred_pos",
    "pred_neg",
    "description",
    "companyid",
    "subseg_name",
    "fullname",
    "marketmap",
    "segment",
    "subsegment",
    "count_TP",
]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--inputdir", default="inputdata")
    parser.add_argument("--outputdir", default="outputdata")
    parser.add_argument("--chunksize", type=int, default=200000)
    parser.add_argument("--overwrite", action="store_true")
    args = parser.parse_args()

    outputdir = Path(args.outputdir)
    outfile = outputdir / "predicted_positive_v2.csv"
    if outfile.exists() and not args.overwrite:
        raise FileExistsError(f"{outfile} already exists. Use --overwrite or a new --outputdir.")
    if outfile.exists():
        outfile.unlink()

    manifest = category_manifest(load_market_map(args.inputdir))
    metadata = manifest.set_index("clean_fullname")[["fullname", "marketmap", "segment", "subsegment", "count_TP"]].to_dict("index")

    wrote_any = False
    for path in sorted((outputdir / "positive_v2").glob("*_positive_bert.csv")):
        match = re.match(r"(.*)_positive_bert\.csv", path.name)
        if not match:
            continue
        subseg_name = match.group(1)
        if subseg_name not in metadata:
            print(f"Skipping prediction file with no market-map match: {path.name}")
            continue
        meta = metadata[subseg_name]
        for chunk in pd.read_csv(path, chunksize=args.chunksize):
            filtered = chunk[chunk["pred_pos"] > chunk["pred_neg"]].copy()
            if filtered.empty:
                continue
            filtered["subseg_name"] = subseg_name
            filtered["fullname"] = meta["fullname"]
            filtered["marketmap"] = meta["marketmap"]
            filtered["segment"] = meta["segment"]
            filtered["subsegment"] = meta["subsegment"]
            filtered["count_TP"] = meta["count_TP"]
            filtered = filtered[FIELDNAMES]
            filtered.to_csv(outfile, mode="a", header=not wrote_any, index=False)
            wrote_any = True

    if not wrote_any:
        write_empty_csv(outfile, FIELDNAMES)
    print(f"Wrote {outfile}")


if __name__ == "__main__":
    main()
