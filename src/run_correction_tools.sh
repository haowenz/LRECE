#!/bin/bash -x
#
# This is a warp script to run correction tools

readonly DIR_TO_SRC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

# source shflags
source "${DIR_TO_SRC}/shflags"

# Set up the args
DEFINE_string 'name' '' 'Name of the data set.' 'n'
DEFINE_string 'platform' '' 'Sequencing platform of the data set.' 'p'
DEFINE_string 'shortRead1' '' 'First sequences of paired-end short reads.' '1'
DEFINE_string 'shortRead2' '' 'Second sequences of paired-end short reads.' '2'
DEFINE_string 'shortRead' '' 'Short read file, single-end or paired-end reads in one file.' 's'
DEFINE_string 'longRead' '' 'Long read file.' 'l'
DEFINE_string 'tmpDir' '' 'Temporary directory to store intermediate results' 't'
DEFINE_string 'outputDir' '' 'Output directory to store corrected reads' 'o'

# Parse the command-line
FLAGS "$@" || exit $?
eval set -- "${FLAGS_ARGV}"

DATA_SET_NAME=''
PLATFORM=''
SHORT_READ_1=''
SHORT_READ_2=''
SHORT_READ=''
LONG_READ=''
TEMP_DIR=''
OUTPUT_DIR=''

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
  PLATFORM="${FLAGS_platform}"
  echo "Short read file 1: ${FLAGS_shortRead1}"
  if [[ ! -f "${FLAGS_shortRead1}" ]]; then
    err "Short read file 1 does not exist!"
  fi
  SHORT_READ1="${FLAGS_shortRead1}"

  echo "Short read file 2: ${FLAGS_shortRead2}"
  if [[ ! -f "${FLAGS_shortRead2}" ]]; then
    err "Short read file 2 does not exist!"
  fi
  SHORT_READ2="${FLAGS_shortRead2}"

  echo "Short read file: ${FLAGS_shortRead}"
  if [[ ! -f "${FLAGS_shortRead}" ]]; then
    err "Short read file does not exist!"
  fi
  SHORT_READ="${FLAGS_shortRead}"

  echo "Long read file: ${FLAGS_longRead}"
  if [[ ! -f "${FLAGS_longRead}" ]]; then
    err "Long read file does not exist!"
  fi
  LONG_READ="${FLAGS_longRead}"

  echo "Temporary directory: ${FLAGS_tmpDir}"
  if [[ ! -d "${FLAGS_tmpDir}" ]]; then
    err "Temporary directory does not exist!"
  fi
  TEMP_DIR="${FLAGS_tmpDir}/lrecbench_temp"
  readonly TEMP_DIR
  echo "Output directory: ${FLAGS_outputDir}"
  if [[ ! -d "${FLAGS_outputDir}" ]]; then
    err "Output directory does not exist!"
  fi
  OUTPUT_DIR="${FLAGS_outputDir}/lrecbench_output"
  readonly OUTPUT_DIR
}

main(){
  check_args
  # Add your command to run error correction tools below
}

main "$@"
