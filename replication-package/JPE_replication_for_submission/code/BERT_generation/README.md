# Expensive ML layer — original code + provenance

The JPE replication package reproduces every exhibit **from raw data**, with one sanctioned
exception: three machine-learning layers that are too computationally intensive to regenerate in the
Stage-A pipeline and are not bit-reproducible. Their outputs ship *frozen* in the package at
`confidential-data-not-for-publication/Raw/BERT_prediction_resource/`.

This folder holds the **original author code** that produced those frozen files, organized by layer,
with machine-specific paths replaced by `PATH_TO_*` placeholders or environment variables so a
replicator can rerun any stage. **Rerunning is optional** — the frozen outputs are provided as
inputs to the rest of the pipeline, and BERT/SBERT training will not reproduce the exact numbers
(random splits, initialization, batch order, hardware kernels, and library versions all shift
results).

**Start with [`PROVENANCE.md`](PROVENANCE.md)** — it maps every frozen file to the script(s),
model, inputs, and compute cost that produced it, and states which file in this folder is the
authoritative producer of which output.

## Layout

```
1_company_bert/           Company market-map BERT classifier -> company_level_predictions_v2.dta
  train_predict_v2-1.ipynb            authoritative production run: trains one model per category
                                      AND predicts the full company corpus in the same loop
  train_predict_crossvalidate_mac.py  same training recipe in script form (later retrain;
                                      the in-loop prediction block is preserved, commented)
  predict_only.py                     inference-only driver for saved models
2_company_similarity/     SBERT business-description similarity -> similarity_compiled.csv,
                          similarity_compiled_western.csv, similarity_at_sector_x_country_x_year.dta
  similarity_mac.ipynb                embeds descriptions + within-sector pairwise cosine
  similarity_clean.py                 aggregates pairwise scores to company level vs China/US
  similarity_clean.ipynb              single-sector walkthrough of the same aggregation + the
                                      "compile all cleaned files" cells -> similarity_compiled.csv
  similarity_clean_detail_western.py  western/non-western split of the Chinese reference firms
  similarity_compile_2025.ipynb       compiles the western (and other later) variants
3_patent_ml/              Patent BERT sector-labeling + patent similarity -> patent_sector_labels_*.dta,
                          patent_countrysector_similarity_*.dta, worldwide_pairs_filtered_*.dta
  train_predict_patent_full.ipynb     first-round train+predict notebook (grant-year run)
  train_predict_pat01.ipynb           authoritative trainer for the new run: one model per
                                      subsegment -> SUBSEGMENT-*/best_model, plus prediction
  patent_additional_prediction_win.ipynb            re-predicts sectors that failed first pass
  patent_additional_prediction_100k_china_win.ipynb prediction sample incl. China -> the shards
                                                    behind positive_results_100k_new*
  patent_prediction_analysis.ipynb        compiles first-round shards -> positive_results_100k.csv
  patent_prediction_analysis_new100k.ipynb compiles new-run shards -> positive_results_100k_new*.dta
  make_patent_sector_labels.py            subsets positive_results_* into the three shipped
                                          patent_sector_labels_*.dta (verified bit-identical)
  patent_similarity.{ipynb,py}            SBERT cross-country patent-abstract similarity
  patent_family_exercise.ipynb            PATSTAT family exercise -> worldwide_pairs_filtered_*
  hpc_inference/                          SLURM setup for full-corpus inference (own README)
reference_reconstruction/
  bert_company/           A clean, faithful re-implementation of Layer 1 (optional runnable reference)
PROVENANCE.md             Frozen file -> producing script -> model -> inputs -> cost
requirements.txt          Python environment
```

## Models (see PROVENANCE.md for the full recipes)

- **Company classifier**: `bert-base-uncased`, `num_labels=2`, one binary model per
  `fullname = marketmap|segment|subsegment`; keep predictions with `pred_pos > pred_neg`.
- **Patent classifier**: `bert-base-uncased`, `num_labels=2`, one binary model per subsegment;
  epoch-level checkpointing with `load_best_model_at_end` (the saved model is `best_model/`).
- **Similarity** (companies and patents): SBERT `all-distilroberta-v1`, normalized embeddings,
  cosine similarity.

Trained weights are not shipped (hundreds of GB). They are retained in the author archive
(external SSDs; the patent models are also mirrored on a university HPC cluster), along with the
per-category training/evaluation metrics.

## Running a stage

1. Install the environment (a fresh venv/conda is strongly recommended; `numpy<2` avoids a known
   `sentence-transformers`/`scikit-learn` binary incompatibility):

   ```bash
   python3 -m pip install -r requirements.txt
   ```

2. Point the scripts at the confidential data root. The `.py` files read these environment
   variables (their in-code defaults are `PATH_TO_*` placeholders — set the variables before
   running); the `.ipynb` notebooks take the same locations as literals in their first cell —
   substitute your paths there before running:

   ```bash
   # the EntTemplates folder that contains Analysis/ (PitchBook, PatentsView, similarity data):
   export EXPENSIVE_ML_ROOT="/path/to/EntTemplates"
   # scratch/model store for the COMPANY BERT layer:
   export BERT_WORK_ROOT="/path/to/bert_work"
   # folder of trained per-subsegment PATENT BERT models (SUBSEGMENT-*/best_model):
   export PATENT_MODEL_DIR="/path/to/PatentSubsegmentFolders"
   ```

3. Run the stage. The production training/prediction runs were executed in **index-range chunks**
   (each script/notebook has `start`/`end` indices near the bottom, left at their last-run values) —
   sweep the chunks from 0 to the end of the category list to cover all ~290 company categories or
   ~220 patent subsegments:

   ```bash
   # Layer 1: the original run trains AND predicts per category in one loop (very expensive)
   #   authoritative notebook: 1_company_bert/train_predict_v2-1.ipynb
   #   script form of the training recipe:
   python3 1_company_bert/train_predict_crossvalidate_mac.py
   #   inference-only over saved models (set the input CSV in the script; the original
   #   full-corpus prediction used pbcompanies.csv):
   python3 1_company_bert/predict_only.py

   # Layer 2: aggregate per-sector pairwise similarity to company level, then compile
   python3 2_company_similarity/similarity_clean.py
   #   (embedding + pairwise: similarity_mac.ipynb; compile cells: similarity_clean.ipynb)

   # Layer 3: train per-subsegment patent models + predict (train_predict_pat01.ipynb),
   #   then compile shards (patent_prediction_analysis_new100k.ipynb), then reproduce the
   #   frozen patent_sector_labels_*.dta subsets:
   python3 3_patent_ml/make_patent_sector_labels.py
   #   large-scale inference on a SLURM cluster: see 3_patent_ml/hpc_inference/README.md
   ```

## Caveats

- **Not bit-reproducible.** Expect different logits and downstream counts on any rerun. The frozen
  outputs in the package are the numbers behind the paper.
- **Confidential inputs required.** These scripts consume PitchBook, PatentsView, and PATSTAT data,
  which are not bundled here.
- **`.py` vs `.ipynb`.** Where both exist, the `.py` is the readable/runnable form and the `.ipynb`
  is the authoritative record of the production run (e.g. `patent_similarity.{py,ipynb}` — the
  `.py` encodes the 500k variant; the frozen 100k file came from the notebook with the filenames
  toggled; see PROVENANCE.md).
- **Run-specific constants are preserved.** Chunk indices, sample seeds, and skip-if-output-exists
  guards are left exactly as in the production runs.

## Optional: clean re-implementation of Layer 1

`reference_reconstruction/bert_company/` is a self-contained, faithful re-implementation of the
Layer-1 company classifier (same model, hyperparameters, and decision rule as the original scripts;
it is NOT the producer of any shipped file). To run it: place `pbmarketmap_v2.csv` and
`pbcompanies.csv` (columns: companyid, marketmap, segment, subsegment, description) in its
`inputdata/`, install its `requirements.txt`, and run the numbered scripts in `code/` in order
(`00_run_all.py` drives the full chain). The same non-reproducibility caveat applies.
