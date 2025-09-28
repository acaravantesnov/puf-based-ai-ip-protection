# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "g_axi_reg_width" -parent ${Page_0}
  ipgui::add_param $IPINST -name "g_clk_freq" -parent ${Page_0}
  ipgui::add_param $IPINST -name "g_lfsr_polynomial" -parent ${Page_0}
  ipgui::add_param $IPINST -name "g_n_ROs_main" -parent ${Page_0}
  ipgui::add_param $IPINST -name "g_n_inverters_lfsr" -parent ${Page_0}
  ipgui::add_param $IPINST -name "g_n_inverters_main" -parent ${Page_0}
  ipgui::add_param $IPINST -name "g_reset_polarity" -parent ${Page_0}
  ipgui::add_param $IPINST -name "g_response_width" -parent ${Page_0}
  ipgui::add_param $IPINST -name "g_timer_comparator_eoc" -parent ${Page_0}
  ipgui::add_param $IPINST -name "g_timer_lfsr_seed_eoc" -parent ${Page_0}


}

proc update_PARAM_VALUE.g_axi_reg_width { PARAM_VALUE.g_axi_reg_width } {
	# Procedure called to update g_axi_reg_width when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.g_axi_reg_width { PARAM_VALUE.g_axi_reg_width } {
	# Procedure called to validate g_axi_reg_width
	return true
}

proc update_PARAM_VALUE.g_clk_freq { PARAM_VALUE.g_clk_freq } {
	# Procedure called to update g_clk_freq when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.g_clk_freq { PARAM_VALUE.g_clk_freq } {
	# Procedure called to validate g_clk_freq
	return true
}

proc update_PARAM_VALUE.g_lfsr_polynomial { PARAM_VALUE.g_lfsr_polynomial } {
	# Procedure called to update g_lfsr_polynomial when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.g_lfsr_polynomial { PARAM_VALUE.g_lfsr_polynomial } {
	# Procedure called to validate g_lfsr_polynomial
	return true
}

proc update_PARAM_VALUE.g_n_ROs_main { PARAM_VALUE.g_n_ROs_main } {
	# Procedure called to update g_n_ROs_main when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.g_n_ROs_main { PARAM_VALUE.g_n_ROs_main } {
	# Procedure called to validate g_n_ROs_main
	return true
}

proc update_PARAM_VALUE.g_n_inverters_lfsr { PARAM_VALUE.g_n_inverters_lfsr } {
	# Procedure called to update g_n_inverters_lfsr when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.g_n_inverters_lfsr { PARAM_VALUE.g_n_inverters_lfsr } {
	# Procedure called to validate g_n_inverters_lfsr
	return true
}

proc update_PARAM_VALUE.g_n_inverters_main { PARAM_VALUE.g_n_inverters_main } {
	# Procedure called to update g_n_inverters_main when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.g_n_inverters_main { PARAM_VALUE.g_n_inverters_main } {
	# Procedure called to validate g_n_inverters_main
	return true
}

proc update_PARAM_VALUE.g_reset_polarity { PARAM_VALUE.g_reset_polarity } {
	# Procedure called to update g_reset_polarity when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.g_reset_polarity { PARAM_VALUE.g_reset_polarity } {
	# Procedure called to validate g_reset_polarity
	return true
}

proc update_PARAM_VALUE.g_response_width { PARAM_VALUE.g_response_width } {
	# Procedure called to update g_response_width when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.g_response_width { PARAM_VALUE.g_response_width } {
	# Procedure called to validate g_response_width
	return true
}

proc update_PARAM_VALUE.g_timer_comparator_eoc { PARAM_VALUE.g_timer_comparator_eoc } {
	# Procedure called to update g_timer_comparator_eoc when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.g_timer_comparator_eoc { PARAM_VALUE.g_timer_comparator_eoc } {
	# Procedure called to validate g_timer_comparator_eoc
	return true
}

proc update_PARAM_VALUE.g_timer_lfsr_seed_eoc { PARAM_VALUE.g_timer_lfsr_seed_eoc } {
	# Procedure called to update g_timer_lfsr_seed_eoc when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.g_timer_lfsr_seed_eoc { PARAM_VALUE.g_timer_lfsr_seed_eoc } {
	# Procedure called to validate g_timer_lfsr_seed_eoc
	return true
}


proc update_MODELPARAM_VALUE.g_timer_lfsr_seed_eoc { MODELPARAM_VALUE.g_timer_lfsr_seed_eoc PARAM_VALUE.g_timer_lfsr_seed_eoc } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.g_timer_lfsr_seed_eoc}] ${MODELPARAM_VALUE.g_timer_lfsr_seed_eoc}
}

proc update_MODELPARAM_VALUE.g_timer_comparator_eoc { MODELPARAM_VALUE.g_timer_comparator_eoc PARAM_VALUE.g_timer_comparator_eoc } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.g_timer_comparator_eoc}] ${MODELPARAM_VALUE.g_timer_comparator_eoc}
}

proc update_MODELPARAM_VALUE.g_clk_freq { MODELPARAM_VALUE.g_clk_freq PARAM_VALUE.g_clk_freq } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.g_clk_freq}] ${MODELPARAM_VALUE.g_clk_freq}
}

proc update_MODELPARAM_VALUE.g_n_inverters_main { MODELPARAM_VALUE.g_n_inverters_main PARAM_VALUE.g_n_inverters_main } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.g_n_inverters_main}] ${MODELPARAM_VALUE.g_n_inverters_main}
}

proc update_MODELPARAM_VALUE.g_n_ROs_main { MODELPARAM_VALUE.g_n_ROs_main PARAM_VALUE.g_n_ROs_main } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.g_n_ROs_main}] ${MODELPARAM_VALUE.g_n_ROs_main}
}

proc update_MODELPARAM_VALUE.g_n_inverters_lfsr { MODELPARAM_VALUE.g_n_inverters_lfsr PARAM_VALUE.g_n_inverters_lfsr } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.g_n_inverters_lfsr}] ${MODELPARAM_VALUE.g_n_inverters_lfsr}
}

proc update_MODELPARAM_VALUE.g_lfsr_polynomial { MODELPARAM_VALUE.g_lfsr_polynomial PARAM_VALUE.g_lfsr_polynomial } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.g_lfsr_polynomial}] ${MODELPARAM_VALUE.g_lfsr_polynomial}
}

proc update_MODELPARAM_VALUE.g_response_width { MODELPARAM_VALUE.g_response_width PARAM_VALUE.g_response_width } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.g_response_width}] ${MODELPARAM_VALUE.g_response_width}
}

proc update_MODELPARAM_VALUE.g_reset_polarity { MODELPARAM_VALUE.g_reset_polarity PARAM_VALUE.g_reset_polarity } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.g_reset_polarity}] ${MODELPARAM_VALUE.g_reset_polarity}
}

proc update_MODELPARAM_VALUE.g_axi_reg_width { MODELPARAM_VALUE.g_axi_reg_width PARAM_VALUE.g_axi_reg_width } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.g_axi_reg_width}] ${MODELPARAM_VALUE.g_axi_reg_width}
}

