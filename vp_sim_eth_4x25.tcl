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
set VP_jtag_id [jtag::get_connected_devices]
puts "Found connected device $VP_jtag_id"
set jtag_id $VP_jtag_id

# Source utility functions
source AC7t1500ES0_common_utils.tcl
# Source ethernet functions
source AC7t1500ES0_ethernet_utils.tcl
# Source serdes utility functions
source AC7t1500ES0_serdes_utils.tcl

# When running under ACE, ensure jtag port is open
puts "Open the JTAG interface"
ac7t1500::open_jtag

# ---------------------------------------------------------------------
# Flow starts here
# ---------------------------------------------------------------------
# set quiet_script to 0 for more verbose messaging
set quiet_script 1

# ---------------------------------------------------------------------
# Check all the Ethernet revision and scratch registers
# ---------------------------------------------------------------------
puts "Check ETHERNET_1 version and scratch registers"
foreach eth {ETHERNET_1} {
    eth_utils::chk_version_and_scratch_regs $eth
}

# Autodetect whether this is a first run based on whether PCS is already locked.
puts "Autodetect whether this is a first run based on whether PCS is already locked"
set pcs_status1 [ac7t1500::csr_read_named CSR_SPACE ETHERNET_1 QUAD_PCS_0 BASER_STATUS1_0]
puts "PCS status1 = $pcs_status1"

if { ($pcs_status1) == "00001001" } {
    set first_run 0
    message -info "Ethernet already locked. PCS status $pcs_status1"
} else {
    set first_run 1
    message -warning "Ethernet not yet locked, run initialization. PCS status $pcs_status1"
}

# Setup Serdes configuration, equalization, check CDR, PMA, PCS, and MAC
if { ![ac7t1500::get_reg_lib_sim_generate] && ($first_run == 1) } {
    puts "Setup Serdes configuration, equalization, check CDR, PMA, PCS, and MAC"

    # Toggle Serdes TX and RX STATE REQ to 0. After bitstream download it is 1.
    puts "Toggle Serdes TX and RX STATE REQ to 0."
    foreach eth {ETHERNET_1} {
        foreach xcvr {SERDES_0 SERDES_1} {
            serdes_utils::tx_rx_state_req $eth $xcvr 0
        }
    }

    # Check EIU registers.  This confirms if simulation and bitstream have
    # correctly configured the EIU 
    puts "Check EIU registers."
    foreach eth {ETHERNET_1} {
         eth_utils::dump_eiu_registers $eth
    }

    # Trigger RX EQ.  This will attempt PCS lock for each channel
    puts "Trigger RX EQ.  This will attempt PCS lock for each channel."
    foreach eth {ETHERNET_1} {
        foreach serdes {SERDES_0} {
            serdes_utils::acx_pcs_trigger_rx_eq $eth $serdes
        }
    }

    # Wait for CDR to settle.
    puts "Wait for CDR to settle."
    ac7t1500::wait_ns 200

    # Read the PMA lock status
    puts "Read the PMA lock status"
    foreach eth {ETHERNET_1} {
        serdes_utils::rx_lock_status $eth 2
    }

    # Check BASE-R registers
    puts "Check BASE-R registers"
    foreach eth {ETHERNET_1} {
        eth_utils::quad_pcs_baser_status1 $eth
    }

    # Check Quad MAC status
    # Do twice to clear local fault flag
    puts "Check Quad MAC status.  Do twice to clear local fault flag."
    foreach eth {ETHERNET_1} {
        eth_utils::quad_mac_status $eth
        eth_utils::quad_mac_status $eth
    }

};  # End of ![ac7t1500::get_reg_lib_sim_generate] and $first_run

# Ensure all the above is done
ac7t1500::wait_ns 200

# ---------------------------------------------------------------------
# Reset MAC/PCS blocks
# ---------------------------------------------------------------------
# Reset PCS
puts "Reset PCS."
if { ![ac7t1500::get_reg_lib_sim_generate] } {
    foreach eth {ETHERNET_1} {
        foreach qpcs {QUAD_PCS_0} {
            eth_utils::reset_quad_pcs $eth $qpcs
        }
    }
}

# Reset MAC
puts "Reset MAC."
if { ![ac7t1500::get_reg_lib_sim_generate] } {
    foreach eth {ETHERNET_1} {
        foreach qmac {QUAD_MAC_0} {
            eth_utils::reset_quad_mac $eth $qmac
        }
    }
}

# ---------------------------------------------------------------------
# Reset stats module
# ---------------------------------------------------------------------
puts "Reset Ethernet Stats"
foreach eth {ETHERNET_1} {
    foreach qmac {QUAD_MAC_0} {
        eth_utils::stats_reset_module $eth $qmac
    }
}

puts "Reset Ethernet FEC Quad Stats"
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
