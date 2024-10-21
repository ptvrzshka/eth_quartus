module top_module
(
		
		input  wire        clk_clk,                                     //                                   clk.clk
		output wire        eth_tse_0_mac_mdio_connection_mdc,           //         eth_tse_0_mac_mdio_connection.mdc
		inout  wire        eth_tse_0_mac_mdio_connection_mdio_inout,       //                                     


		input  wire [3:0]  eth_tse_0_mac_rgmii_connection_rgmii_in,     //        eth_tse_0_mac_rgmii_connection.rgmii_in
		output wire [3:0]  eth_tse_0_mac_rgmii_connection_rgmii_out,    //     
		
		input  wire        eth_tse_0_mac_rgmii_connection_rx_control,   //                                      .rx_control
		output wire        eth_tse_0_mac_rgmii_connection_tx_control,   //                                      .tx_control

		input  wire        eth_tse_0_pcs_mac_rx_clock_connection_clk,   // eth_tse_0_pcs_mac_rx_clock_connection.clk
		output wire 		 GTX_CLK,
		
		
		output wire [3:0] test



);

assign test[0] = irq_eth_input_export;
assign eth_tse_0_mac_mdio_connection_mdio_in = eth_tse_0_mac_mdio_connection_mdio_inout;
assign eth_tse_0_mac_mdio_connection_mdio_inout = eth_tse_0_mac_mdio_connection_mdio_oen ? 1'hz : eth_tse_0_mac_mdio_connection_mdio_out;

enet_pll enet_pll 
(

	clk_clk,
	eth_tse_0_pcs_mac_tx_clock_connection_clk,
	GTX_CLK
	
);


eth_nios_v2 eth_nios_v2 
( 
		.clk_clk														(GTX_CLK),                                     //                                   clk.clk
		.eth_tse_0_mac_mdio_connection_mdc					(eth_tse_0_mac_mdio_connection_mdc),           //         eth_tse_0_mac_mdio_connection.mdc
		.eth_tse_0_mac_mdio_connection_mdio_in				(eth_tse_0_mac_mdio_connection_mdio_in),       //                                      .mdio_in
		.eth_tse_0_mac_mdio_connection_mdio_out			(eth_tse_0_mac_mdio_connection_mdio_out),      //                                      .mdio_out
		.eth_tse_0_mac_mdio_connection_mdio_oen			(eth_tse_0_mac_mdio_connection_mdio_oen),      //                                      .mdio_oen
		.eth_tse_0_mac_rgmii_connection_rgmii_in			(eth_tse_0_mac_rgmii_connection_rgmii_in),     //        eth_tse_0_mac_rgmii_connection.rgmii_in
		.eth_tse_0_mac_rgmii_connection_rgmii_out			(eth_tse_0_mac_rgmii_connection_rgmii_out),    //                                      .rgmii_out
		.eth_tse_0_mac_rgmii_connection_rx_control		(eth_tse_0_mac_rgmii_connection_rx_control),   //                                      .rx_control
		.eth_tse_0_mac_rgmii_connection_tx_control		(eth_tse_0_mac_rgmii_connection_tx_control),   //                                      .tx_control
		.eth_tse_0_pcs_mac_rx_clock_connection_clk		(eth_tse_0_pcs_mac_rx_clock_connection_clk),   // eth_tse_0_pcs_mac_rx_clock_connection.clk
		.eth_tse_0_pcs_mac_tx_clock_connection_clk		(eth_tse_0_pcs_mac_tx_clock_connection_clk),   // eth_tse_0_pcs_mac_tx_clock_connection.clk
		.irq_eth_input_export									(irq_eth_input_export)

	);
	
	
test_data_generator test_data_generator
(
	.clk_clk															(clk_clk),
	.eth_packet_ready												(irq_eth_input_export)
);






	
	
endmodule

