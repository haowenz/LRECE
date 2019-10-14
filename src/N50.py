import os
import sys
import argparse
import subprocess
import fileinput

min_read_length = 0

def get_predata_parser():
    parser=argparse.ArgumentParser(description='Compute N50 from read length distribution file.')
    parser.add_argument('-i', nargs=1, action='store', dest='read_length_distribution_file_path', required=True, help='Input read length distribution file')
    parser.add_argument('--min-length', type=int, nargs=1, action='store', dest='min_read_length', help='Minimum length of reads required (default: 0)')
    return parser

def compute_N50(read_length_distribution_file_path):
    total_read_length = 0
    read_length_list = []
    num_reads_list = []
    read_length_distribution_file = fileinput.input(files = read_length_distribution_file_path)
    for line in read_length_distribution_file:
        read_length, num_reads = map(int, line.split())
        if read_length >= min_read_length:
            read_length_list.append(read_length)
            num_reads_list.append(num_reads)
            total_read_length = total_read_length + read_length * num_reads 
    sum_read_length = 0
    N50 = 0
    while len(read_length_list) > 0 and len(num_reads_list) > 0:
        read_length = read_length_list.pop()
        num_reads = num_reads_list.pop()
        sum_read_length = sum_read_length + read_length * num_reads
        if sum_read_length >= total_read_length / 2:
            N50 = read_length
            break
    print(str(N50))
    read_length_distribution_file.close()

if __name__ == '__main__':
    parser = get_predata_parser()
    args = parser.parse_args()
    if args.min_read_length is not None:
        min_read_length = args.min_read_length[0]
    compute_N50(args.read_length_distribution_file_path[0])
