#!/bin/bash
#SBATCH --job-name=freebayes_local
#SBATCH --account=project_xxxx
#SBATCH --partition=small
#SBATCH --time=2:00:00
#SBATCH --cpus-per-task=60
#SBATCH --mem=32G
#SBATCH --output=logs/freebayes_local_%j.out
#SBATCH --error=logs/freebayes_local_%j.err

# Load required modules if needed (beyond what's in snakefile)
module load snakemake

# Set working directory
cd $SLURM_SUBMIT_DIR

# Run info
echo "Job started on $(date)"
echo "Running on node: $(hostname)"
echo "Job ID: $SLURM_JOB_ID"
echo "Working directory: $PWD"

# Run Snakemake with local execution
# All jobs run within this single SLURM allocation
snakemake \
    --snakefile freebayes_snakemake.smk \
    --configfile config_mtDNA.yaml \
    --cores 60 \
    --use-envmodules \
    --latency-wait 60 \
    --rerun-incomplete \
    --printshellcmds \
    --stats logs/snakemake_stats_${SLURM_JOB_ID}.txt \
    --keep-going

# Check exit status
if [ $? -eq 0 ]; then
    echo "Workflow completed successfully on $(date)"
else
    echo "Workflow failed on $(date)"
    exit 1
fi