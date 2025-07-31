#!/bin/bash
#SBATCH --job-name=freebayes_controller
#SBATCH --account=project_xxxx
#SBATCH --partition=small
#SBATCH --time=00:30:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --output=logs/freebayes_controller_%j.out
#SBATCH --error=logs/freebayes_controller_%j.err

# Create logs directory if it doesn't exist
mkdir -p logs

# Set working directory
cd $SLURM_SUBMIT_DIR

# Run info
echo "SLURM controller job started on $(date)"
echo "Running on node: $(hostname)"
echo "Job ID: $SLURM_JOB_ID"
echo "Working directory: $PWD"

# Run Snakemake with SLURM executor
# This job acts as a controller that submits individual jobs to SLURM
snakemake \
    --snakefile freebayes_snakemake.smk \
    --configfile config_mtDNA.yaml \
    --executor slurm \
    --jobs 100 \
    --use-envmodules \
    --default-resources \
        slurm_account="project_xxxx" \
        slurm_partition="small" \
        mem_mb=4000 \
        runtime=60 \
        cpus_per_task=1 \
    --latency-wait 60 \
    --rerun-incomplete \
    --printshellcmds \
    --stats logs/snakemake_stats_${SLURM_JOB_ID}.txt \
    --keep-going \
    --slurm-cancel-on-fail

# Check exit status
if [ $? -eq 0 ]; then
    echo "Workflow completed successfully on $(date)"
else
    echo "Workflow failed on $(date)"
    exit 1
fi