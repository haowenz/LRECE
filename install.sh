#!/bin/bash -x
#
# This is a script to set up dependencies for evaluation.
# Note that conda is required.

readonly LRECBENCH_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
readonly NCBI_DIR="${LRECBENCH_DIR}/ncbi"

err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@" >&2
  exit 1
}

install_seqtk(){
  echo "Start to install seqtk."
  local seqtk_dir
  seqtk_dir="${LRECBENCH_DIR}/seqtk"
  cd "${seqtk_dir}"
  make 
  if [[ $? -ne 0 ]]; then
    err "Failed to install seqtk!"
  fi   
  echo "Installed seqtk successfully!"
}

install_minimap2(){
  echo "Start to install minimap2"
  local minimap2_dir
  minimap2_dir="${LRECBENCH_DIR}/minimap2"
  cd "${minimap2_dir}"
  make 
  if [[ $? -ne 0 ]]; then
    err "Failed to install minimap2!"
  fi   
  echo "Installed minimap2 successfully!"
}

install_ngs(){
  echo "Start to install ngs."
  local ngs_dir
  ngs_dir="${LRECBENCH_DIR}/ngs"
  cd "${ngs_dir}"
  ./configure --build-prefix="${NCBI_DIR}/build" --prefix="${NCBI_DIR}"
  make && make install
  if [[ $? -ne 0 ]]; then
    err "Failed to install ngs!"
  fi   
  echo "Installed ngs successfully!"
}

install_ncbi_vdb(){
  echo "Start to install ncbi-vdb."
  local ncbi_vdb_dir
  ncbi_vdb_dir="${LRECBENCH_DIR}/ncbi-vdb"
  cd "${ncbi_vdb_dir}"
  ./configure --build-prefix="${NCBI_DIR}/build" --prefix="${NCBI_DIR}"
  make && make install
  if [[ $? -ne 0 ]]; then
    err "Failed to install ncbi-vdb!"
  fi   
  echo "Installed ncbi-vdb successfully!"
}

install_sra_tools(){
  echo "Start to install sra tools."
  echo "sra tools require ncbi-vdb and ngs. Start to install them first."
  install_ngs
  install_ncbi_vdb
  local sra_tools_dir
  sra_tools_dir="${LRECBENCH_DIR}/sra-tools"
  cd "${sra_tools_dir}"
  ./configure --build-prefix="${NCBI_DIR}/build" --prefix="${NCBI_DIR}"
  make && make install
  if [[ $? -ne 0 ]]; then
    err "Failed to install sra tools!"
  fi   
  echo "Installed sra tools successfully!"
}

main(){
  git submodule update
  install_seqtk
  install_minimap2
  install_sra_tools
  conda create -n "pbh5tools" pbh5tools
  conda create -n "poretools" poretools
}

main "$@"
