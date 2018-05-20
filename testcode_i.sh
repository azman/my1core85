#!/bin/bash
TOOLPATH="$(dirname $0)"
THISPATH="$(pwd)"
VSRCPATH=${VSRCPATH:="hdl"}
VLOGEXEC="iverilog"
VSIMPATH="$(which $VLOGEXEC 2>/dev/null)"
VSIM_LOG="vlog.log"
SEL_CODE="$1"
ONE_TIME="NO"

# make sure verilog compiler is available
[ ! -x "${VSIMPATH}" ] &&
	echo "Cannot find verilog compiler '$VLOGEXEC'! Abort!" && exit 1

# look for source files...
codes=$(find ${VSRCPATH} -maxdepth 1 -name "*.v"|grep -v "*_tb.v"|sort)
[ "$codes" == "" ] && echo "No source file found!" && exit 0

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
	# ignore testbenches - should have already been filtered out!
	[ "${a//tb.v/}" != "$a" ] && continue
	# display file and module name
	echo -n "File: '$a' => Module: "
	count=$(cat $code|grep -e '^[[:space:]]*module')
	check=$(echo $count|sed -e 's/^.*module\s*\(\S*\)\s*(.*$/\1/')
	count=$(echo $count|sed -e 's/^.*module.*(\(.*\)).*$/\1/'|tr -cd ,|wc -c)
	((count++))
	echo "'$check' {Param=$count}"
	# try to compile
	echo -n "    Checking design for syntax error... "
	${VSIMPATH} -t null $code >$VSIM_LOG
	if [ $? -eq 0 ] ; then
		echo "done!"
	else
		echo "compile error!"
		read -n 1 -p "[S]how error or press any key to continue..." dummy
		echo
		if [ "$dummy" == "S" -o "$dummy" == "s" ] ; then
			echo "$(cat $VSIM_LOG)"
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
		continue
	fi
	# compile test bench
	echo -n "    Checking testbench for syntax error... "
	${VSIMPATH} -y hdl -o runsim $code_tb >$VSIM_LOG
	if [ $? -eq 0 ] ; then
		echo "done!"
	else
		echo "compile error!" ; echo
		read -n 1 -p "[S]how error or press any key to continue..." dummy
		echo
		if [ "$dummy" == "S" -o "$dummy" == "s" ] ; then
			echo "$(cat $VSIM_LOG)"
			read -n 1 -p "Press any key to continue..." dummy
			echo
		fi
		rm -rf runsim
		exit 1
	fi
	# run simulation
	echo "    Running testbench simulation... "
	./runsim
	echo "    Done checking module '$check'."
	if [ "$ONE_TIME" != "YES" ] ; then
		read -n 1 -p "Press any key to continue..." dummy
		echo
	fi
	# removes compiled library - in case same name with the next
	rm -rf runsim
	# remove log
	rm -rf $VSIM_LOG
done
