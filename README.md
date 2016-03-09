# GATK / MuTect SGE scripts #

## Overview ##
I've developed two sets of scripts for running the various stages of the GATK analysis workflow and somatic variant calling in MuTect these take the form of SGE scripts for cluster job submission scripts (specifically I've tested them using [Son of Grid Engine](https://arc.liv.ac.uk/trac/SGE)).  Out of the box I've tested these scrips on both exome and high depth targeted panel sequencing, I've set various setting appropriate for exome analysis using GATK 3.5.  Comments in these scripts document where these have been changed from the standard best-practices workflow/defaults and why.  These scripts have grown up from basic shell scripts for running each stage of the GATK pipeline, where possible I've tried to generalise them using a common settings file.  I've placed them here in the hope that they will be useful to others.  

The first set of scripts (in `Automatic/`) is a fully automated pipeline for running variant calling via the HalplotypeCaller, starting from raw FASTQ files.  It takes variants that pass the final Variant Quality Score Recalibration (VQSR) stage and runs the [Ensemble Variant Effect Predictor (VEP)](http://www.ensembl.org/info/docs/tools/vep/index.html) on them, this provided a complete FASTQ to annotated variant (html VEP report) automated pipeline, which also runs [FastQC](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/)

The second set of scripts (in `Manual/`) allows for manual submission of each stage of the analysis pipeline for both the HaplotypeCaller (HC) using the current GATK 3.x genomic vcf (`g.vcf`) GenotypeGVCFs workflow, which allows for per-sample preprocessing and variant calling prior to join Genotyping; and the classic GATK 2.x UnifiedGenotyper (UG) workflow which uses merged samples preprocessing steps which are somewhat more computationally intensive.  The latter pipeline is essential for Tumour/Normal variant calling using MuTect 1.x (although this will change with MuTect 2 when released as it is now based on the active region walker from the HaplotypeCaller).

## Design considerations ##
Unlike many other scripts for running GATK which people share around this is not a monolithic shell script which attempts to run each stage of the analysis one after the other as a single cluster job.  This is a series of atomic shell scripts, each script encapsulates a particular stage of the GATK best practises workflow for each sample, par stages which require a union of all samples such as GenotypeGVCFs.

The two checked out sets of scrips each have a common `GATKsettings.sh` file which contains various whole run settings/defaults, and the location of the GATK bundle and binaries on your file system.  This script is sourced by all others so enables global setting to be changed for each run.  Each stage of the analysis is organised into a sub-directories off the base dir, this keeps output, SGE standard error/out and GATK log files organised for each stage in one place.  An overview of the various stages of the analysis work flow with dir names in blue and scrips in red is given in `MB-GATK-SGE_overview.pdf` - note that currently the scripts for running VEP (and splitting VCF) are not included in this diagram - I plan to rework this the future and specifically illustrate the automated pipeline too.  I've segregated this diagram into 3 parts: common per-sample processing, stages for the new per sample HaplotypeCaller (HC) workflow, introduced in version 3.x and the older 2.x workflow reliant on a merged bam file which is optimal for the Unified Genotyper (UG) and MuTect.  The new stage 3.x workflow omits a joint realignment and recalibration step via the use of genomic VCF which is converted to a classic raw VCF file at the join Genotyping stage.  It should be noted that joint Tumour/Normal realignment via merged BAM is still recommended for use with MuTect 1.x

### Cloning the current master branch from GitHub ###
At the command-line [(assuming you have a working git installation)](https://git-scm.com/download/linux) simply type:

`git clone https://github.com/MattBashton/MB-GATK-SGE`

You should then find a complete download of all scripts and documentation in the newly created `MB-GATK-SGE` directory present in your current working directory.


### Automated pipeline specific config and instructions ###
The automated pipeline requires some extra settings namely `$G_NAME` which is a global name for an analysis run which needs to be set in the `GATKsettings.sh` file.  The automated pipeline is run using SGE array job dependancies such that should say the BWA stage for a sample complete the corresponding MarkDuplicates stage for said sample will launch in the next job array and so on.  The file `Go_pipline.sh` specifies the pipeline as a series of qsub commands.  Finally a file called `master_list.txt` needs to be present in the same dir as `GATKsettings.sh` / `Go_pipline.sh` this is a tab-delimited flat file, which encodes per-line numeric sample id (used for the run only in `.sam`, `.bam` and `.vcf` file names - suggest you increment this up from one), the `@RG` read group definition line for BWA to incorporate into SAM headers, and the locations of each pair of FASTQ files for BWA for that sample one after the other, these need to be referenced as `../FASTQ/<name_1>.fastq.gz` and `../FASTQ/<name_2>.fastq.gz` as these paths are being passed to BWA operating out of the `BWA_MEM/` dir, the two files needs to be separated by a tab character as do all the other fields.  The format of the file should look like this:

```
1       @RG\tID:RG_01\tLB:Lib_01\tSM:Sample_01\tPL:ILLUMINA       ../FASTQ/Sample_01_1.fastq.gz        ../FASTQ/Sample_01_2.fastq.gz
2       @RG\tID:RG_02\tLB:Lib_02\tSM:Sample_02\tPL:ILLUMINA       ../FASTQ/Sample_02_1.fastq.gz        ../FASTQ/Sample_02_2.fastq.gz
3       @RG\tID:RG_03\tLB:Lib_03\tSM:Sample_03\tPL:ILLUMINA       ../FASTQ/Sample_03_1.fastq.gz        ../FASTQ/Sample_03_2.fastq.gz
```

Note that the `\t` present in the second column (which will define the read groups in your SAM headers) is present to indicate to BWA that this should be a tab character as these can't be directly passed to BWA on the command-line.  Please consult the [GATK documentation on read groups (point 9)](http://gatkforums.broadinstitute.org/discussion/1317/collected-faqs-about-bam-files?) for more info on how to define your experimental setup.

Finally for exome or targeted sequencing you'll need to edit the `INTERVALS` variable in `GATKsettings.sh` to point to the `.bed` file of your kit or targeted regions of the genome.

### Optional MuTect2 somatic variant calling automated workflow ###
[MuTect2](https://www.broadinstitute.org/gatk/guide/tooldocs/org_broadinstitute_gatk_tools_walkers_cancer_m2_MuTect2.php) is now bundled into GATK 3.5 and the automated pipe-line now allows for somatic variant calling of specific tumour / normal pairs of GATK pre-processed bam files and for annotation of somatic variation with Ensembl VEP.  By default these steps are commented out in `Go_pipline.sh` but can be enabled by uncommenting those lines.  Specifically the length of MuTect2 related job arrays needs to be determined so uncomment lines 36-38, additionally array jobs 10Mu, 14Mu and 16Mu should also be uncommented so MuTect2, filtration of somatic variation, and Ensembl VEP can be run.  All of these stages requires a `MuTect2_pairs.txt` file to be placed in the same dir as  `master_list.txt`.  This is a tab-delimited flat file which encodes a per-line numeric id for each pair, normal sample name and tumour sample name - these should correspond to the sample names used in the `SM` field of the read group `@RG` column in `master_list.txt`.  This enables the script which runs MuTect2 to automatically workout which files from the down stream pre-processing stages are needed for each tumour / normal pair.  The format of the file should look like this:

```
1       Sample_01_normal       Sample_01_tumor
2       Sample_02_normal       Sample_02_tumor
3       Sample_03_normal       Sample_03_tumor
```

### Manual workflow specific config and instructions ###
Just as the automated pipeline required a `master_list.txt` file as described above, this file needs to be present in the BWA_MEM directory for a manual run of the BWA alignment stage.  You'll also need to edit `GATKsettings.sh` as above to include the location of your exome/targeted regions `.bed` file.  For the manual workflow in order to set-off stages which run per sample a generic `qsub` submission script wrapper `gsub.sh` is provided, this will submit each sample to SGE for stages which don't unify output or depend on a single input file.  This script submits a qsub job on the specified shell script for each file passed to it via the shell in a dir via `../*.ext` *e*.*g*. to submit a batch of MarkDuplicates.sh jobs use:

`gsub.sh MarkDuplicates.sh ../SamToSortedBam/*.bam`

So each stage of the manual workflow can be submitted like this, in-turn, after all jobs have finished for the previous stage.

## Documentation ##
In addition to this overview the header of each shell script should have some discussion of what stage of GATK *etc*. it's running and the input/output files expected/produced, `GATKsettings.sh` also has many comments on the parameters and settings listed there.

## Dependancies ##
The following binaries and resources are required:

* [GATK 3.5](https://www.broadinstitute.org/gatk/download/)
* [MuTect 1.7](https://www.broadinstitute.org/gatk/download/) (optional as MuTect2 included with GATK 3.5)
* [GATK Resource Bundle 2.8](https://www.broadinstitute.org/gatk/download/)
* [Picard tools](http://broadinstitute.github.io/picard/)
* [Son of Grid Engine](https://arc.liv.ac.uk/trac/SGE)
* [Burrows-Wheeler Aligner](http://bio-bwa.sourceforge.net/)
* [FastQC](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/)
* [vcfutils.pl](https://github.com/lh3/samtools/blob/master/bcftools/vcfutils.pl)
* [VCFtools](https://vcftools.github.io/index.html)
* [Ensembl Variant Effect Predictor](http://www.ensembl.org/info/docs/tools/vep/script/vep_download.html)
* [SAMtools 1.x](http://www.htslib.org/)
* [pigz (required only for gziping large amounts of FASTQ)](http://zlib.net/pigz/)
* [Cowsay](https://en.wikipedia.org/wiki/Cowsay) optional :)

## Performance optimisations ##
Where possible throughout the pipeline/workflow parallelisation and SGE job memory allocation is appropriately set for maximum performance without wastage.

The output of BWA is not piped via the shell into Picard SortSam as this appears to limit BWAs performance to a single thread.  Bam indexes `.bai` are created on the fly for all stages where required using `CREATE_INDEX=true` in Picard tools this saves time reading in the file a second time for indexing as a separate stage.

The execution of all stages is monitored using GNU time (in verbose mode) this reports CPU and memory usage (beware the four fold memory over reporting [issue](https://groups.google.com/forum/#!topic/gnu.utils.help/u1MOsHL4bhg) on older distributions with unpatched code).  GATK parallelisation has been tuned using `-nc/-nct` for each stage so as not to waste CPU thread allocation, if a stage seldom used more than n threads, SGE slot allocation and `-nt/-nct` are scaled back and set appropriately.  Memory usage for each stage is appropriately scaled for exome analysis with adequate headroom on top of the JVM size in the SGE allocation.  Keeping these as lean as need be with a small overhead should increase the chance of an SGE job finding an appropriate sized slot.

### Advantage of modularity ###
One of the advantages of atomic scripts for each stage is that different CPU slot allocations and memory requirements can be levelled appropriately for each stage rather than setting this once for a monolith script, as some stages can take advantage of parallelisation and others cannot.  This optimally frees up SGE slots rather than the whole run having to be the width of the most parallel part of the pipeline and multiple slots being locked out of the cluster queue whilst single core analysis stages run.  By optimally using the cluster the pipeline can process 30 exomes from FASTQ to annotated html VEP report in ~12 hours on E5-2680v2 2.8 GHz Xeons.

### IO optimisation for Lustre FS ###
The cluster environment used in testing uses the [Lustre (file system)](http://lustre.org/), this is very efficient at large monolithic file transfers but slow at successive small read/write operations used by many bioinformatics programs.  Each job thus copies the input to local scratch (created under $TMPDIR by SGE) as local disk proves to be faster in all cases, copying was fast on test hardware owing to 40GbE networking.  At the end of each analysis run the output files are copied back of local scratch to Lustre, this reduces load on Lustre too and is likely to be beneficial for systems running NFS as well, as multiple simulations and successive small read/write operations can also degrade performance and swamp the network/NFS daemon.

### Hardware acceleration of PairHMM using Intel Advanced Vector eXtensions (AVX) instructions ###
In GATK 3.1+ AVX instructions are employed by the HaplotypeCaller for the PairHMM mediated pairwise alignment of each read against each haplotype, these give a 2-2.5x speed-up in  execution time, however they can only run when the HaplotypeCaller is run single core owing to implementation.  As the HaplotypeCaller is an active region rather than locus walker speed-up improvements using multiple cores were never good, consequently in testing running the HC single core with AVX optimisations enabled on a modern Sandybridge or newer Intel CPUs allow for run times equivalent to using 10 cores (`-nct`) under a non-hardware accelerated run.  From my experience a single sample exome can be called in about ~2-3hr single core using AVX optimisations, this allows for many samples to be simultaneously called at once with modest CPU core count.  Also it should be noted that GATK 3.4 requires GCC libs version 4.8.x or greater in order to load the VectorLoglessPairHMM implementation this requirement will be relaxed in later versions.

## Error tracking and debugging ##
All bash scripts run with `bash -e`, and will thus bail on any error, `set -o pipefail` is also used ensuring failures in piping operations also result in a script stopping.  All copy operations and runs of any binary or GATK are done with `/usr/bin/time -—verbose` preceding them, this means that GNU time will log time, memory, CPU usage and IO.  This is useful not just in profiling the performance and run time of a job, but also to log the exit code too, this output will be sent to standard error when whatever was being timed finishes.  Currently both standard error and out are directed to separate files.  GATK and BWA along with other programs and GNU time will write to standard error.  Each script logs the time/date and hostname at the start of execution along with a list of all variables used in the run to standard out when initialised to help with debugging, so separating this from GATK output helps with quickly establishing what is going on.  The final line of each script if run correctly will always be `END`.  Consequently you can check to see if all scripts of a particular stage have run correctly using:

`grep -c END *.o*`

in each directory, scripts that ran successfully will have a count of 1 those which failed will be 0.

Only scripts that ran fully without error will have their last line as `END` on their standard out.  Non-zero exit status can be checked for in all scripts via:

`grep Exit *.e*`

anything non-zero here indicates that a copy operation or GATK / BWA or other binary terminated abnormally.

For the automated pipeline the script `Audit_run.sh` can be run which will systematically perform the above checks for all stages and report success / errors *e*.*g*. for the HaplotypeCaller stage:

```
 * Checking 29 Haplotype Caller jobs:
  - 29 jobs ran fully
  - 0 failed to finish
  - 0 non-zero exit statuses reported
```

In order to output its report this the script sources `GATKsettings.sh` and examines `master_list.txt` to obtain the global run name and number of sample in the analysis.

The `Audit_run.sh` script also reports system and real world run time for each stage and the whole automated pipeline in total.

### What happens if a stage or individual job fails in the automated pipeline? ###
Presently SGE will blindly run the next stage of the job array dependency chain.  However, this not as bad as it seems since `bash -e` is employed at the start of each script, should the main binary for a preceding job fail, the final copy operation from `$TMPDIR` will never run.  Consequently upon starting the next stage of the automated pipeline will fail to find it's input file immediately and terminate.  Should this happen, the failing job and downstream jobs can be re-run using array job notation, this is set at `-t 1-$N` by default, simply change this to `-t n`, where `n `is the array job(s) that failed, commas can by used to specify additional tasks of the array job.  I plan to improve this behaviour in future updates.

## Overall run stats ##
Stats from various stages of the analysis: alignment stats, read duplication rates, depth of coverage, called SNP and indel counts can be generated after the run has finished using the `Run_stats.sh` script.

## Post run clean up ##
Following a successful run temporary `.sam` and `.bam` files produced by intermediate stages can be removed by running the `CleanUpRun.sh` script, all `.g.vcf` / `.vcf` and log files will be left in tact along with the final preprocessed `.bam` file which has been de-duplicated, realigned and re-calibrated.  I don't automatically run this at the end of the run, since the use of intermediate files may be desirable for some workflows and debugging.

## Can I run this without a cluster? ##
Whilst this set of scripts has been tested on a cluster environment with a network filesystem, there is nothing to stop you installing SGE on a phat server and using SGE to schedule the analysis jobs, however you might want to remove the copy operations to and from `$TMPDIR` unless you have some nice fast flash based storage you plan to use temporarily during the analysis run or a whopping great RAM disk and huge amounts of RAM.  

## Why did you not implement this in X or do Y *etc*? ###
### Why Bash? ###
My aim with this series of scripts / pipeline was to create a light weight system with minimal dependancies that would be accessible to the more novice user, so I chose to use SGE directly as the scheduler of jobs since this is the most light weight and easiest win from my current scripting base.  I fully acknowledge that [Bpipe](https://code.google.com/p/bpipe/) would also have been a good choice here.  Since SGE job submission already happens in shell wrappers it made most sense to simply extend that system.  Ultimately the best system for GATK pipeline creation is the Broads own [Queue](https://www.broadinstitute.org/gatk/guide/topic?name=queue) however as  a custom dialect of [Scala](https://en.wikipedia.org/wiki/Scala_%28programming_language%29) implementation is none trivial and is harder to grasp if you're not already somewhat familiar with Scala.

### Style considerations ###
Contrary to the belief held by certain coding pedants backticks are [not deprecated](http://unix.stackexchange.com/questions/126927/have-backticks-i-e-cmd-in-sh-shells-been-deprecated) and are part of the POSIX standard, personally since I was first exposed to shell scripting in the 90s I actually prefer backticks, their good enough for the markdown I'm using in this document so there good enough for use in my code, I don't nest backticks so don't have any issues with nesting.  I also think that backticks are cleaner visually than the dollar parens `$()` paradigm particularly if you're new to shell scripting.  For this reason I'm also employing the use of the external `basename` and `dirname` mainly for clarity in showing how I assign values to variables as the combination of `$()` and bash string manipulation operations are the perfect storm of Perl-like "explosion in a punctuation factory" code which is hard to read.

## Roadmap ##
Ultimately I plan to re-implement this whole workflow in Queue, time permitting.

For whole genome analysis speedups can be gained easily in the HaplotypeCaller stage by parallelising per chromosome this can be done without the need for Queue - implementation of this is under way.  However, if run-time is still an issue, Queue may have to be used to scatter gather various stages of analysis including realignment and the HaplotypeCaller.

## What this is not ##
This set of scripts, and comments in said scripts, are in no way a replacement for reading the excellent and extensive [GATK documentation](https://www.broadinstitute.org/gatk/guide/), understanding how it works, and choosing appropriate parameters for your experiment.  Choices I've made here reflect my usage case with exoms and my interpretation of the GATK documentation / past and present best practices workflow documentation, your usage case and opinions may differ.  Nor as yet is this a robust error tolerant pipeline, you will need to check things ran correctly (`Audit_run.sh` is provided for the automated pipeline).  This system is not "foolproof and incapable of error" you still need some bioinformatics skills.
