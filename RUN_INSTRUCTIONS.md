# Running FreeBayes Snakemake Pipeline on CSC Puhti

## Prerequisites

1. Update the project number in all scripts (replace `project_xxxx` with your actual project)
2. Ensure your config file (`config_mtDNA.yaml`) has correct paths
3. Create logs directory: `mkdir -p logs`
4. Make scripts executable: `chmod +x submit_*.sh`

## Option 1: Local Batch Execution (Recommended for small jobs)

**Best for:** mtDNA, small genomes, or testing
- All processing happens within a single SLURM allocation
- Simple to monitor and debug
- Limited to resources of one node (max 40 cores on Puhti small partition)

```bash
# Submit the job
sbatch submit_batch_local.sh

# Monitor progress
squeue -u $USER
tail -f logs/freebayes_local_*.out
```

**Modify resources as needed:**
- For mtDNA: `--time=0:30:00 --cpus-per-task=4 --mem=8G`
- For whole genome: `--time=24:00:00 --cpus-per-task=40 --mem=180G`

## Option 2: SLURM Executor (Recommended for large jobs)

**Best for:** Whole genome sequencing, multiple samples
- Submits each Snakemake rule as a separate SLURM job
- Can use multiple nodes simultaneously
- Better resource utilization

```bash
# Submit the controller job
sbatch submit_slurm_executor.sh

# Monitor progress
squeue -u $USER  # See all spawned jobs
tail -f logs/freebayes_controller_*.out
```

**The controller job:**
- Uses minimal resources (1 CPU, 4GB RAM)
- Submits and monitors child jobs
- Automatically cancels failed jobs with `--slurm-cancel-on-fail`

## Customizing Resources

### For Local Batch (`submit_batch_local.sh`):
Edit the SBATCH headers:
```bash
#SBATCH --time=4:00:00      # Increase for larger datasets
#SBATCH --cpus-per-task=60  # Max cores to use
#SBATCH --mem=64G           # Total memory needed
```

### For SLURM Executor (`submit_slurm_executor.sh`):
Edit the default resources:
```bash
--default-resources \
    mem_mb=8000 \      # Memory per job (8GB)
    runtime=120 \      # Max runtime per job (minutes)
    cpus_per_task=2 \  # CPUs per job
```

Or add rule-specific resources in your Snakefile:
```python
rule VariantCallingFreebayes:
    resources:
        mem_mb=16000,
        runtime=180,
        partition="small"
```

## Monitoring and Troubleshooting

### Check job status:
```bash
# Your jobs
squeue -u $USER

# Detailed job info
scontrol show job <jobid>

# Why a job is pending
squeue -u $USER -o "%.18i %.9P %.8j %.8T %.10M %.6D %R"
```

### Common issues:

1. **Jobs pending too long:**
   - Check if partition is busy: `sinfo -p small`
   - Reduce resource requests
   - Use `--partition=test` for quick tests (max 15 min)

2. **Out of memory errors:**
   - Increase `mem_mb` in default resources
   - Check `.snakemake/log/` for detailed error messages

3. **Module errors:**
   - Verify modules exist: `module spider freebayes`
   - Check module compatibility: `module load biokit`

4. **Too many jobs:**
   - Reduce `--jobs` parameter (default 100)
   - CSC limit is ~300 jobs per user

## For Different Data Types

### mtDNA or small targets:
```bash
# In config file
chunks_per_chrom: 1
chroms: ["MT"]  # or ["chrM"]

# Use local batch with minimal resources
#SBATCH --time=00:30:00
#SBATCH --cpus-per-task=4
```

### Whole genome:
```bash
# In config file  
chunks_per_chrom: 20
chroms: ["1","2","3",...,"22","X","Y"]

# Use SLURM executor for parallelization
```

### Exome/targeted:
```bash
# In config file
chunks_per_chrom: 5
# Include only chromosomes with targets
```