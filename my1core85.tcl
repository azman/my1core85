# ISE WebPack 12.1

set projectName			"my1core85"
set myProject			"${projectName}.xise"
set myProjectCG			"${projectName}.cgp"
set myScript			"${projectName}.tcl"

set top_name			"$projectName"
set top_arch			"structural"
set ucf_file			""
set keep_cores			"false"

set vhdl_files [ list \
	"my1core85.vhd" \
	"my1core85ctrl.vhd" \
	"my1core85inst.vhd" \
	"my1core85pack.vhd" \
]

set core_files [ list \
]

set tb_files [ list \
	"my1core85sim.vhd" \
	"my1core85_tb.vhd" \
]

set keep_files [ list \
	"$myScript" \
	"$myProjectCG" \
]

proc generate_core_add { args } {

	global myProjectCG

	foreach tfile [ split [ join $args ] ] {
		set the_length [ string length $tfile ]
		set ext_index [ string last ".xco" $tfile ]
		set afile [ string replace $tfile $ext_index $the_length ".vhd" ]
		set bfile [ string replace $tfile $ext_index $the_length ".ngc" ]
		if { [ string match *\.\x\c\o $tfile ] } {
			if { ![ file exists $afile ] || \
					![ file exists $bfile ] || \
					![ file exists $tfile ] } {
				puts "COREGen: core/$tfile"
				exec coregen -b "core/$tfile" -r -p "$myProjectCG"
			}
			if { ![ file exists $afile ] } {
				puts "Warning! Cannot find '$afile'! COREGen error?"
			} elseif { ![ file exists $bfile ] } {
				puts "Warning! Cannot find '$bfile'! COREGen error?"
			} elseif { ![ file exists $tfile ] } {
				puts "Warning! Cannot find '$tfile'! COREGen error?"
			} else {
				#puts "Adding generated NGC & VHD to project"
				xfile add $bfile -view "Implementation"
				xfile add $afile -view "Simulation"
			}
		} else {
			xfile add core/$tfile -view "All"
		}
	}

}

proc check_core_sweep { args } {

	global core_files

	set sweep_this true
	set the_length [ string length $args ]
	set ext_index [ string last "." $args ]
	incr ext_index -1
	set base_src [ string range $args 0 $ext_index ]

	foreach tfile [ split [ join $core_files ] ] {
		if { ![ string match *\.\x\c\o $tfile ] } {
			continue ;# ignore if not xco??
		}
		set ext_index [ string last "." $tfile ]
		incr ext_index -1
		set base_cmp [ string range $tfile 0 $ext_index ]
		if { "$base_cmp" == "$base_src" } {
			set afile "${base_cmp}.vhd"
			set bfile "${base_cmp}.ngc"
			if { $args == $afile || $args == $bfile || $args == $tfile } {
				set sweep_this false;
				break;
			}
		}
	}

	return $sweep_this

}

proc clean_project {} {

	global myScript
	global myProject
	global keep_files
	global keep_cores

	puts "\n$myScript: cleaning ($myProject)...\n"

	# check visible files & folders
	foreach tfile [glob -nocomplain *] {
		if [file isdirectory $tfile] {
			if { "$tfile" == "core" } {
			} elseif { "$tfile" == "data" } {
			} elseif { "$tfile" == "vhdl" } {
			} elseif { "$tfile" == "docs" } {
			} else {
				file delete -force "$tfile"
			}
		} else { # must be a file then?
			foreach cfile $keep_files {
				if { "$tfile" eq "$cfile" } {
					puts "Keeping $cfile"
					set tfile ""
					break
				}
			}
			if { "$tfile" ne "" } {
				if { $keep_cores } {
					if { ! [ check_core_sweep $tfile ] } {
						puts "Keeping $tfile"
						continue
					}
				}
				file delete -force "$tfile"
			}
		}
	}

	# check hidden files & folders
	foreach tfile [glob -nocomplain -types { hidden } *] {
		if { "$tfile" eq ".git" || "$tfile" eq ".gitignore" || \
			"$tfile" eq "." || "$tfile" eq ".." } {
			continue
		}
		file delete -force "$tfile"
	}

	puts "\nDone cleaning project path.\n"
}

proc check_syntax { args } {

	global projectName
	global myScript
	global myProject

	if { ! [ open_project ] } {
		return
	}

	puts "\n$myScript: checking syntax in ($myProject)...\n"

	if { $args eq "" } {
		set args $projectName
	}

	foreach tfile [ split $args ] {
		set var_find_chk [ search *$tfile -type instance ]
		if { $var_find_chk eq "Empty Collection" } {
			puts "Cannot find instance $tfile!\n"
			continue
		}
		foreach object [ split $var_find_chk ] {
			set var_chkproc [ project get_processes -instance $object ]
			set var_testproc "{Check Syntax}"
			if { [ string first $var_testproc $var_chkproc 0 ] eq -1 } {
				puts "Cannot perform $var_testproc on $object!\n"
			} else {
				process run "Check Syntax" -instance $object
			}
			break ;# do this only for first valid instance
		}
	}

	puts "\nDone checking syntax.\n"

	project close
}

proc run_process {} {

	global projectName
	global myScript
	global myProject

	puts "\n$myScript: running ($myProject)...\n"

	if { ! [ open_project ] } {
		return false
	}

	# process run "Synthesize"
	# process run "Translate"
	# process run "Map"
	# process run "Place & Route"

	puts "Running 'Implement Design'"
	if { ! [ process run "Implement Design" -force rerun ] } {
		puts "$myScript: Implementation run failed, check run output for details."
		project close
		return
	}

	puts "Running 'Generate Programming File'"
	if { ! [ process run "Generate Programming File" ] } {
		puts "$myScript: Generate Programming File run failed, check run output for details."
		project close
		return
	}

	puts "Run completed."
	project close

}

proc rebuild_project {} {

	global myScript
	global myProject
	global keep_cores

	if { [ file exists $myProject ] } { 
		puts "$myScript: Removing existing project file."
		set temp_keep $keep_cores
		set keep_cores true
		clean_project
		set keep_cores $temp_keep
	}

	puts "\n$myScript: rebuilding ($myProject)...\n"
	project new $myProject
	set_project_props
	add_source_files
	create_libraries
	create_partitions
	set_process_props
	puts "$myScript: project rebuild completed."
	project close

}

proc show_help {} {

	global myScript

	puts ""
	puts "usage: xtclsh $myScript <options>"
	puts "       or you can run xtclsh and then enter 'source $myScript'."
	puts ""
	puts "options:"
	puts "   clean_project     - clean up project folder"
	puts "   check_syntax      - check syntax (optionally provide instance name)"
	puts "   run_process       - run all processes with properties set in build"
	puts "   rebuild_project   - rebuild the project from scratch"
	puts "   set_project_props - set project properties (device, speed, etc.)"
	puts "   add_source_files  - add source files"
	puts "   create_libraries  - create vhdl libraries"
	puts "   create_partitions - create partitions"
	puts "   set_process_props - set process property values"
	puts "   show_help         - print this message"
	puts ""

}

proc show_help_bash {} {

	global myScript

	puts ""
	puts "usage: xtclsh $myScript <options>"
	puts "       or you can run xtclsh and then enter 'source $myScript'."
	puts ""
	puts "options:"
	puts "   clean - clean up project folder"
	puts "   sweep - clean up project folder, but keep core generated files"
	puts "   build - build the project from scratch"
	puts "   check - check syntax (optionally provide instance name)"
	puts "   run   - run all processes"
	puts "   help  - print this message"
	puts ""

}

proc open_project {} {

	global myScript
	global myProject

	if { ! [ file exists $myProject ] } {
		puts "Project $myProject not found. Use 'build' to recreate it."
		return false
	}

	project open $myProject

	return true

}

proc set_project_props {} {

	global myScript

	if { ! [ open_project ] } {
		return false
	}

	puts "$myScript: Setting project properties..."

	project set family "Spartan-3A DSP"
	project set device "xc3sd3400a"
	project set package "fg676"
	project set speed "-4"
	project set top_level_module_type "HDL"
	project set synthesis_tool "XST (VHDL/Verilog)"
	project set simulator "ISim (VHDL/Verilog)"
	project set "Preferred Language" "VHDL"
	project set "Enable Message Filtering" "false"
}

proc add_source_files {} {

	global myScript
	global core_files
	global vhdl_files
	global tb_files
	global ucf_file
	global top_name
	global top_arch

	if { ! [ open_project ] } {
		return false
	}

	puts "$myScript: Adding sources to project..."

	foreach tfile $vhdl_files {
		xfile add "vhdl/$tfile" -view "All"
	}
	generate_core_add $core_files
	foreach tfile $tb_files {
		xfile add "vhdl/$tfile" -view "Simulation"
	}
	if { [ file exists "data/$ucf_file" ] } {
		xfile add "data/$ucf_file"
	}

	project set top "$top_arch" "$top_name"
	project save

	puts "$myScript: project sources reloaded."

}

proc create_libraries {} {

	global myScript

	if { ! [ open_project ] } {
		return false
	}

	puts "$myScript: Creating libraries..."
	# note: if you have multiple files with the same name at different paths,
	# you may have problems with the lib_vhdl command.

	project save
	# to active the newly defined library set
	#project close
	#open_project

}

proc create_partitions {} {

	global myScript

	if { ! [ open_project ] } {
		return false
	}

	puts "$myScript: Creating Partitions..."

	project save
	# to active the newly defined partitions
	#project close
	#open_project

}

proc set_process_props {} {

	global myScript

	if { ! [ open_project ] } {
		return false
	}

	puts "$myScript: setting process properties..."

	# just use default values for the others
	project set "Project Description" "MY1 Intel 8085 Microprocessor Core"
	project set "Target UCF File Name" "" -process "Back-annotate Pin Locations"
	project set "Working Directory" "."

	puts "$myScript: project property values set."

}

proc main {} {

	global keep_cores
	global myLogFile

	if { [llength $::argv] == 0 } {
		show_help_bash
		return true
	}

	set opt_check_syntax "false"
	foreach option $::argv {
		if { $opt_check_syntax eq "true" } {
			check_syntax $option
			set opt_check_syntax "false"
			continue
		}
		switch $option {
			"check"	{ set opt_check_syntax "true" }
			"cores"	{ generate_cores }
			"clean"	{ clean_project }
			"sweep"	{ set keep_cores "true" ; clean_project }
			"run"	{ run_process }
			"build"	{ rebuild_project }
			"help"	{ show_help_bash }
			default	{
				puts "unrecognized option: $option"
				show_help_bash
			}
		}
	}
	if { $opt_check_syntax eq "true" } {
		check_syntax
	}
}

if { $tcl_interactive } {
	show_help
} else {
	if {[catch {main} result]} {
		puts "$myScript failed: $result."
	}
}
