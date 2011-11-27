#!/bin/sh

  PIKE_ARGS=""

  if [ x$FINS_HOME != "x" ]; then
    PIKE_ARGS="$PIKE_ARGS -M$FINS_HOME/lib"
  else
    echo "FINS_HOME is not defined. Define if you have Fins installed outside of your standard Pike module search path."
  fi

  ARG0=$1
  if [ x$ARG0 = "x" ]; then
    echo "$0: no command given."
    exit 1
  fi
  shift 1

  cd `dirname $0`/../..
  exec pike $PIKE_ARGS -x fins $ARG0 tunesd $*
