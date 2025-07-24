# PBS directives
#---------------

#PBS -N 02_QC_Ding_2024
#PBS -l nodes=1:ncpus=12
#PBS -l walltime=03:00:00
#PBS -q three_hour
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
## 1. FASTQC ANALYSIS ON RAW READS
###############################
echo
echo running FastQC on raw reads
echo

##1a. Load the necessary modules and make the necessary directories
module use /apps2/modules/all
module load FastQC

## 1b. Run fastqc on the raw reads
fastqc /mnt/beegfs/home/tatiana.stead/thesis_fungal_repo/04_raw_data/*.fastq --outdir /mnt/beegfs/home/tatiana.stead/thesis_fungal_repo/05_QC_output




## Tidy up the log directory
## =========================
rm $PBS_O_WORKDIR/$PBS_JOBID