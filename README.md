# LRECE
LRECE (**L**ong **R**ead **E**rror **C**orrection **E**valuation) is a set of scripts that can establish benchmark data sets, run error correction tools and evaluation correction quality.

## Installation
### Install dependencies
Make sure [Conda](https://conda.io/docs/) is in your *PATH* environment variable. A Conda environment named *lrece* will be created after the installation.

LRECE also uses [minimap2](https://github.com/lh3/minimap2/), [seqtk](https://github.com/lh3/seqtk/), [ncbi-vdb](https://github.com/ncbi/ncbi-vdb/), [ngs](https://github.com/ncbi/ngs/) and [sra-tools](https://github.com/ncbi/sra-tools/) as submodules. But you don't have to install them by yourself since we provide a script to build and install them.

[pbh5tools](https://github.com/PacificBiosciences/pbh5tools), [poretools](https://github.com/arq5x/poretools) and [Samtools](http://www.htslib.org) are also required but will be installed by Conda.

### Download and install
First get the repo:
```
git clone git@github.com:haowenz/LRECE.git
```
Then just run:
```
cd LRECE && sh install.sh
```
LRECE will download the submodules and build them automatically. Note that two Conda environments, *pbh5tools* and *poretools* will be created.

## Usage
### Establish benchmark
Before you run error correction tools, you need to get the benchmark data sets first. Download *E. coli* and yeast sequencing data and store them into *benDir* while use *tmpDir* to store temperary raw data:
```
sh establish_benchmark.sh -e -y -t tmpDir -o benDir
```
Or you can get more help information:
```
sh establish_benchmark.sh -h
```
The benchmark data sets can also be downloaded manually from [here]().

### Run error correction tools
Use paired-end short reads to correct PacBio long reads:
```
sh run_correction_tools.sh -n 'data_set_name' -p 'pb' -1 data/short_read_1.fa -2 data/short_read_2.fa -l data/long_read.fa -t tmpDir -o outputDir
```
Or use paired-end short reads to correct ONT long reads:
```
sh run_correction_tools.sh -n 'data_set_name' -p 'ont' -1 data/short_read_1.fa -2 data/short_read_2.fa -l data/long_read.fa -t tmpDir -o outputDir
```
For help information:
```
sh run_correction_tools.sh -h
```
Note that you should put the commands to run your error correction tools into the *main* function of this script.

### Evaluate correction quality
For all the corrected read files in *correctedReadDir*, filter out corrected PacBio reads of length less than 1000bp and run evaluation script on current node:
```
sh evaluate_correction.sh -g 'sh' -n 'data_set_name' -p 'pb' -l 1000 -r data/ref.fa -i correctedReadDir -o outputDir
```
Filter out corrected ONT reads of length less than 500bp (default value for -l) and submit evaluation job with *qsub*:
```
sh evaluate_correction.sh -n 'data_set_name' -p 'ont' -r data/ref.fa -i correctedReadDir -o outputDir
```
Print the help information:
```
sh evaluate_correction.sh -h
```
