## A simple example snakemake .smk file for parallelising freebayes
## Uses a fasta_generate_regions to split the genome into regions of equal size based on the .fai index
## As snakemake automatically moves each cpu core to the next genome chunk, this works out faster
## than the freebayes-parallel wrapper.
## This .smk file assumes we have a list of the bam files called bam.list
## This .smk file splits the genome by chromosome, which of course, is not necessary.
## One will want to edit the paths (for example, the path to bam files)

# Example run command: snakemake --snakefile freebayes_snakemake.smk --configfile config_mtDNA.yaml --cores 60 --use-envmodules

path_prefix = "../"
samples = config["samples"]
samples_folder = path_prefix + config["samples_folder"]
reference = path_prefix + config["path_to_reference"]
reference_fai = reference + ".fai"
output_folder = config["output_folder"]
chroms = config["chroms"]
nchunks = config.get("chunks_per_chrom", 20)  # More reasonable default

bamlist = config["bam_list"]
chunks = list(range(1, nchunks + 1))

rule all:
    input:
        expand(output_folder + "/results/variants/vcfs/variants.{chrom}.vcf", chrom=chroms)

rule GenomeIndex:
    input:
        ref = reference
    output:
        idx = reference + ".fai"
    log: 
        "logs/GenomeIndex.log"
    envmodules:
        "freebayes",
        "biokit"
    wrapper: 
        "v0.69.0/bio/samtools/faidx"


rule GenerateFreebayesRegions:
    input:
        ref_idx = reference,
        index = reference + ".fai",
        bams = expand(samples_folder + "/{sample}.bam", sample=samples)
    output:
        regions = expand(output_folder + "/resources/regions/genome.{chrom}.region.{i}.bed", chrom=chroms, i = chunks)
    log:
        "logs/GenerateFreebayesRegions.log"
    params:
        chroms = chroms,
        chunks = chunks
    conda:
        "../envs/freebayes-env.yaml"
    envmodules:
        "freebayes",
        "biokit"
    script:
        # "../scripts/GenerateFreebayesRegions.R" # This is located in the scripts/ directory of freebayes
        "python fasta_generate_regions.py --chunks --bed resources/regions/genome --chromosome {params.chroms} {input.index} {params.chunks} 2> {log}"


rule VariantCallingFreebayes:
    input:
        bams = expand(output_folder + "/resources/alignments/{sample}.bam", sample=samples),
        index = expand(output_folder + "/resources/alignments/{sample}.bam.bai", sample=samples),
        ref = reference,
        samples = bamlist,
        regions = expand(output_folder + "/resources/regions/genome.{chrom}.region.{i}.bed", chrom=chroms, i=chunks)
    output:
        temp("results/variants/vcfs/{chrom}/variants.{i}.vcf")
    log:
        "logs/VariantCallingFreebayes/{chrom}.{i}.log"
    conda:
        "../envs/freebayes-env.yaml"
    envmodules:
        "freebayes",
        "biokit"
    threads:1
    shell:	"freebayes --no-population-priors --genotype-qualities --use-mapping-quality --use-best-n-alleles 2 -f {input.ref} -t {input.regions} -L {input.samples} > {output} 2> {log}"


rule ConcatVCFs:
    input:
        calls = expand("results/variants/vcfs/{{chrom}}/variants.{i}.vcf", i=chunks)
    output:
        "results/variants/vcfs/variants.{chrom}.vcf"
    log:
        "logs/ConcatVCFs/{chrom}.log"
    conda:
        "../envs/freebayes-env.yaml"
    envmodules:
        "freebayes",
        "biokit"
    threads:4
    shell:  
        "bcftools concat {input.calls} | vcfuniq > {output} 2> {log}"