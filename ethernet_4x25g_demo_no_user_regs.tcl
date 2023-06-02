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
# The Software is provided ‚Äúas is‚Äù without warranty of any kind
# expressed or implied, including  but not limited to the warranties
# of merchantability fitness for a particular purpose and non-infringement.
# In no event shall the copyright holder be liable for any claim,
# damages, or other liability for any damages or other liability,
# whether an action of contract, tort or otherwise, arising from, 
# out of, or in connection with the Software
#
# ---------------------------------------------------------------------
# Simple Ethernet 4x25G reference design script
# ---------------------------------------------------------------------
#
# BEFORE running this script, must setup jtag device
# jtag::get_connected_devices
# ACVP8070192
# set jtag_id ACVP8070192
#cd c:/Achronix/kits/VP_S7t-VG6/Roche/vp_sim_eth_demo-main/scripts

# REVISIT - check if this should remain
# allow redefinitions
#if {[string length [info commands _proc]]} {
#††† rename proc ""
#††† rename _proc proc
#}

# Mik notes
#ac7t1500::get_dict_spaces
#ac7t1500::get_dict_spaces CSR_SPACE
#ac7t1500::get_dict_spaces CSR_SPACE ETHERNET_1 
#ac7t1500::program_hex_file project_top.hex
#ac7t1500::close_jtag
#set jtag_port_open 0

# Source utility functions
source AC7t1500ES0_common_utils.tcl
# Source ethernet functions
source AC7t1500ES0_ethernet_utils.tcl
# Source serdes utility functions
source AC7t1500ES0_serdes_utils.tcl

# Process input arguments
ac7t1500::process_args $argc $argv

# Define command filename
set OUTPUT_FILENAME "../../sim/ethernet_4x25g_sim.txt"


# Open the command file.
# File will only be created if not running under ACE
# Pass script name, ($argv0), for header
ac7t1500::open_command_file $OUTPUT_FILENAME $argv0

# When running under ACE, ensure jtag port is open
ac7t1500::open_jtag

# ---------------------------------------------------------------------
# Flow starts here
# ---------------------------------------------------------------------
set quiet_script 1

# ---------------------------------------------------------------------
# Check all the Ethernet revision and scratch registers
# ---------------------------------------------------------------------
puts "Check ETHERNET_1 version and scratch registers"
foreach eth {ETHERNET_1} {
    eth_utils::chk_version_and_scratch_regs $eth
}

# Autodetect whether this is a first run based on whether PCS is already locked.
set pcs_status1 [ac7t1500::csr_read_named CSR_SPACE ETHERNET_1 QUAD_PCS_0 BASER_STATUS1_0]
puts "PCS Status1 = $pcs_status1"

if { ($pcs_status1) == "00001001" } {
    set first_run 0
    message -info "Ethernet already locked. PCS status $pcs_status1"
} else {
    set first_run 1
    message -warning "Ethernet not yet locked, run initialization. PCS status $pcs_status1"
}
puts "Did I get here 1?"
# Define the location of the reg control block NAP
# This is fixed in the testbench, and the ace_placements.pdc
set ur_row 7
set ur_col 4

# ---------------------------------------------------------------------
# Read the version registers
# ---------------------------------------------------------------------
ac7t1500::write_comment_line "Read version registers"
#read_version_regs $ur_col $ur_row
puts "Did I get here 2?"

# Set loopback when running under ACE
if { ![ac7t1500::get_reg_lib_sim_generate] && ($first_run == 1) } {

    # ---------------------------------------------------------------------
    # Toggle Serdes TX and RX STATE REQ to 0. After bitstream download it is 1.
    # ---------------------------------------------------------------------
    foreach eth {ETHERNET_1} {
        foreach xcvr {SERDES_0 SERDES_1} {
            serdes_utils::tx_rx_state_req $eth $xcvr 0
        }
    }
puts "Did I get here 3?"

    # ---------------------------------------------------------------------
    # Configure SerDes
    # ---------------------------------------------------------------------
    # Ethernet 1 is a loopback test, so again set Ethernet 1 to NES
    # Both Ethernet subsystems are only using the lower Serdes quad, the upper is unused

    # ---------------------------------------------------------------------
    # Check EIU registers.  This confirms if simulation and bitstream have
    # correctly configured the EIU 
    # ---------------------------------------------------------------------
    foreach eth {ETHERNET_1} {
         eth_utils::dump_eiu_registers $eth
    }

    # ---------------------------------------------------------------------
    # Set NES loopback
    # ---------------------------------------------------------------------
    # Serdes near end serial
    foreach eth {ETHERNET_1} {
        foreach serdes {SERDES_0} {
            serdes_utils::nes_loopback $eth $serdes 1
        }
    }
puts "Did I get here 4?"

    # Trigger RX EQ.  This will achieve PCS lock for each channel
    foreach eth {ETHERNET_1} {
        foreach serdes {SERDES_0} {
            serdes_utils::acx_pcs_trigger_rx_eq $eth $serdes
        }
    }
puts "Did I get here 5?"

    # Wait for CDR to settle.
    ac7t1500::wait_ns 200

    # Read the PMA lock status
    foreach eth {ETHERNET_1} {
        serdes_utils::rx_lock_status $eth 2
    }

    # ---------------------------------------------------------------------
    # Check BASE-R registers
    # ---------------------------------------------------------------------
    foreach eth {ETHERNET_1} {
        eth_utils::quad_pcs_baser_status1 $eth
    }

    # ---------------------------------------------------------------------
    # Check Quad MAC status
    # Do twice to clear local fault flag
    # ---------------------------------------------------------------------
    foreach eth {ETHERNET_1} {
        eth_utils::quad_mac_status $eth
        eth_utils::quad_mac_status $eth
    }
puts "Did I get here 6?"

    # Check PCS lock signals
#    eth_utils::chk_quad_pcs_status $ur_col $ur_row 76
puts "Did I get here 7?"

};  # End of ![ac7t1500::get_reg_lib_sim_generate] and $first_run

# Ensure all the above is done
ac7t1500::wait_ns 200

# ---------------------------------------------------------------------
# Reset MAC/PCS blocks
# ---------------------------------------------------------------------
# Only reset PCS when under ACE
if { ![ac7t1500::get_reg_lib_sim_generate] } {
    foreach eth {ETHERNET_1} {
        foreach qpcs {QUAD_PCS_0} {
            eth_utils::reset_quad_pcs $eth $qpcs
        }
    }
}
puts "Did I get here 8?"

# Only reset MAC when under ACE
if { ![ac7t1500::get_reg_lib_sim_generate] } {
    foreach eth {ETHERNET_1} {
        foreach qmac {QUAD_MAC_0} {
            eth_utils::reset_quad_mac $eth $qmac
        }
    }
}
puts "Did I get here 9?"

# ---------------------------------------------------------------------
# Reset stats module
# ---------------------------------------------------------------------
foreach eth {ETHERNET_1} {
    foreach qmac {QUAD_MAC_0} {
        eth_utils::stats_reset_module $eth $qmac
    }
}

foreach eth {ETHERNET_1} {
    foreach qpcs {QUAD_PCS_0} {
        for {set ch 0} {$ch < 4} {incr ch} {
            eth_utils::fec_quad_status $eth $qpcs $ch 0
        }
    }
}
puts "Did I get here 10?"

# Set channel number
set ch 0

# Reset each channel
#ac7t1500::write_comment_line "Reset ethernet channel $ch"
#eth_utils::eth_ch_reset $ur_col $ur_row 0x0

# Unset variables to prevent issues when switching designs
unset pcs_status1
unset first_run

# ---------------------------------------------------------------------
#                 Flow ends here
# ---------------------------------------------------------------------

# Close command file
# File will only exist when not running under ACE
ac7t1500::close_command_file $OUTPUT_FILENAME

# Close the jtag port to allow user to run SnapShot
ac7t1500::close_jtag

return
