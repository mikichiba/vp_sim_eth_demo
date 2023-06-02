#!/usr/bin/tclsh
# ---------------------------------------------------------------------
#
# Copyright (c) 2021 Achronix Semiconductor Corp.
# All Rights Reserved.
#
# This Software constitutes an unpublished work and contains
# valuable proprietary information and trade secrets belonging
# to Achronix Semiconductor Corp.
#
# Permission is hereby granted to use this Software including
# without limitation the right to copy, modify, merge or distribute
# copies of the software subject to the following condition:
#
# The above copyright notice and this permission notice shall
# be included in in all copies of the Software.
#
# The Software is provided “as is” without warranty of any kind
# expressed or implied, including  but not limited to the warranties
# of merchantability fitness for a particular purpose and non-infringement.
# In no event shall the copyright holder be liable for any claim,
# damages, or other liability for any damages or other liability,
# whether an action of contract, tort or otherwise, arising from, 
# out of, or in connection with the Software
#
# ---------------------------------------------------------------------
# Utility functions to use with Tcl script and the device dictionary
# ---------------------------------------------------------------------
# These functions do not have a namespace as they can be called from multiple
# other scripts or functions


#------------------------------------------------------------------------------------
# Check PLL register status in all corners
#------------------------------------------------------------------------------------
  
proc check_pll_status {} {
    foreach corner [list N S] {
        foreach num [list 0 1 2 3] {
            set x [ac7t1500::noc_read [ac7t1500::csr_named_addr CSR_SPACE CLK_${corner}W BASE_IP SYNTH${num}_STATUS]]
            puts -nonewline "PLL at CLK_${corner}W #$num : $x                         "

            set x [ac7t1500::noc_read [ac7t1500::csr_named_addr CSR_SPACE CLK_${corner}E BASE_IP SYNTH${num}_STATUS]]
            puts "PLL at CLK_${corner}E #$num : $x"

        }

        puts -nonewline "PLL at ENOC_${corner}W  : "
        set x [ac7t1500::noc_read [ac7t1500::csr_named_addr CSR_SPACE ENOC_${corner}W BASE_IP CLK_RST_TOP_CSR_INTERNAL_CSR_STATUS]]
        puts "$x"
        puts ""
    }
    foreach g6 [list 0 1 2 3 4 5 6 7] {
        puts -nonewline "PLL at GDDR_${g6}   : "
        set x [ac7t1500::noc_read [ac7t1500::csr_named_addr CSR_SPACE GDDR_${g6} PHY CPHY_CM_CACM_PHYCMN_PYINITSTS0]]
        puts "$x"
    }
}

#------------------------------------------------------------------------------------
# Perform write-verify operations on a users scratch register
#------------------------------------------------------------------------------------
proc check_scratch_register { col row addr {verbose 0}} {

    # When in verbose mode, turn on register transactions echo to the console
    if { $verbose } { set quiet_script 0 }

    set retval 0

    # Have to have a delay between reads and writes due to the pipelining
    # of the registers in sim. 3x10ns.
    ac7t1500::nap_axi_write  "NAP_SPACE" $col $row $addr 12345678
    ac7t1500::wait_ns 32
    incr retval [ac7t1500::nap_axi_verify "NAP_SPACE" $col $row $addr 12345678]
    ac7t1500::nap_axi_write  "NAP_SPACE" $col $row $addr aa55dead
    ac7t1500::wait_ns 32
    incr retval [ac7t1500::nap_axi_verify "NAP_SPACE" $col $row $addr aa55dead]

    # Turn off command echo to the console
    set quiet_script 1

    if { $retval } { message -error "Scratch register at address $addr failed to verify" }

    return $retval

}

#------------------------------------------------------------------------------------
# Read register control block registers and display
# User has to supply the NAP location of the register block
#------------------------------------------------------------------------------------
proc read_version_regs { col row } {

    ac7t1500::write_comment_line "Read version registers"
    set major_ver [ac7t1500::nap_axi_read "NAP_SPACE" $col $row fff0000]
    set minor_ver [ac7t1500::nap_axi_read "NAP_SPACE" $col $row fff0004]
    set patch_ver [ac7t1500::nap_axi_read "NAP_SPACE" $col $row fff0008]
    set p4_ver    [ac7t1500::nap_axi_read "NAP_SPACE" $col $row fff000c]

    scan $major_ver %x major_ver_dec
    scan $minor_ver %x minor_ver_dec
    scan $patch_ver %x patch_ver_dec
    scan $p4_ver    %x p4_ver_dec

    if { ![ac7t1500::get_reg_lib_sim_generate] } {
        message -info " -----------------------------------------"
        message -info "   Read Version Registers"
        message -info " -----------------------------------------"
        message -info "   Major Version    : $major_ver_dec"
        message -info "   Minor Version    : $minor_ver_dec"
        message -info "   Patch Version    : $patch_ver_dec"
        message -info "   Perforce Version : $p4_ver_dec"
        message -info " -----------------------------------------"
    }

    return [list $major_ver_dec $minor_ver_dec $patch_ver_dec $p4_ver_dec]
}

#------------------------------------------------------------------------------------
# Read Clock monitor when connected to user registers and display frequency
# If reference clock is not provided, default is assumed to be 100MHz
#------------------------------------------------------------------------------------
proc read_clock_monitor { col row addr_offset {ref_clock 100} {quiet 0} } {
    set mon_val [ac7t1500::nap_axi_read "NAP_SPACE" $col $row [ac7t1500::tidy_value $addr_offset 7]]

    # Calculate the target clock frequency.
    # The result from the read will be in hex
    scan $mon_val %x mon_val_dec

    # Calculate value
    set measured_f [expr { round(($mon_val_dec * $ref_clock)/10000) }] 

    if { [namespace exists ::jtag] && ($quiet != 1) } {
        message -info "Clock Monitor Block at $addr_offset returns a value of $mon_val_dec"
        message -info "With a reference frequency of $ref_clock MHz this equates to $measured_f MHz"
    }

    return $measured_f
}


# ---------------------------------------------------------------------
# Compare values from simulation file with those programmed in hardware
# ---------------------------------------------------------------------
# This will only compare CSR values, anything outside the CSR memory space
# will be ignored.  The ignore will be reported as a warning to the console
# By default this will only be run under ACE, the user can override this if
# they wish to also run in simulation
proc verify_programmed_values { infile {run_in_sim 0}} {

    if { [namespace exists ::jtag] || ($run_in_sim == 1) } {

        set fpi [open $infile {RDONLY}]
        if { $fpi == 0} {
            puts "Cannot open input file $infile"
            return -1
        }

        # Reading the file backwards is slow and costly
        # Read first and get a list of pointers to the start of each line
        # Construct the list of indices
        set indices {}
        while {![eof $fpi]} {
            lappend indices [tell $fpi]
            gets $fpi
        }

        set addr_chkd [list]

        # The config files have the same register written multiple times
        # Need to read from the bottom up, and ignore reading any address that has
        # already been read.
        # Iterate backwards
        foreach idx [lreverse $indices] {
            seek $fpi $idx
            set line [gets $fpi]

            # Ignore blank and comment lines
            if { ([string length $line] < 5) || ([string range $line 0 0] == "#") || \
                 ([string range $line 0 1] == "//") } { continue }

            # Parse input
            if { [info exists full]  } { unset full  }
            if { [info exists addr]  } { unset addr  }
            if { [info exists value] } { unset value }
            regexp {\s*([wrvd])\s+([0-9a-fA-F\_]+)\s+([0-9a-fA-F\_]+)} $line full cmd addr value
            if { ![info exists full] } {
                puts "ERROR - Unable to parse $line"
                return -1
            }
            # puts "$full - $cmd - $addr - $value"

            if { [lsearch $addr_chkd $addr] == -1 } {
                # Get the correct CSR address.  If not a CSR address, then drop entry
                set reg_list [ac7t1500::disassemble_csr_addr $addr]
                if { [llength $reg_list] != 4 } {
                    puts "Warning : Address $addr not decoded to CSR space.  Not verified" 
                    continue
                }

                # Do verify. This will print errors to the console if the verify fails
                # puts "ac7t1500::csr_verify_named $reg_list $value"
                # ac7t1500::csr_verify_named $reg_list $value
                if  { [ac7t1500::csr_verify_named [lindex $reg_list 0] [lindex $reg_list 1] [lindex $reg_list 2] [lindex $reg_list 3] $value] == 0 } {
                    # puts "ac7t1500::csr_verify_named $reg_list $value PASSED"
                }

                # Add addr into the current list as already having been checked
                lappend addr_chkd $addr
            } else {
                # puts "$addr already in the list"
            }

        }

    } else {
        puts "Warning : verify_programmed_values not run"
    }
}

# ---------------------------------------------------------------------
# Calculate an address given a base and offset when the registers offsets
# are given in steps of 1.
# To input hex values, precede the input strings with 0x
# Returns a hex string
# ---------------------------------------------------------------------
proc calc_reg_addr_1inc {base reg_offset} {

    # ACE Tcl console only supports 32-bit ints
    # Various experiments with wide() etc do not work because whenever the
    # value is then passed through scan/format/binary scan etc they only 
    # support a 32-bit input
    # Solution to do as strings

    # Base value will be a hex string anyway, expand to 11 chars
    set base_str [ac7t1500::tidy_value $base 11]

    # Offset can only be to a maximum of 24 bits
    set offset_str [format %06X [expr {($reg_offset*4) + "0x[string range $base_str 5 10]"}]]

    # Join top of base with offset
    set out_str "[string range $base_str 0 4]$offset_str"
    # puts "$base_str $offset_str $out_str"

    return $out_str
}

# ---------------------------------------------------------------------
# Clear all the user registers
# ---------------------------------------------------------------------
proc clear_all_user_regs { ur_col ur_row num_regs } {

    ac7t1500::write_comment_line "Clear all user registers"
    for {set reg 0} {$reg < $num_regs} {incr reg} {
        ac7t1500::nap_axi_write "NAP_SPACE" $ur_col $ur_row [calc_reg_addr_1inc 0x0 $reg] 0x0
    }
}

# ---------------------------------------------------------------------
# Read a pair of 32-bit registers to get a 64-bit value
# ---------------------------------------------------------------------
proc read_64_bit_user_regs { ur_col ur_row low_reg {threshold 100}} {

    # Clean inputs
    set low_reg_hex [ac7t1500::tidy_value $low_reg 8]

    # To handle wrap around, read high word, low word.  If low word is below
    # the threshold, then re-read high word and use that new value
    # To use this function, the high word register must be the next register up
    set high_reg_hex [format %x [expr (0x$low_reg_hex + 4)]]

    # Read back to back
    set high_word [ac7t1500::nap_axi_read "NAP_SPACE" $ur_col $ur_row $high_reg_hex]
    set low_word  [ac7t1500::nap_axi_read "NAP_SPACE" $ur_col $ur_row $low_reg_hex]

    if { [expr (0x$low_word)] < $threshold } {
        set high_word [ac7t1500::nap_axi_read "NAP_SPACE" $ur_col $ur_row $high_reg_hex]
    }

    return [expr ((0x$high_word << 32) + 0x$low_word)]
}

# ---------------------------------------------------------------------
# Verify a pair of 32-bit registers against a 64-bit value
# ---------------------------------------------------------------------
proc verify_64_bit_user_regs { ur_col ur_row low_reg exp_value {threshold 100}} {

    # Clean inputs & calculate register addresses
    set low_reg_hex [ac7t1500::tidy_value $low_reg 8]
    set high_reg_hex [format %x [expr (0x$low_reg_hex + 4)]]

    # Calc expected values
    set exp_low  [format %08x [expr ($exp_value & 0xffffffff)]]
    set exp_high [format %08x [expr ($exp_value >> 32)]]

    # To handle wrap around, read high word, low word.  If low word is below
    # the threshold, then re-read high word and use that new value
    # To use this function, the high word register must be the next register up

    if { [ac7t1500::get_reg_lib_sim_generate] } {
        # Simulation
        ac7t1500::nap_axi_verify "NAP_SPACE" $ur_col $ur_row $high_reg_hex $exp_high
        ac7t1500::nap_axi_verify "NAP_SPACE" $ur_col $ur_row $low_reg_hex $exp_low
    } else {
        # Silicon

        # Read back to back, re-read high if low just wrapped            
        set high_word [ac7t1500::nap_axi_read "NAP_SPACE" $ur_col $ur_row $high_reg_hex]
        set low_word  [ac7t1500::nap_axi_read "NAP_SPACE" $ur_col $ur_row $low_reg_hex]

        if { [expr (0x$low_word)] < $threshold } {
            set high_word [ac7t1500::nap_axi_read "NAP_SPACE" $ur_col $ur_row $high_reg_hex]
        }

        if { ($high_word != $exp_high) || ($low_word != $exp_low) } {
            puts "ERROR : Incorrect 64-bit value at address $low_reg_hex"
            # puts "$high_word $exp_high : $low_word $exp_low"
            set read_val [format %x [expr {("0x$high_word" << 32) + "0x$low_word"}]]
            puts "        Expected value [format %x $exp_value] : Actual value $read_val"
            return -1
        }
    }

    # To get here means value passed
    return 0
}

# ---------------------------------------------------------------------
# Display large numbers
# By default add comma's. In addition can scale and add K or M multipliers
# ---------------------------------------------------------------------
proc format_large_val { in_str {multiplier -1} } {

    # Trap an input of 0
    if { [expr $in_str] == 0 } { return $in_str }

    # Trim any leading 0's, otherwise this looks like an Octal number
    set in_str [string trimleft $in_str "0"]

    # Check input is an integer or a double
    if { ![string is integer -strict $in_str] && ![string is double -strict $in_str]} {
        puts "ERROR - Input is not an integer or double : $in_str"
        return -1
    }

    set len [string length $in_str]
    # Don't process if value is below 1000
    if { $len < 4 } { return $in_str } 

    # Auto-set multiplier if not fixed
    if { $multiplier == -1 } {
        if { $len > 12 } {
            set multiplier 9
        } elseif { $len > 9 } {
            set multiplier 6
        } elseif { $len > 6 } {
            set multiplier 3
        } else {
            set multiplier 0
        }
    }

    switch $multiplier {
        0 { set mod_str $in_str
          }
        3 { set mod_str [expr ($in_str/1000)]
          }
        6 { set mod_str [expr ($in_str/1000000)]
          }
        9 { set mod_str [expr ($in_str/1000000000)]
          }
        default { puts "ERROR - Unknown multiplier value of $multiplier"; return -1 }
    }

    # puts "mod $mod_str"
    set mod_len [string length $mod_str]

    # Add comma's every 3 characters
    set i 0
    set out_str ""
    while { $i < $mod_len } {
        # This builds the output string in reverse
        append out_str [string index $mod_str end-$i]
        # puts "a $i [string index $mod_str end-$i] $out_str [expr ($i % 3)]"
        if { ([expr (($i+1) % 3)] == 0) && ([expr ($i+1)] != $mod_len) } {
            append out_str ","
        }
        # puts "b $i $out_str"
        incr i
    }

    # Add the multiplier indicator
    switch $multiplier {
        3 { return "[string reverse $out_str] K"
          }
        6 { return "[string reverse $out_str] M"
          }
        9 { return "[string reverse $out_str] B"
          }
    }

    return [string reverse $out_str]
}

# ---------------------------------------------------------------------
# Reset AXI memory channel
# ---------------------------------------------------------------------
proc reset_axi_mem_channel { name ur_col ur_row base_addr {verbose 0}} {
    set CONTROL_REG_ADDR  [calc_reg_addr_1inc $base_addr 0]

    # Ensure register is 0 to start, puts everything into reset
    ac7t1500::nap_axi_write NAP_SPACE $ur_col $ur_row $CONTROL_REG_ADDR 0

    if { $verbose } { message -info "AXI memory channel $name placed in reset" }
}

# ---------------------------------------------------------------------
# Start AXI memory channel
# ---------------------------------------------------------------------
proc start_axi_mem_channel { name ur_col ur_row base_addr num_xact max_bursts {verbose 0} {continuous 0} } {
    set CONTROL_REG_ADDR  [calc_reg_addr_1inc $base_addr 0]
    set STATUS_REG_ADDR   [calc_reg_addr_1inc $base_addr 1]
    set NUM_XACT_REG_ADDR [calc_reg_addr_1inc $base_addr 2]

    # Ensure register is 0 to start, puts everything into reset
    reset_axi_mem_channel $name $ur_col $ur_row $base_addr $verbose

    # Release all resets, enable fifo flush
    ac7t1500::nap_axi_write NAP_SPACE $ur_col $ur_row $CONTROL_REG_ADDR 0x1f

    # Release fifo flush
    ac7t1500::nap_axi_write NAP_SPACE $ur_col $ur_row $CONTROL_REG_ADDR 0x0f

    # Write number of transactions
    ac7t1500::nap_axi_write  NAP_SPACE $ur_col $ur_row $NUM_XACT_REG_ADDR [format %x $num_xact]
    ac7t1500::nap_axi_verify NAP_SPACE $ur_col $ur_row $NUM_XACT_REG_ADDR [format %x $num_xact]

    # Start channel, (if more than zero transfers required)
    if { $num_xact || $continuous } {
        if { $max_bursts } { set val 0x6f } else { set val 0x4f }
        ac7t1500::nap_axi_write NAP_SPACE $ur_col $ur_row $CONTROL_REG_ADDR $val
        if { $verbose } { 
            if {$continuous} {
                message -info "Starting AXI memory channel $name in continuous mode"
            } else {
                message -info "Starting AXI memory channel $name with [format_large_val $num_xact 0] transactions"
            }
        }
        # Presume that having num_xact set to 0 is intentional from the calling routine
        # So return as error free
        return 0
    }

    # Test should be running, not done and no errors.  
    # Outstanding_compares may be set, so needs to be masked off
    set status_reg [ac7t1500::nap_axi_read NAP_SPACE $ur_col $ur_row $STATUS_REG_ADDR]
    # message -info "$name status reg $status_reg"
    if { [expr (0x$status_reg & 0xf)] != 0x5 } {
        return -1
    }

    return 0
}

# ---------------------------------------------------------------------
# Monitor AXI memory channel
# ---------------------------------------------------------------------
proc monitor_axi_mem_channel { name ur_col ur_row base_addr {verbose 0}} {
    # Return how many transactions remaining
    set REMAINING_XACT_ADDR  [calc_reg_addr_1inc $base_addr 3]

    set ret_val [expr "0x[ac7t1500::nap_axi_read NAP_SPACE $ur_col $ur_row $REMAINING_XACT_ADDR]"]

    if { $verbose } { message -info "$ret_val transactions remaining on AXI memory channel $name" }

    return $ret_val
}

# ---------------------------------------------------------------------
# Read AXI memory channel performance
# ---------------------------------------------------------------------
proc read_axi_mem_channel { name ur_col ur_row base_addr {verbose 0}} {
    # Return how many transactions remaining
    set STATUS_REG_ADDR     [calc_reg_addr_1inc $base_addr 1]
    set REMAINING_XACT_ADDR [calc_reg_addr_1inc $base_addr 3]
    set MONITOR_BASE_ADDR   [calc_reg_addr_1inc $base_addr 4]

    if { $verbose } { message -info " Checking status of AXI memory channel $name" }

    set ret_val 0

    # Confirm test has completed with no errors. Done signals set, all others clear
    incr ret_val [ac7t1500::nap_axi_verify NAP_SPACE $ur_col $ur_row $STATUS_REG_ADDR 0A]
    # Confirm no outstanding transactions
    incr ret_val [ac7t1500::nap_axi_verify NAP_SPACE $ur_col $ur_row $REMAINING_XACT_ADDR 0]

    # Read performance monitor
    read_axi_monitor $name $ur_col $ur_row $MONITOR_BASE_ADDR

    return $ret_val
}

# ---------------------------------------------------------------------
# Read AXI performance monitor
# ---------------------------------------------------------------------
proc read_axi_monitor { name ur_col ur_row base_addr } {
    # set READ_BW_ADDR    [calc_reg_addr_1inc $base_addr 0]
    # set WRITE_BW_ADDR   [calc_reg_addr_1inc $base_addr 1]
    set CURR_LAT_ADDR   [calc_reg_addr_1inc $base_addr 2]
    set AVG_LAT_ADDR    [calc_reg_addr_1inc $base_addr 3]
    set MAX_LAT_ADDR    [calc_reg_addr_1inc $base_addr 4]
    set MIN_LAT_ADDR    [calc_reg_addr_1inc $base_addr 5]
    set FREQ_WIDTH_ADDR [calc_reg_addr_1inc $base_addr 6]

    message -info " -----------------------------------------"
    message -info "  $name monitor results"
    message -info " -----------------------------------------"
    message -info "     Bandwidth"
    message -info " -----------------------------------------"

    # Read Frequency, width and monitor type
    set freq_width_reg [ac7t1500::nap_axi_read NAP_SPACE $ur_col $ur_row $FREQ_WIDTH_ADDR 01000100]

    # puts "freq_width_reg $freq_width_reg"
    set mon_type [string range $freq_width_reg 0 0]
    set freq     [string range $freq_width_reg 1 3]
    set width    [string range $freq_width_reg 4 7]

    if { $mon_type != 0 } { message -error "Incorrect monitor type read.  Monitor reports type $mon_type" }

    # puts "Frequency [expr 0x$freq]. Data width [expr 0x$width]"

    # Read the two bandwidth results
    for {set ch 0} {$ch < 2} {incr ch} {
        set BW_ADDR [calc_reg_addr_1inc $base_addr $ch]
        set bw_reg [ac7t1500::nap_axi_read NAP_SPACE $ur_col $ur_row $BW_ADDR]

        # Split bandwidth registers
        # [29:20] = Average
        # [19:10] = Max
        # [9:0]   = Min
        set bw_reg_dec [expr 0x$bw_reg]
        set av_bw  [expr { ($bw_reg_dec & 0x3ff00000) >> 20 }]
        set max_bw [expr { ($bw_reg_dec & 0x000ffc00) >> 10 }]
        set min_bw [expr { ($bw_reg_dec & 0x000003ff) }]

        # puts "BW reg $bw_reg"
        # puts "Av hex [format %x $av_bw] Max [format %x $max_bw] Min [format %x $min_bw]"
        # puts "Av $av_bw Max $max_bw Min $min_bw"
        set max_limit [expr (0x$freq * 0x$width)]
        # puts "max_limit $max_limit"

        if {$ch == 0} { set str "read " } else { set str "write" }

        # Results are divided by 1024 as they are accumulated over a 2^10 deep FIFO
        message -info "  Maximum $str bandwidth : [format %0.2f [expr {($max_limit * $max_bw) / (1024.0 * 1000.0)}]] Gbps"
        message -info "  Average $str bandwidth : [format %0.2f [expr {($max_limit * $av_bw)  / (1024.0 * 1000.0)}]] Gbps"
        message -info "  Minimum $str bandwidth : [format %0.2f [expr {($max_limit * $min_bw) / (1024.0 * 1000.0)}]] Gbps"
    }

    message -info " -----------------------------------------"
    message -info "     Latency"
    message -info " -----------------------------------------"

    # Read the latency registers
    # Skip current latency, that would be better served on its own
    for {set ch 3} {$ch < 6} {incr ch} {
        set LAT_ADDR [calc_reg_addr_1inc $base_addr $ch]
        set lat_reg [ac7t1500::nap_axi_read NAP_SPACE $ur_col $ur_row $LAT_ADDR]

        # puts "lat_reg $lat_reg"

        # Split bandwidth registers
        # [27:16] = Read
        # [11:0]  = Write
        set lat_reg_dec [expr 0x$lat_reg]
        set rd_lat [expr { ($lat_reg_dec & 0x0fff0000) >> 16 }]
        set wr_lat [expr { ($lat_reg_dec & 0x00000fff) }]

        # puts "rd_lat $rd_lat. wr_lat $wr_lat"

        # Clock frequency period in ns
        set period [expr (1000.0 / 0x$freq)]
        # puts "period $period"

        switch $ch {
            3 { set str "Average" }
            4 { set str "Maximum" }
            5 { set str "Minimum" }
        }

        # Results are divided by 1024 as they are accumulated over a 2^10 deep FIFO
        message -info "  $str read latency  : [format %0.2f [expr {$rd_lat * $period}]] ns"
        message -info "  $str write latency : [format %0.2f [expr {$wr_lat * $period}]] ns"
    }


    message -info " -----------------------------------------"
}

# ---------------------------------------------------------------------
# Read Data stream performance monitor
# ---------------------------------------------------------------------
proc read_data_stream_monitor { name ur_col ur_row base_addr {verbose 1} {debug 0}} {

    set BW_REG_ADDR     [calc_reg_addr_1inc $base_addr 0]
    set FREQ_WIDTH_ADDR [calc_reg_addr_1inc $base_addr 1]

    # if debug set, then assume we need verbose set as well
    if { $debug } { set verbose 1 }

    if { $verbose } {
        message -info " -----------------------------------------"
        message -info "  $name monitor results"
        message -info " -----------------------------------------"
        message -info "     Bandwidth"
        message -info " -----------------------------------------"
    }
    
    set freq_width_reg [ac7t1500::nap_axi_read "NAP_SPACE" $ur_col $ur_row $FREQ_WIDTH_ADDR]

    set mon_type [string range $freq_width_reg 0 0]
    set freq     [string range $freq_width_reg 1 3]
    set width    [string range $freq_width_reg 4 7]

    if { $mon_type != 4 } { message -error "Incorrect monitor type read.  Monitor reports type $mon_type" }

    if { $debug } {
        puts "freq_width_reg $freq_width_reg"
    }
    
    if { $verbose } {
        puts "Frequency [expr 0x$freq]. Data width [expr 0x$width]"
    }

    set bw_reg  [ac7t1500::nap_axi_read NAP_SPACE $ur_col $ur_row $BW_REG_ADDR]
    # Split bandwidth registers
    # [29:20] = current
    # [19:10] = Max
    # [9:0]   = Min
    set bw_reg_dec [expr 0x$bw_reg]
    set cur_bw     [expr { ($bw_reg_dec & 0x3ff00000) >> 20 }]
    set max_bw     [expr { ($bw_reg_dec & 0x000ffc00) >> 10 }]
    set min_bw     [expr { ($bw_reg_dec & 0x000003ff) }]

    # The max value is limited to 0xff in order to not overflow.  If 0xff is detected, then
    # increment to reflect 100% BW
    if { $cur_bw == 1023 } { incr cur_bw }
    if { $max_bw == 1023 } { incr max_bw }

    if { $debug } {
        puts "BW reg $bw_reg"
        puts "Cur hex [format %x $cur_bw] Max [format %x $max_bw] Min [format %x $min_bw]"
        puts "Cur $cur_bw Max $max_bw Min $min_bw"
    }
    set max_limit [expr (0x$freq * 0x$width)]
    set width_dec [expr 0x$width]
    set freq_dec [expr 0x$freq]

    # Although there are 10-bits for the value, it allows for 100% throughput
    # So the normalised range is 512, resulting in an accuracy of 0.2%
    set max_bw_scaled    [expr {($max_limit * $max_bw) / (512.0 * 1000.0)}]
    set avg_bw_scaled    [expr {($max_limit * $cur_bw) / (512.0 * 1000.0)}]
    set min_bw_scaled    [expr {($max_limit * $min_bw) / (512.0 * 1000.0)}]
    set max_limit_scaled [expr {($max_limit * 512.0)   / (512.0 * 1000.0)}]

    if { $verbose } {
        message -info "  Maximum bandwidth : [format %0.2f $max_bw_scaled] Gbps"
        message -info "  Average bandwidth : [format %0.2f $avg_bw_scaled] Gbps"
        message -info "  Minimum bandwidth : [format %0.2f $min_bw_scaled] Gbps"
    }
    
    return [list $max_bw_scaled $avg_bw_scaled $min_bw_scaled $max_limit_scaled]
}


# ---------------------------------------------------------------------
#  Read write and modify a field in a register.
#  width:  width of field
#  low: lowest bit in  field
#  field_value:  new value in decimal 
# ---------------------------------------------------------------------

proc csr_set_field_named {space target ip name low width field_value } {

    set reg_val [ac7t1500::csr_read_named $space $target $ip $name]
    if { $reg_val eq "" } {
        return reg_val
        }
    scan $reg_val %x reg_val
        
    set mask [expr ((2**$width)-1)<<$low]
    set new_val [expr ((~$mask) & $reg_val) | ($mask&($field_value<<$low))]
    ac7t1500::csr_write_named  $space $target $ip $name [format %X $new_val]
    ac7t1500::csr_verify_named $space $target $ip $name [format %X $new_val]
    return $new_val
}

# ---------------------------------------------------------------------
# ---------------------------------------------------------------------

