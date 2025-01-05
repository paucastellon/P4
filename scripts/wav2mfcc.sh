#!/bin/bash

# Make pipeline return code the last non-zero one or zero if all the commands return zero.
set -o pipefail

## \file
## \TODO This file now calculates MFCC features instead of LPC features.

# Base name for temporary files
base=/tmp/$(basename $0).$$ 

# Ensure cleanup of temporary files on exit
trap cleanup EXIT
cleanup() {
   \rm -f $base.*
}

if [[ $# != 3 ]]; then
   echo "$0 mfcc_order input.wav output.mfcc"
   exit 1
fi

mfcc_order=$1
inputfile=$2
outputfile=$3
melfilter_order=16
freq_order=8

UBUNTU_SPTK=1
if [[ $UBUNTU_SPTK == 1 ]]; then
   # In case you install SPTK using debian package (apt-get)
   X2X="sptk x2x"
   FRAME="sptk frame"
   WINDOW="sptk window"
   MFCC="sptk mfcc"
else
   # or install SPTK building it from its source
   X2X="x2x"
   FRAME="frame"
   WINDOW="window"
   MFCC="mfcc"
fi

# Main command for MFCC feature extraction
sox $inputfile -t raw -e signed -b 16 - | $X2X +sf | $FRAME -l 240 -p 80 | $WINDOW -l 240 -L 240 |
  $MFCC -s $freq_order -l 180 -m $mfcc_order -n $melfilter_order > $base.mfcc || exit 

# Our array files need a header with the number of cols and rows:
ncol=$((mfcc_order + 1)) # MFCC includes energy term
nrow=$(($($X2X +fa < $base.mfcc | wc -l) / ncol))

# Build fmatrix file by placing nrow and ncol in front, and the data after them
echo $nrow $ncol | $X2X +aI > $outputfile
cat $base.mfcc >> $outputfile
