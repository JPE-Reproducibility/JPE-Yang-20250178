#!/bin/bash
#SBATCH --job-name=patpred-b01
#SBATCH --partition=gpu
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=3
#SBATCH --cpus-per-task=6
#SBATCH --mem-per-cpu=4096
#SBATCH --gres=gpu:lovelace_l40:3
#SBATCH --time=48:00:00
#SBATCH --chdir=PATH_TO_HPC_PROJECT/code
#SBATCH --output=log/%x-%j-%t.out

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${PROJECT_DIR:-${SCRIPT_DIR}}"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "${PROJECT_DIR}/.." && pwd)}"
export PROJECT_DIR PROJECT_ROOT

LOG_DIR="${PROJECT_DIR}/log"
mkdir -p "$LOG_DIR"

module purge
module load CUDA/12.4.0
module load Python/3.11.5-GCCcore-13.2.0

VENV_DIR="${VENV_DIR:-${PROJECT_DIR}/.venv_patent_pred}"
if [ ! -d "$VENV_DIR" ]; then
  python -m venv "$VENV_DIR" --system-site-packages
fi

export TMPDIR="${PROJECT_DIR}/tmp"
export PIP_CACHE_DIR="${PROJECT_DIR}/.pip_cache"
export XDG_CACHE_HOME="${PROJECT_DIR}/.cache"
mkdir -p "$TMPDIR" "$PIP_CACHE_DIR" "$XDG_CACHE_HOME"

source "$VENV_DIR/bin/activate"

TORCH_INDEX="${TORCH_INDEX:-https://download.pytorch.org/whl/cu121}"
TORCH_VERSION="${TORCH_VERSION:-2.3.1}"  # cu121 build
tokenizers_version="${TOKENIZERS_VERSION:-0.21.0}"
pip install --upgrade --quiet pip
pip install --no-cache-dir --upgrade \
  --extra-index-url "$TORCH_INDEX" \
  "torch==${TORCH_VERSION}" "torchvision==${TORCHVISION_VERSION:-0.18.1}" "torchaudio==${TORCHAUDIO_VERSION:-2.3.1}" \
  "transformers==4.42.4" "datasets==2.21.0" "accelerate==0.33.0" "evaluate==0.4.2" "tokenizers==${tokenizers_version}" \
  pandas numpy pyarrow fastparquet openpyxl

export HF_HOME="${XDG_CACHE_HOME}/huggingface"
export TRANSFORMERS_CACHE="${HF_HOME}/transformers"
export HF_DATASETS_CACHE="${HF_HOME}/datasets"
mkdir -p "$HF_HOME" "$TRANSFORMERS_CACHE" "$HF_DATASETS_CACHE"
export WANDB_DISABLED=1

export SECTOR_OFFSET=0
export SECTOR_COUNT=12
export SECTORS_PER_TASK="${SECTORS_PER_TASK:-4}"
export PRED_BATCH_SIZE="${PRED_BATCH_SIZE:-16}"
export NUM_WORKERS="${NUM_WORKERS:-2}"
export DATA_DIR="${DATA_DIR:-${PROJECT_ROOT}/data}"
export OUTPUT_DIR="${OUTPUT_DIR:-${PROJECT_ROOT}/output/patent_predictions_full}"
export PATENT_MODEL_DIR="${PATENT_MODEL_DIR:-${DATA_DIR}/PatentSubsegmentFolders/PatentSubsegmentFolders}"
export CACHE_FILTERED="${CACHE_FILTERED:-1}"

srun --export=ALL,SECTOR_OFFSET,SECTOR_COUNT,SECTORS_PER_TASK,PRED_BATCH_SIZE,NUM_WORKERS,DATA_DIR,OUTPUT_DIR,PATENT_MODEL_DIR,CACHE_FILTERED \
  --ntasks=3 --cpus-per-task=6 --gpus-per-task=1 --distribution=block:cyclic \
  --output="${LOG_DIR}/%x-%j-%t.out" --label \
  bash -lc '
    set -euo pipefail
    echo "[task] host=$(hostname) localid=${SLURM_LOCALID:-0} gpu=${CUDA_VISIBLE_DEVICES:-unset}"
    "$VENV_DIR/bin/python" "$PROJECT_DIR/predict_patent_sectors.py"
  '
