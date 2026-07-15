# Patent-model inference on an HPC cluster

This folder documents the SLURM setup used to run the trained per-subsegment patent classifiers
(inference only, no training) over a full filtered PatentsView corpus on a university GPU cluster.

The frozen patent files shipped with the package were produced by the notebook runs described in
[`../../PROVENANCE.md`](../../PROVENANCE.md); this SLURM path was built for the later full-corpus
run and is provided as the scalable way to re-run inference with the same models and the same
filtering logic.

## Files

- `predict_patent_sectors.py` — end-to-end filtering + inference. Environment-variable driven (see
  its docstring); shards the sector list across `srun` tasks via `SLURM_LOCALID`.
- `slurm_predict_patents_batch_01.sh` — job template. The production sweep used 19 copies of this
  file, identical except for `--job-name` and `SECTOR_OFFSET` (0, 12, 24, ..., 216), covering the
  full sector set in 12-sector chunks (3 GPUs x 4 sectors per job).

## Prerequisites on the cluster

- PatentsView raw data in `<project>/data/`: `g_patent.tsv`, `g_assignee_disambiguated.tsv`,
  `g_location_disambiguated.tsv`, plus `matched_result.xlsx` and `predicted_positive_v2.csv`.
- Trained models under
  `<project>/data/PatentSubsegmentFolders/PatentSubsegmentFolders/SUBSEGMENT-*/best_model/`,
  each containing `model.safetensors`.

## Workflow

1. `rsync` this folder, the PatentsView data, and the model store to the cluster, e.g.:

   ```bash
   rsync -avh --exclude "__pycache__/" --exclude "*.pyc" --exclude ".DS_Store" \
     ./ user@cluster:PATH_TO_HPC_PROJECT/code/
   rsync -avh PATH_TO_PATENT_MODEL_FOLDERS \
     user@cluster:PATH_TO_HPC_PROJECT/data/PatentSubsegmentFolders
   rsync -avh PATH_TO_ENTTEMPLATES_DATA_ROOT/Analysis/python_Patent/data/ \
     user@cluster:PATH_TO_HPC_PROJECT/data/
   ```

2. Edit `#SBATCH --chdir` in the job file(s) to the cluster-side code folder.

3. Submit the sweep:

   ```bash
   for i in $(seq -w 1 19); do sbatch slurm_predict_patents_batch_${i}.sh; done
   ```

   Each job creates/reuses a shared venv `.venv_patent_pred` (torch 2.3.1 cu121,
   transformers 4.42.4, datasets 2.21.0; installed automatically by the job file) and writes
   per-sector `{sector}_patent_positive_bert.csv` to `<project>/output/patent_predictions_full/`,
   plus a cached filtered-corpus TSV reused by later jobs.

## Tuning (environment overrides)

`DATA_DIR`, `OUTPUT_DIR`, `PATENT_MODEL_DIR` point at custom locations; `PRED_BATCH_SIZE`
(default 16) and `NUM_WORKERS` (default 2) balance speed and memory; `SECTORS_PER_TASK`
(default 4) sets how many sectors each GPU processes; `SECTOR_OFFSET`/`SECTOR_COUNT` re-slice
the sector list.
