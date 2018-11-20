#!/bin/bash
TOOLPATH="$(dirname $0)"
THISPATH="$(pwd)"
VSRCPATH="$THISPATH/vlog"
#VHDLEXEC="vcom"
VLOGEXEC="vlog"
VLIBEXEC="vlib"
VSIMEXEC="vsim"
VDELEXEC="vdel"
VSIMPATH="$(which $VLOGEXEC 2>/dev/null)"
VSIMWORK="work"
VSIM_LOG="vlog.log"
VSIM_OPT="-c -keepstdout -l $VSIM_LOG"
VLOG_V95="-vlog95compat"
VLOG_OPT="+incdir+vlog"
ONE_TIME="NO"
DO_CLEAN="NO"
SKIPTEST="NO"
# base module should be specified BEFORE dependants
LIB_COMP="adder subtractor decoder zbuffer latch register"

# make sure verilog compiler is available
[ ! -x "${VSIMPATH}" ] &&
	echo "Cannot find verilog compiler '$VLOGEXEC'! Abort!" && exit 1
VSIMPATH=$(dirname $VSIMPATH)

# look for available source files...
lcode=$(find ${VSRCPATH} -maxdepth 1 -name "*.v"|grep -v "*_tb.v"|sort)
[ "$lcode" == "" ] && echo "No source file found!" && exit 0
codes=""
count=0
comps=""

# process params
while [ "$1" != "" ]; do
	case "$1" in
		--clean) DO_CLEAN="YES" ;;
		--compile) SKIPTEST="YES" ;;
		--use-lib) # default component
			for check in $LIB_COMP ; do
				check=${VSRCPATH}/$check.v
				[ -f $check ] && comps="$comps $check"
			done
			;;
		--vlog95) VLOG_OPT="${VLOG_OPT} ${VLOG_V95}" ;;
		--component)
			shift
			check=$(echo $lcode|grep "$1")
			if [ "$check" != "" ] ; then
				check=${VSRCPATH}/$1.v
				[ -f $check ] && comps="$comps $check"
			fi
			;;
		--remove-lib) ;; # ignore and continue
		-*) echo "Invalid option? Aborting!" && exit 1 ;;
		*)
			# any particular module requested?
			check=$(echo $lcode|grep "$1")
			if [ "$check" != "" ] ; then
				check=${VSRCPATH}/$1.v
				[ -f $check ] && codes="$codes $check" && ((count++))
			else
				echo "Unknown module '$1'"
			fi
			;;
	esac
	shift
done

function get_module_name()
{
	local code="$1"
	local count=$(cat $code|sed -ne '/^\s*module\s*.*(.*)\s*;\s*$/ p')
	[ "$count" == "" ] &&
		count=$(cat $code|sed -ne '/^\s*module\s*.*(/,/[)].*[;]/ p')
	local check=$(echo $count|sed -e 's/^\s*module\s*\(\S*\)\s*(.*/\1/')
	count=$(echo $count|sed -e 's/^\s*module\s*(\s*\(.*\)\s*)\s*;\s*/\1/')
	if [ "$count" == "" ] ; then
		count=0
	else
		count=$(echo $count|tr -cd ,|wc -c)
		((count++))
	fi
	echo "$check:$count"
}

function do_compile()
{
	local what=1
	local code="$1"
	local type="design"
	[ "${code//_tb.v/}" != "${code}" ] && type="testbench"
	# try to compile
	echo -n "    Checking $type for sim-ready... "
	${VSIMPATH}/${VLOGEXEC} ${VLOG_OPT} $code >$VSIM_LOG
	if [ $? -eq 0 ] ; then
		echo "done!"
		what=0
		# remove module per request
		[ "$(echo $@|grep -- '--remove-lib')" != "" ] &&
			${VSIMPATH}/${VDELEXEC} ${info[0]}
	else
		echo "compile error!"
		read -n 1 -p "[S]how error or press any key to continue..." dummy
		echo
		if [ "$dummy" == "S" -o "$dummy" == "s" ] ; then
			echo "$(cat $VSIM_LOG|grep -e Error -e Warning)"
			read -n 1 -p "Press any key to continue..." dummy
			echo
		fi
	fi
	# remove log
	rm -rf $VSIM_LOG
	# return status
	return $what
}

function do_testing()
{
	# run simulation
	echo -n "    Running testbench simulation... "
	${VSIMPATH}/${VSIMEXEC} ${VSIM_OPT} work.$1 -do "run -all" &>$VSIM_LOG
	VSIM_RES=$?
	echo "completed! [$VSIM_RES]"
	if [ $VSIM_RES -eq 0 ] ; then
		echo "$(cat $VSIM_LOG|grep -e '# \[')"
	else
		echo "$(cat $VSIM_LOG)"
	fi
	# remove log
	rm -rf $VSIM_LOG
}

# clean up option... starting new
if [ "$DO_CLEAN" == "YES" ] ; then
	# clean up compiler work path
	echo -n "Removing work path for compiler... "
	${VSIMPATH}/${VDELEXEC} -all
	#[ -d $VSIMWORK ] && rm -rf $VSIMWORK
	echo "done!"
fi

# if no module file specified, terminate?
[ $count -eq 0 ] && exit 0

# make sure compiler work path is ready
echo -n "Check/create work path for compiler... "
${VSIMPATH}/${VLIBEXEC} ${VSIMWORK} >$VSIM_LOG
[ $? -ne 0 ] && echo "ERROR! [$?]" && exit 1
echo "done!"

# build components?
for comp in $comps ; do
	file=$(basename $comp)
	info=$(get_module_name $comp)
	name=${info%:*}
	info=${info#*:}
	# display file and module name
	echo "File: '$file' => Module: '$name' {Param=$info}"
	# compile design
	do_compile $comp
done

# check one-file option?
[ $count -eq 1 ] && ONE_TIME="YES"

# do your thing...
for code in $codes ; do
	# get module name & info
	file=$(basename $code)
	info=$(get_module_name $code)
	name=${info%:*}
	info=${info#*:}
	# display file and module name
	echo "File: '$file' => Module: '$name' {Param=$info}"
	# compile design
	do_compile $code
	[ $? -ne 0 ] && continue
	# compile only?
	[ "$SKIPTEST" == "YES" ] && continue
	# look for testbench
	code_tb=${code//.v/_tb.v}
	if [ ! -f "$code_tb" ] ; then
		echo "  Cannot find testbench for '$file'!"
		read -n 1 -p "Press any key to continue..." dummy
		echo
		continue
	fi
	file_tb=$(basename $code_tb)
	info_tb=$(get_module_name $code_tb)
	name_tb=${info_tb%:*}
	# display file and module name
	echo "File: '$file_tb' => Module: '$name_tb'"
	# compile testbench
	do_compile $code_tb
	[ $? -ne 0 ] && continue
	# simulate testbench
	do_testing $name_tb
	# post check
	echo "    Done checking module '$name'."
	if [ "$ONE_TIME" != "YES" ] ; then
		read -n 1 -p "Press any key to continue..." dummy
		echo
	fi
done
