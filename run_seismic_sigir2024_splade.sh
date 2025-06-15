#!/bin/bash
#SBATCH --qos=debug
#SBATCH --time=30:00
#SBATCH --nodes=1
#SBATCH --constraint=cpu
#SBATCH --output=%j.log

source /pscratch/sd/d/dhaura/benchmarks/SpKNN/forks/seismic/venv/bin/activate

python3 scripts/run_experiments.py --exp experiments/sigir2024/splade.toml

