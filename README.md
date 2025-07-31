# Freebayes_smk

### Interactive use
```
  sinteractive -c 60 -m 32G -t 2:00:00 -A project_xxxx

  snakemake --snakefile freebayes_snakemake.smk --configfile config_mtDNA.yaml --cores 60 --use-envmodules
```

### Batch job
See file submit_batch_local.sh