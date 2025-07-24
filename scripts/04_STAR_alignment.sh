# PBS directives
#---------------

#PBS -N 04_STAR_alignment_Ding_2024
#PBS -l nodes=1:ncpus=12
#PBS -l walltime=24:00:00
#PBS -q one_day
#PBS -m abe
#PBS -M tatiana.stead@cranfield.ac.uk

#===============
#PBS -j oe
#PBS -v "CUDA_VISIBLE_DEVICES="
#PBS -W sandbox=PRIVATE
#PBS -k n
ln -s $PWD $PBS_O_WORKDIR/$PBS_JOBID
## Change to working directory
cd $PBS_O_WORKDIR
## Calculate number of CPUs and GPUs
export cpus=`cat $PBS_NODEFILE | wc -l`
## Load production modules
module use /apps2/modules/all
## =============

# --- Your code starts here --- #


# Stop at runtime errors
set -e


###############################
##4. STAR ALIGNMENT
###############################
echo
echo STAR alignment on untrimmed reads
echo

## 4a. load necessary modules
module purge
module load STAR

## 4b. Create directory for genome index
mkdir -p /mnt/beegfs/home/tatiana.stead/I-BIX-NGS_dataForAssignment_flang/genomeIndex/

## 4c. Run STAR to create index
STAR --runMode genomeGenerate \
 --genomeDir /mnt/beegfs/home/tatiana.stead/thesis_fungal_repo/07_STAR_genome_index/ \
 --genomeFastaFiles /mnt/beegfs/home/tatiana.stead/thesis_fungal_repo/04_raw_data/01_genomic_data/GCF_000149555.1_ASM14955v1_genomic.fna \
 --sjdbGTFfile /mnt/beegfs/home/tatiana.stead/thesis_fungal_repo/04_raw_data/01_genomic_data/genomic.gtf \
 --sjdbOverhang 149 

## 4d. Apply loop to align reads
for f1 in /mnt/beegfs/home/tatiana.stead/thesis_fungal_repo/06_trimmed_reads/*_1_paired.fq
do
# only store the sample names as f2 variable, by removing R1.fastq:
f2="${f1%%_1_paired.fq}"
echo processing $f2 ...
# store only the sample name by trimming the path
prefix=$(basename $f2 _)

# carry out alignment using star
STAR --runThreadN 4 --genomeDir /mnt/beegfs/home/tatiana.stead/thesis_fungal_repo/07_STAR_genome_index/ \
 --sjdbGTFfile /mnt/beegfs/home/tatiana.stead/thesis_fungal_repo/04_raw_data/01_genomic_data/genomic.gtf \
 --sjdbOverhang 149 \
 --outSAMtype BAM SortedByCoordinate \
 --readFilesIn $f2"_1_paired.fq" $f2"_2_paired.fq" \
 --outFileNamePrefix $prefix"_"

echo finished processing $f2
# close the loop
done

## 4e. Move output files to new directories
mv /mnt/beegfs/home/tatiana.stead/thesis_fungal_repo/06_trimmed_reads/*.bam /mnt/beegfs/home/tatiana.stead/thesis_fungal_repo/08_BAMS_aligned

# move all log files to a new directory
mv /mnt/beegfs/home/tatiana.stead/thesis_fungal_repo/06_trimmed_reads/*.out /mnt/beegfs/home/tatiana.stead/thesis_fungal_repo/08_BAMS_aligned/01_STAR_logs
mv /mnt/beegfs/home/tatiana.stead/thesis_fungal_repo/06_trimmed_reads/*.tab /mnt/beegfs/home/tatiana.stead/thesis_fungal_repo/08_BAMS_aligned/01_STAR_logs




## Tidy up the log directory
## =========================
rm $PBS_O_WORKDIR/$PBS_JOBID