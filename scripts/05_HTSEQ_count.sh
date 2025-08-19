# PBS directives
#---------------

#PBS -N 05_HTSEQ_count_Ding_2024
#PBS -l nodes=1:ncpus=12
#PBS -l walltime=48:00:00
#PBS -q two_day
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
## 6. HTSEQ COUNT OF STAR ALIGNMENT
###############################

echo
echo HTSeq Count of mapped reads
echo

## 6a. Load necessary modules
module purge
module load HTSeq/2.0.2-foss-2022a

## /mnt/beegfs/home/tatiana.stead/thesis_fungal_repo/09_HTSeq_counts

## 6c. create a loop to count all the reads for each bam file created using star aligner
for f1 in /mnt/beegfs/home/tatiana.stead/thesis_fungal_repo/08_BAMS_aligned/*_Aligned.sortedByCoord.out.bam
do
# only store the sample names as f2 variable, by removing R1.fastq:
f2="${f1%%_Aligned.sortedByCoord.out.bam}"
echo processing $f2 ...
# store only the sample name by trimming the path
prefix=$(basename $f2)

# apply htseq count
htseq-count -s no -f bam --type exon --idattr gene_id $f1 \
 /mnt/beegfs/home/tatiana.stead/thesis_fungal_repo/04_raw_data/01_genomic_data/genomic.gtf > /mnt/beegfs/home/tatiana.stead/thesis_fungal_repo/09_HTSeq_counts/$prefix"_htseq_count_CDS_trscpt.txt"

echo finished processing $f2
echo
# close the loop
done



## Tidy up the log directory
## =========================
rm $PBS_O_WORKDIR/$PBS_JOBID