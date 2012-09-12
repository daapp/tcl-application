package require Tcl 8.5

package require msgcat
namespace import ::msgcat::mc

namespace eval ::application {
    variable version 0.1

    variable name ""
    # keys are: home, configuration, system-configuration, temporary
    #           prefix, bin, lib, share
    # todo: later may be add keys desktop, documents, ...
    variable folders [dict create]

    namespace ensemble create -subcommands {
	configure
	folder
	folders
    }
}


proc ::application::configure {args} {
    global env
    variable name
    variable folders

    set name [dict get $args -name]

    switch -- $::tcl_platform(platform) {
	unix {
	    # todo: check here what will be in bin if start file just launcher
	    # todo: check with tclkit
	    dict set folders prefix [file dirname [file dirname [file normalize $::argv0]]]
	    dict set folders bin    [file dirname [file normalize $::argv0]]
	    dict set folders lib    [file join [dict get $folders prefix] lib $name]
	    dict set folders share  [file join [dict get $folders prefix] share $name]

	    dict set folders home [file nativename ~]
	    dict set folders configuration [file join [dict get $folders home] .config $name]

	    if {[dict get $folders prefix] ne "/usr"} {
		dict set folders system-configuration [file join [dict get $folders prefix] etc $name]
	    } else {
		dict set folders system-configuration [file join /etc $name]
	    }

	    if {[info exists env(TMPDIR)] &&
		[file isdirectory $env(TMPDIR)] &&
		[file writable $env(TMPDIR)]} {

		dict set folders temporary $env(TMPDIR)
	    }

	    file mkdir [dict get $folders configuration]
	}
    }
}

proc ::application::folders {} {
    variable folders

    return [dict keys $folders]
}

proc ::application::folder {name args} {
    variable folders

    set name [string tolower $name]
    if {[llength $args] > 0} {
	dict set folders $name [lindex $args 0]
    } else {
	if {[dict exists $folders $name]} {
	    return [dict get $folders $name]
	} else {
	    set names [dict keys folders]
	    error "Invalid folder \"$name\": should be one of [join [lrange $names 0 end-1] {, }] or [lindex $names end]"
	}
    }
}

package provide application $::application::version

# sample code, it will be executed if you start tclsh with this file:
# tclsh thisFileName
if {[info exists argv0] && [file tail [info script]] eq [file tail $argv0]} {
    # "application configure" must be called first to initialize
    # application and create application specific directory
    switch -- $::tcl_platform(platform) {
	windows {
	    # this will create application configuration directory
	    # C:\Documents and Settings\UserName\Application Data\Sample Company\SampleApplication
	    # option -company is optional, but recommended for windows platform
	    application configure -company "Sample Company" -name SampleApplication
	}
	unix {
	    # this will create application configuration directory
	    # /home/user/.config/SampleApplication
	    application configure -name SampleApplication
	}
    }

    foreach folder [application folders] {
	puts "$folder = [application folder $folder]"
    }
}
