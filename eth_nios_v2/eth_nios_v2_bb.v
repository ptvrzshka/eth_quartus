
module eth_nios_v2 (
	clk_clk,
	eth_tse_0_mac_mdio_connection_mdc,
	eth_tse_0_mac_mdio_connection_mdio_in,
	eth_tse_0_mac_mdio_connection_mdio_out,
	eth_tse_0_mac_mdio_connection_mdio_oen,
	eth_tse_0_mac_misc_connection_magic_wakeup,
	eth_tse_0_mac_misc_connection_magic_sleep_n,
	eth_tse_0_mac_misc_connection_ff_tx_crc_fwd,
	eth_tse_0_mac_misc_connection_ff_tx_septy,
	eth_tse_0_mac_misc_connection_tx_ff_uflow,
	eth_tse_0_mac_misc_connection_ff_tx_a_full,
	eth_tse_0_mac_misc_connection_ff_tx_a_empty,
	eth_tse_0_mac_misc_connection_rx_err_stat,
	eth_tse_0_mac_misc_connection_rx_frm_type,
	eth_tse_0_mac_misc_connection_ff_rx_dsav,
	eth_tse_0_mac_misc_connection_ff_rx_a_full,
	eth_tse_0_mac_misc_connection_ff_rx_a_empty,
	eth_tse_0_mac_rgmii_connection_rgmii_in,
	eth_tse_0_mac_rgmii_connection_rgmii_out,
	eth_tse_0_mac_rgmii_connection_rx_control,
	eth_tse_0_mac_rgmii_connection_tx_control,
	eth_tse_0_mac_status_connection_set_10,
	eth_tse_0_mac_status_connection_set_1000,
	eth_tse_0_mac_status_connection_eth_mode,
	eth_tse_0_mac_status_connection_ena_10,
	eth_tse_0_pcs_mac_rx_clock_connection_clk,
	eth_tse_0_pcs_mac_tx_clock_connection_clk,
	rx_tx_buf_clk2_clk,
	rx_tx_buf_reset2_reset,
	rx_tx_buf_reset2_reset_req,
	rx_tx_buf_s2_address,
	rx_tx_buf_s2_chipselect,
	rx_tx_buf_s2_clken,
	rx_tx_buf_s2_write,
	rx_tx_buf_s2_readdata,
	rx_tx_buf_s2_writedata);	

	input		clk_clk;
	output		eth_tse_0_mac_mdio_connection_mdc;
	input		eth_tse_0_mac_mdio_connection_mdio_in;
	output		eth_tse_0_mac_mdio_connection_mdio_out;
	output		eth_tse_0_mac_mdio_connection_mdio_oen;
	output		eth_tse_0_mac_misc_connection_magic_wakeup;
	input		eth_tse_0_mac_misc_connection_magic_sleep_n;
	input		eth_tse_0_mac_misc_connection_ff_tx_crc_fwd;
	output		eth_tse_0_mac_misc_connection_ff_tx_septy;
	output		eth_tse_0_mac_misc_connection_tx_ff_uflow;
	output		eth_tse_0_mac_misc_connection_ff_tx_a_full;
	output		eth_tse_0_mac_misc_connection_ff_tx_a_empty;
	output	[17:0]	eth_tse_0_mac_misc_connection_rx_err_stat;
	output	[3:0]	eth_tse_0_mac_misc_connection_rx_frm_type;
	output		eth_tse_0_mac_misc_connection_ff_rx_dsav;
	output		eth_tse_0_mac_misc_connection_ff_rx_a_full;
	output		eth_tse_0_mac_misc_connection_ff_rx_a_empty;
	input	[3:0]	eth_tse_0_mac_rgmii_connection_rgmii_in;
	output	[3:0]	eth_tse_0_mac_rgmii_connection_rgmii_out;
	input		eth_tse_0_mac_rgmii_connection_rx_control;
	output		eth_tse_0_mac_rgmii_connection_tx_control;
	input		eth_tse_0_mac_status_connection_set_10;
	input		eth_tse_0_mac_status_connection_set_1000;
	output		eth_tse_0_mac_status_connection_eth_mode;
	output		eth_tse_0_mac_status_connection_ena_10;
	input		eth_tse_0_pcs_mac_rx_clock_connection_clk;
	input		eth_tse_0_pcs_mac_tx_clock_connection_clk;
	input		rx_tx_buf_clk2_clk;
	input		rx_tx_buf_reset2_reset;
	input		rx_tx_buf_reset2_reset_req;
	input	[10:0]	rx_tx_buf_s2_address;
	input		rx_tx_buf_s2_chipselect;
	input		rx_tx_buf_s2_clken;
	input		rx_tx_buf_s2_write;
	output	[7:0]	rx_tx_buf_s2_readdata;
	input	[7:0]	rx_tx_buf_s2_writedata;
endmodule
