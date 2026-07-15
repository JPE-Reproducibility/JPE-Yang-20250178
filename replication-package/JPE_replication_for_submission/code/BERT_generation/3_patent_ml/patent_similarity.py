import os
import math
import pandas as pd
from pathlib import Path
import plotly.graph_objects as go

from multiprocessing import get_context, cpu_count
import numpy as np
from sentence_transformers import SentenceTransformer
from tqdm.auto import tqdm

os.environ.setdefault("TOKENIZERS_PARALLELISM", "false")

N_CORES = 15

_EMB = None
_COUNTRIES = None
_PATENT_IDS = None
_SECTOR = None


def _init_worker(embeddings, countries, patent_ids, sector):
    global _EMB, _COUNTRIES, _PATENT_IDS, _SECTOR
    _EMB = embeddings
    _COUNTRIES = countries
    _PATENT_IDS = patent_ids
    _SECTOR = sector


def _process_i_range(args):
    start_i, end_i = args
    results = []
    emb = _EMB
    countries = _COUNTRIES
    patent_ids = _PATENT_IDS
    sector = _SECTOR
    n = len(emb)

    for i in range(start_i, end_i):
        emb_i = emb[i]
        country_i = countries[i]
        pid_i = patent_ids[i]
        for j in range(i + 1, n):
            if country_i == countries[j]:
                continue
            score = float(np.dot(emb_i, emb[j]))
            results.append({
                "patent_id1": pid_i,
                "patent_id2": patent_ids[j],
                "country1": country_i,
                "country2": countries[j],
                "sbert_score": score,
                "sector": sector,
            })

    return start_i, end_i, results


def _pairs_in_range(start_i, end_i, n):
    if end_i <= start_i:
        return 0
    count = end_i - start_i
    return int(count * (n - 1) - (start_i + end_i - 1) * count / 2)

def main():
    # set directories
    # path parameterized: data root = the EntTemplates folder containing Analysis/
    ENT_ROOT = Path(os.environ.get("EXPENSIVE_ML_ROOT", "PATH_TO_ENTTEMPLATES_DATA_ROOT"))
    data_dir = ENT_ROOT / 'Analysis' / 'python_Patent' / 'data'
    output_dir = ENT_ROOT / 'Analysis' / 'python_Patent' / 'output'

    #df_predictions = pd.read_csv(ENT_ROOT / 'Analysis/python_BERT/data_patent/positive_results_100k_.csv', dtype=str)
    df_predictions = pd.read_stata(ENT_ROOT / 'Analysis/python_BERT/data_patent/positive_results_500k_new.dta')
    # drop "index" column if exists
    if 'index' in df_predictions.columns:
        df_predictions = df_predictions.drop(columns=['index'])
    df_patent = pd.read_csv(data_dir / 'g_patent.tsv', sep='\t', dtype=str)
    # merge to get abstract
    df_predictions = df_predictions.merge(df_patent[['patent_id','patent_abstract']], on='patent_id', how='left')

    # get the first four digit of patent_date, and only keep if the first four digit is between 2000 and 2013. Drop if missing values
    df_predictions = df_predictions[df_predictions['patent_year'].between(2000, 2013)]
    df_predictions = df_predictions[['patent_id', 'patent_date', 'patent_year','disambig_country','file',  'patent_abstract']]
    # rename file to sector
    df_predictions = df_predictions.rename(columns={'file': 'sector'})
    df_predictions['patent_id'].nunique()
    del df_patent

    model = SentenceTransformer("all-distilroberta-v1")

    df_sbert_input = (
        df_predictions
        .dropna(subset=["patent_abstract", "disambig_country", "sector"])
        .reset_index(drop=True)
     )

    groups = list(df_sbert_input.groupby("sector"))
    output_dir_progress = output_dir / "progress_500k"
    output_dir_progress.mkdir(parents=True, exist_ok=True)

    for sector, grp in tqdm(groups, desc="Sectors"):
        progress_file = output_dir_progress / f"pairwise_{sector}.parquet"
        if progress_file.exists():
            tqdm.write(f"Skip {sector}: {progress_file.name} exists")
            continue

        grp = grp.reset_index(drop=True)
        embeddings = model.encode(
            grp["patent_abstract"].tolist(),
            convert_to_numpy=True,
            normalize_embeddings=True,
        )
        n = len(grp)
        countries = grp["disambig_country"].tolist()
        patent_ids = grp["patent_id"].tolist()

        n_cores = min(N_CORES, n) if n > 0 else 1
        chunk_size = max(1, math.ceil(n / n_cores))
        i_ranges = [(i, min(i + chunk_size, n)) for i in range(0, n, chunk_size)]
        total_pairs = n * (n - 1) // 2

        sector_pairs = []
        ctx = get_context("spawn")
        with ctx.Pool(
            processes=n_cores,
            initializer=_init_worker,
            initargs=(embeddings, countries, patent_ids, sector),
        ) as pool:
            with tqdm(
                total=total_pairs,
                desc=f"{sector} pairs",
                leave=False,
            ) as pbar:
                for start_i, end_i, part in pool.imap_unordered(_process_i_range, i_ranges):
                    sector_pairs.extend(part)
                    pbar.update(_pairs_in_range(start_i, end_i, n))

        df_sector_pairs = pd.DataFrame(sector_pairs)
        df_sector_pairs.to_parquet(progress_file, index=False)
        tqdm.write(f"Wrote {len(df_sector_pairs)} rows for {sector} -> {progress_file.name}")

        del sector_pairs
        del df_sector_pairs
        del embeddings

    progress_files = sorted(output_dir_progress.glob("pairwise_*.parquet"))
    if not progress_files:
        raise FileNotFoundError(f"No progress files found in {output_dir_progress}")

    df_pairwise_similarity = pd.concat(
        [pd.read_parquet(pf) for pf in progress_files],
        ignore_index=True,
    )

    print(f"Total pairs across sectors: {len(df_pairwise_similarity)}")

    df_pairwise_similarity.to_parquet(
        output_dir / "patent_pairwise_similarity_2000_2013_500k_new_china.parquet",
        index=False,)


if __name__ == '__main__':
    main()
