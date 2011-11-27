#!/bin/sh

  PIKE_ARGS=""

  if [ x$FINS_HOME != "x" ]; then
    PIKE_ARGS="$PIKE_ARGS -M$FINS_HOME/lib"
  else
    echo "FINS_HOME is not defined. Define if you have Fins installed outside of your standard Pike module search path."
  fi

  cd `dirname $0`/../..
  exec pike $PIKE_ARGS -x fins start tunesd $*
