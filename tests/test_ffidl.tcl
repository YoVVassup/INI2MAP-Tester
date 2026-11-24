#----------------------------------------------------------------------------------------------------------
# test_ffidl.tcl - Regression test for the ffidl DLL used by script mode.
# Guards the AV fix (USE_LIBFFI_RAW_API must be OFF): libffi i386 ffi_raw_call
# builds its stack image below esp when esp mod 32 == 4 and the call crashes
# with 0xC0000005 - see third_party\ffidl\build_xp.bat.
# Also guards that the root copy (loaded FIRST by main.tcl:41) never drifts
# from the canonical others\ffidl build.
# Paths are resolved relative to this script (works from any drive/checkout).
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file normalize [info script]]]
set root_dir   [file dirname $script_dir]

set root_dll   [file join $root_dir "ffidl_xp.dll"]
set others_dll [file join $root_dir "others" "ffidl" "ffidl_xp.dll"]

# --- 1. DLL candidates exist ---------------------------------------------------
test ffidl-1.1 "root and others ffidl DLLs exist" -body {
    expr {[file exists $root_dll] && [file exists $others_dll]}
} -result 1

# --- 2. root copy is byte-identical to the canonical others build --------------
proc read_binary {path} {
    set fh [open $path rb]
    fconfigure $fh -translation binary
    set data [read $fh]
    close $fh
    return $data
}
test ffidl-1.2 "root ffidl_xp.dll == others\ffidl\ffidl_xp.dll" -body {
    expr {[read_binary $root_dll] eq [read_binary $others_dll]}
} -result 1

# --- 3. load the same candidate main.tcl picks first (root) --------------------
set load_err ""
set loaded 0
if {[file exists $root_dll] && ![catch {load $root_dll Ffidl} load_err]} {
    set loaded 1
}
test ffidl-2.1 "root ffidl_xp.dll loads" -body {expr {$loaded}} -result 1

test ffidl-2.2 "package require Ffidl 0.9 works" -body {
    package require Ffidl 0.9
} -result {0.9}

# --- 4. THE regression: raw API must be compiled OUT ---------------------------
test ffidl-3.1 "use-libffi-raw is 0 (AV fix regression guard)" -body {
    ::ffidl::info use-libffi-raw
} -result {0}

# --- 5. smoke: a real callout through the non-raw ffi path ---------------------
test ffidl-4.1 "callout GetCurrentProcessId works" -body {
    ::ffidl::callout ::testffidl_mypid {} int \
        [::ffidl::symbol kernel32.dll GetCurrentProcessId]
    expr {[::testffidl_mypid] > 0}
} -result 1

cleanupTests
