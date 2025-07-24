# PBS directives
#---------------

#PBS -N 02_QC_Ding_2024
#PBS -l nodes=1:ncpus=12
#PBS -l walltime=06:00:00
#PBS -q six_hour
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
## 2. TRIMMING RAW READS
###############################
echo
echo trimming raw reads
echo

## 2a. load necessary modules
module purge
module load Trimmomatic

## 2b. Apply for loop to trim all reads in the raw_reads file
for f1 in /mnt/beegfs/home/tatiana.stead/thesis_fungal_repo/04_raw_data/*_1.fastq
do
# only store the sample names as f2 variable, by removing R1.fastq:
f2="${f1%%_1.fastq}"
echo processing $f2 ...

java -jar $EBROOTTRIMMOMATIC/trimmomatic-0.39.jar PE -phred33 $f2"_1.fastq" $f2"_2.fastq" $f2"_1_paired.fq" $f2"_1_unpaired.fq" $f2"_2_paired.fq" $f2"_2_unpaired.fq" \
ILLUMINACLIP:/apps2/software/Trimmomatic/0.39-Java-17/adapters/TruSeq3-PE.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36

echo
echo

done

## 2c. Move trimmed reads into designated folder
mv /mnt/beegfs/home/tatiana.stead/thesis_fungal_repo/04_raw_data/*paired.fq /mnt/beegfs/home/tatiana.stead/thesis_fungal_repo/06_trimmed_reads


## Tidy up the log directory
## =========================
rm $PBS_O_WORKDIR/$PBS_JOBID