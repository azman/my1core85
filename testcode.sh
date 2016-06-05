#!/bin/bash
TOOLPATH="$(dirname $0)"
THISPATH="$(pwd)"
VSRCPATH=${VSRCPATH:="vlog"}
LINEDIFF=${LINEDIFF:=10}
#VHDLEXEC="vcom"
VLOGEXEC="vlog"
VLIBEXEC="vlib"
VSIMEXEC="vsim"
VDELEXEC="vdel"
VSIMPATH="$(which $VLOGEXEC 2>/dev/null)"
VSIMWORK="work"
VSIM_LOG="vlog.log"
VSIM_OPT="-c -keepstdout -l $VSIM_LOG"
SEL_CODE="$1"
ONE_TIME="NO"

# make sure target path is available
[ "$VSRCPATH" == "" ] && VSRCPATH="$(pwd)"
[ ! -d "${VSRCPATH}" ] &&
	echo "Invalid path '$VSRCPATH'? Abort!" && exit 1
VSRCPATH=$(cd $VSRCPATH ; pwd)

# make sure verilog compiler is available
[ ! -x "${VSIMPATH}" ] &&
	echo "Cannot find verilog compiler '$VLOGEXEC'! Abort!" && exit 1
VSIMPATH=$(dirname $VSIMPATH)

# look for source files...
codes=$(find ${VSRCPATH} -maxdepth 1 -name "*.v"|sort)
[ "$codes" == "" ] && echo "No source file found!" && exit 0

# make sure compiler work path is ready
echo -n "Creating work path for compiler... "
${VSIMPATH}/${VLIBEXEC} ${VSIMWORK} >$VSIM_LOG
[ $? -ne 0 ] && echo "ERROR! [$?]" && exit 1
echo "done!"

# any particular module requested?
CHK_CODE=$(echo $codes|grep "$SEL_CODE")
if [ "$CHK_CODE" != "" ] ; then
	SEL_CODE=${VSRCPATH}/${SEL_CODE}.v
	[ -f $SEL_CODE ] && codes=$SEL_CODE && ONE_TIME="YES"
fi

# do your thing...
for code in $codes ; do
	# strip file
	a=$(basename $code)
	# ignore testbenches
	[ "${a//tb.v/}" != "$a" ] && continue
	# display file and module name
	echo -n "File: '$a' => Module: "
	count=$(cat $code|grep -e '^[[:space:]]*module')
	check=$(echo $count|sed -e 's/^.*module\s*\(\S*\)\s*(.*$/\1/')
	count=$(echo $count|sed -e 's/^.*module.*(\(.*\)).*$/\1/'|tr -cd ,|wc -c)
	((count++))
	echo "'$check' {Param=$count}"
	# try to compile
	echo -n "    Checking design for sim-ready... "
	${VSIMPATH}/${VLOGEXEC} $code >$VSIM_LOG
	if [ $? -eq 0 ] ; then
		echo "done!"
	else
		echo "compile error!"
		read -n 1 -p "[S]how error or press any key to continue..." dummy
		echo
		if [ "$dummy" == "S" -o "$dummy" == "s" ] ; then
			echo "$(cat $VSIM_LOG|grep -e Error -e Warning)"
			read -n 1 -p "Press any key to continue..." dummy
			echo
		fi
		continue
	fi
	# look for testbench
	code_tb=${code//.v/_tb.v}
	if [ ! -f "$code_tb" ] ; then
		echo "  Cannot find test bench for '$a'!"
		read -n 1 -p "Press any key to continue..." dummy
		echo
		${VSIMPATH}/${VDELEXEC} $check
		continue
	fi
	# compile test bench
	echo -n "    Checking testbench for sim-ready... "
	${VSIMPATH}/${VLOGEXEC} $code_tb >>$VSIM_LOG
	if [ $? -eq 0 ] ; then
		echo "done!"
	else
		echo "compile error!" ; echo
		read -n 1 -p "[S]how error or press any key to continue..." dummy
		echo
		if [ "$dummy" == "S" -o "$dummy" == "s" ] ; then
			echo "$(cat $VSIM_LOG|grep -e Error -e Warning)"
			read -n 1 -p "Press any key to continue..." dummy
			echo
		fi
		exit 1
	fi
	# find test bench module
	bench=$(cat $code_tb|grep -e '^[[:space:]]*module')
	bench=$(echo $bench|sed -e 's/^.*module\s*\(\S*\)\s*(.*$/\1/')
	echo "    Test Module: '$bench'"
	# run simulation
	echo -n "    Running testbench simulation... "
	${VSIMPATH}/${VSIMEXEC} ${VSIM_OPT} work.$bench -do "run -all" &>$VSIM_LOG
	echo "completed! [$?]"
	echo "$(cat $VSIM_LOG|grep -e '# \[')"
	echo "    Done checking module '$check'."
	if [ "$ONE_TIME" != "YES" ] ; then
		read -n 1 -p "Press any key to continue..." dummy
		echo
	fi
	# removes compiled library - in case same name with the next
	${VSIMPATH}/${VDELEXEC} $check
	${VSIMPATH}/${VDELEXEC} $bench
	# remove log
	rm -rf $VSIM_LOG
done

# clean up compiler work path
echo -n "Removing work path for compiler... "
[ -d $VSIMWORK ] && rm -rf $VSIMWORK
echo "done!"
