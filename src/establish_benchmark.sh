#!/bin/bash -x
#
# This is a script to download sequencing data and establish benchmark

readonly DIR_TO_SRC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
readonly LRECE_DIR="$( cd "${DIR_TO_SRC}/.." >/dev/null && pwd )"
readonly EXTERN_DIR="${LRECE_DIR}/extern"
readonly FASTERQ_DUMP="${LRECE_DIR}/ncbi/bin/fasterq-dump"
readonly SEQTK="${EXTERN_DIR}/seqtk/seqtk"

# source shflags
source "${DIR_TO_SRC}/shflags"

# Set up the args
DEFINE_boolean 'ecoli' false 'Include E. coli data set into the benchmark' 'e'
DEFINE_boolean 'yeast' false 'Include yeast data set into the benchmark' 'y'
DEFINE_boolean 'fruitFly' false 'Include fruit fly data set into the benchmark' 'f'
DEFINE_string 'tmpDir' '' 'Temporary directory to store downloaded data' 't'
DEFINE_string 'benDir' '' 'Directory to store benchmark' 'o'

# Parse the command-line
FLAGS "$@" || exit $?
eval set -- "${FLAGS_ARGV}"

# Data sets for E. coli
readonly RAW_D1I1="ftp://webdata:webdata@ussd-ftp.illumina.com/Data/SequencingRuns/MG1655/MiSeq_Ecoli_MG1655_110721_PF_R1.fastq.gz" 
readonly RAW_D1I2="ftp://webdata:webdata@ussd-ftp.illumina.com/Data/SequencingRuns/MG1655/MiSeq_Ecoli_MG1655_110721_PF_R2.fastq.gz"
readonly RAW_D1P="https://s3.amazonaws.com/files.pacb.com/datasets/secondary-analysis/e-coli-k12-P6C4/p6c4_ecoli_RSII_DDR2_with_15kb_cut_E01_1.tar.gz"
readonly RAW_D1O1D="${LRECE_DIR}/accession_lists/D1O1D.txt" # need sra tools
readonly RAW_D1O2D1="ftp://ftp.sra.ebi.ac.uk/vol1/run/ERR764/ERR764952/flowcell_20_LomanLabz_PC_Ecoli_K12_R7.3.tar"
readonly RAW_D1O2D2="ftp://ftp.sra.ebi.ac.uk/vol1/run/ERR764/ERR764953/flowcell_32_LomanLabz_K12_His_tag.tar"
readonly RAW_D1O2D3="ftp://ftp.sra.ebi.ac.uk/vol1/run/ERR764/ERR764954/flowcell_33_LomanLabz_PC_K12_0.4SPRI_Histag.tar"
readonly RAW_D1O2D4="ftp://ftp.sra.ebi.ac.uk/vol1/run/ERR764/ERR764955/flowcell_39.tar"

# flowcell data to generate 2D reads (the ncbi links are unvalid, use the links from ebi instead)
# ERX708228: https://sra-download.ncbi.nlm.nih.gov/traces/era21/ERZ/000764/ERR764952/flowcell_20_LomanLabz_PC_Ecoli_K12_R7.3.tar
# ERX708229: https://sra-download.ncbi.nlm.nih.gov/traces/era21/ERZ/000764/ERR764953/flowcell_32_LomanLabz_K12_His_tag.tar
# ERX708230: https://sra-download.ncbi.nlm.nih.gov/traces/era21/ERZ/000764/ERR764954/flowcell_33_LomanLabz_PC_K12_0.4SPRI_Histag.tar
# ERX708231: https://sra-download.ncbi.nlm.nih.gov/traces/era21/ERZ/000764/ERR764955/flowcell_39.tar
# ftp://ftp.sra.ebi.ac.uk/vol1/ERA411/ERA411499/oxfordnanopore_native/flowcell_20_LomanLabz_PC_Ecoli_K12_R7.3.tar
# ftp://ftp.sra.ebi.ac.uk/vol1/ERA411/ERA411499/oxfordnanopore_native/flowcell_32_LomanLabz_K12_His_tag.tar
# ftp://ftp.sra.ebi.ac.uk/vol1/ERA411/ERA411499/oxfordnanopore_native/flowcell_33_LomanLabz_PC_K12_0.4SPRI_Histag.tar
# ftp://ftp.sra.ebi.ac.uk/vol1/ERA411/ERA411499/oxfordnanopore_native/flowcell_39.tar

# Data sets for yeast
readonly RAW_D2I="${LRECE_DIR}/accession_lists/D2I.txt" # need sra tools
readonly RAW_D2P="${LRECE_DIR}/accession_lists/D2P.txt" # need sra tools
readonly RAW_D2P1="https://sra-download.ncbi.nlm.nih.gov/traces/era17/ERZ/001655/ERR1655118/ERR1655118_hdf5.tgz"
readonly RAW_D2P2="https://sra-download.ncbi.nlm.nih.gov/traces/era16/ERZ/001655/ERR1655119/ERR1655119_hdf5.tgz"
readonly RAW_D2P3="https://sra-download.ncbi.nlm.nih.gov/traces/era15/ERZ/001655/ERR1655125/ERR1655125_hdf5.tgz"
readonly RAW_D2O="https://www.ebi.ac.uk/biostudies/files/S-BSST17/u/yeast_ont_scirep7_3935.tar.gz" 

# Data sets for fruit fly
readonly RAW_D3I="${LRECE_DIR}/accession_lists/D3I.txt" # need sra tools
readonly RAW_D3P="${LRECE_DIR}/accession_lists/D3P.txt" # need sra tools
readonly RAW_D3O="${LRECE_DIR}/accession_lists/D3O.txt" # need sra tools

# Variables for configuration
TEMP_DIR=""
BENCHMARK_DIR=""

err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@" >&2
  exit 1
}

# Check and print the args
check_args(){
  if [[ "${FLAGS_ecoli}" -eq "${FLAGS_TRUE}" ]]; then
    echo "E. coli data set will be included into the benchmark."
  fi
  if [[ "${FLAGS_yeast}" -eq "${FLAGS_TRUE}" ]]; then
    echo "Yeast data set will be included into the benchmark."
  fi
  if [[ "${FLAGS_fruitFly}" -eq "${FLAGS_TRUE}" ]]; then
    echo "Fruit fly data set will be included into the benchmark."
  fi
  echo "Temporary directory: ${FLAGS_tmpDir}"
  if [[ ! -d "${FLAGS_tmpDir}" ]]; then
    err "Temporary directory does not exist!"
  fi
  TEMP_DIR="${FLAGS_tmpDir}/LRECE_temp"
  readonly TEMP_DIR
  echo "Benchmark directory: ${FLAGS_benDir}"
  if [[ ! -d "${FLAGS_benDir}" ]]; then
    err "Benchmark directory does not exist!"
  fi
  BENCHMARK_DIR="${FLAGS_benDir}/LRECE_benchmark"
  readonly BENCHMARK_DIR
}

#######################################
# Download data with a accession list
# using sra tools 
# Globals:
#   FASTERQ_DUMP
# Arguments:
#   accession_list
#   concatenated
#   destination_read_file
#   name_prefix
# Returns:
#   None
#######################################
download_data_with_sra_tools(){
  local accession_list
  accession_list="${1}"
  local concatenated
  concatenated="${2}"
  local destination_read_file
  destination_read_file="${3}"
  local name_prefix
  name_prefix="${4}"
  while read -r accession || [[ -n "${accession}" ]]; do
    echo "Start to download ${accession}."
    if [[ "${concatenated}" = true ]]; then
      "${FASTERQ_DUMP}" "${accession}" --concatenate-reads
      cat "${accession}.fastq" >> "${destination_read_file}"
      rm "${accession}.fastq"
    else
      "${FASTERQ_DUMP}" "${accession}"
      for file in ${accession}*.fastq; do
        mv "${file}" "${file/${accession}/${name_prefix}}"
      done
    fi  
    echo "Finished loading ${accession}."
  done < "${accession_list}"
}

prepare_ecoli_data(){
  local d1_dir
  d1_dir="${BENCHMARK_DIR}/ecoli"
  mkdir "${d1_dir}"
  local temp_d1_dir
  temp_d1_dir="${TEMP_DIR}/ecoli"
  mkdir "${temp_d1_dir}"

  # Prepare short reads
  cd "${temp_d1_dir}"
  local ecoli_miseq_1_file_name
  ecoli_miseq_1_file_name="ecoli_miseq_1.fastq.gz"
  echo "Start to download E. coli Miseq data 1."
  wget "${RAW_D1I1}" -O "${ecoli_miseq_1_file_name}"
  if [[ $? -ne 0 ]]; then
    err "Failed to download E. coli Miseq data!"
  fi
  echo "Downloaded E. coli Miseq data 1 successfully."
  echo "Start to decompress it."
  gzip -d "${ecoli_miseq_1_file_name}"
  if [[ $? -ne 0 ]]; then
    err "Failed to decompress E. coli Miseq data 1!"
  fi
  echo "Decompressed it successfully."
  ecoli_miseq_1_file_name="${ecoli_miseq_1_file_name%.*}"
  mv "${ecoli_miseq_1_file_name}" "${d1_dir}"
  ${SEQTK} seq -A "${d1_dir}/${ecoli_miseq_1_file_name}" > "${d1_dir}/${ecoli_miseq_1_file_name/%.fastq/.fasta}" 

  local ecoli_miseq_2_file_name
  ecoli_miseq_2_file_name="ecoli_miseq_2.fastq.gz"
  echo "Start to download E. coli Miseq data 2."
  wget "${RAW_D1I2}" -O "${ecoli_miseq_2_file_name}"
  if [[ $? -ne 0 ]]; then
    err "Failed to download E. coli Miseq data 2!"
  fi
  echo "Downloaded E. coli Miseq data 2 successfully."
  echo "Start to decompress it."
  gzip -d "${ecoli_miseq_2_file_name}"
  if [[ $? -ne 0 ]]; then
    err "Failed to decompress E. coli Miseq data!"
  fi
  echo "Decompressed it successfully."
  ecoli_miseq_2_file_name="${ecoli_miseq_2_file_name%.*}"
  mv "${ecoli_miseq_2_file_name}" "${d1_dir}"
  "${SEQTK}" seq -A "${d1_dir}/${ecoli_miseq_2_file_name}" > "${d1_dir}/${ecoli_miseq_2_file_name/%.fastq/.fasta}" 

  # Prepare pacbio reads
  local ecoli_pacbio_file_name
  ecoli_pacbio_file_name="ecoli_pacbio.tar.gz"
  echo "Start to download E. coli PacBio data."
  wget "${RAW_D1P}" -O "${ecoli_pacbio_file_name}"
  if [[ $? -ne 0 ]]; then
    err "Failed to download E. coli PacBio data!"
  fi
  echo "Downloaded E. coli PacBio data successfully."
  echo "Start to decompress it."
  tar -xf "${ecoli_pacbio_file_name}" && rm "${ecoli_pacbio_file_name}"
  echo "Decompressed it successfully."
  if [[ $? -ne 0 ]]; then
    err "Failed to decompress E. coli PacBio data!"
  fi
  # Need pbh5tools (https://github.com/PacificBiosciences/pbh5tools) to extract data
  echo "Start to extract E. coli PacBio data with pbh5tools."
  source activate pbh5tools
  bash5tools.py --readType "subreads" --outFilePrefix ecoli_pacbio --outType "fastq"  "E01_1/Analysis_Results/m141013_011508_sherri_c100709962550000001823135904221533_s1_p0.bas.h5"
  source deactivate
  rm -r "E01_1"
  echo "Extract E. coli PacBio data successfully!"
  mv "ecoli_pacbio.fastq" "${d1_dir}"
  "${SEQTK}" seq -A "${d1_dir}/ecoli_pacbio.fastq" > "${d1_dir}/ecoli_pacbio.fasta" 

  # Prepare Nanopore reads
  local ecoli_ont_2D
  ecoli_ont_2D="ecoli_ont_2D.fastq"
  touch "${ecoli_ont_2D}"
  local ecoli_ont_1_file_name
  ecoli_ont_1_file_name="ecoli_ont_1.tar"
  echo "Start to download E. coli ONT data 1."
  wget "${RAW_D1O2D1}" -O "${ecoli_ont_1_file_name}"
  if [[ $? -ne 0 ]]; then
    err "Failed to download E. coli ONT data 1!"
  fi
  echo "Downloaded E. coli ONT data 1 successfully."
  echo "Start to decompress it."
  tar -xf "${ecoli_ont_1_file_name}" && rm "${ecoli_ont_1_file_name}"
  echo "Decompressed it successfully."
  if [[ $? -ne 0 ]]; then
    err "Failed to decompress E. coli ONT data 1!"
  fi
  source activate poretools
  echo "Start to extract 2D reads."
  poretools fastq --type 2D "flowcell_20/1.9/downloads/pass/" >> "${ecoli_ont_2D}"
  rm -r "flowcell_20"
  echo "Extracted 2D reads successfully."

  local ecoli_ont_2_file_name
  ecoli_ont_2_file_name="ecoli_ont_2.tar"
  echo "Start to download E. coli ONT data 2."
  wget "${RAW_D1O2D2}" -O "${ecoli_ont_2_file_name}"
  if [[ $? -ne 0 ]]; then
    err "Failed to download E. coli ONT data 2!"
  fi
  echo "Downloaded E. coli ONT data 2 successfully."
  echo "Start to decompress it."
  tar -xf "${ecoli_ont_2_file_name}" && rm "${ecoli_ont_2_file_name}"
  echo "Decompressed it successfully."
  if [[ $? -ne 0 ]]; then
    err "Failed to decompress E. coli ONT data 2!"
  fi
  echo "Start to extract 2D reads."
  poretools fastq --type 2D "flowcell_32/downloads/pass/" >> "${ecoli_ont_2D}"
  rm -r "flowcell_32"
  echo "Extracted 2D reads successfully."

  local ecoli_ont_3_file_name
  echo "Start to download E. coli ONT data 3."
  ecoli_ont_3_file_name="ecoli_ont_3.tar"
  wget "${RAW_D1O2D3}" -O "${ecoli_ont_3_file_name}"
  if [[ $? -ne 0 ]]; then
    err "Failed to download E. coli ONT data 3!"
  fi
  echo "Downloaded E. coli ONT data 3 successfully."
  echo "Start to decompress it."
  tar -xf "${ecoli_ont_3_file_name}" && rm "${ecoli_ont_3_file_name}"
  echo "Decompressed it successfully."
  if [[ $? -ne 0 ]]; then
    err "Failed to decompress E. coli ONT data 3!"
  fi
  echo "Start to extract 2D reads."
  poretools fastq --type 2D "flowcell_33/downloads/pass/" >> "${ecoli_ont_2D}"
  rm -r "flowcell_33"
  echo "Extracted 2D reads successfully."

  local ecoli_ont_4_file_name
  echo "Start to download E. coli ONT data 4."
  ecoli_ont_4_file_name="ecoli_ont_4.tar"
  wget "${RAW_D1O2D4}" -O "${ecoli_ont_4_file_name}"
  if [[ $? -ne 0 ]]; then
    err "Failed to download E. coli ONT data 4!"
  fi
  echo "Downloaded E. coli ONT data 4 successfully."
  echo "Start to decompress it."
  tar -xf "${ecoli_ont_4_file_name}" && rm "${ecoli_ont_4_file_name}"
  echo "Decompressed it successfully."
  if [[ $? -ne 0 ]]; then
    err "Failed to decompress E. coli ONT data 4!"
  fi
  echo "Start to extract 2D reads."
  poretools fastq --type 2D "flowcell_39_K12_Histag/downloads/pass/" >> "${ecoli_ont_2D}"
  rm -r "flowcell_39_K12_Histag"
  echo "Extracted 2D reads successfully."
  source deactivate
  mv "${ecoli_ont_2D}" "${d1_dir}"
  "${SEQTK}" seq -A "${d1_dir}/ecoli_ont_2D.fastq" > "${d1_dir}/ecoli_ont_2D.fasta"

  local ecoli_ont_1D
  ecoli_ont_1D="ecoli_ont_1D.fastq"
  touch "${ecoli_ont_1D}"
  download_data_with_sra_tools "${RAW_D1O1D}" true "${ecoli_ont_1D}" 'NULL'
  mv "${ecoli_ont_1D}" "${d1_dir}" 
  "${SEQTK}" seq -A "${d1_dir}/ecoli_ont_1D.fastq" > "${d1_dir}/ecoli_ont_1D.fasta"
}

prepare_yeast_data(){ 
  local d2_dir 
  d2_dir="${BENCHMARK_DIR}/yeast" 
  mkdir "${d2_dir}" 
  local temp_d2_dir 
  temp_d2_dir="${TEMP_DIR}/yeast" 
  mkdir "${temp_d2_dir}" 
  cd "${temp_d2_dir}" # Will stay in this directory before the end of the function! 
 
  # Prepare short reads 
  echo "Start to prepare yeast short reads."
  download_data_with_sra_tools "${RAW_D2I}" false 'NULL' 'yeast_miseq'
  mv yeast_miseq* "${d2_dir}"
  "${SEQTK}" seq -A "${d2_dir}/yeast_miseq_1.fastq" > "${d2_dir}/yeast_miseq_1.fasta"
  "${SEQTK}" seq -A "${d2_dir}/yeast_miseq_2.fastq" > "${d2_dir}/yeast_miseq_2.fasta"
  echo "Finished yeast short read preparation successfully."
  
  # Prepare PacBio reads
  echo "Start to prepare yeast PacBio reads."
  local yeast_pacbio
  yeast_pacbio="yeast_pacbio.fastq"
  touch "${yeast_pacbio}"
  source activate pbh5tools

  echo "Start to download yeast PacBio data 1."
  wget "${RAW_D2P1}"
  if [[ $? -ne 0 ]]; then
    err "Failed to download yeast PacBio data 1!"
  fi
  echo "Downloaded yeast PacBio data successfully."
  echo "Start to decompress it."
  gzip -d "ERR1655118_hdf5.tgz"
  if [[ $? -ne 0 ]]; then
    err "Failed to decompress yeast PacBio data!"
  fi
  echo "Decompressed it successfully."
  echo "Start to decompress it."
  tar -xf "ERR1655118_hdf5.tar" && rm "ERR1655118_hdf5.tar"
  echo "Decompressed it successfully."
  echo "Start to extract yeast PacBio data with pbh5tools."
  bash5tools.py --readType "subreads" --outFilePrefix yeast_pacbio_1 --minLength 500 --minReadScore 0.8000 --outType "fastq"  "m150412_173450_00127_c100782612550000001823173608251585_s1_p0.bas.h5"
  cat "yeast_pacbio_1.fastq" >> "${yeast_pacbio}"
  rm "yeast_pacbio_1.fastq"
  rm -rf m150412_173450_00127_c100782612550000001823173608251585_s1_p0*
  echo "Extract yeast PacBio data successfully!"

  echo "Start to download yeast PacBio data 2."
  wget "${RAW_D2P2}"
  if [[ $? -ne 0 ]]; then
    err "Failed to download yeast PacBio data 2!"
  fi
  echo "Downloaded yeast PacBio data successfully."

  echo "Start to decompress it."
  gzip -d "ERR1655119_hdf5.tgz"
  if [[ $? -ne 0 ]]; then
    err "Failed to decompress yeast PacBio data!"
  fi
  echo "Decompressed it successfully."
  echo "Start to decompress it."
  tar -xf "ERR1655119_hdf5.tar" && rm "ERR1655119_hdf5.tar"
  echo "Decompressed it successfully."
  echo "Start to extract yeast PacBio data with pbh5tools."
  bash5tools.py --readType "subreads" --outFilePrefix yeast_pacbio_2 --minLength 500 --minReadScore 0.8000 --outType "fastq"  "m150415_122551_00127_c100785582550000001823160308251567_s1_p0.bas.h5"
  cat "yeast_pacbio_2.fastq" >> "${yeast_pacbio}"
  rm "yeast_pacbio_2.fastq"
  rm -rf m150415_122551_00127_c100785582550000001823160308251567_s1_p0*
  echo "Extract yeast PacBio data successfully!"

  echo "Start to download yeast PacBio data 3."
  wget "${RAW_D2P3}"
  if [[ $? -ne 0 ]]; then
    err "Failed to download yeast PacBio data 3!"
  fi
  echo "Downloaded yeast PacBio data successfully."
  echo "Start to decompress it."
  gzip -d "ERR1655125_hdf5.tgz"
  if [[ $? -ne 0 ]]; then
    err "Failed to decompress yeast PacBio data!"
  fi
  echo "Decompressed it successfully."
  echo "Start to decompress it."
  tar -xf "ERR1655125_hdf5.tar" && rm "ERR1655125_hdf5.tar"
  echo "Decompressed it successfully."
  echo "Start to extract yeast PacBio data with pbh5tools."
  bash5tools.py --readType "subreads" --outFilePrefix yeast_pacbio_3 --minLength 500 --minReadScore 0.8000 --outType "fastq"  "m150423_060136_00127_c100802652550000001823174910081537_s1_p0.bas.h5"
  cat "yeast_pacbio_3.fastq" >> "${yeast_pacbio}"
  rm "yeast_pacbio_3.fastq"
  rm -rf m150423_060136_00127_c100802652550000001823174910081537_s1_p0*
  echo "Extract yeast PacBio data successfully!"

  source deactivate
  mv "${yeast_pacbio}" "${d2_dir}"
  "${SEQTK}" seq -A "${d2_dir}/yeast_pacbio.fastq" > "${d2_dir}/yeast_pacbio.fasta"
  echo "Finished yeast PacBio read preparation successfully."

  # Prepare ONT reads  
  echo "Start to prepare yeast ONT reads."
  local yeast_ont_file_name
  yeast_ont_file_name="yeast_ont.tar.gz"
  echo "Start to download yeast ONT data."
  wget "${RAW_D2O}" -O "${yeast_ont_file_name}"
  if [[ $? -ne 0 ]]; then
    err "Failed to download yeast ONT data!"
  fi
  echo "Downloaded yeast ONT data successfully."
  echo "Start to decompress it."
  gzip -d "${yeast_ont_file_name}"
  if [[ $? -ne 0 ]]; then
    err "Failed to decompress yeast ONT data!"
  fi
  echo "Decompressed it successfully."
  echo "Start to decompress it."
  yeast_ont_file_name="yeast_ont.tar"
  tar -xf "${yeast_ont_file_name}" && rm "${yeast_ont_file_name}"
  if [[ $? -ne 0 ]]; then
    err "Failed to decompress yeast ONT data!"
  fi
  echo "Decompressed it successfully."
  mv "${temp_d2_dir}/Yeast_ONT_SciRep7_3935/s288c_all2D.fastq" "${d2_dir}/yeast_ont_all.fastq"
  mv "${temp_d2_dir}/Yeast_ONT_SciRep7_3935/s288c_pass2D.fastq" "${d2_dir}/yeast_ont_pass.fastq"
  rm -r "${temp_d2_dir}/Yeast_ONT_SciRep7_3935"
  ${SEQTK} seq -A "${d2_dir}/yeast_ont_all.fastq" > "${d2_dir}/yeast_ont_all.fasta" 
  ${SEQTK} seq -A "${d2_dir}/yeast_ont_pass.fastq" > "${d2_dir}/yeast_ont_pass.fasta" 
  echo "Finished yeast ONT read preparation successfully."
}

prepare_fruit_fly_data(){
  local d3_dir 
  d3_dir="${BENCHMARK_DIR}/fruit_fly" 
  mkdir "${d3_dir}" 
  local temp_d3_dir 
  temp_d3_dir="${TEMP_DIR}/fruit_fly" 
  mkdir "${temp_d3_dir}" 
  cd "${temp_d3_dir}" # Will stay in this directory before the end of the function! 

  # Prepare short reads 
  echo "Start to prepare fruit fly short reads."
  download_data_with_sra_tools "${RAW_D3I}" false 'NULL' 'fruit_fly_nextseq'
  mv fruit_fly_nextseq* "${d3_dir}"
  "${SEQTK}" seq -A "${d3_dir}/fruit_fly_nextseq_1.fastq" > "${d3_dir}/fruit_fly_nextseq_1.fasta"
  "${SEQTK}" seq -A "${d3_dir}/fruit_fly_nextseq_2.fastq" > "${d3_dir}/fruit_fly_nextseq_2.fasta"
  echo "Finished fruit fly short read preparation successfully."

  # Prepare PacBio reads
  echo "Start to prepare fruit fly PacBio reads."
  local fruit_fly_pacbio
  fruit_fly_pacbio="fruit_fly_pacbio.fastq"
  touch "${fruit_fly_pacbio}"
  download_data_with_sra_tools "${RAW_D3P}" true "${fruit_fly_pacbio}" 'NULL'
  mv "${fruit_fly_pacbio}" "${d3_dir}" 
  "${SEQTK}" seq -A "${d3_dir}/fruit_fly_pacbio.fastq" > "${d3_dir}/fruit_fly_pacbio.fasta"
  echo "Finished fruit fly PacBio read preparation successfully."

  # Prepare ONT reads
  echo "Start to prepare fruit fly ONT reads."
  local fruit_fly_ont
  fruit_fly_ont="fruit_fly_ont.fastq"
  touch "${fruit_fly_ont}"
  download_data_with_sra_tools "${RAW_D3O}" true "${fruit_fly_ont}" 'NULL'
  mv "${fruit_fly_ont}" "${d3_dir}" 
  "${SEQTK}" seq -A "${d3_dir}/fruit_fly_ont.fastq" > "${d3_dir}/fruit_fly_ont.fasta"
  echo "Finished fruit fly ONT read preparation successfully."
}

# TODO(haowen): Generate subsamples if necessary.

main(){
  check_args
  # TODO(haowen): Start from last time to establish the benchmark
  mkdir "${TEMP_DIR}"
  mkdir "${BENCHMARK_DIR}"
  if [[ "${FLAGS_ecoli}" -eq "${FLAGS_TRUE}" ]]; then
    echo "Start to prepare E. coli data set."
    prepare_ecoli_data
    if [[ $? -ne 0 ]]; then
      err "Failed to prepare E. coli data set."
    fi
    echo "E. coli data set is ready."
  fi
  if [[ "${FLAGS_yeast}" -eq "${FLAGS_TRUE}" ]]; then
    echo "Start to prepare yeast data set."
    prepare_yeast_data
    if [[ $? -ne 0 ]]; then
      err "Failed to prepare yeast data set."
    fi
    echo "Yeast data set is ready."
  fi
  if [[ "${FLAGS_fruitFly}" -eq "${FLAGS_TRUE}" ]]; then
    echo "Start to prepare fruit fly data set."
    prepare_fruit_fly_data
    if [[ $? -ne 0 ]]; then
      err "Failed to prepare fruit fly data set."
    fi
    echo "Fruit fly data set is ready."
  fi
}

main "$@"
