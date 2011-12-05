#!/bin/sh
#
# Launch AWE Server as a daemon process.

usage() {
    me=`basename "$0"`
    echo >&2 "Usage: $me {start|stop|restart|check|run|supervise}"
    exit 1
}

test $# -gt 0 || usage

##################################################
# Some utility functions
##################################################
running() {
  test -f $1 || return 1
  PID=`cat $1`
  ps -p $PID >/dev/null 2>/dev/null || return 1
  return 0
}

#####################################################
# Configure sane ulimits for a daemon of our size.
#####################################################

ulimit -c 0            ; # core file size
ulimit -d unlimited    ; # data seg size
ulimit -f unlimited    ; # file size
ulimit -m >/dev/null 2>&1 && ulimit -m unlimited  ; # max memory size
ulimit -n unlimited    ; # open files
ulimit -t unlimited    ; # cpu time
ulimit -v unlimited    ; # virtual memory
ulimit -x >/dev/null 2>&1 && ulimit -x unlimited  ; # file locks

##################################################
# Do the action
##################################################
case "$ACTION" in
  start)
    printf '%s' "Starting AWE Server: "

    test -z "$UID" && UID=`id | sed -e 's/^[^=]*=\([0-9]*\).*/\1/'`

    RUN_ID=`date +%s`.$$
    RUN_ARGS="$RUN_ARGS --run-id=$RUN_ID"

    if test -f "$AWE_PID" ; then
		if running "$AWE_PID" ; then
			echo "Already Running!!"
			exit 1
		else
			rm -f "$AWE_PID" "$AWE_RUN"
		fi
	fi

	if test $UID = 0 -a -n "$GERRIT_USER" ; then 
        touch "$AWE_PID"
        chown $AWE_USER "$AWE_PID"
        su - $AWE_USER -c "
          JAVA='$JAVA' ; export JAVA ;
          $RUN_EXEC $RUN_Arg1 '$RUN_Arg2' $RUN_Arg3 $RUN_ARGS &
          PID=\$! ;
          disown \$PID ;
          echo \$PID >\"$AWE_PID\""
	else
        $RUN_EXEC $RUN_Arg1 "$RUN_Arg2" $RUN_Arg3 $RUN_ARGS &
        PID=$!
        type disown >/dev/null 2>&1 && disown $PID
        echo $PID >"$AWE_PID"
      fi
    fi

    TIMEOUT=90  # seconds
    sleep 1
    while running "$AWE_PID" && test $TIMEOUT -gt 0 ; do
      if test "x$RUN_ID" = "x`cat $AWE_RUN 2>/dev/null`" ; then
        echo OK
        exit 0
      fi

      sleep 2
      TIMEOUT=`expr $TIMEOUT - 2`
    done

    echo FAILED
    exit 1
  ;;

  stop)
    printf '%s' "Stopping AWE Server: "

	PID=`cat "$AWE_PID" 2>/dev/null`
	TIMEOUT=30
	while running "$AWE_PID" && test $TIMEOUT -gt 0 ; do
		kill $PID 2>/dev/null
		sleep 1
		TIMEOUT=`expr $TIMEOUT - 1`
	done
	test $TIMEOUT -gt 0 || kill -9 $PID 2>/dev/null
	rm -f "$AWE_PID" "$AWE_RUN"
	echo OK
  ;;

  restart)
    AWE_SH=$0
    if test -f "$AWE_SH" ; then
      : OK
    else
      echo >&2 "** ERROR: Cannot locate awe.sh"
      exit 1
    fi
    $AWE_SH stop $*
    sleep 5
    $AWE_SH start $*
  ;;

  supervise)
    #
    # Under control of daemontools supervise monitor which
    # handles restarts and shutdowns via the svc program.
    #
    exec "$RUN_EXEC" $RUN_Arg1 "$RUN_Arg2" $RUN_Arg3 $RUN_ARGS
    ;;

  run|daemon)
    echo "Running Gerrit Code Review:"

    if test -f "$AWE_PID" ; then
        if running "$AWE_PID" ; then
          echo "Already Running!!"
          exit 1
        else
          rm -f "$AWE_PID"
        fi
    fi

    exec "$RUN_EXEC" $RUN_Arg1 "$RUN_Arg2" $RUN_Arg3 $RUN_ARGS --console-log
  ;;

  check)
    echo "Checking arguments to Gerrit Code Review:"
    echo "  GERRIT_SITE     =  $GERRIT_SITE"
    echo "  GERRIT_CONFIG   =  $GERRIT_CONFIG"
    echo "  GERRIT_PID      =  $GERRIT_PID"
    echo "  GERRIT_WAR      =  $GERRIT_WAR"
    echo "  GERRIT_FDS      =  $GERRIT_FDS"
    echo "  GERRIT_USER     =  $GERRIT_USER"
    echo "  JAVA            =  $JAVA"
    echo "  JAVA_OPTIONS    =  $JAVA_OPTIONS"
    echo "  RUN_EXEC        =  $RUN_EXEC $RUN_Arg1 '$RUN_Arg2' $RUN_Arg3"
    echo "  RUN_ARGS        =  $RUN_ARGS"
    echo

    if test -f "$GERRIT_PID" ; then
        if running "$GERRIT_PID" ; then
            echo "Gerrit running pid="`cat "$GERRIT_PID"`
            exit 0
        fi
    fi
    exit 1
  ;;

  *)
    usage
  ;;
esac

exit 0
