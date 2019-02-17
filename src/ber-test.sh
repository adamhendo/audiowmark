#!/bin/bash

TRANSFORM=$1
if [ "x$AWM_SET" == "x" ]; then
  AWM_SET=small
fi
if [ "x$AWM_SEEDS" == "x" ]; then
  AWM_SEEDS=0
fi
if [ "x$AWM_REPORT" == "x" ]; then
  AWM_REPORT=fer
fi
if [ "x$AWM_FILE" == "x" ]; then
  AWM_FILE=t
fi

{
  if [ "x$AWM_SET" == "xsmall" ]; then
    ls test/T*
  elif [ "x$AWM_SET" == "xbig" ]; then
    cat test_list
  elif [ "x$AWM_SET" != "x" ] && [ -d "$AWM_SET" ] && [ -f "$AWM_SET/T001"*wav ]; then
    ls $AWM_SET/T*
  else
    echo "bad AWM_SET $AWM_SET" >&2
    exit 1
  fi
} | while read i
do
  for SEED in $AWM_SEEDS
  do
    echo in_file $i

    if [ "x$AWM_RAND_PATTERN" != "x" ]; then
      # random pattern, 128 bit
      PATTERN=$(
        for i in $(seq 16)
        do
          printf "%02x" $((RANDOM % 256))
        done
      )
    else
      # pseudo random pattern, 128 bit
      PATTERN=4e1243bd22c66e76c2ba9eddc1f91394
    fi
    echo in_pattern $PATTERN
    echo in_flags $AWM_PARAMS --test-key $SEED
    audiowmark add "$i" ${AWM_FILE}.wav $PATTERN $AWM_PARAMS --test-key $SEED >/dev/null
    if [ "x$AWM_RAND_CUT" != x ]; then
      CUT=$RANDOM
      audiowmark cut-start "${AWM_FILE}.wav" "${AWM_FILE}.wav" $CUT
      TEST_CUT_ARGS="--test-cut $CUT"
      echo in_cut $CUT
    else
      TEST_CUT_ARGS=""
    fi
    if [ "x$TRANSFORM" == "xmp3" ]; then
      if [ "x$2" == "x" ]; then
        echo "need mp3 bitrate" >&2
        exit 1
      fi
      lame -b $2 ${AWM_FILE}.wav ${AWM_FILE}.mp3 --quiet
      OUT_FILE=${AWM_FILE}.mp3
    elif [ "x$TRANSFORM" == "xdouble-mp3" ]; then
      if [ "x$2" == "x" ]; then
        echo "need mp3 bitrate" >&2
        exit 1
      fi
      # first mp3 step (fixed bitrate)
      lame -b 128 ${AWM_FILE}.wav ${AWM_FILE}.mp3 --quiet
      rm ${AWM_FILE}.wav
      ffmpeg -i ${AWM_FILE}.mp3 ${AWM_FILE}.wav -v quiet -nostdin

      # second mp3 step
      lame -b $2 ${AWM_FILE}.wav ${AWM_FILE}.mp3 --quiet
      OUT_FILE=${AWM_FILE}.mp3
    elif [ "x$TRANSFORM" == "xogg" ]; then
      if [ "x$2" == "x" ]; then
        echo "need ogg bitrate" >&2
        exit 1
      fi
      oggenc -b $2 ${AWM_FILE}.wav -o ${AWM_FILE}.ogg --quiet
      OUT_FILE=${AWM_FILE}.ogg
    elif [ "x$TRANSFORM" == "x" ]; then
      OUT_FILE=${AWM_FILE}.wav
    else
      echo "unknown transform $TRANSFORM" >&2
      exit 1
    fi
    echo
    audiowmark cmp $OUT_FILE $PATTERN $AWM_PARAMS --test-key $SEED $TEST_CUT_ARGS
    echo
    rm -f ${AWM_FILE}.wav $OUT_FILE # cleanup temp files
  done
done | {
  if [ "x$AWM_REPORT" == "xfer" ]; then
    awk 'BEGIN { bad = n = 0 } $1 == "match_count" { if ($2 == 0) bad++; n++; } END { print bad, n, bad * 100.0 / n; }'
  elif [ "x$AWM_REPORT" == "xferv" ]; then
    awk 'BEGIN { bad = n = 0 } { print "###", $0; } $1 == "match_count" { if ($2 == 0) bad++; n++; } END { print bad, n, bad * 100.0 / n; }'
  elif [ "x$AWM_REPORT" == "xsync" ]; then
    awk 'BEGIN { bad = n = 0 } $1 == "sync_match" { bad += (3 - $2) / 3.0; n++; } END { print bad, n, bad * 100.0 / n; }'
  elif [ "x$AWM_REPORT" == "xsyncv" ]; then
    awk '{ print "###", $0; } $1 == "sync_match" { correct += $2; missing += 3 - $2; incorrect += $3-$2; print "correct:", correct, "missing:", missing, "incorrect:", incorrect; }'
  else
    echo "unknown report $AWM_REPORT" >&2
    exit 1
  fi
}
