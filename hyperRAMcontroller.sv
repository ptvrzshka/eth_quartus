module hyperRAMcontroller
(
	input 		clk_50,
	
	inout [7:0] RamChipData,					///////////////////////////
	inout 		RamChipRwds,					///////////////////////////
														///////////////////////////
	output 		RamChipClk,						///  Chip Connections   ///
	output 		RamChipClkInv,					///////////////////////////		
	output		RamChipRestN,					///////////////////////////
	output		RamChipChipSelect,			///////////////////////////
	
	
	input [7:0] RamDataToWrite,
	input 		clkData,
	
	
	
	
	input [22:0] RamAdrInput,					// RAM adress input 
	input [10:0] RamTransactionLengInput,	// RAM trasnfer length
	input RamReadWriteFlagInput,				// RAM read or write mode
	input RamSeqclock,							// RAM queue write sync
	
	
	output reg [23:0] RamAdrOutput,			//output information about actual transaction Adress
	output reg RamReadWriteFlagOutput,		//output information about actual transaction Read/write flag
	output wire transferingStatus,			//output information about actual transaction Transfer status
	
	
	output [7:0] RamDataOutRead,				//read fifo output
	input RamFifoReadReadReqR,					//read fifo read req
	
	
	input [7:0] RamDataToWriteW,				//write fifo input
	input RamFifoWriteReqW						//write fifo write req
);



reg [35:0] RamControlSeqRegister;

always @(posedge clk_50)													
if (RamSeqclock)
begin
	RamControlSeqRegister[0] <= RamReadWriteFlagInput;
	RamControlSeqRegister[23:1] <= RamAdrInput[22:0];
	RamControlSeqRegister[35:24] <= RamTransactionLengInput[10:0];
end

reg RamControlSeqFifoClock;
always @(posedge clk_50) RamControlSeqFifoClock <= RamSeqclock; 			//Create delayed sync signal for fifo writet request



reg RamControlSeqWrReq;
always @(negedge clk_50) 																//Create RS - trigger for  fifo write request
	if (RamSeqclock) RamControlSeqWrReq <= 1'b1;
	else if (RamControlSeqFifoClock) RamControlSeqWrReq <= 1'b0;
	

reg RamControlFifoReadReq;
reg RamControlFifoReadClock;
wire [35:0] RamControlSeqRegisteOutput;


RamControlSeqFifo RamControlSeqFifo 
(
	.data								(RamControlSeqRegister[35:0]),
	.rdclk							(RamControlFifoReadClock),
	.rdreq							(RamControlFifoReadReq),
	.wrclk							(RamControlSeqFifoClock),
	.wrreq							(RamControlSeqWrReq),
	.q									(RamControlSeqRegisteOutput[35:0]),
	.rdempty							(RamControlFifoEmpty)
);


reg [7:0] RamTrasferFSM;
reg [7:0] nextState;
reg [10:0] RamBytesToTransfer;
reg [47:0] RamControlRegister;




reg RamFifoWriteReqR;


//always_ff@(posedge RamClock200 or posedge RamFlagTrasferEnd)
//begin
//	if(RamFlagTrasferEnd)
//		RamTrasferFSM <= 0;
//	else
//		RamTrasferFSM <= nextState;
//end
//
//always_comb
//begin
//	case(RamTrasferFSM)
//		0:
//			begin
//				if(flag)
//					nextState = 1;
//			end
//	endcase
//end
//
//always_ff@(negedge slow_clk or negedge reset)
//	case(state)
//		0:
//	endcase


always @(posedge clk_50 or posedge RamFlagTrasferEnd)

if (RamFlagTrasferEnd)
begin

	RamTrasferFSM <= 8'h0;
	RamFifoReadReqW <= 1'b0;
	RamFifoWriteReqR <= 1'b0;
	RamEnable <= 1'b0;
	
end

else begin
	case (RamTrasferFSM)
	
		8'h0:	if (!RamControlFifoEmpty) RamTrasferFSM <= 8'h1;			//IDLE state
		
		8'h1:																				//if ram queue is not empty generate fifo sync signals
		begin		
			RamControlFifoReadReq <= 1'b1;
			if (RamControlFifoReadReq) 
			begin
				RamControlFifoReadClock <= 1'b1;
				RamTrasferFSM <= 8'h2;
				
			end
		end
		
		
		8'h2:	
		begin
			RamControlFifoReadReq <= 1'b0;
			RamControlFifoReadClock <= 1'b0;
			RamTrasferFSM <= 8'h3;
		end
		
		
		8'h3:																					//Control register settings
		begin
			RamBytesToTransfer[10:0] <= RamControlSeqRegisteOutput[35:25];						
			
			RamControlRegister[47] <= RamControlSeqRegisteOutput[0];			//1 - a read transaction  0 - a write transaction
			RamControlRegister[46] <= 1'b0;											//0 - memory space, 1 - control register space
			RamControlRegister[45] <= 1'b0;											//0 - wrapped burst, 1 - linear burst
			RamControlRegister[44:36] <= 9'h00;										//not used adress space
			RamControlRegister[35:16] <= RamControlSeqRegisteOutput[23:4];	//high adress space
			RamControlRegister[15:3] <= 13'h00;										//reserverd set to 0
			RamControlRegister[2:0] <= RamControlSeqRegisteOutput[3:1];		//low adress space
			
			RamRWmode <= RamControlSeqRegisteOutput[0];
			
			
			RamAdrOutput[22:0] <= RamControlSeqRegisteOutput[23:1];			//output information about actual transaction
			RamReadWriteFlagOutput <= RamControlSeqRegisteOutput[0];			//output information about actual transaction
			
			
			
			RamTrasferFSM <= 8'h4;
			
		end
		
		8'h4:																					//waiting for transfer control end and a latancy end
		begin
			RamEnable <= 1'b1;
			if (RamFlagSetupDone) RamTrasferFSM <= 8'h5;
		end
		
		8'h5:
		begin
			if (RamControlSeqRegisteOutput[0])										//if transaction type is read from RAM, up read fifo write request
				begin
					RamFifoWriteReqR <= 1'b1;
					RamFifoReadReqW <= 1'b0;	
				end
			else 																				//if transaction type is write to RAM, up write fifo read request
				begin
					RamFifoWriteReqR <= 1'b0;
					RamFifoReadReqW <= 1'b1;	
				end												
		
			RamTrasferFSM <= 8'h6;
		end
		
	
		8'h6:																					//we can write error handler here, now that module doing bothing))
		if (!RamFlagDataTransfewring)
			RamTrasferFSM <= 8'h0;
			
		default: RamTrasferFSM <= 8'h0;
		
	endcase
end


assign transferingStatus = RamFlagDataTransfewring;

wire [7:0] RamDataIn;

HyperRamFifo HyperRamFifoRead
(	
	.data									(RamDataIn[7:0]),
	.wrclk								(RamClock400),
	.wrreq								(RamFifoWriteReqR),

	.q										(RamDataOutRead[7:0]),
	.rdclk								(clkData),
	.rdreq								(RamFifoReadReadReqR),

	.aclr									(RamClr)

);


wire [7:0] RamDataOutR;

HyperRamFifo HyperRamFifoWrite 
(	
	.data									(RamDataToWriteW[7:0]),
	.wrclk								(clkData),
	.wrreq								(RamFifoWriteReqW),

	.rdclk								(clkData),
	.rdreq								(RamFifoReadReqW),
	.q										(RamDataOutR[7:0]),

	.aclr									(RamClr)

);


hyperRamDriver hyperRamDriver
(


	.enable								(RamEnable),								//Modul's enable
	.clock200							(RamClock200), 
	.clock200shifted					(RamClock200Shifted), 
	.clock400							(RamClock400),
	.rwMode								(RamRWmode),								//Choose read or write mode
	.dataFromFifo						(RamDataOutR[7:0]),						//Input data
	.caInfo								(RamControlRegister[47:0]),			//RAM settings register
	.bytesToTransfer					(RamBytesToTransfer[10:0]),			//How many bytes module will trasnfer, 1280 max
	.dataToFifo							(RamDataIn[7:0]),							//Output data

	.toRamData							(RamChipData[7:0]),						//data connected to chip
	.rwds									(RamChipRwds),								//rwds connected to chip

	.toRamCk								(RamChipClk),								//clock connected to chip (pos in ddr mode)
	.toRamCkInv							(RamChipClkInv),							//clock connected to chip (neg in ddr mode, in common mode is not connected)
	.toRamNrst							(RamChipRestN),							//chip reset
	.toRamCs								(RamChipChipSelect),						//chip chip select

	.csDone								(RamFlagCsDone),							//chip select signal ended, chip ready to config
	.setupDone							(RamFlagSetupDone),						//config ended, chip ready to transfer
	.dataTransfering					(RamFlagDataTransfewring),				//data transfernig status
	.processDone						(RamFlagTrasferEnd)						//data transfering ended


);



endmodule
