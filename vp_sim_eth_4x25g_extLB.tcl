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
# Simple Ethernet 4x25G reference design script
# ---------------------------------------------------------------------
# cd to the directory that contains this script.
# In ACE Tcl shell do:
# cmd> source vp_sim_eth_4x25_extLB.tcl
set jtag_id ACVP8070192

# Source utility functions
source AC7t1500ES0_common_utils.tcl
# Source ethernet functions
source AC7t1500ES0_ethernet_utils.tcl
# Source serdes utility functions
source AC7t1500ES0_serdes_utils.tcl

# When running under ACE, ensure jtag port is open
ac7t1500::open_jtag

# ---------------------------------------------------------------------
# Flow starts here
# ---------------------------------------------------------------------
# quiet_script 0 or 1 where 0 gives more terse information as script runs
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
# ---------------------------------------------------------------------
# Reset MAC/PCS blocks
# ---------------------------------------------------------------------
foreach eth {ETHERNET_1} {
    foreach qpcs {QUAD_PCS_0} {
        eth_utils::reset_quad_pcs $eth $qpcs
    }
}

# Only reset MAC when under ACE
foreach eth {ETHERNET_1} {
    foreach qmac {QUAD_MAC_0} {
        eth_utils::reset_quad_mac $eth $qmac
    }
}
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

# Unset variables to prevent issues when switching designs
unset pcs_status1
unset first_run

# ---------------------------------------------------------------------
#                 Flow ends here
# ---------------------------------------------------------------------

# Close the jtag port to allow user to run SnapShot
ac7t1500::close_jtag

return
