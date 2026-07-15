import argparse

from bert_pipeline_lib import load_market_map, write_manifest


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--inputdir", default="inputdata")
    parser.add_argument("--outputdir", default="outputdata")
    args = parser.parse_args()

    market_map = load_market_map(args.inputdir)
    manifest = write_manifest(market_map, args.outputdir)
    print(f"Wrote {len(manifest)} categories to {args.outputdir}/category_manifest.csv")


if __name__ == "__main__":
    main()
