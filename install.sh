#!/bin/bash -x
#
# This is a script to set up dependencies for evaluation.
# Note that conda is required.

err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@" >&2
  exit 1
}

main(){
  conda create -n "lrece" -c bioconda minimap2 seqtk sra-tools=2.9.1 pbh5tools poretools samtools
  if [[ $? -ne 0 ]]; then
    err "Failed to install LRECE!"
  fi   
  echo "Installed LRECE successfully!"
}

main "$@"
