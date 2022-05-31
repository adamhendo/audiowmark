#!/bin/bash

source test-common.sh

IN_WAV=sync-test.wav
OUT_WAV=sync-test-out.wav
CUT_WAV=sync-test-cut.wav

$AUDIOWMARK test-gen-noise $IN_WAV 200 44100 || die "failed to generate noise"
audiowmark_add $IN_WAV $OUT_WAV $TEST_MSG
# cut 20 seconds and 300 samples
$AUDIOWMARK cut-start $OUT_WAV $CUT_WAV 882300 || die "failed to cut input"
audiowmark_cmp $CUT_WAV $TEST_MSG

rm $IN_WAV $OUT_WAV $CUT_WAV
exit 0
