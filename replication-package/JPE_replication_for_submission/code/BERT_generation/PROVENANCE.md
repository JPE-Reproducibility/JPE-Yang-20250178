# Provenance: the expensive ML layer

This folder documents and ships the **original author code** for the three machine-learning
layers whose outputs are shipped *frozen* in the replication package at
`confidential-data-not-for-publication/Raw/BERT_prediction_resource/`.

These outputs are the one sanctioned exception to the "everything from raw" rule: they are too
computationally intensive to regenerate as part of the Stage-A pipeline, and BERT/SBERT training
is not bit-reproducible (random splits, initialization, batch order, hardware kernels, library
versions). **A rerun is therefore optional** — the frozen outputs are provided as inputs to the
rest of the pipeline. This document maps every frozen file to the script(s) that produced it.

Paths below are given both as the copy shipped **in this folder** and as the **original location**
in the author tree (`EntTemplates/Analysis/...`). Trained model weights are not shipped; they are
retained in the author archive (external SSDs; the patent models are also mirrored on a university
HPC cluster), together with the per-category training/evaluation metrics.

## Model recipes

| | Company classifier | Patent classifier | Similarity |
|---|---|---|---|
| Model | `bert-base-uncased`, `num_labels=2` | `bert-base-uncased`, `num_labels=2` | SBERT `all-distilroberta-v1` |
| Unit | one binary classifier per `fullname = marketmap\|segment\|subsegment` | one binary classifier per subsegment | — |
| Training set | positives = the category; negatives = adjacent-segment sample (cap 100) + per-segment downsample (15) | positives = the category's matched patents, resampled to 1,000; negatives = per-segment downsample + adjacent-segment sample matched in size | — |
| Training args | 5 epochs, `gradient_accumulation_steps=16`, `per_device_train_batch_size=2`, final model saved | 5 epochs, `per_device_train_batch_size=16`, epoch-level eval/checkpointing, `load_best_model_at_end` → saved as `best_model/` | — |
| Decision rule | keep predictions with `pred_pos > pred_neg` | keep `positive == 1` | normalized embeddings, cosine similarity |

---

## Layer 1 — company market-map prediction → `company_level_predictions_v2.dta`

**Producing chain**

1. `1_company_bert/train_predict_v2-1.ipynb` — the authoritative production run (March 2023): for
   each `fullname`, train one `bert-base-uncased` classifier AND predict every company description
   in `pbcompanies.csv` in the same loop, writing per-category
   `pbmarketmap_v2/positive/<clean_fullname>_positive_bert.csv` with
   `pred_pos, pred_neg, positive, description, companyid`. The ~295 categories were swept in
   index-range chunks (`start`/`end` in the last cell, left at their final-chunk values).
   *(orig: `python_BERT/codes/train_predict_v2-1.ipynb`; shards and per-category eval metrics in
   `python_BERT/data_v2/`.)*
2. **Stata hand-off** (performed in the original production pipeline; the shipped
   `01_generate_analysis_v2.do` consumes the finished file): L470–507 read the positive CSVs, keep
   `pred_pos > pred_neg`, merge `pbmarketmap_v2`, save `predicted_positive_v2.dta`; L560–583 number
   each company's subsegments, `reshape wide`, split the taxonomy string →
   **`company_level_predictions_v2.dta`** (402,695 companies × ordered
   `fullname#`/`marketmap#`/`segment#`/`subsegment#` slots).

**Later runs of the same recipe (shipped for completeness):**
`1_company_bert/train_predict_crossvalidate_mac.py` is the script form of the identical training
recipe, used for a 2025 retrain of the category models (the in-loop prediction block is preserved,
commented out); its Windows twin is `train_predict_crossvalidate_win.ipynb` in the author tree.
`1_company_bert/predict_only.py` is the standalone inference driver over saved category models —
as shipped it reads `pbcompanies_new_additions.csv` (the 2022–24 data refresh, which the package
classifies from the raw PitchBook market map instead); point it at `pbcompanies.csv` to reproduce
the original full-corpus prediction step.

**Inputs:** `pbmarketmap_v2.csv` (companyid, marketmap, segment, subsegment, description),
`pbcompanies.csv` (companyid, description).
**Consumed in the package by:** `01_generate_analysis_v2.do`, `03c_generate_regression_auxiliary.do`,
`05c_generate_regression_alltype_by_cat.do`, `05d_generate_dealcount_alltype_cluster.do`,
`05h_generate_deal_22_24.do`, `07d_generate_analysis_city.do`.
**Cost:** very high — ~295 categories × (train 5 epochs + predict over ~400k descriptions).

---

## Layer 2 — business-description similarity → `similarity_compiled.csv`, `similarity_compiled_western.csv`, `similarity_at_sector_x_country_x_year.dta`

**Producing chain**

1. **Embeddings + pairwise** — `2_company_similarity/similarity_mac.ipynb` encodes every company
   description with `SentenceTransformer('all-distilroberta-v1')` → `company_embedding_ST`
   (pickle), then computes within-sector pairwise cosine → per-sector
   `output/similarity_ST_<sector>.csv` with `companyid1, companyid2, similarity`.
   *(orig: `python_Similarity/codes/similarity_mac.ipynb`.)*
2. **Aggregate to company level** — `2_company_similarity/similarity_clean.py`: per sector, keep
   pairs where exactly one endpoint is a China- or US-headquartered firm, orient each pair so
   `companyid1` is the non-China/US firm, and compute that firm's mean/10th/25th-percentile
   similarity vs Chinese and vs US firms, plus the `_afteronly` variants restricted to
   `yearfounded1 > yearfounded2` → `<sector>_processed.csv`. Run on a dedicated Windows
   workstation over the per-sector pairwise files.
   *(orig: `python_Similarity/codes/similarity_clean.py` → `processed/`.)*
3. **Compile** — `2_company_similarity/similarity_clean.ipynb`, "Compile all cleaned files
   together" cells: concatenate `processed/` → **`similarity_compiled.csv`**. (The notebook's
   earlier cells are a single-sector walkthrough of step 2; its other compile cells produced
   placebo/detail variants not used by the paper.)
4. **Western split** — `2_company_similarity/similarity_clean_detail_western.py` repeats step 2
   splitting the Chinese reference firms by `any_deal_western` → `processed_western/`;
   `2_company_similarity/similarity_compile_2025.ipynb` (western section) concatenates →
   **`similarity_compiled_western.csv`**. (That notebook's country-sector sections produced files
   not used by the paper.)
5. **Sector×country×year panel** — the original regression prep collapsed `analysis_v2.dta` (which
   carries the merged company-level similarity columns) by `fullname × hqcountry × year`, dropping
   China and the US, summing `first_deal/early/late` and averaging the `china_*`/`us_*` similarity
   columns → **`similarity_at_sector_x_country_x_year.dta`**. *(orig:
   `Stata/codes/regressions_similarity.do`; the package's `05f_generate_similarity_western.do`
   performs the same collapse for the western variant.)*

**Inputs:** company descriptions + `hqcountry`/`yearfounded`/`firstfinancingdate` from
`pbcompanies.dta`; sector membership (`fullname`) from `pbmarketmap_v2` / `analysis_v2`; western
flag from `company_china_western_or_not.dta`.
**Consumed in the package by:** `01_generate_analysis_v2.do`, `04_generate_regression_corrected_120623.do`,
`05f_generate_similarity_western.do`.
**Cost:** high — one-time embedding of ~400k descriptions, then O(n²) pairwise cosine within each
sector.

---

## Layer 3 — patent BERT sector-labeling + patent similarity

### 3a. `patent_sector_labels_grantyear.dta`, `patent_sector_labels_new100k.dta`, `patent_sector_labels_new_grantyear.dta`

These names are **not written by any original script** — they are column subsets/renames of the
`positive_results_*` prediction files. `3_patent_ml/make_patent_sector_labels.py` (written for this
package) reproduces **all three, verified bit-for-bit** against the shipped files:

| Frozen file | Source `positive_results_*` (in `python_BERT/data_patent/`) | Columns kept | Status |
|---|---|---|---|
| `patent_sector_labels_grantyear.dta` | `positive_results_100k.csv` | `patent_id`, `file`→`sector`, `disambig_country`, `patent_date` | **verified identical** |
| `patent_sector_labels_new_grantyear.dta` | `positive_results_100k_new.dta` | `patent_id`, `file`→`sector`, `patent_year`, `disambig_country` | **verified identical** |
| `patent_sector_labels_new100k.dta` | `positive_results_100k_new.dta` + citation restriction | `patent_id`, `sector` = lowercased `file` | **verified identical** |

`patent_sector_labels_new100k.dta` takes one extra step (verified to reproduce all 84,179 patents /
451,328 rows exactly): start from `positive_results_100k_new.dta`, set `sector` = lowercased `file`
(alphanumeric, digits kept — e.g. `...web3security`), keep unique `[patent_id, sector]`, and **restrict
to patents that appear as citing patents in `g_us_patent_citation.tsv` where both the citing and the
cited patent are located** (utility + `assignee_sequence==0` + non-null `disambig_country`). This is the
same both-endpoints-located citation logic the package's `06a_generate_patent_citations_from_raw.py` uses; it is
the one slow step in the helper (it streams the ~9 GB citation table).

**Producers of the source `positive_results_*` files — two independent prediction runs:**

- **First round (grant-year run)** → `positive_results_100k.csv`: per-subsegment shards in
  `python_BERT/data_patent/positive/`, produced by the `train_predict_patent*` notebook family
  (the shipped `3_patent_ml/train_predict_patent_full.ipynb` is the surviving representative of
  that round: same train-and-predict-per-subsegment shape). Compiled by
  `3_patent_ml/patent_prediction_analysis.ipynb` (merge `g_patent` utility ≥2000 + assignee +
  location; drop sectors with <20 training patents).
  *(orig: `python_Patent/codes/train_predict_new/patent_prediction_analysis.ipynb`.)*
- **New run** → `positive_results_100k_new.dta` / `positive_results_100k_new_china.dta`:
  1. `3_patent_ml/train_predict_pat01.ipynb` — the authoritative trainer: one model per
     subsegment on PatentsView×PitchBook-matched patents → `SUBSEGMENT-*/best_model`
     (run on a cloud GPU workspace, slice-based with per-slice progress files), plus prediction
     over its 100k sample (non-US/CN, grant year ≥2000, `random_state=1`).
  2. `3_patent_ml/patent_additional_prediction_win.ipynb` — re-predicts the sectors whose
     first-pass predictions failed or were missing (discovers `SUBSEGMENT-*/best_model` folders,
     skips sectors with existing shards).
  3. `3_patent_ml/patent_additional_prediction_100k_china_win.ipynb` — the prediction run behind
     the compiled files: a fresh 100k sample that **keeps Chinese patents** (drop US only), grant
     years 2000–2019, non-null abstract/country, `random_state=42` →
     `patent_predictions_100k_china/` shards.
  4. `3_patent_ml/patent_prediction_analysis_new100k.ipynb` — compiles the shards (keep
     `positive==1`; filing year via `g_application`; drop poor sectors) →
     `positive_results_100k_new.dta` and the China-inclusive `positive_results_100k_new_china.dta`.
- **Full-corpus inference at scale** — `3_patent_ml/hpc_inference/` (SLURM job template +
  `predict_patent_sectors.py`) documents the cluster path used for the later full-corpus run with
  the same models and filtering logic; it is not the producer of the shipped 100k files. See its
  README.

**Consumed in the package by:** `06b_generate_patent_layers.py`, `06a_generate_patent_citations_from_raw.py`.
**Cost:** very high (train + predict per subsegment over the full utility-patent corpus).

### 3b. `patent_countrysector_similarity_2000_2013_100k_new_china.dta` (Table A5, SBERT)

- **Producer:** `3_patent_ml/patent_similarity.ipynb` (multi-variant workspace) — the readable `.py`
  sibling `3_patent_ml/patent_similarity.py` shows the identical pairwise-encoding logic. *(orig:
  `python_Patent/codes/patent_similarity.{ipynb,py}`; named as the producer at
  `JPE_revision_suitvalid.do:62`.)*
- **Model:** `all-distilroberta-v1`, normalized embeddings, cosine via dot product; aggregates
  pairwise scores by `country1 × country2 × sector` into mean/median/top-25/10/5/1%.
- **Inputs:** a `positive_results_*` patent→sector file merged with `g_patent` abstracts, filtered
  to `patent_year` 2000–2013 (the frozen file is the 100k-new-china run).
- The `.py` and the notebook implement the same encoding/aggregation logic; the input/output
  filename literals at the top select the run variant (the notebook's current state is set to the
  later 500k variant).
- **Consumed in the package by:** `05g_generate_regression_validation_countrypair.do`.
- **Cost:** highest in the package — per sector, all cross-country patent-abstract pairs (O(n²));
  run with a 15-core multiprocessing pool writing per-sector `.parquet` progress files.

### 3c. `worldwide_pairs_filtered_no_EPO_countries.dta` (Table A5, BERT + PATSTAT)

- **Producer:** `3_patent_ml/patent_family_exercise.ipynb`, cell writing
  `worldwide_pairs_filtered_no_EPO_countries.dta`. *(orig:
  `python_Patent/codes/patent_family_exercise.ipynb`; named at `JPE_revision_suitvalid.do:141`.)*
- **Model:** `bert-base-uncased` per-subsegment classifiers applied to PATSTAT patent-family
  application abstracts → `<subsegment>_patent_family_predictions.csv`, then aggregated to
  country-pair family counts with an EPO-share filter.
- **Inputs:** PATSTAT `all_abstracts_titles_combined.parquet` +
  `patent_family_mapping_...2010.csv`; `2013_EPO_granted_patents_en.xlsx` (EPO filter); PatentsView
  `g_patent/g_assignee/g_location`; `matched_result.xlsx`; `predicted_positive_v2.csv`.
- **Consumed in the package by:** `05g_generate_regression_validation_countrypair.do`.
- **Cost:** moderate (inference-only over family abstracts + aggregation).

---

## What is NOT here (and why)

- **The confidential input data** (PitchBook `pbcompanies`/`pbmarketmap_v2`, PatentsView bulk,
  PATSTAT) is not bundled — point `EXPENSIVE_ML_ROOT` at the confidential data root to supply it.
- **Trained model weights and per-category metrics** (hundreds of GB) — retained in the author
  archive, layout `SUBSEGMENT-<category>/` (company) and `SUBSEGMENT-<subsegment>/best_model/`
  with `model.safetensors` (patent).
- Only the original author code is shipped as authoritative. `reference_reconstruction/bert_company/`
  additionally provides a clean, faithful re-implementation of Layer 1 as an optional runnable
  reference (see the README in this folder); it is not the producer of any shipped file.

---

## Appendix: full input → output data flow

Three data/model roots (env vars in the shipped `.py`; the notebooks take the same locations as
literals in their first cell): `EXPENSIVE_ML_ROOT` (data = the EntTemplates folder),
`BERT_WORK_ROOT` (company BERT models/scratch), `PATENT_MODEL_DIR` (patent BERT models
`SUBSEGMENT-*/best_model`).

**Layer 1 — company BERT**
`pbmarketmap_v2.csv` + `pbcompanies.csv` → `train_predict_v2-1.ipynb` (per-fullname
bert-base-uncased; train + predict in one loop → `pbmarketmap_v2/positive/<clean>_positive_bert.csv`,
categories swept in index chunks) → Stata `data_generation.do`
(keep `pred_pos>pred_neg` → `predicted_positive_v2.dta` → reshape wide →
**`company_level_predictions_v2.dta`**).

**Layer 2 — company SBERT similarity**
`similarity_mac.ipynb` encodes company descriptions with `all-distilroberta-v1` →
`company_embedding_ST` (pickle) → within-sector pairwise cosine → `output/similarity_ST_<sector>.csv`
→ `similarity_clean.py` (China/US reference aggregation; mean/10th/25th + `_afteronly` =
`yearfounded1 > yearfounded2`) → `similarity_clean.ipynb` compile cells →
**`similarity_compiled.csv`**; western variant via `similarity_clean_detail_western.py` →
`similarity_compile_2025.ipynb` → **`similarity_compiled_western.csv`**; collapse of `analysis_v2`
by sector×country×year (`regressions_similarity.do`) →
**`similarity_at_sector_x_country_x_year.dta`**.

**Layer 3a — patent sector labels** (two independent runs, from *different* shard folders — this is
why their patent sets differ):
- `patent_sector_labels_grantyear` ← BERT shards in `python_BERT/data_patent/positive/`
  (first-round `train_predict_patent*` notebooks) → `patent_prediction_analysis.ipynb` (merge
  `g_patent` utility ≥2000 + assignee + location; drop sectors with <20 training patents) →
  `positive_results_100k.csv` → subset. **verified identical.**
- `patent_sector_labels_new_grantyear` ← models from `train_predict_pat01.ipynb` (+
  `patent_additional_prediction_win.ipynb` re-runs) → shards in
  `python_Patent/output/patent_predictions_100k_china/`
  (`patent_additional_prediction_100k_china_win.ipynb`; keeps China, 2000–2019, seed 42) →
  `patent_prediction_analysis_new100k.ipynb` (keep `positive==1`; filing year via `g_application`;
  drop poor sectors) → `positive_results_100k_new.dta` → subset. **verified identical.**
- `patent_sector_labels_new100k` — 451,328 rows, 84,179 patents. **Same source as `new_grantyear`**
  (`positive_results_100k_new.dta`), but `sector` = lowercased `file` and **restricted to patents that are
  citing patents in `g_us_patent_citation.tsv` with both endpoints located** (utility + assignee_seq 0 +
  country). `make_patent_sector_labels.py` reproduces it **bit-for-bit**.

**Layer 3b — patent SBERT similarity**
`positive_results_*_new*.dta` + `g_patent` abstracts, filtered `patent_year` 2000–2013 →
`patent_similarity.{py,ipynb}` (`all-distilroberta-v1`, per-sector cross-country cosine, 15-core pool →
per-sector `.parquet` → concat → `patent_pairwise_similarity_*.parquet`) → aggregate country×country×sector
→ **`patent_countrysector_similarity_2000_2013_100k_new_china.dta`**.

**Layer 3c — patent family / PATSTAT**
PATSTAT `all_abstracts_titles_combined.parquet` + `patent_family_mapping_...2010.csv` →
`patent_family_exercise.ipynb` (the predict cell's sample size and variant filenames are set at the
top of the notebook; the frozen file is the full-sample run): predict each family's primary-English abstract with the
per-subsegment bert-base-uncased models → `<subsegment>_patent_family_predictions.csv`; keep `positive==1`,
drop poor sectors; keep `GRANTED=='Y'`, within 48 months of earliest family filing, dedup
`(family, auth)`, drop `WO`; assign sectors to families; count within-sector country pairs; drop EP +
EPO members (via `2013_EPO_granted_patents_en.xlsx`) → **`worldwide_pairs_filtered_no_EPO_countries.dta`**
(+ EPO-redistributed / `cn_pairs` / `us_pairs` variants).
