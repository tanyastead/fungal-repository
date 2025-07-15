# PBS directives
#---------------

#PBS -N 01_get_data_Ding_2024
#PBS -l nodes=1:ncpus=12
#PBS -l walltime=00:30:00
#PBS -q half_hour
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

# Start message
echo "Started downloading FASTQ files from SRA"
date
echo ""

# Folders
base_folder="/mnt/beegfs/home/tatiana.stead/thesis_fungal_repo"
sra_folder="${base_folder}/02_sra_toolkit/sratoolkit.3.1.1-ubuntu64/bin" # update x.y.z 
data_folder="${base_folder}/04_raw_data" # may exist, but should not contain the data

# List of SRA IDs 
# The next line of code reads the first colimn from the samples.txt file,   
# omitting the header line, and saves it to the variable sra_ids.  
# It ames that the samples file is in the same folder as the script.  
sra_ids=$(awk 'NR > 1 {print $1}' SRR_Acc_List.txt)

# Loop over SRA IDs and use fasterq-dump to download the data
for id in $sra_ids
do
  echo "${id}"
  "${sra_folder}/fasterq-dump" $id --split-files --skip-technical --outdir "${data_folder}"
  echo ""
done

# Completion message
echo ""
echo "Done"
date


## Tidy up the log directory
## =========================
rm $PBS_O_WORKDIR/$PBS_JOBID