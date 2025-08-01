# Example run command: snakemake --snakefile freebayes_snakemake_2_local.smk --configfile config_mtDNA_min_min.yaml --cores 8

path_prefix = "../"
samples = config["samples"]
samples_folder = path_prefix + config["samples_folder"]
reference = path_prefix + config["path_to_reference"]
reference_fai = reference + ".fai"
output_folder = config["output_folder"]
chroms = config["chroms"]
nchunks = config.get("chunks_per_chrom", 20)  # More reasonable default

freebayes_path = config.get("freebayes_path", "freebayes")  # Default to 'freebayes' if not specified

bamlist = config["bam_list"]
chunks = list(range(1, nchunks + 1))

rule all:
    input:
        expand(output_folder + "/results/variants/vcfs/variants.{chrom}.vcf", chrom=chroms)


rule GenerateFreebayesRegions:
    input:
        ref_idx = reference,
        index = reference_fai,
        bams = expand(samples_folder + "/{sample}.bam", sample=samples)
    output:
        regions = expand(output_folder + "/regions/genome.{chrom}.region.{i}.bed", chrom=chroms, i = chunks)
    log:
        "logs/GenerateFreebayesRegions.log"
    params:
        chroms = chroms,
        chunks = chunks,
        nchunks = nchunks,
        region_size = 100,
        outfolder = output_folder + "/regions/genome"
    envmodules:
        "freebayes",
        "biokit"
    shell:
        """
        python3 fasta_generate_regions.py {input.index} {params.nchunks} --chunks --bed {params.outfolder} --chromosomes {params.chroms}
        """


rule VariantCallingFreebayes:
    input:
        bams = expand(samples_folder + "/{sample}.bam", sample=samples),
        index = expand(samples_folder + "/{sample}.bam.bai", sample=samples),
        ref = reference,
        samples = bamlist,
        region = output_folder + "/regions/genome.{chrom}.region.{i}.bed"
    output:
        output_folder + "/results/variants/vcfs/{chrom}/variants.{i}.vcf"
    params:
        freebayes_path = freebayes_path
    log:
        "logs/VariantCallingFreebayes/{chrom}.{i}.log"
    threads: 1
    shell:	"{params.freebayes_path} -f {input.ref} -t {input.region} -L {input.samples} > {output} 2> {log}"


rule ConcatVCFs:
    input:
        calls = expand(output_folder + "/results/variants/vcfs/{{chrom}}/variants.{i}.vcf", i=chunks)
    output:
        output_folder + "/results/variants/vcfs/variants.{chrom}.vcf"
    log:
        "logs/ConcatVCFs/{chrom}.log"
    envmodules:
        "freebayes",
        "biokit"
    threads:4
    shell:  
        "bcftools concat {input.calls} | vcfuniq > {output} 2> {log}"