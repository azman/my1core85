#!/bin/bash
TOOLPATH="$(dirname $0)"
THISPATH="$(pwd)"
VSRCPATH="$THISPATH/vlog"
VLOGEXEC="iverilog"
VSIMPATH="$(which $VLOGEXEC 2>/dev/null)"
VSIMEXEC="iverilog"
VSIMWORK="$THISPATH/work"
VSIM_LOG="vlog.log"
VSIM_OPT="-I $VSRCPATH -y $VSIMWORK -gno-xtypes -g2001"
VLOG_V95="-g1995"
VLOG_OPT="-I $VSRCPATH -y $VSIMWORK -gno-xtypes -g2001 -t null"
SEL_CODE="$1"
ONE_TIME="NO"
DO_CLEAN="NO"
SKIPTEST="NO"
LIB_COMP="alu_add1b alu_add8b alu_sub1b alu_sub8b alu_logic alu_alu"
LIB_COMP="${LIB_COMP} decoder zbuffer register incdec"

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
		--vlog95)
			VLOG_OPT="${VLOG_OPT} ${VLOG_V95}"
			VSIM_OPT="${VSIM_OPT} ${VLOG_V95}"
			;;
		--component)
			shift
			check=$(echo $lcode|grep "$1")
			if [ "$check" != "" ] ; then
				check=${VSRCPATH}/$1.v
				[ -f $check ] && comps="$comps $check"
			fi
			;;
		-*) echo "Invalid option '$1'? Aborting!" && exit 1 ;;
		*)
			# any particular module requested?
			check=$(echo $lcode|grep "$1")
			if [ "$check" != "" ] ; then
				check=${VSRCPATH}/$1.v
				[ -f $check ] && codes="$codes $check" && ((count++))
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
	local new_=0
	local code="$1"
	local type="design"
	[ "${code//_tb.v/}" != "${code}" ] && type="testbench"
	# try to compile
	echo -n "    Checking $type for sim-ready... "
	${VSIMPATH}/${VSIMEXEC} ${VLOG_OPT} $code >$VSIM_LOG
	if [ $? -eq 0 ] ; then
		echo "done!"
		what=0
		# copy to module path if this is design?
		if [ $type == "design" ] ; then
			info=$(get_module_name $code)
			name=${info%:*}
			[ ! -f ${VSIMWORK}/$name.v ] && new_=1
			cp $code ${VSIMWORK}/$name.v
			[ $new_ -eq 1 ] &&
				echo "    A $type ($name) is added to module path!"
		fi
	else
		echo "compile error!"
		read -n 1 -p "[S]how error or press any key to continue..." dummy
		echo
		if [ "$dummy" == "S" -o "$dummy" == "s" ] ; then
			echo "$(cat $VSIM_LOG)"
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
	local code="$1"
	[ "${code//_tb.v/}" == "${code}" ] &&
		echo "NOT a testbench? Aborting!" && return
	local info=$(get_module_name $code)
	local name=${info%:*}
	# run simulation
	echo -n "    Creating testbench vvp executable... "
	${VSIMPATH}/${VSIMEXEC} ${VSIM_OPT} -o $name $code >$VSIM_LOG
	VSIM_RES=$?
	if [ $VSIM_RES -eq 0 ] ; then
		echo "completed!"
		echo "    Running vvp executable [BEGIN]"
		${VSIMPATH}/vvp $name
		echo "    Running vvp executable [END:$?] "
		rm -rf $name
	else
		echo "create error! [$VSIM_RES]"
		read -n 1 -p "[S]how error or press any key to continue..." dummy
		echo
		if [ "$dummy" == "S" -o "$dummy" == "s" ] ; then
			echo "$(cat $VSIM_LOG)"
			read -n 1 -p "Press any key to continue..." dummy
			echo
		fi
	fi
	# remove log
	rm -rf $VSIM_LOG
}

# make sure work path is ready
echo -n "Check/create work path for compiler... "
mkdir -pv ${VSIMWORK} >$VSIM_LOG
[ $? -ne 0 ] && echo "ERROR! [$?]" && exit 1
echo "done!"
echo "Work path: '${VSIMWORK}'"

# build components?
for comp in $comps ; do
	file=$(basename $comp)
	info=$(get_module_name $comp)
	name=${info%:*}
	info=${info#*:}
	[ -f ${VSIMWORK}/$name.v ] && continue
	# display file and module name
	echo "File: '$file' => Module: '$name' {Param=$info}"
	# compile design
	do_compile $comp
done

# if no module file specified, terminate?
[ $count -eq 0 ] && exit 0

# check one-file option?
[ $count -eq 1 ] && ONE_TIME="YES"

# do your thing...
for code in $codes ; do
	# ignore testbench
	#[ "${code//_tb.v/}" != "${code}" ] && continue
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
	file=$(basename $code_tb)
	info=$(get_module_name $code_tb)
	name_tb=${info%:*}
	# display file and module name
	echo "File: '$file' => Module: '$name_tb'"
	# simulate testbench
	do_testing $code_tb
	# post check
	echo "    Done checking module '$name'."
	if [ "$ONE_TIME" != "YES" ] ; then
		read -n 1 -p "Press any key to continue..." dummy
		echo
	fi
done

if [ "$DO_CLEAN" == "YES" ] ; then
	# clean up work path
	echo -n "Removing work path for compiler... "
	[ -d $VSIMWORK ] && rm -rf $VSIMWORK
	echo "done!"
fi
