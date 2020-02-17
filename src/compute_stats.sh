#!/bin/bash -x
#
# This is a script to generate correction quality

###################################################
# Put the configurations for your grid engine below
#PBS -N compute_stats
#PBS -l nodes=1:ppn=28
#PBS -l walltime=72:00:00
#PBS -q job_queue_name
#PBS -j oe
#PBS -m abe
#PBS -M your@email.com
#PBS -o /path/to/save/results
###################################################

err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@" >&2
  exit 1
}

if [[ $# -lt 8 ]]; then
    err "Usage: compute_stats.sh <platform> <data set name> <min coverage> <min read length> <corrected read> <reference> <output directory> <LRECE directory>"
fi

# Paremeters
PLATFORM="${1}"
DATA_SET_NAME="${2}"
MIN_COVERAGE="${3}"
MIN_READ_LENGTH="${4}"
CORRECTED_READ_PATH="${5}"
REFERENCE="${6}"
OUTPUT_DIR="${7}"
LRECE_DIR="${8}"
FILTER_READS_OUTPUT_DIR="${OUTPUT_DIR}/filtered_reads_${DATA_SET_NAME}"
ALIGNMENT_OUTPUT_DIR="${OUTPUT_DIR}/alignment_${DATA_SET_NAME}"
STATS_OUTPUT_DIR="${OUTPUT_DIR}/stats_${DATA_SET_NAME}"

readonly LRECE_DIR
readonly SEQTK="seqtk"
readonly MINIMAP2="minimap2"
readonly N50="${LRECE_DIR}/src/N50.py"

echo "Start to evaluate corrected reads."

# Filter the reads by the length
read_file_name=${CORRECTED_READ_PATH##*/}
read_file_name=${read_file_name%.*}
filtered_reads_file="${FILTER_READS_OUTPUT_DIR}/${read_file_name}.filtered.fasta"
"${SEQTK}" seq -L "${MIN_READ_LENGTH}" "${CORRECTED_READ_PATH}" > "${filtered_reads_file}"

# Corrected long reads are mapped to the reference using Minimap2
sam_file="${ALIGNMENT_OUTPUT_DIR}/${read_file_name}.sam"
if [[ "${PLATFORM}" == "pb" ]]; then
    "${MINIMAP2}" -ax map-pb -L "${REFERENCE}" "${filtered_reads_file}" > "${sam_file}"
elif [[ "${PLATFORM}" == "ont" ]]; then
    "${MINIMAP2}" -ax map-ont -L "${REFERENCE}" "${filtered_reads_file}" > "${sam_file}"
else
    err "Invalid sequencing platform: ${PLATFORM}."
fi
rm "${filtered_reads_file}"

# We use samtools to generate stats
eval "$(conda shell.bash hook)"
conda activate lrece
bam_file="${ALIGNMENT_OUTPUT_DIR}/${read_file_name}.bam"
samtools view -o "${bam_file}" "${sam_file}"
rm "${sam_file}"
sorted_bam_file="${ALIGNMENT_OUTPUT_DIR}/${read_file_name}.sorted.bam"
samtools sort -o "${sorted_bam_file}" "${bam_file}"
rm "${bam_file}"
samtools index "${sorted_bam_file}"
stats_file="${STATS_OUTPUT_DIR}/${read_file_name}.stats"
samtools stats -F 0x900 "${sorted_bam_file}" > "${stats_file}"

# extract basic stats
stats_txt_file="${STATS_OUTPUT_DIR}/${read_file_name}.txt"
grep ^SN "${stats_file}" | cut -f 2- > "${stats_txt_file}" 

# extract read length distribution (two columns, one for read length, the other one for the number of reads in that length
read_length_file="${STATS_OUTPUT_DIR}/${read_file_name}.rl"
grep ^RL "${stats_file}" | cut -f 2- > ${read_length_file}

# run a python script to get N50
printf "N50:    " >> "${stats_txt_file}"
python "${N50}" -i "${read_length_file}" --min-length "${MIN_READ_LENGTH}" >> "${stats_txt_file}"
rm "${read_length_file}"

# Calculate genome coverage
bed_file="${STATS_OUTPUT_DIR}/${read_file_name}.bed"
bedtools genomecov -max "${MIN_COVERAGE}" -ibam "${sorted_bam_file}" > "${bed_file}"
rm "${sorted_bam_file}"
printf "Genome fraction:    " >> "${stats_txt_file}"
cut -f 5- "${bed_file}" | tail -1 >> "${stats_txt_file}"
rm "${bed_file}"

conda deactivate

echo "Finished evaluating corrected reads."
