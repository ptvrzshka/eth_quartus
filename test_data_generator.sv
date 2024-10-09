module test_data_generator
(
	input clk_clk,
	output reg eth_packet_ready
);


reg [26:0] test_counter;

always @(posedge clk_clk)
begin
	if (test_counter <= 16000) test_counter <= test_counter + 1;
	else test_counter <= 0;
	
	if (test_counter >= 16000 - 8000) eth_packet_ready <= 1'b1;
	else eth_packet_ready <= 1'b0;
end


endmodule
