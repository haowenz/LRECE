#!/bin/bash -x
#
# This is a script to evaluate correction

readonly DIR_TO_SRC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
readonly LRECBENCH_DIR="$( cd "${DIR_TO_SRC}/.." >/dev/null && pwd )"
readonly COMPUTE_STATS_SCRIPT="${DIR_TO_SRC}/compute_stats.sh"

# source shflags
source "${DIR_TO_SRC}/shflags"

# Set up the args
DEFINE_string 'grid' 'qsub' "The command to submit jobs to your grid engine, e.g. qsub, sbatch. Set it to 'sh' to use shell." 'g'
DEFINE_string 'name' 'myDataSetName' 'The name of data set.' 'n'
DEFINE_string 'platform' '' "Sequencing platform, 'pb' or 'ont'" 'p'
DEFINE_integer 'minCoverage' 1 'Minimum coverage required for each base to be covered on the reference.' 'c'
DEFINE_integer 'minReadLen' 500 'Minimum read length required for each read to be involved into the evaluation.' 'l'
DEFINE_string 'reference' '' 'Path to reference file.' 'r'
DEFINE_string 'correctedReadDir' '' 'The directory which stores the corrected reads for each tool.' 'i'
DEFINE_string 'outputDir' '' 'The directory which stores the statistics.' 'o'

# Parse the command-line
FLAGS "$@" || exit $?
eval set -- "${FLAGS_ARGV}"

GRID_ENGINE='qsub'
DATA_SET_NAME=''
PLATFORM=''
MIN_COVERAGE=1
MIN_READ_LENGTH=500
REFERENCE=''
CORRECTED_READ_DIR=''
OUTPUT_DIR=''
FILTER_READS_OUTPUT_DIR=""
ALIGNMENT_OUTPUT_DIR=""
STATS_OUTPUT_DIR=""


err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@" >&2
  exit 1
}

# Check and print the args
check_args(){
  if [[ -z "${FLAGS_name// }" ]]; then
    err "Invalid data set name!"
  fi
  DATA_SET_NAME="${FLAGS_name}"
  readonly DATA_SET_NAME
  MIN_COVERAGE="${FLAGS_minCoverage}"
  readonly MIN_COVERAGE
  echo "Minimum coverage is ${MIN_COVERAGE}."
  MIN_READ_LENGTH="${FLAGS_minReadLen}"
  readonly MIN_READ_LENGTH
  echo "Minimum read length is ${MIN_READ_LENGTH}."
  if [[ "${FLAGS_platform}" == "pb" ]]; then
    echo "Sequencing platform is PacBio."
  elif [[ "${FLAGS_platform}" == "ont" ]]; then
    echo "Sequencing platform is Oxford Nanopore."
  else
    err "Invalid sequencing platform ${FLAGS_platform}!"
  fi
  PLATFORM="${FLAGS_platform}"
  echo "Reference: ${FLAGS_reference}"
  if [[ ! -f "${FLAGS_reference}" ]]; then
    err "Reference file does not exist!"
  fi
  REFERENCE="${FLAGS_reference}"
  readonly REFERENCE
  if [[ ! -d "${FLAGS_correctedReadDir}" ]]; then
    err "Corrected read directory does not exist!"
  fi
  CORRECTED_READ_DIR="${FLAGS_correctedReadDir}"
  readonly CORRECTED_READ_DIR
  OUTPUT_DIR="${FLAGS_outputDir}"
  readonly OUTPUT_DIR
  FILTER_READS_OUTPUT_DIR="${OUTPUT_DIR}/filtered_reads_${DATA_SET_NAME}"
  readonly FILTER_READS_OUTPUT_DIR
  ALIGNMENT_OUTPUT_DIR="${OUTPUT_DIR}/alignment_${DATA_SET_NAME}"
  readonly ALIGNMENT_OUTPUT_DIR
  STATS_OUTPUT_DIR="${OUTPUT_DIR}/stats_${DATA_SET_NAME}"
  readonly STATS_OUTPUT_DIR
}

main(){
  check_args
  mkdir "${FILTER_READS_OUTPUT_DIR}"
  mkdir "${ALIGNMENT_OUTPUT_DIR}"
  mkdir "${STATS_OUTPUT_DIR}"
  for corrected_read_file in ${CORRECTED_READ_DIR}/*.fasta*; do
    if [[ "${GRID_ENGINE}" == "sh" ]]; then
      sh "${COMPUTE_STATS_SCRIPT}" "${PLATFORM} ${DATA_SET_NAME} ${MIN_COVERAGE} ${MIN_READ_LENGTH} ${corrected_read_file} ${REFERENCE} ${CORRECTED_READ_DIR} ${LRECBENCH_DIR}" &
    elif [[ "${GRID_ENGINE}" == "qsub" ]]; then
      qsub "${COMPUTE_STATS_SCRIPT}" -F "${PLATFORM} ${DATA_SET_NAME} ${MIN_COVERAGE} ${MIN_READ_LENGTH} ${corrected_read_file} ${REFERENCE} ${CORRECTED_READ_DIR} ${LRECBENCH_DIR}" &
    else
      err "Grid engine ${GRID_ENGINE} is not supported."
    fi
  done
  echo "Submitted the jobs successfully."
}

main "$@"
