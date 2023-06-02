#!/usr/bin/tclsh
# -----------------------------------------------------------------------
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
# -----------------------------------------------------------------------
# Utility functions to sit with common Tcl test script API
#   SerDes utilities package 
#   Users can create their own functions in here
# -----------------------------------------------------------------------

# Static variables in the top level global namespace
# Only create variables the once
# To clear them back to their invalid state, then run clear_nep_loopback_state()
if { ![info exists programmed_ck_sel_nt] } {
    set programmed_ck_sel_nt   "0xbad"
    set programmed_data_sel_nt "0xbad"
}

namespace eval serdes_utils {
    # Any variables that should be shared between serdes utilities as
    # static variables can be defined here


    # ---------------------------------------------------------------------
    # Print the status of the SERDES TX OBSERVABILITY REGISTERS
    # ---------------------------------------------------------------------

    proc tx_lane_reg_dump {target xcvr ch} {
        puts "-----------------------------------------------------------------------------"
        puts " $target $xcvr LANE_$ch Observability Register Dump "
        puts "-----------------------------------------------------------------------------"
        puts "ETHERNET   SERDES   LANE_$ch                     :     ADDR    DATA"
        puts "$target $xcvr AFE_OCTERM_TX_RDREG_$ch      : [ac7t1500::csr_named_addr CSR_SPACE $target $xcvr AFE_OCTERM_TX_RDREG_$ch] [ac7t1500::csr_read_named CSR_SPACE $target $xcvr AFE_OCTERM_TX_RDREG_$ch]"
        puts "$target $xcvr TX_DETECTRX_RDREG_$ch        : [ac7t1500::csr_named_addr CSR_SPACE $target $xcvr TX_DETECTRX_RDREG_$ch] [ac7t1500::csr_read_named CSR_SPACE $target $xcvr TX_DETECTRX_RDREG_$ch]"
        puts "$target $xcvr TX_FEP_LOOPBACK_FIFO_TOP_$ch : [ac7t1500::csr_named_addr CSR_SPACE $target $xcvr TX_FEP_LOOPBACK_FIFO_TOP_$ch] [ac7t1500::csr_read_named CSR_SPACE $target $xcvr TX_FEP_LOOPBACK_FIFO_TOP_$ch]"
        puts "$target $xcvr TX_FIR_RDREG_$ch             : [ac7t1500::csr_named_addr CSR_SPACE $target $xcvr TX_FIR_RDREG_$ch] [ac7t1500::csr_read_named CSR_SPACE $target $xcvr TX_FIR_RDREG_$ch]"
        puts "$target $xcvr TX_LOOPBACK_CNTRL_$ch        : [ac7t1500::csr_named_addr CSR_SPACE $target $xcvr TX_LOOPBACK_CNTRL_$ch] [ac7t1500::csr_read_named CSR_SPACE $target $xcvr TX_LOOPBACK_CNTRL_$ch]"
        puts "$target $xcvr TX_LOOPBACK_CNTRL_RDREG_$ch  : [ac7t1500::csr_named_addr CSR_SPACE $target $xcvr TX_LOOPBACK_CNTRL_RDREG_$ch] [ac7t1500::csr_read_named CSR_SPACE $target $xcvr TX_LOOPBACK_CNTRL_RDREG_$ch]"
        puts "$target $xcvr TX_PHASE_ADAPT_RDREG_$ch     : [ac7t1500::csr_named_addr CSR_SPACE $target $xcvr TX_PHASE_ADAPT_RDREG_$ch] [ac7t1500::csr_read_named CSR_SPACE $target $xcvr TX_PHASE_ADAPT_RDREG_$ch]"
        puts "$target $xcvr TX_PHASE_ADAPT_REG2_$ch      : [ac7t1500::csr_named_addr CSR_SPACE $target $xcvr TX_PHASE_ADAPT_REG2_$ch] [ac7t1500::csr_read_named CSR_SPACE $target $xcvr TX_PHASE_ADAPT_REG2_$ch]"
        puts "$target $xcvr TX_PHASE_ADAPT_REG3_$ch      : [ac7t1500::csr_named_addr CSR_SPACE $target $xcvr TX_PHASE_ADAPT_REG3_$ch] [ac7t1500::csr_read_named CSR_SPACE $target $xcvr TX_PHASE_ADAPT_REG3_$ch]"
        puts "$target $xcvr TX_PHASE_ADAPT_REG4_$ch      : [ac7t1500::csr_named_addr CSR_SPACE $target $xcvr TX_PHASE_ADAPT_REG4_$ch] [ac7t1500::csr_read_named CSR_SPACE $target $xcvr TX_PHASE_ADAPT_REG4_$ch]"
        puts "$target $xcvr TX_PHASE_ADAPT_REG5_$ch      : [ac7t1500::csr_named_addr CSR_SPACE $target $xcvr TX_PHASE_ADAPT_REG5_$ch] [ac7t1500::csr_read_named CSR_SPACE $target $xcvr TX_PHASE_ADAPT_REG5_$ch]"
        puts "$target $xcvr TX_PHASE_FIFO_$ch            : [ac7t1500::csr_named_addr CSR_SPACE $target $xcvr TX_PHASE_FIFO_$ch] [ac7t1500::csr_read_named CSR_SPACE $target $xcvr TX_PHASE_FIFO_$ch]"
        puts "$target $xcvr TX_PPM_LOCK_DETECT_RDREG_$ch : [ac7t1500::csr_named_addr CSR_SPACE $target $xcvr TX_PPM_LOCK_DETECT_RDREG_$ch] [ac7t1500::csr_read_named CSR_SPACE $target $xcvr TX_PPM_LOCK_DETECT_RDREG_$ch]"
        puts "$target $xcvr TX_PPM_LOCK_DETECT_REG1_$ch  : [ac7t1500::csr_named_addr CSR_SPACE $target $xcvr TX_PPM_LOCK_DETECT_REG1_$ch] [ac7t1500::csr_read_named CSR_SPACE $target $xcvr TX_PPM_LOCK_DETECT_REG1_$ch]"
        puts "$target $xcvr TX_PPM_LOCK_DETECT_REG2_$ch  : [ac7t1500::csr_named_addr CSR_SPACE $target $xcvr TX_PPM_LOCK_DETECT_REG2_$ch] [ac7t1500::csr_read_named CSR_SPACE $target $xcvr TX_PPM_LOCK_DETECT_REG2_$ch]"
        puts "$target $xcvr TX_PPM_LOCK_DETECT_REG3_$ch  : [ac7t1500::csr_named_addr CSR_SPACE $target $xcvr TX_PPM_LOCK_DETECT_REG3_$ch] [ac7t1500::csr_read_named CSR_SPACE $target $xcvr TX_PPM_LOCK_DETECT_REG3_$ch]"
        puts "$target $xcvr TX_VCO_ADAPT_RDREG1_$ch      : [ac7t1500::csr_named_addr CSR_SPACE $target $xcvr TX_VCO_ADAPT_RDREG1_$ch] [ac7t1500::csr_read_named CSR_SPACE $target $xcvr TX_VCO_ADAPT_RDREG1_$ch]"
        puts "$target $xcvr TX_VCO_ADAPT_RDREG2_$ch      : [ac7t1500::csr_named_addr CSR_SPACE $target $xcvr TX_VCO_ADAPT_RDREG2_$ch] [ac7t1500::csr_read_named CSR_SPACE $target $xcvr TX_VCO_ADAPT_RDREG2_$ch]"
        puts "$target $xcvr TXIFFSM_CTRL_$ch             : [ac7t1500::csr_named_addr CSR_SPACE $target $xcvr TXIFFSM_CTRL_$ch] [ac7t1500::csr_read_named CSR_SPACE $target $xcvr TXIFFSM_CTRL_$ch]"
        puts "$target $xcvr TXIFFSM_STAT_$ch             : [ac7t1500::csr_named_addr CSR_SPACE $target $xcvr TXIFFSM_STAT_$ch] [ac7t1500::csr_read_named CSR_SPACE $target $xcvr TXIFFSM_STAT_$ch]"
        puts "$target $xcvr TXMFSM_STAT_$ch              : [ac7t1500::csr_named_addr CSR_SPACE $target $xcvr TXMFSM_STAT_$ch] [ac7t1500::csr_read_named CSR_SPACE $target $xcvr TXMFSM_STAT_$ch]"
        puts "$target $xcvr TXMFSM_STATE_$ch             : [ac7t1500::csr_named_addr CSR_SPACE $target $xcvr TXMFSM_STATE_$ch] [ac7t1500::csr_read_named CSR_SPACE $target $xcvr TXMFSM_STATE_$ch]"
        puts "$target $xcvr DIG_SOC_LANE_STAT_REG1_$ch   : [ac7t1500::csr_named_addr CSR_SPACE $target $xcvr DIG_SOC_LANE_STAT_REG1_$ch] [ac7t1500::csr_read_named CSR_SPACE $target $xcvr DIG_SOC_LANE_STAT_REG1_$ch]"
        puts "$target $xcvr DIG_SOC_LANE_STAT_REG2_$ch   : [ac7t1500::csr_named_addr CSR_SPACE $target $xcvr DIG_SOC_LANE_STAT_REG2_$ch] [ac7t1500::csr_read_named CSR_SPACE $target $xcvr DIG_SOC_LANE_STAT_REG2_$ch]"
        puts "$target $xcvr DIG_SOC_LANE_STAT_REG3_$ch   : [ac7t1500::csr_named_addr CSR_SPACE $target $xcvr DIG_SOC_LANE_STAT_REG3_$ch] [ac7t1500::csr_read_named CSR_SPACE $target $xcvr DIG_SOC_LANE_STAT_REG3_$ch]"
        puts "$target $xcvr LOOPBACK_CNTRL_$ch           : [ac7t1500::csr_named_addr CSR_SPACE $target $xcvr LOOPBACK_CNTRL_$ch] [ac7t1500::csr_read_named CSR_SPACE $target $xcvr LOOPBACK_CNTRL_$ch]"
        puts "-----------------------------------------------------------------------------"
    }

    # ---------------------------------------------------------------------
    # Print the status of the SERDES LOCK STATUS
    # ---------------------------------------------------------------------

    proc rx_lock_status { target num_quads} {

        puts "-----------------------------------------------------------------------------"
        puts "               Reading $target RX Serdes Lock Status"
        puts "-----------------------------------------------------------------------------"
        puts "  Block    Serdes   Lane   : Analog  CDR  PPM  Digital   AFE    FOM   FOM"
        puts "                           : Sig Det Lock Lock Sig Det Sig Det   1     2"

        # This allows for 2 or 4 quads to be read, so routine can work for Ethernet and PCIe
        for {set quad 0} {$quad < $num_quads} {incr quad} {
            set serdes "SERDES_$quad"
            for {set ch 0} {$ch < 4} {incr ch} {
                #RX Analog SIGNAL DETECT
                set dig_soc_lane_stat_reg3_value [ac7t1500::csr_read_named CSR_SPACE $target $serdes DIG_SOC_LANE_STAT_REG3_$ch]
                #RX CDR LOCK (actually data valid, which indicates CDR locked)
                set dig_soc_lane_stat_reg1_value [ac7t1500::csr_read_named CSR_SPACE $target $serdes DIG_SOC_LANE_STAT_REG1_$ch]
                #RX PPM LOCK
                set rx_ppm_lock_detect_rdreg_value [ac7t1500::csr_read_named CSR_SPACE $target $serdes RX_PPM_LOCK_DETECT_RDREG_$ch]
                #RX Digital and AFE signal detect
                set rx_signal_detect_rdreg_value [ac7t1500::csr_read_named CSR_SPACE $target $serdes RX_SIGNAL_DETECT_RDREG_$ch]
                #RX Link Eval status
                set rx_linkeval_stat [ac7t1500::csr_read_named CSR_SPACE $target $serdes RXLINKEVAL_STAT_$ch]

                if {[expr 0x$dig_soc_lane_stat_reg3_value & 0x00000001]} {
                    set val1 1
                } else {
                    set val1 0
                }

                if {[expr 0x$dig_soc_lane_stat_reg1_value & 0x00000002]} {
                    set val2 1
                } else {
                    set val2 0
                }

                if {[expr 0x$rx_ppm_lock_detect_rdreg_value & 0x00010000]} {
                    set val3 1
                } else {
                    set val3 0
                }

                set val4 [expr 0x$rx_signal_detect_rdreg_value & 0x1]
                
                if {[expr 0x$rx_signal_detect_rdreg_value & 0x00000004]} {
                    set val5 1
                } else {
                    set val5 0
                }

                # puts "reg3 $dig_soc_lane_stat_reg3_value linkeval $rx_linkeval_stat"
                # Get FOM value, bits [12:5]
                set rx_linkeval_fom1 [expr {("0x$dig_soc_lane_stat_reg3_value" & 0x1fe0) >> 5}]
                # Alternate FOM value, bits [7:0]
                set rx_linkeval_fom2 [expr {"0x$rx_linkeval_stat" & 0x0ff}]

                puts "$target $serdes LANE_$ch :    $val1     $val2    $val3      $val4       $val5      $rx_linkeval_fom1     $rx_linkeval_fom2"
            }
        }
        puts "-----------------------------------------------------------------------------"
    }

    # ---------------------------------------------------------------------
    # Toggle Serdes RX STATE REQ
    # ---------------------------------------------------------------------
    proc tx_rx_state_req { target quad enable} {

        # These registers are unfortunately not in the Tcl dictionary (yet)
        # When they are, then can remove the hardcoded values and replace with tokens
        set base_addr [ac7t1500::csr_named_addr CSR_SPACE $target $quad]
        
        # TX
        for {set ch 0} {$ch < 4} {incr ch} {
            # Note that calc_reg_addr_1inc multiplies the offset by 4
            # So divide the result of the absolute calculation below by 4
            set reg_addr [expr {((0x100000 * $ch) + 0xC00000 + 0x4)/4}]
            set full_addr [calc_reg_addr_1inc $base_addr $reg_addr]

            if { $enable == 1 } {
                ac7t1500::set_bits_addressed   $full_addr 0 1 0x0;  # [1:0] = 1'b11
            } else {
                # Ensure bit[0] is set first
                ac7t1500::set_bits_addressed     $full_addr 0 0 0x0;

                # De-assert bit[1]
                ac7t1500::clear_bits_addressed   $full_addr 1 1 0x0;

                # Clear override bit[0]
                ac7t1500::clear_bits_addressed   $full_addr 0 0 0x0;
            }
        }
        
        # RX
        for {set ch 0} {$ch < 4} {incr ch} {
            # Note that calc_reg_addr_1inc multiplies the offset by 4
            # So divide the result of the absolute calculation below by 4
            set reg_addr [expr {((0x100000 * $ch) + 0xC00000 + 0x8)/4}]
            set full_addr [calc_reg_addr_1inc $base_addr $reg_addr]

            if { $enable == 1 } {
                ac7t1500::set_bits_addressed   $full_addr 0 1 0x0;  # [1:0] = 1'b11
            } else {
                # Ensure bit[0] is set first
                ac7t1500::set_bits_addressed     $full_addr 0 0 0x0;

                # De-assert bit[1]
                ac7t1500::clear_bits_addressed   $full_addr 1 1 0x0;

                # Clear override bit[0]
                ac7t1500::clear_bits_addressed   $full_addr 0 0 0x0;
            }
        }

        if { $enable == 1 } {
            puts "Set Serdes TX and RX state REQ for $target $quad"
        } else {
            puts "Cleared Serdes TX and RX state REQ for $target $quad"
        }

        puts "--------------------------------------------------------"
    }

    # ---------------------------------------------------------------------
    # Invert RX Data
    # ---------------------------------------------------------------------
    # Default to enable, in order to be backwards compatible
    proc invert_rx_data { target quad ch {enable 1} } {
        if { $enable == 1 } {
            puts "Invert rx data for $target $quad channel $ch"
            ac7t1500::csr_set_bits_named CSR_SPACE $target $quad RX_DEMAPPER_$ch 15 15
        } else {
            puts "Clear invert of rx data for $target $quad channel $ch"
            ac7t1500::csr_clear_bits_named CSR_SPACE $target $quad RX_DEMAPPER_$ch 15 15
        }
    }
      # if { $enable == 1 } {
      #      puts "Invert rx data for $target $quad channel $ch"
      #      ac7t1500::csr_set_bits_named CSR_SPACE $target $quad RX_DEMAPPER_$ch 15 15
      #  } else {
      #      puts "Clear invert of rx data for $target $quad channel $ch"
      #      ac7t1500::csr_clear_bits_named CSR_SPACE $target $quad RX_DEMAPPER_$ch 15 15
      #  }


    # ---------------------------------------------------------------------
    # Set the CDR bandwidth
    # kprop -> Proportional Gain settings
    # Kint -> Integral Gain Settings
    # Ted_bias: Timing Errpr Detector Bias Settings
    #
    # Necessary for modes with zero settings after power up
    # ---------------------------------------------------------------------

     proc set_cdr_bandwidth { target ip ch } {
     
         puts "set_cdr_bandwidth  $target $ip channel $ch"
 
         #rx_itr_dpll_dlpf_reg1 Kprop1_nt 7
         csr_set_field_named CSR_SPACE $target $ip RX_ITR_DPLL_DLPF_REG1_$ch 8 5 7

         #rx_itr_dpll_dlpf_reg1 Kprop2_nt 7
         csr_set_field_named CSR_SPACE $target $ip RX_ITR_DPLL_DLPF_REG1_$ch 16 5 7
 
         #rx_itr_dpll_dlpf_reg1 Kprop3_nt 7
         csr_set_field_named CSR_SPACE $target $ip RX_ITR_DPLL_DLPF_REG1_$ch 21 5 7

         #rx_itr_dpll_dlpf_reg2 Kint1_nt 17
         csr_set_field_named CSR_SPACE $target $ip RX_ITR_DPLL_DLPF_REG2_$ch 8 5 17

         #rx_itr_dpll_dlpf_reg2 Kint2_nt 17
         csr_set_field_named CSR_SPACE $target $ip RX_ITR_DPLL_DLPF_REG2_$ch 16 5 17

         #rx_itr_dpll_dlpf_reg2 Kint3_nt 17
         csr_set_field_named CSR_SPACE $target $ip RX_ITR_DPLL_DLPF_REG2_$ch 21 5 17

         #rx_itr_dpll_ted bias1_nt 3
         csr_set_field_named CSR_SPACE $target $ip RX_ITR_DPLL_TED_$ch 11 5 3

         #rx_itr_dpll_ted bias2_nt 3
         csr_set_field_named CSR_SPACE $target $ip RX_ITR_DPLL_TED_$ch 16 5 3

         #rx_itr_dpll_dlpf_reg1 ted_bias3_nt 3
         csr_set_field_named CSR_SPACE $target $ip RX_ITR_DPLL_DLPF_REG1_$ch 26 5 3 
    }

    # ---------------------------------------------------------------------
    # Trigger Serdes RX EQ
    # ---------------------------------------------------------------------
    proc acx_pcs_trigger_rx_eq { target quad {max_ch 4}} {

        puts "ACX PCS based trigger serdes RX EQ for $target $quad all channels starting"

        # Register is ovr_pma_prts_ln#_2, at address offset 0xC
        # Bit fields as follows; (taken from the RTL)
        # Bit[0] 
        # assign reg_ovr_rx_linkeval_type_ln0           = reg_ctrl_n_ovr_pma_prts_ln0_2 [0];
        # assign reg_ovr_rx_linkeval_type_value_ln0     = reg_ctrl_n_ovr_pma_prts_ln0_2 [4:1];
        # assign reg_ovr_rx_linkeval_req_ln0            = reg_ctrl_n_ovr_pma_prts_ln0_2 [5];
        # assign reg_ovr_rx_linkeval_req_value_ln0      = reg_ctrl_n_ovr_pma_prts_ln0_2 [6];
        # assign reg_ovr_ictl_rx_linkeval_ack_ln0       = reg_ctrl_n_ovr_pma_prts_ln0_2 [7];
        # assign reg_ovr_ictl_rx_linkeval_ack_value_ln0 = reg_ctrl_n_ovr_pma_prts_ln0_2 [8];
        # assign reg_ovr_rx_linkeval_dir_ln0            = reg_ctrl_n_ovr_pma_prts_ln0_2 [9];
        # assign reg_ovr_rx_linkeval_dir_value_ln0      = reg_ctrl_n_ovr_pma_prts_ln0_2 [17:10];
        # The ACK signal is not available in the ACX_PCS registers.  We will need read this from the Serdes registers

        # These registers are unfortunately not in the Tcl dictionary (yet)
        # When they are, then can remove the hardcoded values and replace with tokens
        set base_addr [ac7t1500::csr_named_addr CSR_SPACE $target $quad]
        for {set ch 0} {$ch < $max_ch} {incr ch} {

            # Invert RX data bits for even numbered lanes
            #if { [expr {$ch % 2}] == 0 } {
            #    puts "Invert rx data for channel $ch"
            #    csr_ac7t1500::set_bits_named CSR_SPACE $target $quad RX_DEMAPPER_$ch 15 15
            #}

            # Note that calc_reg_addr_1inc multiplies the offset by 4
            # So divide the result of the absolute calculation below by 4
            set reg_addr [expr {((0x100000 * $ch) + 0xC00000 + 0xC)/4}]
            set full_addr [calc_reg_addr_1inc $base_addr $reg_addr]

            # Make sure active bits are cleared first
            ac7t1500::clear_bits_addressed $full_addr 0 6 0x61

            # Run loop multiple times until CDR lock is obtained
            set cdr_lock 0
            set cdr_loop 4
            while { ($cdr_lock != 1) && ($cdr_loop > 0)} {
               if { $cdr_loop != 4 } { puts "$target $quad $ch CDR loop $cdr_loop" }

                # Check ACK status beforehand
                set timeout 20
                set linkeval_ack 1
                while { ($linkeval_ack != 0) && ($timeout > 0)} {
                    set retval [ac7t1500::csr_read_named CSR_SPACE $target $quad DIG_SOC_LANE_STAT_REG1_$ch 0x0]
                    set retval "0x$retval"
                    # puts "Pre DIG_SOC_LANE_STAT_REG1_$ch is $retval"
                    set linkeval_ack [expr {($retval & 0x4) >> 2}]
                    # puts "Pre ACK is $linkeval_ack"
                    ac7t1500::wait_us 100
                    incr timeout -1
                }

                if { $timeout == 0 } {
                    puts "ERROR - Linkeval_ack not cleared in time"
                    return 0
                }

                # Set the bits to activate Rx Eq
                ac7t1500::clear_bits_addressed $full_addr 1 4 0x0;   # [4:1] = 4'b0000 Full EQ
                ac7t1500::set_bits_addressed   $full_addr 0 0 0x0;   # [0]   = 1'b1
                ac7t1500::set_bits_addressed   $full_addr 5 6 0x1;   # [6:5] = 2'b11

                # Re-run waiting for ack
                set timeout 20
                while { ($linkeval_ack != 1) && ($timeout > 0)} {
                    set retval "0x[ac7t1500::csr_read_named CSR_SPACE $target $quad DIG_SOC_LANE_STAT_REG1_$ch 0x0]"
                    # puts "Post DIG_SOC_LANE_STAT_REG1_$ch is $retval"
                    set linkeval_ack [expr {($retval & 0x4) >> 2}]
                    # puts "Post ACK is $linkeval_ack"
                    ac7t1500::wait_us 100
                    incr timeout -1
                }

                if { $timeout == 0 } {
                    puts "ERROR - Linkeval_ack not set in time"
                    return 0
                }

                # Once we have a good ACK, then deassert the req.  Otherwise this is preventing the state machine from transitioning
                ac7t1500::clear_bits_addressed $full_addr 5 6 0x61

                # Check CDR lock status
                # Actually read the data_valid status - this indicates CDR lock.
                ac7t1500::wait_us 100
                set retval "0x[ac7t1500::csr_read_named CSR_SPACE $target $quad DIG_SOC_LANE_STAT_REG1_$ch 0x0]"
                # puts "Post DIG_SOC_LANE_STAT_REG1_$ch is $retval"
                set cdr_lock [expr {($retval & 0x2) >> 1}]

                # Decrement the outer CDR loop
                incr cdr_loop -1
            }

            if { $timeout == 0 } {
                puts "ERROR - CDR lock not set after multiple attempts for $target $quad channel $ch"
                return 0
            } else {
                puts "CDR lock obtained for $target $quad channel $ch"
            }
            
        }
            
        # PMA force signal detect valid
        # This should not be necessary, we are getting CDR lock, which asserts data valid.
        # If it is needed, then it should be called explicity by the calling script
        # override_pma_data_valid $target $quad 1

        puts "ACX PCS based trigger serdes RX EQ for $target $quad all channels completed"
        puts "--------------------------------------------------------"

    }

    proc rxiffsm_trigger_rx_eq { target quad } {

        for {set ch 0} {$ch < 4} {incr ch} {
            set retval [ac7t1500::csr_read_named CSR_SPACE $target $quad RXIFFSM_LINKEVAL_$ch]
            set retval "0x$retval"
            # puts "Read $retval from $full_addr"

            set retval [expr {$retval & 0xffffffe1}]; # [4:1] = 4'b0000
            set retval [format %X $retval]
            ac7t1500::csr_write_named CSR_SPACE $target $quad RXIFFSM_LINKEVAL_$ch $retval
            ac7t1500::csr_verify_named CSR_SPACE $target $quad RXIFFSM_LINKEVAL_$ch $retval
            
            set retval [expr {$retval | 0x1}];        # [0]   = 1'b1
            set retval [format %X $retval]
            ac7t1500::csr_write_named CSR_SPACE $target $quad RXIFFSM_LINKEVAL_$ch $retval
            ac7t1500::csr_verify_named CSR_SPACE $target $quad RXIFFSM_LINKEVAL_$ch $retval
            
            set retval [expr {$retval | 0x2}];       # [1] = 1'b1
            set retval [format %X $retval]
            ac7t1500::csr_write_named CSR_SPACE $target $quad RXIFFSM_LINKEVAL_$ch $retval
            ac7t1500::csr_verify_named CSR_SPACE $target $quad RXIFFSM_LINKEVAL_$ch $retval

            unset retval
        }
            
        # PMA force signal detect valid
        override_pma_data_valid $target $quad 1

        puts "RXIFFSM based trigger serdes RX EQ for $target $quad all channels"
        puts "--------------------------------------------------------"

    }

    proc pma_trigger_rx_eq { target quad } {

        # Within a Quad set all 4 Serdes lanes to be the same
        for {set ch 0} {$ch < 4} {incr ch} {
                
            # puts "dig soc lane ovrd reg1"
            # Enable lane override
            set retval [ac7t1500::csr_read_named CSR_SPACE $target $quad DIG_SOC_LANE_OVRD_REG1_$ch 0x0]
            # Value read back is hex
            set retval "0x$retval"
            # Set bit[0], lane override
            set retval [expr {$retval | 0x1}]
            # Format result back to hex
            set retval [format %X $retval]
            ac7t1500::csr_write_named CSR_SPACE $target $quad DIG_SOC_LANE_OVRD_REG1_$ch $retval
            ac7t1500::csr_verify_named CSR_SPACE $target $quad DIG_SOC_LANE_OVRD_REG1_$ch $retval
            unset retval

            # puts "dig soc lane ovrd reg2"        
            # Set eq type and assert req
            set retval [ac7t1500::csr_read_named CSR_SPACE $target $quad DIG_SOC_LANE_OVRD_REG2_$ch 0x0]
            # Value read back is hex
            set retval "0x$retval"
            # Set bit[24], trigger_rx_req
            set retval [expr {$retval | 0x1000000}]
            # Format result back to hex
            set retval [format %X $retval]
            ac7t1500::csr_write_named CSR_SPACE $target $quad DIG_SOC_LANE_OVRD_REG2_$ch $retval
            ac7t1500::csr_verify_named CSR_SPACE $target $quad DIG_SOC_LANE_OVRD_REG2_$ch $retval
            unset retval
            
            # puts "dig soc lane ovrd reg1"
            # Release lane override
            set retval [ac7t1500::csr_read_named CSR_SPACE $target $quad DIG_SOC_LANE_OVRD_REG1_$ch 0x1]
            # Value read back is hex
            set retval "0x$retval"
            # Clear bit[0], lane override
            set retval [expr {$retval & 0xfffffffe}]
            # Format result back to hex
            set retval [format %X $retval]
            ac7t1500::csr_write_named CSR_SPACE $target $quad DIG_SOC_LANE_OVRD_REG1_$ch $retval
            ac7t1500::csr_verify_named CSR_SPACE $target $quad DIG_SOC_LANE_OVRD_REG1_$ch $retval
            unset retval
            
            # puts "rx sig det 3"
            # Force rx_signal_detect_reg3
            set retval [ac7t1500::csr_read_named CSR_SPACE $target $quad RX_SIGNAL_DETECT_REG3_$ch 0x6663]
            # Value read back is hex
            set retval "0x$retval"
            # Set bits[3:2], force_valid_a, clear force_invalid_a
            set retval [expr {$retval | 0x00000008}]
            set retval [expr {$retval & 0xfffffffb}]
            # Format result back to hex
            set retval [format %X $retval]
            ac7t1500::csr_write_named  CSR_SPACE $target $quad RX_SIGNAL_DETECT_REG3_$ch $retval
            ac7t1500::csr_verify_named CSR_SPACE $target $quad RX_SIGNAL_DETECT_REG3_$ch $retval
            unset retval

        }

        puts "PMA based trigger serdes RX EQ for $target $quad all channels"
        puts "--------------------------------------------------------"

    }

    # ---------------------------------------------------------------------
    # ---------------------------------------------------------------------
    # Serdes loopback functions
    # ---------------------------------------------------------------------
    # ---------------------------------------------------------------------

    # To clear them back to their invalid state, then run clear_nep_loopback_state()
    proc clear_nep_loopback_state {} {
        set ::programmed_ck_sel_nt   "0xbad"
        set ::programmed_data_sel_nt "0xbad"
        puts ""
    }

    # ---------------------------------------------------------------------
    # Set serdes near-end parallel loopback
    # ---------------------------------------------------------------------
    # By default this routine will set rx_signal_detect and rx_data_valid asserted
    # by overriding them in the ACX PCS block.
    proc nep_loopback { target quad enable {acx_pcs_ovr 1} } {

        # From AW app note, for Near-end parallel loopback
        # To program through registers:
        #   rx_cntrl_reg1[rx_width_ovr_ena_nt] = 1
        #   seq_cntrl_rx[data_sel_nt] = 3
        #   seq_cntrl_rx[ck_sel_nt] = ‘hC

        # The expected read values are used in simulation only
        # Set them to match the 8x10g noFec simulation, as this is used for verification
        set rx_cntrl_reg1_exp 0x64
        set seq_cntrl_rx_exp  0x060633c4

        # Within a Quad set all 4 Serdes lanes to be the same
        for {set ch 0} {$ch < 4} {incr ch} {
            # Programme rx_cntrl_reg1
            set retval [ac7t1500::csr_read_named CSR_SPACE $target $quad RX_CNTRL_REG1_$ch $rx_cntrl_reg1_exp]
            # Value read back is hex
            set retval "0x$retval"
            if { $enable == 1 } {
                # Set bit[4], rx_width_ovr_ena_nt
                set retval [expr {$retval | 0x10}]
            } else {
                # Clear bit[4], rx_width_ovr_ena_nt
                set retval [expr {$retval & 0xffffffef}]
            }
            # Format result back to hex
            set retval [format %X $retval]

            ac7t1500::csr_write_named  CSR_SPACE $target $quad RX_CNTRL_REG1_$ch $retval
            ac7t1500::csr_verify_named CSR_SPACE $target $quad RX_CNTRL_REG1_$ch $retval
            unset retval

            # Programme seq_cntrl_rx
            set retval [ac7t1500::csr_read_named CSR_SPACE $target $quad SEQ_CNTRL_RX_$ch $seq_cntrl_rx_exp]
            # Value read back is hex
            set retval "0x$retval"
            if { $enable == 1 } {
                # Set bits[25:24], data_sel_nt to 3
                # This will already have a value, so store that in global variable
                set ::programmed_data_sel_nt "0x[format %x [expr {$retval & 0x03000000}]]"
                set retval [expr {$retval & 0xfcffffff}]
                set retval [expr {$retval | 0x03000000}]
                # Set bits[19:16], ck_sel_nt to C
                # This will already have a value, so store that in global variable
                set ::programmed_ck_sel_nt "0x[format %x [expr {$retval & 0xf0000}]]"
                set retval [expr {$retval & 0xfff0ffff}]
                set retval [expr {$retval | 0x000c0000}]

            } else {
                # If the static variables have been set then
                # mask off the bits that were changed and re-insert the static variables
                if { ($::programmed_data_sel_nt != "0xbad") && ($::programmed_ck_sel_nt != "0xbad") } {
                    set retval [expr {$retval & 0xfcffffff}]
                    set retval [expr {$retval & 0xfff0ffff}]
                    set retval [expr {$retval | $::programmed_data_sel_nt}]
                    set retval [expr {$retval | $::programmed_ck_sel_nt}]
                } else {
                    # SEQ_CNTRL_RX_0 entry {0046ec 32 060633e2}

                    # We can only set back to the default, which may not be correct.
                    # We would need to know the original value fully to restore correctly
                    # Clear bit 24 only as that is 1'b0 by default.
                    set retval [expr {$retval & 0xfeffffff}]
                    # Clear bit 19 only as that is 1'b0 by default
                    set retval [expr {$retval & 0xfff7ffff}]
                }
            }

            # Format result back to hex
            set retval [format %X $retval]

            ac7t1500::csr_write_named  CSR_SPACE $target $quad SEQ_CNTRL_RX_$ch $retval
            ac7t1500::csr_verify_named CSR_SPACE $target $quad SEQ_CNTRL_RX_$ch $retval
            unset retval

        }

        if { $enable == 1 } {
            puts "Set serdes near-end parallel loopback for $target $quad all channels"
        } else {
            puts "Cleared serdes near-end parallel loopback for $target $quad all channels"
        }

        # Need to set an override in the ACX PCS signals as well to force 
        # RX signal_detect and data_valid to be asserted
        if { $acx_pcs_ovr == 1 } {
            override_acx_pcs_valid_det $target $quad $enable
        }

        # In theory PMA can force data valid.  To be tested
        set aw_sig_det_ovr 0
        if { $aw_sig_det_ovr == 1 } {
            override_pma_data_valid $target $quad $enable
        }

        puts "--------------------------------------------------"

    }

    # ---------------------------------------------------------------------
    # Override ACX PCS rx_data_valid and rx_sig_detect
    # ---------------------------------------------------------------------
    proc override_acx_pcs_valid_det { target quad enable } {

        # These registers are unfortunately not in the Tcl dictionary (yet)
        # When they are, then can remove the hardcoded values and replace with tokens
        set base_addr [ac7t1500::csr_named_addr CSR_SPACE $target $quad]
        for {set ch 0} {$ch < 4} {incr ch} {
            # Note that calc_reg_addr_1inc multiplies the offset by 4
            # So divide the result of the absolute calculation below by 4
            set reg_addr [expr {((0x100000 * $ch) + 0xC00000 + 0x10)/4}]
            set full_addr [calc_reg_addr_1inc $base_addr $reg_addr]

            # Set or clear relevant bits
            if { $enable == 1 } {
                # [5:4] = 2'b11 and [7:6] = 2'b11
                ac7t1500::set_bits_addressed     $full_addr 4 7 0x0;
            } else {
                # [5:4] = 2'b00 and [7:6] = 2'b00
                ac7t1500::clear_bits_addressed   $full_addr 4 7 0x0;
            }
        }

        if { $enable == 1 } {
            puts "Set ACX PCS valid and detect overrides for $target $quad"
        } else {
            puts "Cleared ACX PCS valid and detect overrides for $target $quad"
        }

    }

    # ---------------------------------------------------------------------
    # Override ACX PCS rx_disable
    # enable set the override, (so enable override)
    # value set the value it is overridden to. Value will be ignored if enable is not set
    # ---------------------------------------------------------------------
    proc override_acx_pcs_rx_disable { target quad enable value} {

        # These registers are unfortunately not in the Tcl dictionary (yet)
        # When they are, then can remove the hardcoded values and replace with tokens
        set base_addr [ac7t1500::csr_named_addr CSR_SPACE $target $quad]
        for {set ch 0} {$ch < 4} {incr ch} {
            # Note that calc_reg_addr_1inc multiplies the offset by 4
            # So divide the result of the absolute calculation below by 4
            set reg_addr [expr {((0x100000 * $ch) + 0xC00000 + 0x10)/4}]
            set full_addr [calc_reg_addr_1inc $base_addr $reg_addr]

            # Set or clear override bit
            # Override is bit[0]
            if { $enable == 1 } {
                ac7t1500::set_bits_addressed     $full_addr 0 0 0x0;
                set exp_value 0x1
            } else {
                ac7t1500::clear_bits_addressed   $full_addr 0 0 0x0;
                set exp_value 0x0
            }

            # Set or clear value bit
            # Value is bit[1]
            if { $value == 1 } {
                ac7t1500::set_bits_addressed     $full_addr 1 1 $exp_value
            } else {
                ac7t1500::clear_bits_addressed   $full_addr 1 1 $exp_value
            }
        }

        if { $enable == 1 } {
            puts "Set ACX PCS rx_disable override to value $value for $target $quad"
        } else {
            puts "Cleared ACX PCS rx_disable override for $target $quad"
        }

    }

    # ---------------------------------------------------------------------
    # Force data_valid output from PMA
    # ---------------------------------------------------------------------
    proc override_pma_data_valid { target quad enable } {

        # Programme force_valid_a bit in rx_signal_detect_reg3
        for {set ch 0} {$ch < 4} {incr ch} {
            # Read register
            set retval [ac7t1500::csr_read_named CSR_SPACE $target $quad RX_SIGNAL_DETECT_REG3_$ch 0x66b3]
            # Set as hex value
            set retval "0x$retval"
            if { $enable == 1 } {
                # Turn on "force_sig_detect" bit, ensure invalid bit is cleared. Bits [3:2]
                set retval [expr {$retval | 0x00000008}]
                set retval [expr {$retval & 0xfffffffb}]
            } else {
                set retval [expr {$retval & 0xfffffff7}]
            }

            # Format back to hex.
            set retval [format %X $retval]
            ac7t1500::csr_write_named  CSR_SPACE $target $quad RX_SIGNAL_DETECT_REG3_$ch $retval
        }

        if { $enable == 1 } {
            puts "Set rx_sig_det_reg3\[force_valid_a\] for $target $quad all channels"
        } else {
            puts "Cleared rx_sig_det_reg3\[force_valid_a\] for $target $quad all channels"
        }

    }

    # ---------------------------------------------------------------------
    # Set serdes near-end serial loopback
    # ---------------------------------------------------------------------
    proc nes_loopback { target quad enable { acx_pcs_ovr 0} } {

        # ENHANCE : Currently function just sets the loopback
        # Once register defaults established, then also add in the ability
        # to clear the defaults

        # From AW app note, for Near-end serial loopback
        # To program through registers:
        # isolate front end from external signal
        #   rx_adapt_vga_offset_ctle[isolate_a] = 1
        # set loopback path
        #   loopback_cntrl[rx_nes_loopback_ena_nt] = 1
        #   loopback_cntrl[tx_nes_loopback_ena_nt] = 1
        #   loopback_cntrl[ena_nt] = 1
        # in case the firmware overrides the default values,
        #   rx_signal_detect_reg3[valid_ctrl_nt] = 6
        #   rx_signal_detect_reg3[invalid_ctrl_nt] = 6
        #
        # To program through control pins:
        #   ictl_loopback_req_ln = 1
        #   ictl_loopback_type_ln = 2’b01
        #   wait for octl_loopback_ack_ln = 1

        # Within a Quad set all 4 Serdes lanes to be the same
        for {set ch 0} {$ch < 4} {incr ch} {

            # Isolate front-end from external signal
            set retval [ac7t1500::csr_read_named CSR_SPACE $target $quad RX_ADAPT_VGA_OFFSET_CTLE_$ch 0x2]
            # Value read back is hex
            set retval "0x$retval"
            if { $enable == 1 } {
                # Set bit[0], isolate_a
                set retval [expr {$retval | 0x1}]
            } else {
                # Clear bit[0], isolate_a
                set retval [expr {$retval & 0xfffffffe}]
            }
            # Format result back to hex
            set retval [format %X $retval]
            ac7t1500::csr_write_named  CSR_SPACE $target $quad RX_ADAPT_VGA_OFFSET_CTLE_$ch $retval
            ac7t1500::csr_verify_named CSR_SPACE $target $quad RX_ADAPT_VGA_OFFSET_CTLE_$ch $retval
            unset retval

            # Set the rxmfsm_scratch_reg11 bit[0] 
            ac7t1500::csr_set_bits_named CSR_SPACE $target $quad RXMFSM_SCRATCH_REG11_$ch 0 0
      
            # Programme loopback_cntrl
            # puts "loopback cntrl"
            set retval [ac7t1500::csr_read_named CSR_SPACE $target $quad LOOPBACK_CNTRL_$ch 0x0]
            # Value read back is hex
            set retval "0x$retval"
            if { $enable == 1 } {
                # Set bit[5], rx_nes_loopback_ena_nt
                set retval [expr {$retval | 0x20}]
                # Set bit[2], tx_nes_loopback_ena_nt
                set retval [expr {$retval | 0x04}]
                # Set bit[6], ena_nt
                set retval [expr {$retval | 0x40}]
            } else {
                # Clear bit[5], rx_nes_loopback_ena_nt
                set retval [expr {$retval & 0xffffffdf}]
                # Clear bit[2], tx_nes_loopback_ena_nt
                set retval [expr {$retval & 0xfffffffb}]
                # Clear bit[6], ena_nt
                set retval [expr {$retval & 0xffffffbf}]
            }

            # Format result back to hex
            set retval [format %X $retval]

            ac7t1500::csr_write_named  CSR_SPACE $target $quad LOOPBACK_CNTRL_$ch $retval
            ac7t1500::csr_verify_named CSR_SPACE $target $quad LOOPBACK_CNTRL_$ch $retval
            unset retval

            # puts "rx sig det3"
            # Programme rx_signal_detect_reg3
            set retval [ac7t1500::csr_read_named CSR_SPACE $target $quad RX_SIGNAL_DETECT_REG3_$ch 0x66b3]
            # Value read back is hex
            set retval "0x$retval"
            if { $enable == 1 } {
                # Set to the register default of 0x660
                # Would need to store the previous value if we were to restore this
                # to whatever was programmed originally.
                # Set bits[6:4], valid_ctrl_nt
                # Set bits[12:8], invalid_ctrl_nt
                set retval [expr {$retval | 0x00000660}]
                set retval [expr {$retval & 0xffffe66f}]
            }

            # Format result back to hex
            set retval [format %X $retval]
            ac7t1500::csr_write_named  CSR_SPACE $target $quad RX_SIGNAL_DETECT_REG3_$ch $retval
            ac7t1500::csr_verify_named CSR_SPACE $target $quad RX_SIGNAL_DETECT_REG3_$ch $retval
            unset retval

        }

        if { $enable == 1 } {
            puts "Set serdes near-end serial loopback for $target $quad all channels"
        } else {
            puts "Cleared serdes near-end serial loopback for $target $quad all channels"
        }

        # As an experiment set an override in the ACX PCS signals as well to force 
        # RX signal_detect and data_valid to be asserted
        if { $acx_pcs_ovr == 1 } {
            override_acx_pcs_valid_det $target $quad $enable
        }


    }

    # --------------------------------------------------------------------------
    # AW functions to enable high-speed clock sharing across two quads
    # --------------------------------------------------------------------------
    proc hs_clk_sharing {target} {

        # Note : aw_lib is built into ACE 8.8 onwards.

        foreach ip { SERDES_0 SERDES_1 } {
            aw_lib::write_field CSR_SPACE $target $ip {} pd_afe_cmn hsrefbuf_ba 1
            if { $ip == "SERDES_0" } {
                # Transmit HSREF from Q0 --> Q1
                aw_lib::write_field CSR_SPACE $target $ip {} cmn_refclk l2r_hsref_select_nt 3
                aw_lib::write_field CSR_SPACE $target $ip {} cmn_refclk hsrefbuf_bias_adj_nt 1
            } else {
                # Buffer HSREF from Q(n-1) --> Q(n+1)
                aw_lib::write_field CSR_SPACE $target $ip {} cmn_refclk l2r_hsref_select_nt 1
                aw_lib::write_field CSR_SPACE $target $ip {} cmn_refclk hsrefbuf_bias_adj_nt 1
            }
        }
        
        foreach ip { SERDES_0 SERDES_1 } {
            if { $ip == "SERDES_0" } {
                foreach lane { 0 1 2 3 } {
                    # Leave as is (local hsref)
                    aw_lib::write_field CSR_SPACE $target $ip $lane tx_hsrefmux sel_nt 0
                }
            } else {
                foreach lane { 0 1 2 3 } {
                    # Use the Buffered L2R Clock
                    aw_lib::write_field CSR_SPACE $target $ip $lane tx_hsrefmux sel_nt 3 
                }
            }
        }
    }
  

    # --------------------------------------------------------------------------
    # Link training functions
    # --------------------------------------------------------------------------
    # To support individual lane LT, this routine takes lists of targets, serdes and lanes
    # It then applies training only to those instances.
    proc link_training { target_list quad_list lane_list {verbose 0} {debug 0}} {

        # Link training steps, (detailed in code comments)
        # 1. Set the PMA to hijack the pin controls for the LT block (isolation mode)
        # 2. Set the LT configuration
        # 3. Run LT on each Serdes/Lane
        # 4. Wait for LT to complete

        # Calculate the rate, width and clause by reading the serdes register
        # Expected values
        # set rate_num 1;#0:106G,1:53G,3:25G,4:10G
        # set width 6;   #7:106G,6:53G,4:25G,4:10G
        # set clause 3;  #4:106G,3:53G,2:25G,1:10G
        #1. Configure LT
        foreach target $target_list {
            foreach quad $quad_list {
                foreach lane $lane_list {
                    # Determine LT parameters by reading current Serdes configuration
                    set rate_num [aw_lib::read_field CSR_SPACE $target $quad $lane \
                                                     rxmfsm_stat rxmfsm_rate_cur];
                    set width    [aw_lib::read_field CSR_SPACE $target $quad $lane \
                                                     rxmfsm_stat rxmfsm_width_cur];
                    # 106 & 53G are PAM-4, other rates are NRZ.  For all the NRZ rates, use the 25G clause.
                    if { $rate_num < 2 } {
                        set clause 3;  #3:PAM,2:NRZ,1:NRZ
                    } else {
                        set clause 2;  #3:PAM,2:NRZ,1:NRZ
                    }
                    if { $verbose } {
                        message -info "Link training configured for $target, $quad, $lane with settings rate = $rate_num : width = $width : clause = $clause"
                    }

                    # 1. Re-initialise the Serdes in isolation mode to run LT
                    # This is required as ACE powers up the lanes as soon as the bitstream is loaded
                    # Disable EQBK to prevent glitches when switching to LT
                    aw_lib::write_reg_offset CSR_SPACE $target $quad $lane rxmfsm_scratch_reg7 0 27 1
                    # Enable isolation mode
                    aw_lib::tx_reset_set CSR_SPACE $target $quad $lane 1
                    aw_lib::rx_reset_set CSR_SPACE $target $quad $lane 1
                    aw_lib::lane_isolate_set CSR_SPACE $target $quad $lane 1
                    # Power Up Tx/Rx in isolation mode
                    aw_lib::tx_state_req_set CSR_SPACE $target $quad $lane 0 $rate_num $width
                    aw_lib::rx_state_req_set CSR_SPACE $target $quad $lane 0 $rate_num $width
                    # Turn of the automatic gray-coding. LT should negotiate this on it's own
                    aw_lib::write_field CSR_SPACE $target $quad $lane txmfsm_scratch_reg1 txmfsm_scratch1 0
                    aw_lib::write_field CSR_SPACE $target $quad $lane rxmfsm_scratch_reg4 rxmfsm_scratch4 0
                    aw_lib::write_field CSR_SPACE $target $quad $lane rx_cntrl_reg2 rx_gray_ena_nt 0
                    aw_lib::write_field CSR_SPACE $target $quad $lane tx_datapath_reg2 pamcode_ovr_en_a 0
                    # Disable PRBS based RxEQ
                    aw_lib::write_reg_offset CSR_SPACE $target $quad $lane rxmfsm_scratch_reg12 0 24 1

                    # 2. Configure link training
                    aw_lib::anlt_link_training_en_set CSR_SPACE $target $quad $lane 1
                    aw_lib::anlt_logical_lane_num_set CSR_SPACE $target $quad $lane 0 1
                    aw_lib::anlt_link_training_without_an_config CSR_SPACE $target $quad $lane $width $clause
                }
            }
        }

        #3. Start LT
        foreach target $target_list {
            foreach quad $quad_list {
                foreach lane $lane_list {
                    aw_lib::anlt_link_training_start_set CSR_SPACE $target $quad $lane 1
                }
            }
        }

        #4. Wait for LT
        set lane_fail 0
        foreach target $target_list {
            foreach quad $quad_list {
                foreach lane $lane_list {
                    if {$verbose} { 
                        message -info "Waiting for LT Done for $target, $quad, lane $lane"
                    }
                    set done [aw_lib::poll_field CSR_SPACE $target $quad $lane \
                                                           eth_anlt_status lt_done 10000 1]
                    set lt_failed [aw_lib::read_field CSR_SPACE $target $quad $lane \
                                                     eth_lt_stat lt_training_failure];
                    if {$verbose} { 
                        message -info "Link training done = $done"
                    }
                    if { $debug } {
                        aw_lib::anlt_link_training_status_get CSR_SPACE $target $quad $lane
                        message -info  "Final TXFIR: [aw_lib::tx_fir_get CSR_SPACE $target $quad $lane]"
                    }
                    # Once LT is complete, release the Serdes from isolation mode
                    aw_lib::lane_isolate_set CSR_SPACE $target $quad $lane 0
                    # Enable PRBS based RxEQ
                    aw_lib::write_reg_offset CSR_SPACE $target $quad $lane rxmfsm_scratch_reg12 1 24 1

                    if { !$done } {incr lane_fail -1}
                    if { $lt_failed } {incr lane_fail -1}
                }
            }
        }

        return $lane_fail
    }


# Close the namespace
}
# ---------------------------------------------------------------------
# ---------------------------------------------------------------------
