# ---------------------------------------------------------------------------
# XDC Constraints for GPIO Interface
#
# Maps the external GPIO_0 port to the PYNQ-Z2 Arduino Header pins.
# The I/O standard for these pins is LVCMOS33.
# ---------------------------------------------------------------------------

# === PS to PL Outputs ===

## Python Pin 0 (ack_to_pl) -> GPIO Bit 0
set_property -dict { PACKAGE_PIN Y16   IOSTANDARD LVCMOS33 } [get_ports { GPIO_0_0_tri_t[0] }];

## Python Pin 1 (reset_n) -> GPIO Bit 1
set_property -dict { PACKAGE_PIN Y17   IOSTANDARD LVCMOS33 } [get_ports { GPIO_0_0_tri_t[1] }];

## Python Pin 2 (enable) -> GPIO Bit 2
set_property -dict { PACKAGE_PIN Y18   IOSTANDARD LVCMOS33 } [get_ports { GPIO_0_0_tri_t[2] }];


# === PL to PS Inputs ===

## Python Pin 3 (response[0]) -> GPIO Bit 3
set_property -dict { PACKAGE_PIN Y19   IOSTANDARD LVCMOS33 } [get_ports { GPIO_0_0_tri_t[3] }];

## Python Pin 4 (response[1]) -> GPIO Bit 4
set_property -dict { PACKAGE_PIN U18   IOSTANDARD LVCMOS33 } [get_ports { GPIO_0_0_tri_t[4] }];

## Python Pin 5 (response[2]) -> GPIO Bit 5
set_property -dict { PACKAGE_PIN U19   IOSTANDARD LVCMOS33 } [get_ports { GPIO_0_0_tri_t[5] }];

## Python Pin 6 (response[3]) -> GPIO Bit 6
set_property -dict { PACKAGE_PIN W18   IOSTANDARD LVCMOS33 } [get_ports { GPIO_0_0_tri_t[6] }];

## Python Pin 7 (response[4]) -> GPIO Bit 7
set_property -dict { PACKAGE_PIN W19   IOSTANDARD LVCMOS33 } [get_ports { GPIO_0_0_tri_t[7] }];

## Python Pin 8 (response[5]) -> GPIO Bit 8
set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33 } [get_ports { GPIO_0_0_tri_t[8] }];

## Python Pin 9 (response[6]) -> GPIO Bit 9
set_property -dict { PACKAGE_PIN W16   IOSTANDARD LVCMOS33 } [get_ports { GPIO_0_0_tri_t[9] }];

## Python Pin 10 (response[7]) -> GPIO Bit 10
set_property -dict { PACKAGE_PIN W14   IOSTANDARD LVCMOS33 } [get_ports { GPIO_0_0_tri_t[10] }];

## Python Pin 11 (ready_to_ps) -> GPIO Bit 11
set_property -dict { PACKAGE_PIN Y14   IOSTANDARD LVCMOS33 } [get_ports { GPIO_0_0_tri_t[11] }];

## Python Pin 12 (sampled_counters_ready_lfsr) -> GPIO Bit 12
set_property -dict { PACKAGE_PIN T11   IOSTANDARD LVCMOS33 } [get_ports { GPIO_0_0_tri_t[12] }];
