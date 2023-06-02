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
#   Ethernet utilities package
# ---------------------------------------------------------------------

namespace eval eth_utils {
    # Any variables that should be shared between ethernet utilities as
    # common static variables can be defined here

    # All functions below are declared in the eth_utils namespace

    # ---------------------------------------------------------------------
    # ---------------------------------------------------------------------
    # Functions that match eth_channel_one_nap.sv
    # ---------------------------------------------------------------------
    # ---------------------------------------------------------------------

    # ---------------------------------------------------------------------
    # Reset the channel
    # ---------------------------------------------------------------------
    proc eth_ch_reset { ur_col ur_row base_addr } {

        # Set reset and clear all control bits
        ac7t1500::nap_axi_write "NAP_SPACE" $ur_col $ur_row $base_addr 0x0
        ac7t1500::wait_ns 10
    }

    # ---------------------------------------------------------------------
    # Set the number of packets on a channel and start
    # num_pkts is decimal.  base_addr is hex
    # ---------------------------------------------------------------------
    proc eth_ch_start { num_pkts_dec ur_col ur_row base_addr {ext_fields 0}} {
        set CONTROL_REG_ADDR [calc_reg_addr_1inc $base_addr 0]
        set NUM_PKT_REG_L    [calc_reg_addr_1inc $base_addr 2]
        set NUM_PKT_REG_M    [calc_reg_addr_1inc $base_addr 3]

        set num_pkts_msb [format %x [expr ($num_pkts_dec >> 32)]]
        set num_pkts_lsb [format %x [expr ($num_pkts_dec & 0xffffffff)]]

        # Set number of packets, (in hex)
        ac7t1500::nap_axi_write "NAP_SPACE" $ur_col $ur_row $NUM_PKT_REG_L $num_pkts_lsb
        ac7t1500::nap_axi_write "NAP_SPACE" $ur_col $ur_row $NUM_PKT_REG_M $num_pkts_msb

        # Release reset, (bit [0])
        set value 0x1
        ac7t1500::nap_axi_write "NAP_SPACE" $ur_col $ur_row $CONTROL_REG_ADDR [format %x $value]
        ac7t1500::wait_ns 10

        # Add in any extended fields specific to that design
        set value [expr ($value | 0x$ext_fields)]
        ac7t1500::nap_axi_write "NAP_SPACE" $ur_col $ur_row $CONTROL_REG_ADDR [format %x $value]
        ac7t1500::wait_ns 10

        # Turn on tx and rx enable, (bit [2] & [5])
        set value [expr ($value | 0x24)]
        ac7t1500::nap_axi_write "NAP_SPACE" $ur_col $ur_row $CONTROL_REG_ADDR [format %x $value]
        ac7t1500::wait_ns 10

        # Turn on tx and rx start, (bit [1] & [4])
        set value [expr ($value | 0x12)]
        ac7t1500::nap_axi_write "NAP_SPACE" $ur_col $ur_row $CONTROL_REG_ADDR [format %x $value]

        # Confirm num_pkts registers are set
        ac7t1500::nap_axi_verify "NAP_SPACE" $ur_col $ur_row $NUM_PKT_REG_L $num_pkts_lsb
        ac7t1500::nap_axi_verify "NAP_SPACE" $ur_col $ur_row $NUM_PKT_REG_M $num_pkts_msb
    }
    proc eth_ch_start_mik { num_pkts_dec ur_col ur_row base_addr {ext_fields 0}} {
        set CONTROL_REG_ADDR [calc_reg_addr_1inc $base_addr 0]
        set NUM_PKT_REG_L    [calc_reg_addr_1inc $base_addr 2]
        set NUM_PKT_REG_M    [calc_reg_addr_1inc $base_addr 3]

        set num_pkts_msb [format %x [expr ($num_pkts_dec >> 32)]]
        set num_pkts_lsb [format %x [expr ($num_pkts_dec & 0xffffffff)]]

        # Set number of packets, (in hex)
        ac7t1500::nap_axi_write "NAP_SPACE" $ur_col $ur_row $NUM_PKT_REG_L $num_pkts_lsb
        puts "ac7t1500::nap_axi_write NAP_SPACE $ur_col $ur_row $NUM_PKT_REG_L $num_pkts_lsb"
        ac7t1500::nap_axi_write "NAP_SPACE" $ur_col $ur_row $NUM_PKT_REG_M $num_pkts_msb
        puts "ac7t1500::nap_axi_write NAP_SPACE $ur_col $ur_row $NUM_PKT_REG_M $num_pkts_msb"

        # Release reset, (bit [0])
        set value 0x1
        ac7t1500::nap_axi_write "NAP_SPACE" $ur_col $ur_row $CONTROL_REG_ADDR [format %x $value]
        puts "ac7t1500::nap_axi_write NAP_SPACE $ur_col $ur_row $CONTROL_REG_ADDR [format %x $value]"
        ac7t1500::wait_ns 10

        # Add in any extended fields specific to that design
        set value [expr ($value | 0x$ext_fields)]
        ac7t1500::nap_axi_write "NAP_SPACE" $ur_col $ur_row $CONTROL_REG_ADDR [format %x $value]
        puts "ac7t1500::nap_axi_write NAP_SPACE $ur_col $ur_row $CONTROL_REG_ADDR [format %x $value]"
        ac7t1500::wait_ns 10

        # Turn on tx and rx enable, (bit [2] & [5])
        set value [expr ($value | 0x24)]
        ac7t1500::nap_axi_write "NAP_SPACE" $ur_col $ur_row $CONTROL_REG_ADDR [format %x $value]
        puts "ac7t1500::nap_axi_write NAP_SPACE $ur_col $ur_row $CONTROL_REG_ADDR [format %x $value]"
        ac7t1500::wait_ns 10

        # Turn on tx and rx start, (bit [1] & [4])
        set value [expr ($value | 0x12)]
        ac7t1500::nap_axi_write "NAP_SPACE" $ur_col $ur_row $CONTROL_REG_ADDR [format %x $value]
        puts "ac7t1500::nap_axi_write NAP_SPACE $ur_col $ur_row $CONTROL_REG_ADDR [format %x $value]"

        # Confirm num_pkts registers are set
        ac7t1500::nap_axi_verify "NAP_SPACE" $ur_col $ur_row $NUM_PKT_REG_L $num_pkts_lsb
        puts "ac7t1500::nap_axi_verify NAP_SPACE $ur_col $ur_row $NUM_PKT_REG_L $num_pkts_lsb"
        ac7t1500::nap_axi_verify "NAP_SPACE" $ur_col $ur_row $NUM_PKT_REG_M $num_pkts_msb
        puts "ac7t1500::nap_axi_verify NAP_SPACE $ur_col $ur_row $NUM_PKT_REG_M $num_pkts_msb"
    }

    # ---------------------------------------------------------------------
    # Stop the RX and TX monitors on the channel
    # ---------------------------------------------------------------------
    proc eth_ch_mon_stop { ur_col ur_row base_addr } {
        set CONTROL_REG_ADDR [calc_reg_addr_1inc $base_addr 0]

        # The control register should be set to 0x37, (see routine above)
        set nap_addr [ac7t1500::assemble_nap_addr NAP_SPACE $ur_col $ur_row $base_addr]
        # Stop TX mon, (bit [3])
        ac7t1500::set_bits_addressed $nap_addr 3 3 0x37
        # Stop RX mon, (bit [6])
        ac7t1500::set_bits_addressed $nap_addr 6 6 0x3f
    }

    # ---------------------------------------------------------------------
    # Check status on a channel
    # Number of expected packets must be in decimal, not hex
    # ---------------------------------------------------------------------
    proc eth_ch_status { exp_num_pkts_dec ur_col ur_row base_addr {quad 0} {terse 0} } {
        set STATUS_REG    [calc_reg_addr_1inc $base_addr 1]
        set PKT_CHK_NUM_L [calc_reg_addr_1inc $base_addr 10]
        set PKT_CHK_NUM_H [calc_reg_addr_1inc $base_addr 11]
        set TX_MON_BASE   [calc_reg_addr_1inc $base_addr 4]
        set RX_MON_BASE   [calc_reg_addr_1inc $base_addr 12]

        set retval 0

        set exp_pkts_hex [format %X $exp_num_pkts_dec]

        # Set options if checking on a quad channel
        if { $quad == 1 } {
            set good_status 01010101
            set naps 4
        } else {
            set good_status 00000001
            set naps 1
        }

        puts "-----------------------------------------"
        puts "Checking Channel status at address $base_addr"
        puts "-----------------------------------------"

        # Read status flags
        # Done should be set, all other values should be 0
        if { [ac7t1500::get_reg_lib_sim_generate] } {
            # Simulation
            ac7t1500::nap_axi_verify NAP_SPACE $ur_col $ur_row $STATUS_REG $good_status
        } else {
            # Silicon
            set status_val [ac7t1500::nap_axi_read NAP_SPACE $ur_col $ur_row $STATUS_REG]

            if { $status_val != $good_status } {
                set msg "ERROR.  Status reg : $status_val.  Should be $good_status :"
                if { "0x$status_val" & 0x0002 } { append msg " Checksum ERROR :" }
                if { "0x$status_val" & 0x0004 } { append msg " Packet size ERROR :" }
                if { "0x$status_val" & 0x0008 } { append msg " Payload ERROR" }
                puts $msg
                if { "0x$status_val" & 0x00f0 } {
                    set eth_mon_msg "ERROR.  Ethernet monitor : "
                    if { "0x$status_val" & 0x0010 } { append msg " TX invalid SoP :" }
                    if { "0x$status_val" & 0x0020 } { append msg " TX invalid EoP :" }
                    if { "0x$status_val" & 0x0040 } { append msg " TX invalid transfer :" }
                    if { "0x$status_val" & 0x0080 } { append msg " RX invalid SoP :" }
                    if { "0x$status_val" & 0x0100 } { append msg " RX invalid EoP :" }
                    if { "0x$status_val" & 0x0200 } { append msg " RX invalid transfer :" }
                    puts $eth_mon_msg
                }
                if { "0x$status_val" & 0xff00 } {
                    set rx_err_flags "ERROR.  Rx error flags set : "
                    if { "0x$status_val" & 0x010000 } { append rx_err_flags " Frame error :" }
                    if { "0x$status_val" & 0x020000 } { append rx_err_flags " Length error :" }
                    if { "0x$status_val" & 0x040000 } { append rx_err_flags " CRC error :" }
                    if { "0x$status_val" & 0x080000 } { append rx_err_flags " Decode error :" }
                    if { "0x$status_val" & 0x100000 } { append rx_err_flags " FIFO Overflow error :" }
                    if { "0x$status_val" & 0x200000 } { append rx_err_flags " Short frame error :" }
                    if { "0x$status_val" & 0x400000 } { append rx_err_flags " Inverted CRC :" }
                    if { "0x$status_val" & 0x800000 } { append rx_err_flags " Transmit Frame error :" }
                    puts $rx_err_flags
                }
                # Set the return error code
                incr retval -1
            } else {
                puts "Status reg PASS"
            }
        }

        # Check each of the channel registers
        for {set ch 0} {$ch < $naps} {incr ch} {
            if { $naps > 1 } { 
                puts "-----------------------------------------"
                puts "Checking NAP $ch results"
                puts "-----------------------------------------"
            }

            if { [ac7t1500::get_reg_lib_sim_generate] } {
                # In simulation only, verify the packets received by each checker and monitor
                verify_64_bit_user_regs $ur_col $ur_row $PKT_CHK_NUM_L $exp_num_pkts_dec
                verify_64_bit_user_regs $ur_col $ur_row $TX_MON_BASE $exp_num_pkts_dec
                verify_64_bit_user_regs $ur_col $ur_row $RX_MON_BASE $exp_num_pkts_dec
            } else {
                # In silicon, read the packet checker and monitors and compare values
                set readval_dec_pkts_chk_rx [read_64_bit_user_regs $ur_col $ur_row $PKT_CHK_NUM_L]

                # Read the ethernet monitors
                set tx_mon [eth_utils::read_ethernet_monitor "tx" $ur_col $ur_row $TX_MON_BASE 1]
                set rx_mon [eth_utils::read_ethernet_monitor "rx" $ur_col $ur_row $RX_MON_BASE 1]

                # Extract individual values from monitors
                set readval_dec_avg_bw_tx [lindex $tx_mon 1]
                set readval_dec_pkts_tx   [lindex $tx_mon 3]
                set readval_dec_bytes_tx  [lindex $tx_mon 4]
                set readval_dec_avg_bw_rx [lindex $rx_mon 1]
                set readval_dec_pkts_rx   [lindex $rx_mon 3]
                set readval_dec_bytes_rx  [lindex $rx_mon 4]

                if { ($readval_dec_pkts_chk_rx != $readval_dec_pkts_tx) ||
                     ($readval_dec_pkts_chk_rx != $readval_dec_pkts_rx) ||
                     ($readval_dec_bytes_tx != $readval_dec_bytes_rx) } {
                    incr retval -1
                }

                if { ($terse == 1) && ($retval == 0) } {
                    puts "Channel status PASS.  [format_large_val $readval_dec_pkts_chk_rx 0] packets"
                    puts "Average BW. Tx $readval_dec_avg_bw_tx Gbps : Rx $readval_dec_avg_bw_rx Gbps"
                } else {
                    if { $retval } { puts "Channel FAIL" }

                    puts "RX pkt checker received [format_large_val $readval_dec_pkts_chk_rx 0] packets"
                    puts "TX monitor counted      [format_large_val $readval_dec_pkts_tx 0] packets"
                    puts "RX monitor counted      [format_large_val $readval_dec_pkts_rx 0] packets"
                    puts "TX monitor counted      [format_large_val $readval_dec_bytes_tx 0] bytes"
                    puts "RX monitor counted      [format_large_val $readval_dec_bytes_rx 0] bytes"
                    puts "TX monitor average BW   $readval_dec_avg_bw_tx Gbps"
                    puts "RX monitor average BW   $readval_dec_avg_bw_rx Gbps"
                }
            }

            # Increment base_addr for the next set of reads
            # 18 registers per channel, 32-bits each
            # incr doesn't work with hex numbers
            scan $base_addr %x base_dec
            set base_addr [format %x [expr {$base_dec + (18*4)}]]
        }

        puts "-----------------------------------------"

        return $retval
    }

    # ---------------------------------------------------------------------
    # Check status on quad packet mode, set to linear
    # Number of expected packets must be in decimal, not hex
    # ---------------------------------------------------------------------
    proc eth_ch_status_quad_linear { exp_num_pkts_dec ur_col ur_row base_addr } {
        set STATUS_REG_ADDR [calc_reg_addr_1inc $base_addr 1]
        set PKT_CHK_NUM_L   10
        set TX_MON_BASE     4
        set RX_MON_BASE     12
        set REGS_PER_CH     18

        set exp_pkts_hex [format %X $exp_num_pkts_dec]

        set ret_code 0

        # Because linear mode does not return the same packets to the same channels
        # then each of the packet checkers will report payload error.  This is okay
        # The packet checkers should not report checksum, or length errors.
        # set good_status 01010101
        set good_status 09090909
        set naps 4

        puts "-----------------------------------------"
        puts "Checking Channel status at address $base_addr"
        puts "-----------------------------------------"

        # Read status flags
        # Done should be set, all other values should be 0
        incr ret_code [ac7t1500::nap_axi_verify "NAP_SPACE" $ur_col $ur_row $STATUS_REG_ADDR $good_status]
        puts "Status reg [ac7t1500::nap_axi_read NAP_SPACE $ur_col $ur_row $STATUS_REG_ADDR]"

        # Check bits of status register

        set total_tx_pkts     0
        set total_tx_bytes    0
        set total_tx_avg_bw   0
        set total_rx_pkts_chk 0
        set total_rx_pkts_mon 0
        set total_rx_bytes    0
        set total_rx_avg_bw   0

        for {set ch 0} {$ch < $naps} {incr ch} {
            if { $naps > 1 } { 
                puts "-----------------------------------------"
                puts "Checking NAP $ch results"
            }
            puts "-----------------------------------------"

            # Calculate the base for this set of registers
            set ch_base_addr [calc_reg_addr_1inc $base_addr [expr ($REGS_PER_CH*$ch)]]

            if { [ac7t1500::get_reg_lib_sim_generate] } {
                # Left as a place holder for anything that will need to be done for simulation only
            } else {
                # In silicon, read the packet checker and monitors and compare values
                set readval_dec_pkts_chk_rx [read_64_bit_user_regs $ur_col $ur_row [calc_reg_addr_1inc $ch_base_addr $PKT_CHK_NUM_L]]

                # Read the ethernet monitors
                set tx_mon [eth_utils::read_ethernet_monitor "tx" $ur_col $ur_row [calc_reg_addr_1inc $ch_base_addr $TX_MON_BASE] 1]
                set rx_mon [eth_utils::read_ethernet_monitor "rx" $ur_col $ur_row [calc_reg_addr_1inc $ch_base_addr $RX_MON_BASE] 1]

                # Extract individual values from monitors
                set readval_dec_avg_bw_tx [lindex $tx_mon 1]
                set readval_dec_pkts_tx   [lindex $tx_mon 3]
                set readval_dec_bytes_tx  [lindex $tx_mon 4]
                set readval_dec_avg_bw_rx [lindex $rx_mon 1]
                set readval_dec_pkts_rx   [lindex $rx_mon 3]
                set readval_dec_bytes_rx  [lindex $rx_mon 4]


                # Read the packet and byte counts
                incr total_rx_pkts_chk $readval_dec_pkts_chk_rx
                incr total_tx_pkts     $readval_dec_pkts_tx
                incr total_tx_bytes    $readval_dec_bytes_tx
                set  total_tx_avg_bw   [expr ($total_tx_avg_bw+$readval_dec_avg_bw_tx)]
                incr total_rx_pkts_mon $readval_dec_pkts_rx
                incr total_rx_bytes    $readval_dec_bytes_rx
                set  total_rx_avg_bw   [expr ($total_rx_avg_bw+$readval_dec_avg_bw_rx)]
            }
        }

        if { ![ac7t1500::get_reg_lib_sim_generate] } {
            puts "----------------------------------------------------------------------------------------------------------"
            puts "Total TX packets [format_large_val $total_tx_pkts]. Total RX packets (chk) [format_large_val $total_rx_pkts_chk]. Total RX packets (mon) [format_large_val $total_rx_pkts_mon]"
            puts "Total TX bytes [format_large_val $total_tx_bytes]. Total RX bytes [format_large_val $total_rx_bytes]. \
                  Total RX bytes, (no FCS) [format_large_val [expr {$total_rx_bytes - ($total_rx_pkts_chk * 4)}]]"
            puts "----------------------------------------------------------------------------------------------------------"
        }

        # Check final totals to return a pass / fail
        if { ($total_tx_pkts != $total_rx_pkts_chk) || ($total_rx_pkts_chk != $total_rx_pkts_mon) || 
             ($total_rx_pkts_chk != [expr ($exp_num_pkts_dec*$naps)] ) } {
            incr ret_code -1
        }

        if { ($total_tx_pkts != $total_rx_pkts_chk) } {
            puts "ERROR : Total TX packets $total_tx_pkts does not equal Total RX packets checker $total_rx_pkts_chk"
        }

        if { ($total_rx_pkts_chk != $total_rx_pkts_mon) } {
            puts "ERROR : Total RX packets checker $total_rx_pkts_chk does not equal total RX packets monitor $total_rx_pkts_mon"
        }

        if { ($total_rx_pkts_chk != [expr ($exp_num_pkts_dec*$naps)]) } {
            puts "ERROR : Total RX packets checker $total_rx_pkts_chk does not equal total expected packets [expr ($exp_num_pkts_dec*$naps)]"
        }

        return $ret_code
    }

    # ---------------------------------------------------------------------

    # ---------------------------------------------------------------------
    # Dump EIU registers.  This confirms if simulation and bitstream have
    # correctly configured the EIU 
    # ---------------------------------------------------------------------
    proc dump_eiu_registers { target } {

        puts "--------------------------------------------------"
        puts "     Dump EIU registers for $target"
        puts "--------------------------------------------------"

        puts "$target EIU reg EIU_MODE           = 0x[ac7t1500::csr_read_named CSR_SPACE $target CFG_EIU EIU_MODE]"

        foreach reg {EIU_QUAD0_SOURCE EIU_QUAD0_DEST EIU_QUAD1_SOURCE EIU_QUAD1_DEST} {
            for {set ch 0} {$ch < 8} {incr ch} {
                set retval [ac7t1500::csr_read_named CSR_SPACE $target CFG_EIU $reg\_$ch]
                puts "$target EIU reg $reg\_$ch = 0x$retval"
            }
        }

        foreach reg {EIU_100G_SUB0_RX EIU_100G_SUB0_TX EIU_100G_SUB1_RX EIU_100G_SUB1_TX} {
            set retval [ac7t1500::csr_read_named CSR_SPACE $target CFG_EIU $reg]
            puts "$target EIU reg $reg = 0x$retval"
        }

        set retval [ac7t1500::csr_read_named CSR_SPACE $target CFG_EIU MTIP_RESET_ENABLE]
        puts "$target EIU reg MTIP_RESET_ENABLE = 0x$retval"

        puts "--------------------------------------------------"
    }

    # ---------------------------------------------------------------------
    # Read Ethernet subsystem revision registers
    # Read and write any scratch registers to prove access
    # ---------------------------------------------------------------------
    proc chk_version_and_scratch_regs { target } {

        # Quad MACs, (10/25/40/100G) 
        foreach qmac {QUAD_MAC_0 QUAD_MAC_1} {
            for {set ch 0} {$ch < 4} {incr ch} {
                # Version register
                ac7t1500::csr_verify_named CSR_SPACE $target $qmac REVISION_$ch 0x00010200
                # Scratch register
                ac7t1500::csr_verify_named CSR_SPACE $target $qmac SCRATCH_$ch 0x0
                ac7t1500::csr_write_named  CSR_SPACE $target $qmac SCRATCH_$ch 0x12345678
                ac7t1500::csr_verify_named CSR_SPACE $target $qmac SCRATCH_$ch 0x12345678
                ac7t1500::csr_reset_named  CSR_SPACE $target $qmac SCRATCH_$ch
                ac7t1500::csr_verify_named CSR_SPACE $target $qmac SCRATCH_$ch 0x0
            }
        }

        # Quad PCS lanes, (10/25/40/100G PCS)
        # PCS registers are only 16 bit.
        foreach qpcs {QUAD_PCS_0 QUAD_PCS_1} {
            for {set ch 0} {$ch < 4} {incr ch} {
                # Version register
                # Lanes 0,2 have a different revision than lanes 1,3
                # Same register set though
                if { [expr {$ch % 2}] == 0 } {
                    ac7t1500::csr_verify_named CSR_SPACE $target $qpcs VENDOR_CORE_REV_$ch 0x0
                } else {
                    ac7t1500::csr_verify_named CSR_SPACE $target $qpcs VENDOR_CORE_REV_$ch 0x0300
                }
                # Scratch register
                ac7t1500::csr_verify_named CSR_SPACE $target $qpcs VENDOR_SCRATCH_$ch 0x0
                ac7t1500::csr_write_named  CSR_SPACE $target $qpcs VENDOR_SCRATCH_$ch 0x5678
                ac7t1500::csr_verify_named CSR_SPACE $target $qpcs VENDOR_SCRATCH_$ch 0x5678
                ac7t1500::csr_reset_named  CSR_SPACE $target $qpcs VENDOR_SCRATCH_$ch
                ac7t1500::csr_verify_named CSR_SPACE $target $qpcs VENDOR_SCRATCH_$ch 0x0
            }
        }

    # 400G MACs
    foreach fmac {400G_MAC_0 400G_MAC_1} {
        # Version register
        ac7t1500::csr_verify_named CSR_SPACE $target $fmac REVISION 0x00010102
        # Scratch register
        ac7t1500::csr_verify_named CSR_SPACE $target $fmac SCRATCH 0x0
        ac7t1500::csr_write_named  CSR_SPACE $target $fmac SCRATCH 0x12345678
        ac7t1500::csr_verify_named CSR_SPACE $target $fmac SCRATCH 0x12345678
        ac7t1500::csr_reset_named  CSR_SPACE $target $fmac SCRATCH
        ac7t1500::csr_verify_named CSR_SPACE $target $fmac SCRATCH 0x0
    }

    # 400G PCS
    # 400G PCS registers are 16-bit.
    foreach fpcs {400G_PCS} {
        for {set ch 0} {$ch < 2} {incr ch} {
            # Version register
            # Doc states 0x130, but hardware reports 0x4202
            ac7t1500::csr_verify_named CSR_SPACE $target $fpcs VENDOR_CORE_REV_$ch 0x0004202

            # Scratch register
            ac7t1500::csr_verify_named CSR_SPACE $target $fpcs VENDOR_SCRATCH_$ch 0x0
            # Write 32-bits, but only 16-bits is available to read back
            ac7t1500::csr_write_named  CSR_SPACE $target $fpcs VENDOR_SCRATCH_$ch 0x12348765
            ac7t1500::csr_verify_named CSR_SPACE $target $fpcs VENDOR_SCRATCH_$ch 0x00008765
            ac7t1500::csr_reset_named  CSR_SPACE $target $fpcs VENDOR_SCRATCH_$ch
            ac7t1500::csr_verify_named CSR_SPACE $target $fpcs VENDOR_SCRATCH_$ch 0x0
        }
    }

    }

    # ---------------------------------------------------------------------
    # Print the status of the quad PCS lock and enable signals
    # ---------------------------------------------------------------------
    # These are connected to a user register
    proc chk_quad_pcs_status { ur_col ur_row addr } {

        set retval [ac7t1500::nap_axi_read "NAP_SPACE" $ur_col $ur_row [calc_reg_addr_1inc 0 $addr]]

        # Convert to binary bits
        binary scan [binary format H8 $retval] B32 retval_bstr
        # Below option works on ACE, but not in other Tcl consoles.
        # Format specifier b not recognised.
        # set retval_bstr [format %b "0x$retval"]
        # puts " retval $retval : retval_bstr $retval_bstr"

        # MSB is character 0, LSB is character 31
        puts "Eth 0, Quad 0 PCS Lock = [string range $retval_bstr 28 31]"
        puts "Eth 0, Quad 1 PCS Lock = [string range $retval_bstr 24 27]"
        puts "Eth 0, Quad 0 EMAC En  = [string range $retval_bstr 20 23]"
        puts "Eth 0, Quad 1 EMAC En  = [string range $retval_bstr 16 19]"
        puts "Eth 1, Quad 0 PCS Lock = [string range $retval_bstr 12 15]"
        puts "Eth 1, Quad 1 PCS Lock = [string range $retval_bstr 8  11]"
        puts "Eth 1, Quad 0 EMAC En  = [string range $retval_bstr 4  7 ]"
        puts "Eth 1, Quad 1 EMAC En  = [string range $retval_bstr 0  3 ]"
    }

    # ---------------------------------------------------------------------
    # Print the status of the 400G MAC and PCS status
    # ---------------------------------------------------------------------
    # Split a string and space it out, used for the PCS status display
    proc space_string { str gap } {
        switch $gap {
            3 {set out_str [string map {"1" "1   " "0" "0   "} $str]}
            4 {set out_str [string map {"1" "1    " "0" "0    "} $str]}
            5 {set out_str [string map {"1" "1     " "0" "0     "} $str]}
            default {set out_str [string map {"1" "1      " "0" "0      "} $str]}
        }
        return [string trimright $out_str]
    }

    # These are connected to a user register
    proc chk_400g_mac_pcs_status { ur_col ur_row addr } {

        set retval [ac7t1500::nap_axi_read "NAP_SPACE" $ur_col $ur_row [calc_reg_addr_1inc 0 $addr]]

        # Convert to binary bits
        binary scan [binary format H8 $retval] B32 retval_bstr
        # Below option works on ACE, but not in other Tcl consoles.
        # Format specifier b not recognised.
        # set retval_bstr [format %b "0x$retval"]
        # puts " retval $retval : retval_bstr $retval_bstr"

        # MSB is character 0, LSB is character 31
        puts "-----------------------------------------------------------------------------"
        puts "     400G MAC and PCS status"
        puts "-----------------------------------------------------------------------------"
        puts "400G Eth 0 MAC 0 fault = [string range $retval_bstr 12 12]"
        puts "400G Eth 0 MAC 1 fault = [string range $retval_bstr 13 13]"
        puts "400G Eth 1 MAC 0 fault = [string range $retval_bstr 14 14]"
        puts "400G Eth 1 MAC 1 fault = [string range $retval_bstr 15 15]"
        puts "-----------------------------------------------------------------------------"
        puts " PCS status -    Align  Amps  hi_ored  link"
        puts "                 lock   lock  deg_ser  status"
        puts "-----------------------------------------------------------------------------"
        puts "Eth 0 400G PCS 0   [space_string [string range $retval_bstr 16 19] 6]"
        puts "Eth 0 400G PCS 1   [space_string [string range $retval_bstr 20 23] 6]"
        puts "Eth 1 400G PCS 0   [space_string [string range $retval_bstr 24 27] 6]"
        puts "Eth 1 400G PCS 1   [space_string [string range $retval_bstr 28 31] 6]"
        puts "-----------------------------------------------------------------------------"
    }

    # ---------------------------------------------------------------------
    # Print the status of the Quad PCS BASER_STATUS1 register
    # ---------------------------------------------------------------------

    proc quad_pcs_baser_status1 { target {mode_100g 0}} {

        puts "-----------------------------------------------------------------------------"
        puts "               Reading $target QUAD_PCS BASER_STATUS1"
        puts "-----------------------------------------------------------------------------"

        puts "$target QUAD_PCS BASER_STATUS1     : Block High RX       ADDR       DATA"
        puts "                                      : Lock  BER  Link"

        foreach qpcs {QUAD_PCS_0 QUAD_PCS_1} {
            for {set ch 0} {$ch < 4} {incr ch} {
                if { ($mode_100g == 1) && ($ch == 1) } {
                    set baser_status1_addr  [ac7t1500::csr_named_addr CSR_SPACE $target $qpcs BASER_STATUS1_01]
                    set baser_status1_value [ac7t1500::csr_read_named CSR_SPACE $target $qpcs BASER_STATUS1_01]
                } elseif { ($mode_100g == 1) && ($ch == 3) } {
                    set baser_status1_addr  [ac7t1500::csr_named_addr CSR_SPACE $target $qpcs BASER_STATUS1_23]
                    set baser_status1_value [ac7t1500::csr_read_named CSR_SPACE $target $qpcs BASER_STATUS1_23]
                } else {
                    set baser_status1_addr  [ac7t1500::csr_named_addr CSR_SPACE $target $qpcs BASER_STATUS1_$ch]
                    set baser_status1_value [ac7t1500::csr_read_named CSR_SPACE $target $qpcs BASER_STATUS1_$ch]
                }

                if {[expr 0x$baser_status1_value & 0x00000001]} {
                    set val1 1
                } else {
                    set val1 0
                }

                if {[expr 0x$baser_status1_value & 0x00000002]} {
                    set val2 1
                } else {
                    set val2 0
                }

                if {[expr 0x$baser_status1_value & 0x00001000]} {
                    set val3 1
                } else {
                    set val3 0
                }

                puts "$target $qpcs BASER_STATUS1_$ch :   $val1    $val2     $val3   $baser_status1_addr $baser_status1_value"
            }
        }

        puts "-----------------------------------------------------------------------------"
    }

    # ---------------------------------------------------------------------
    # Print the status of the Quad MAC STATUS register
    # ---------------------------------------------------------------------

    proc quad_mac_status { target {max_quad 2} {max_ch 4} } {

        puts "-----------------------------------------------------------------------------"
        puts "               Reading $target QUAD_MAC STATUS"
        puts "-----------------------------------------------------------------------------"

        puts "$target QUAD_MAC    STATUS  : Local Remote PHY Link       ADDR       DATA"
        puts "                               : Fault Fault  LOS Fault"

        for {set quad 0} {$quad < $max_quad} {incr quad} {
            for {set ch 0} {$ch < $max_ch} {incr ch} {
                set status_addr  [ac7t1500::csr_named_addr CSR_SPACE $target QUAD_MAC_$quad STATUS_$ch]
                set status_value [ac7t1500::csr_read_named CSR_SPACE $target QUAD_MAC_$quad STATUS_$ch]

                if {[expr 0x$status_value & 0x00000001]} {
                    set val1 1
                } else {
                    set val1 0
                }

                if {[expr 0x$status_value & 0x00000002]} {
                    set val2 1
                } else {
                    set val2 0
                }
                
                if {[expr 0x$status_value & 0x00000004]} {
                    set val3 1
                } else {
                    set val3 0
                }

                if {[expr 0x$status_value & 0x00000080]} {
                    set val4 1
                } else {
                    set val4 0
                }

                puts "$target QUAD_MAC_$quad STATUS_$ch :   $val1    $val2     $val3   $val3     $status_addr $status_value"
            }
        }

        puts "-----------------------------------------------------------------------------"
    }

    # ---------------------------------------------------------------------
    # Print the status of the 400G PCS
    # ---------------------------------------------------------------------

    proc pcs_400g_status { target ch debug } {


        # Single PCS target
        set pcs 400G_PCS

        # set baser_status1_addr  [ac7t1500::csr_named_addr CSR_SPACE $target $qpcs BASER_STATUS1_$ch]
        set baser_status1_value [ac7t1500::csr_read_named CSR_SPACE $target $pcs BASER_STATUS1_$ch]

        # set baser_status2_addr  [ac7t1500::csr_named_addr CSR_SPACE $target $qpcs BASER_STATUS2_$ch]
        set baser_status2_value [ac7t1500::csr_read_named CSR_SPACE $target $pcs BASER_STATUS2_$ch]

        # BASE-R status1 indicates lock
        if {[expr 0x$baser_status1_value & 0x00001000]} {
            set link_up 1
        } else {
            set link_up 0
        }

        # BASE-R status2 indicates errored block count
        set err_blk_count [expr 0x$baser_status2_value & 0x00000ff]

        # 
        set lane_align1 [ac7t1500::csr_read_named CSR_SPACE $target $pcs MULTILANE_ALIGN_STAT1_$ch]
        set lane_align3 [ac7t1500::csr_read_named CSR_SPACE $target $pcs MULTILANE_ALIGN_STAT3_$ch]
        set lane_align4 [ac7t1500::csr_read_named CSR_SPACE $target $pcs MULTILANE_ALIGN_STAT4_$ch]

        # MULTI-LANE ALIGN1 indicates all lanes aligned
        if {[expr 0x$baser_status1_value & 0x00001000]} {
            set all_lanes_aligned 1
        } else {
            set all_lanes_aligned 0
        }

        # MULTI-LANE ALIGN3 indicates lanes aligned [7:0]
        set lanes_aligned_7_0 [expr 0x$lane_align3 & 0x00000ff]

        # MULTI-LANE ALIGN4 indicates lanes aligned [15:8]
        set lanes_aligned_15_8 [expr 0x$lane_align4 & 0x00000ff]

        set combined_lanes [format %x [expr {($lanes_aligned_15_8 << 8) + $lanes_aligned_7_0}]]

        if { $debug } {
            puts "------------------------------------------------------------"
            puts " Reading $target Channel $ch 400G PCS status"
            puts "------------------------------------------------------------"
            puts " Link Up = $link_up : Errored block count = $err_blk_count"
            puts " All lanes aligned = $all_lanes_aligned : Lane alignment \[15:0\] $combined_lanes"
            puts "------------------------------------------------------------"
        }

        return [list $link_up $err_blk_count $all_lanes_aligned $combined_lanes]
    }

    # ---------------------------------------------------------------------
    # Print the status of the 400G FEC
    # ---------------------------------------------------------------------

    proc fec_400g_status { target ch debug } {


        # Single PCS target
        set pcs 400G_PCS

        # Must read low counters first
        set ccw_lo  [ac7t1500::csr_read_named CSR_SPACE $target $pcs RSFEC_CCW_LO_$ch]
        set ccw_hi  [ac7t1500::csr_read_named CSR_SPACE $target $pcs RSFEC_CCW_HI_$ch]
        set nccw_lo [ac7t1500::csr_read_named CSR_SPACE $target $pcs RSFEC_NCCW_LO_$ch]
        set nccw_hi [ac7t1500::csr_read_named CSR_SPACE $target $pcs RSFEC_NCCW_HI_$ch]

        set ccw  [expr {("0x$ccw_hi" << 16) + "0x$ccw_lo"}]
        set nccw [expr {("0x$nccw_hi" << 16) + "0x$nccw_lo"}]

        set symerr0_lo  [ac7t1500::csr_read_named CSR_SPACE $target $pcs RSFEC_SYMBLERR0_LO_$ch]
        set symerr0_hi  [ac7t1500::csr_read_named CSR_SPACE $target $pcs RSFEC_SYMBLERR0_HI_$ch]

        set symerr0 [expr {("0x$symerr0_hi" << 16) + "0x$symerr0_lo"}]

        if { $debug } {
            puts "------------------------------------------------------------"
            puts " Reading $target Channel $ch 400G FEC status"
            puts "------------------------------------------------------------"
            puts " Correctable errors         : $ccw"
            puts " Uncorrectable errors       : $nccw"
            puts " Total of corrected symbols : $symerr0"
            puts "------------------------------------------------------------"
        }

        return [list $ccw $nccw $symerr0]
    }

    # ---------------------------------------------------------------------
    # Print the status of the Quad PCS FEC
    # ---------------------------------------------------------------------

    proc fec_quad_status { target pcs ch debug } {

        # Lane 0 registers have no suffix, other lanes [3:1] do
        if { $ch } {
            set lane RSFEC$ch
        } else {
            set lane RSFEC
        }

        # Must read low counters first
        set ccw_lo  [ac7t1500::csr_read_named CSR_SPACE $target $pcs $lane\_CCW_LO]
        set ccw_hi  [ac7t1500::csr_read_named CSR_SPACE $target $pcs $lane\_CCW_HI]
        set nccw_lo [ac7t1500::csr_read_named CSR_SPACE $target $pcs $lane\_NCCW_LO]
        set nccw_hi [ac7t1500::csr_read_named CSR_SPACE $target $pcs $lane\_NCCW_HI]

        set ccw  [expr {("0x$ccw_hi" << 16) + "0x$ccw_lo"}]
        set nccw [expr {("0x$nccw_hi" << 16) + "0x$nccw_lo"}]

        set symerr0_lo  [ac7t1500::csr_read_named CSR_SPACE $target $pcs RSFEC_SYMBLERR$ch\_LO]
        set symerr0_hi  [ac7t1500::csr_read_named CSR_SPACE $target $pcs RSFEC_SYMBLERR$ch\_HI]

        set symerr0 [expr {("0x$symerr0_hi" << 16) + "0x$symerr0_lo"}]

        if { $debug } {
            puts "------------------------------------------------------------"
            puts " Reading $target $pcs Channel $ch FEC status"
            puts "------------------------------------------------------------"
            puts " Correctable errors         : $ccw"
            puts " Uncorrectable errors       : $nccw"
            puts " Total of corrected symbols : $symerr0"
            puts "------------------------------------------------------------"
        }

        return [list $ccw $nccw $symerr0]
    }

    # ---------------------------------------------------------------------
    # Switch Serdes lane remapping
    # ---------------------------------------------------------------------
    proc lane_remap { target mode } {

        switch $mode {
            "linear"  {
                        ac7t1500::csr_write_named CSR_SPACE $target CFG_EIU CFG_LANEMAPTX_LANESEL 0x76543210
                        ac7t1500::csr_write_named CSR_SPACE $target CFG_EIU CFG_LANEMAPRX_LANESEL 0x76543210
                      }
            "qsfp-28" {
                        ac7t1500::csr_write_named CSR_SPACE $target CFG_EIU CFG_LANEMAPTX_LANESEL 0x75643120
                        ac7t1500::csr_write_named CSR_SPACE $target CFG_EIU CFG_LANEMAPRX_LANESEL 0x75643120
                      }
            "qsfp-dd" {
                        ac7t1500::csr_write_named CSR_SPACE $target CFG_EIU CFG_LANEMAPTX_LANESEL 0x71605342
                        ac7t1500::csr_write_named CSR_SPACE $target CFG_EIU CFG_LANEMAPRX_LANESEL 0x71605342
                      }
            default   { puts "ERROR - Unknown lane remap mode of $mode requested"
                        puts "        Legal values are linear, qsfp-28 and qsfp-dd"
                        return
                      }
            }

        # No error if we get here
        puts "$target serdes lanes remapped to $mode"
    }


    # ---------------------------------------------------------------------
    # MII Loopback - MAC TX to MAC RX
    # ---------------------------------------------------------------------
    # Don't think this works as the MAC requires PCS lock first
    proc loopback_txmii_rxmii { eth qpcs en } {
        for {set ch 0} {$ch < 4} {incr ch} {
            set retval [ac7t1500::csr_read_named CSR_SPACE $eth $qpcs CONTROL1_$ch 0x2040]
            # Value read back is hex
            set retval "0x$retval"
            if { $en == 1 } {
                set retval [expr {$retval | 0x4000}]
            } else {
                set retval [expr {$retval & 0xffffbfff}]
            }
            set retval [format %X $retval]
            ac7t1500::csr_write_named  CSR_SPACE $eth $qpcs CONTROL1_$ch $retval
            ac7t1500::csr_verify_named CSR_SPACE $eth $qpcs CONTROL1_$ch $retval
        }
    }

    # ---------------------------------------------------------------------
    # Far end PCS Loopback - PCS TX to PCS RX
    # ---------------------------------------------------------------------
    proc loopback_txpcs_rxpcs { target en } {
        set retval [ac7t1500::csr_read_named CSR_SPACE $target CFG_EIU CONFIG]
        # Value read back is hex
        set retval "0x$retval"
        if { $en == 1 } {
            set retval [expr {$retval | 0x10000}]
        } else {
            set retval [expr {$retval & 0xfffeffff}]
        }
        set retval [format %X $retval]
        ac7t1500::csr_write_named  CSR_SPACE $target CFG_EIU CONFIG $retval
        ac7t1500::csr_verify_named CSR_SPACE $target CFG_EIU CONFIG $retval
        set config_data [ac7t1500::csr_read_named CSR_SPACE $target CFG_EIU CONFIG]
        puts "PCS loopback reg = 0x$config_data"
    }

    # ---------------------------------------------------------------------
    # Reset quad PCS channels
    # ---------------------------------------------------------------------
    proc reset_quad_pcs { eth qpcs {max_ch 4}} {

        # Bit is self-clearing, so no need to clear afterwards
        for {set ch 0} {$ch < $max_ch} {incr ch} {
            ac7t1500::csr_set_bits_named CSR_SPACE $eth $qpcs CONTROL1_$ch 15 15 0x2040
        }
    }

    # ---------------------------------------------------------------------
    # Reset 400G PCS channel
    # ---------------------------------------------------------------------
    proc reset_400g_pcs { eth {max_ch 2}} {

        puts "Resetting $eth 400G_PCS"

        # Bit is self-clearing, so no need to clear afterwards
        for {set ch 0} {$ch < $max_ch} {incr ch} {
            ac7t1500::csr_set_bits_named CSR_SPACE $eth 400G_PCS CONTROL1_$ch 15 15 0x2068
        }
    }

    # ---------------------------------------------------------------------
    # Reset quad MAC channels
    # ---------------------------------------------------------------------
    proc reset_quad_mac { eth qmac {max_ch 4}} {

        for {set ch 0} {$ch < $max_ch} {incr ch} {
            # Clear the TX_ENA and RX_ENA bits
            ac7t1500::csr_clear_bits_named CSR_SPACE $eth $qmac EMAC_COMMAND_CONFIG_$ch 0 1]
            # Flush TX, (not self-clearing)
            ac7t1500::csr_set_bits_named CSR_SPACE   $eth $qmac EMAC_COMMAND_CONFIG_$ch 22 22]
            ac7t1500::csr_clear_bits_named CSR_SPACE $eth $qmac EMAC_COMMAND_CONFIG_$ch 22 22]
            # Reset TX FIFO, (self-clearing)
            ac7t1500::csr_set_bits_named CSR_SPACE   $eth $qmac EMAC_COMMAND_CONFIG_$ch 26 26]
            # Issue a SW reset, (self-clearing)
            ac7t1500::csr_set_bits_named CSR_SPACE   $eth $qmac EMAC_COMMAND_CONFIG_$ch 12 12]
            # Re-enable the TX and RX_ENA bits
            ac7t1500::csr_set_bits_named CSR_SPACE   $eth $qmac EMAC_COMMAND_CONFIG_$ch 0 1]
        }
    }

    # ---------------------------------------------------------------------
    # Reset 400G MAC channels
    # ---------------------------------------------------------------------
    proc reset_400g_mac { eth mac } {

        puts "Resetting $eth $mac"

        # Clear the TX_ENA and RX_ENA bits
        ac7t1500::csr_clear_bits_named CSR_SPACE $eth $mac COMMAND_CONFIG 0 1]
        # Flush TX, (not self-clearing)
        ac7t1500::csr_set_bits_named CSR_SPACE   $eth $mac COMMAND_CONFIG 22 22]
        ac7t1500::csr_clear_bits_named CSR_SPACE $eth $mac COMMAND_CONFIG 22 22]
        # Reset TX FIFO, (self-clearing)
        ac7t1500::csr_set_bits_named CSR_SPACE   $eth $mac COMMAND_CONFIG 26 26]
        # Issue a SW reset, (self-clearing)
        ac7t1500::csr_set_bits_named CSR_SPACE   $eth $mac COMMAND_CONFIG 12 12]
        # Re-enable the TX and RX_ENA bits
        ac7t1500::csr_set_bits_named CSR_SPACE   $eth $mac COMMAND_CONFIG 0 1]
    }

    # ---------------------------------------------------------------------
    # Clear or set CRC forward flag for receive MAC
    # ---------------------------------------------------------------------
    proc configure_rx_crc_fwd { eth mac value {max_ch 4}} {

        # If quad mac chosen, set crc_fwd across all 4 MAC lanes.
        # Includes both express and preemptive channels.
        # If 400G mac chosen, only set for single MAC
        if { [regexp -- {400G_MAC.*} $mac] } {
            if { $value == 0 } {
                # Clear the CRC_FWD bits
                ac7t1500::csr_clear_bits_named CSR_SPACE $eth $mac COMMAND_CONFIG 6 6 0x22093
            } else {
                # Set the CRC_FWD bits
                ac7t1500::csr_set_bits_named   CSR_SPACE $eth $mac COMMAND_CONFIG 6 6 0x22093
            }
        } else {
            # Quad MAC selected
            # CRC_FWD is only present in the (PMAC) COMMAND_CONFIG register
            # For EMAC_COMMAND_CONFIG, bit[6] must always be 0.
            # The single bit in the one register controls both channels
            for {set ch 0} {$ch < $max_ch} {incr ch} {
                if { $value == 0 } {
                    # Clear the CRC_FWD bits
                    ac7t1500::csr_clear_bits_named CSR_SPACE $eth $mac COMMAND_CONFIG_$ch 6 6 0x40
                } else {
                    # Set the CRC_FWD bits
                    ac7t1500::csr_set_bits_named   CSR_SPACE $eth $mac COMMAND_CONFIG_$ch 6 6 0x40
                }
            }
        }
    }

    # ---------------------------------------------------------------------
    # MAC stats module routines
    # ---------------------------------------------------------------------

    proc stats_reset_module { target mac } {

        set retval [ac7t1500::csr_read_named CSR_SPACE $target $mac STATN_CONFIG]
        set retval "0x$retval"
        set retval [expr {$retval | 0x80000000}]
        set retval [format %x $retval]
        set retval "0x$retval"
        ac7t1500::csr_write_named CSR_SPACE $target $mac STATN_CONFIG $retval
        puts "$target $mac Statistics module reset"
    }

    proc stats_clear_counters { target mac } {

        set retval [ac7t1500::csr_read_named CSR_SPACE $target $mac STATN_CONTROL]
        set retval "0x$retval"
        # Set clear bit and all channels
        set retval [expr {$retval | 0xe00000ff}]
        ac7t1500::csr_write_named CSR_SPACE $target $mac STATN_CONTROL $retval
        # Bits[31:30] and [7:0] are self-clearing, but bit[29] is not.  So clear top 3
        set retval [expr {$retval & 0x1fffffff}]
        set retval [format %x $retval]
        set retval "0x$retval"
        ac7t1500::csr_write_named CSR_SPACE $target $mac STATN_CONTROL $retval
        puts "$target $mac Scounters cleared"
    }

    proc print_stats_line { str base offset {print 1} } {
    # puts "base = $base"
        # Read stats page
        set retval [ac7t1500::noc_read [calc_reg_addr_1inc $base $offset]]
        # Convert to decimal
        scan $retval %x retval_dec
        # Read the top 32-bits.  DATA_HI register is at address 0.  Base address is at address 8
        set retval [ac7t1500::noc_read [calc_reg_addr_1inc $base -8]]
        incr retval_dec [expr (0x$retval << 32)]
        # Print message
        if { $print == 1 } {puts "  $str : [format_large_val $retval_dec 0]"}
        # Return the value
        return $retval_dec
    }

    # Routine to capture the appropriate stats page
    proc stats_capture_page { target mac ch tx_rxn } {

        set retval [ac7t1500::csr_read_named CSR_SPACE $target $mac STATN_CONTROL]
        set retval "0x$retval"
        # Set portmask to the appropriate bit
        set port_mask [expr { 1 << $ch }]
        # Set capture tx or rx based on argument
        set capture_bit 27
        if { $tx_rxn == 1 } { incr capture_bit }
        set wrval [expr { (1 << $capture_bit) + $port_mask }]
        set wrval [format %x $wrval]
        set wrval "0x$wrval"
        # puts "Write $wrval to STATIN_CONTROL"
        # This captures appropriate tx or rx page
        ac7t1500::csr_write_named CSR_SPACE $target $mac STATN_CONTROL $wrval

    }

    # ---------------------------------------------------------------------
    # Capture statistics and print
    # Have option for long and short form display
    # Channels [3:0] are express, [7:4] are pre-emptive.
    # Channel [0] shared with 200G MAC
    # ---------------------------------------------------------------------
    proc stats_capture_channel { target mac ch tx_rxn {long 1} {terse 0}} {

        # Page address for the captured stats. This is constant regardless of TX/RX
        set capt_addr [ac7t1500::csr_named_addr CSR_SPACE $target $mac CAPTURED_PAGE]

        # ---------------------------------------------------------------------
        # Error check
        # ---------------------------------------------------------------------
        # Do error check regardless of mode
        set pass 0

        # Capture TX page
        stats_capture_page $target $mac $ch 1

        set oct_tx    [print_stats_line "OctetsTransmittedOk"  $capt_addr 1 0]
        set frames_tx [print_stats_line "aFramesTransmittedOK" $capt_addr 3 0]
        set errors_tx [print_stats_line "IfOutErrors         " $capt_addr 5 0]

        # Capture RX page
        stats_capture_page $target $mac $ch 0

        # Now read RX stats
        set oct_rx    [print_stats_line "etherStatsOctets   " $capt_addr 0  0]
        set oct_rx_ok [print_stats_line "OctetsReceivedOk   " $capt_addr 1  0]
        set fcs_err   [print_stats_line "aFrameCheckSequenceErrors" $capt_addr 7 0]
        set pkts_rx   [print_stats_line "etherStatsPkts     " $capt_addr 14 0]


        if { $tx_rxn == 1 } { set ch_name TX } else { set ch_name RX }
        if { ($errors_tx == 0) && ($fcs_err == 0) &&
             ($oct_tx == $oct_rx) && ($oct_tx == $oct_rx_ok) && ($frames_tx != 0) } {
            puts "$target $mac Channel $ch $ch_name stats PASS.  [format_large_val $pkts_rx 0] packets"
            set pass 1
        }

        # ---------------------------------------------------------------------

        # If terse requested, and stats passed, then exit after the error check
        if { $terse && $pass } { return $pass }

        # Capture the appropriate page based on $tx_rxn
        stats_capture_page $target $mac $ch $tx_rxn

        if { $tx_rxn == 1 } {
            puts "-----------------------------------------------------------------------------"
            if { $long == 1 } {
                puts "   $target $mac Channel $ch TX statistics"
            } else {
                puts "   $target $mac Channel $ch TX statistics : Short form"
            }
            puts "-----------------------------------------------------------------------------"
            print_stats_line "etherStatsOctets                  " $capt_addr 0  $long
            print_stats_line "OctetsTransmittedOk               " $capt_addr 1  1
            print_stats_line "aPauseMacCtrlFramesTransmitted    " $capt_addr 2  $long
            print_stats_line "aFramesTransmittedOK              " $capt_addr 3  1
            print_stats_line "VLANTransmittedOK                 " $capt_addr 4  $long
            print_stats_line "IfOutErrors                       " $capt_addr 5  1
            print_stats_line "IfOutUcastPkts                    " $capt_addr 6  $long
            print_stats_line "IfOutMulticastPkts                " $capt_addr 7  $long
            print_stats_line "IfOutBroadcastPkts                " $capt_addr 8  $long
            print_stats_line "etherStatsPkts 64           Octets" $capt_addr 9  $long
            print_stats_line "etherStatsPkts 65   to 127  Octets" $capt_addr 10 $long
            print_stats_line "etherStatsPkts 128  to 255  Octets" $capt_addr 11 $long
            print_stats_line "etherStatsPkts 256  to 511  Octets" $capt_addr 12 $long
            print_stats_line "etherStatsPkts 512  to 1023 Octets" $capt_addr 13 $long
            print_stats_line "etherStatsPkts 1024 to 1518 Octets" $capt_addr 14 $long
            print_stats_line "etherStatsPkts 1519 to Max  Octets" $capt_addr 15 $long
            puts "-----------------------------------------------------------------------------"
        } else {
            puts "-----------------------------------------------------------------------------"
            if { $long == 1 } {
                puts "   $target $mac Channel $ch RX statistics"
            } else {
                puts "   $target $mac Channel $ch RX statistics : Short form"
            }
            puts "-----------------------------------------------------------------------------"
            print_stats_line "etherStatsOctets                  " $capt_addr 0  1
            print_stats_line "OctetsReceivedOk                  " $capt_addr 1  1
            print_stats_line "aAlignmentErrors                  " $capt_addr 2  $long
            print_stats_line "aPauseMacCtrlFramesReceived       " $capt_addr 3  $long
            print_stats_line "aFrameTooLongErrors               " $capt_addr 4  $long
            print_stats_line "aInRangeLengthErrors              " $capt_addr 5  $long
            print_stats_line "aFramesReceivedOK                 " $capt_addr 6  $long
            print_stats_line "aFrameCheckSequenceErrors         " $capt_addr 7  1
            print_stats_line "VLANReceivedOK                    " $capt_addr 8  $long
            print_stats_line "IfInErrors                        " $capt_addr 9  $long
            print_stats_line "IfInUcastPkts                     " $capt_addr 10 $long
            print_stats_line "IfInMulticastPkts                 " $capt_addr 11 $long
            print_stats_line "IfInBroadcastPkts                 " $capt_addr 12 $long
            print_stats_line "etherStatsDropEvents              " $capt_addr 13 $long
            print_stats_line "etherStatsPkts                    " $capt_addr 14 1
            print_stats_line "etherStatsUndersizePkts           " $capt_addr 15 $long
            print_stats_line "etherStatsPkts 64           Octets" $capt_addr 16 $long
            print_stats_line "etherStatsPkts 65   to 127  Octets" $capt_addr 17 $long
            print_stats_line "etherStatsPkts 128  to 255  Octets" $capt_addr 18 $long
            print_stats_line "etherStatsPkts 256  to 511  Octets" $capt_addr 19 $long
            print_stats_line "etherStatsPkts 512  to 1023 Octets" $capt_addr 20 $long
            print_stats_line "etherStatsPkts 1024 to 1518 Octets" $capt_addr 21 $long
            print_stats_line "etherStatsPkts 1519 to Max  Octets" $capt_addr 22 $long
            print_stats_line "etherStatsOversizePkts            " $capt_addr 23 $long
            print_stats_line "etherStatsJabbers                 " $capt_addr 24 $long
            print_stats_line "etherStatsFragments               " $capt_addr 25 $long
            puts "-----------------------------------------------------------------------------"
        }

        return $pass
    }

    # ---------------------------------------------------------------------
    # Read Ethernet monitor
    # ---------------------------------------------------------------------
    proc read_ethernet_monitor { name ur_col ur_row base_addr {quiet 0} } {
        set NUM_PKTS_ADDR_L  [calc_reg_addr_1inc $base_addr 0]
        set NUM_PKTS_ADDR_U  [calc_reg_addr_1inc $base_addr 1]
        set NUM_BYTES_ADDR_L [calc_reg_addr_1inc $base_addr 2]
        set NUM_BYTES_ADDR_U [calc_reg_addr_1inc $base_addr 3]
        set BANDWIDTH_ADDR   [calc_reg_addr_1inc $base_addr 4]
        set FREQ_WIDTH_ADDR  [calc_reg_addr_1inc $base_addr 5]

        if { $quiet != 1 } {
            puts "-----------------------------------------"
            puts "$name monitor results"
            puts "-----------------------------------------"
        }

        # Read bandwidth values, frequency, width and monitor type
        set bw_reg [ac7t1500::nap_axi_read NAP_SPACE $ur_col $ur_row $BANDWIDTH_ADDR]
        set freq_width_reg [ac7t1500::nap_axi_read NAP_SPACE $ur_col $ur_row $FREQ_WIDTH_ADDR 41000100]

        # puts "freq_width_reg $freq_width_reg"
        set mon_type [string range $freq_width_reg 0 0]
        set freq     [string range $freq_width_reg 1 3]
        set width    [string range $freq_width_reg 4 7]

        if { $mon_type != 4 } { puts "Incorrect monitor type read.  Monitor reports type $mon_type" }

        # puts "Frequency [expr 0x$freq]. Data width [expr 0x$width]"

        # Split bandwidth register
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
        # Results are divided by 1024 as they are accumulated over a 2^10 deep FIFO
        set max_bw_scale [expr {($max_limit * $max_bw) / (1024.0 * 1000.0)}]
        set av_bw_scale  [expr {($max_limit * $av_bw)  / (1024.0 * 1000.0)}]
        set min_bw_scale [expr {($max_limit * $min_bw) / (1024.0 * 1000.0)}]

        # Read packet and byte registers
        set num_pkts [read_64_bit_user_regs $ur_col $ur_row $NUM_PKTS_ADDR_L]
        set num_bytes [read_64_bit_user_regs $ur_col $ur_row $NUM_BYTES_ADDR_L]

        if { $quiet != 1 } {
            puts "Maximum bandwidth : [expr {($max_limit * $max_bw) / (1024.0 * 1000.0)}] Gbps"
            puts "Average bandwidth : [expr {($max_limit * $av_bw)  / (1024.0 * 1000.0)}] Gbps"
            puts "Minimum bandwidth : [expr {($max_limit * $min_bw) / (1024.0 * 1000.0)}] Gbps"
            puts "Number of packets : [format_large_val $num_pkts]"
            puts "Number of bytes   : [format_large_val $num_bytes]"
            puts "-----------------------------------------"
        }

        return [list $max_bw_scale $av_bw_scale $min_bw_scale $num_pkts $num_bytes]
    }


# End of eth_utils namespace
}

