#!/bin/bash

infile=$1
FILT=filt.sam
OUT=canonical.sam
SORTOUT=$2

samtools view -H $infile > header.h
 
# Filter out noncanonical reads and add to file. 
# For this command to work, the second to last column in the sam file needs to be the jM:B:c field. 
# This should always be the case after TranscriptClean.
samtools view $infile | awk '{if($(NF-1) !~ "0") print $0}' >> $OUT

# Remove duplicate mappings
cat header.h > $FILT
awk '!seen[$1]++' $OUT >> $FILT

# Sort 
samtools sort $FILT -o $SORTOUT
