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
# Ethernet 4x25G reference design script
# ---------------------------------------------------------------------
#
# BEFORE running this script, must setup jtag device

# Source utility functions
source AC7t1500ES0_common_utils.tcl
# Source ethernet functions
source AC7t1500ES0_ethernet_utils.tcl
# Source serdes utility functions
source AC7t1500ES0_serdes_utils.tcl

# Process input arguments
ac7t1500::process_args $argc $argv

# When running under ACE, ensure jtag port is open
ac7t1500::open_jtag

# ---------------------------------------------------------------------
# Flow starts here
# ---------------------------------------------------------------------
set quiet_script 1

# ---------------------------------------------------------------------
# Check the loopback test on Ethernet 1, (eth_channel_one_nap 0)
# ---------------------------------------------------------------------

# Set channel number
set ch 0

# Check the channel status
ac7t1500::write_comment_line "Check ethernet channel $ch status"

# Define constants for TX and RX stats capture
set TX_STATS 1
set RX_STATS 0

# Determine whether to print long or short form of stats
set all_stats 1
# Determine whether to shorten stats if the channel passes
# This takes priority over $all_stats above
set terse_stats 0

# Enable stats printout
set report_stats 1

# Only report stats when running under ACE
if { ![ac7t1500::get_reg_lib_sim_generate] } {

    if { $report_stats == 1 } {
        # Read stats for Ethernet 1 only, (Ethernet 0 has no traffic when run on hardware)
        # Both channels only use MAC 0
        set qmac QUAD_MAC_0

        foreach eth {ETHERNET_1} {
            # Report FEC stats. Only channel 0
            set fec_list [eth_utils::fec_quad_status $eth QUAD_PCS_0 0 0]
            if { [lindex $fec_list 0] } { message -info "FEC correctable errors [lindex $fec_list 0]"}
            if { [lindex $fec_list 1] } { message -warning "FEC uncorrectable errors [lindex $fec_list 1]"}
            message -info " ----------------------------------------"
            unset fec_list

            if { ![eth_utils::stats_capture_channel $eth $qmac [expr {$ch % 4}] \
                                                    $TX_STATS $all_stats $terse_stats] } {
                incr retval -1
            }
            if { ![eth_utils::stats_capture_channel $eth $qmac [expr {$ch % 4}] \
                                                    $RX_STATS $all_stats $terse_stats] } {
                incr retval -1
            }
        }
    }

    # ---------------------------------------------------------------------
    # Re-read all the status
    # ---------------------------------------------------------------------
    # Get the PMA lock status
    foreach eth {ETHERNET_1} {
        # serdes_utils::rx_lock_status $eth 2
    }

    # Quad MAC status
    # Read twice, once to clear loc flag
    foreach eth {ETHERNET_1} {
        # eth_utils::quad_mac_status $eth
        # eth_utils::quad_mac_status $eth
    }

    # Check BASER registers
    foreach eth {ETHERNET_1} {
        # eth_utils::quad_pcs_baser_status1 $eth
    }

}; # if { ![ac7t1500::get_reg_lib_sim_generate] } {

# ---------------------------------------------------------------------
# Reset stats module
# ---------------------------------------------------------------------
foreach eth {ETHERNET_1} {
    foreach qmac {QUAD_MAC_0} {
        eth_utils::stats_reset_module $eth $qmac
    }
}

# ---------------------------------------------------------------------
#                 Flow ends here
# ---------------------------------------------------------------------
# Close the jtag port
ac7t1500::close_jtag

return $retval

