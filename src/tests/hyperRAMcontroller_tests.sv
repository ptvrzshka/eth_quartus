`timescale  1 ns/ 1 ns

module hyperRAMcontroller_tests
(
	
	
	inout [7:0] dataChip,					///////////////////////////
	inout 		rwdsChip,					///////////////////////////
													///////////////////////////
	output 		clockChip,					///  Chip Connections   ///
	output 		clockChipN,					///////////////////////////		
	output		resetnChip,					///////////////////////////
	output		csChip,						///////////////////////////
	
	input 		clockData,

	input [22:0] adrQueury,						// RAM adress input 
	input [10:0] transactionLenQueury,		// RAM trasnfer length
	input rwFlagQueury,							// RAM read or write mode
	input clockQueury,							// RAM queue write sync
	
	
	output reg [23:0] adrInfo,					//output information about actual transaction Adress
	output reg rwFlagInfo,						//output information about actual transaction Read/write flag
	output wire transferingStatusInfo,		//output information about actual transaction Transfer status
	
	
	output [7:0] dataOutFifoRead,				//read fifo output
	input RreqFifoRead,							//read fifo read req
	
	input 		clkData,
	
	input reset,

	input [7:0] dataInputFifoWrite,			//write fifo input
	input WreqFifoWrite							//write fifo write req
);

reg clk_50;
reg clock200;
reg clock200Shifted;
reg clock400;

//
//hyperRamPll hyperRamPll 
//(
//	.inclk0 					(clk_50),
//	.c0						(clock200),
//	.c1              	   (clock200Shifted),
//	.c2             	   (clock400)
//);


reg [35:0] dataInputQueuryInput;

always @(posedge clk_50)													
if (clockQueury)
begin
	dataInputQueuryInput[0] <= rwFlagQueury;
	dataInputQueuryInput[23:1] <= adrQueury[22:0];
	dataInputQueuryInput[35:24] <= transactionLenQueury[10:0];
end

reg clockQueuryTemp;
always @(posedge clk_50) clockQueuryTemp <= clockQueury; 			//Create delayed sync signal for fifo writet request



reg WreqFifoQuaury;
always @(negedge clk_50) 														//Create RS - trigger for  fifo write request
	if (clockQueury) WreqFifoQuaury <= 1'b1;
	else if (clockQueuryTemp) WreqFifoQuaury <= 1'b0;
	

reg RreqFifoQueury;
reg clockReadFifoQueury;
wire [35:0] dataOutFifoQueury;


RamControlSeqFifo RamControlSeqFifo 
(
	.data							(dataInputQueuryInput[35:0]),
	.rdclk						(clockReadFifoQueury),
	.rdreq						(RreqFifoQueury),
	.wrclk						(clockQueuryTemp),
	.wrreq						(WreqFifoQuaury),
	.q								(dataOutFifoQueury[35:0]),
	.rdempty						(emptyFlagFifoQueury)
);




initial
begin
	clk_50 = 0;
	clock200 = 0;
	clock400 = 0;
end

always
begin 
	#5 clk_50 = !clk_50;
	#2 clock200 = !clock200;
	#1 clock400 = !clock400;
end

reg [7:0] fsmStateTransfer;
reg [7:0] nextState;
reg [10:0] dataLenRamDriver;
reg [47:0] controlRegRamDriver;
reg WreqFifoRead;
reg RreqFifoWrite;

always @(posedge clk_50 or posedge transferEndFlagRamDriver)

if (transferEndFlagRamDriver)
begin

	fsmStateTransfer[7:0] <= 8'h0;
	RreqFifoWrite <= 1'b0;
	WreqFifoRead <= 1'b0;
	enableRamDriver <= 1'b0;
	controlRegRamDriver[47:0] <= 0;
	dataLenRamDriver[10:0] <= 0;
	
	
end

else begin
	case (fsmStateTransfer)
	
		8'h0:	if (!emptyFlagFifoQueury) fsmStateTransfer <= 8'h1;			//IDLE state
		
		8'h1:																					//if ram queue is not empty generate fifo sync signals
		begin		
			RreqFifoQueury <= 1'b1;
			if (RreqFifoQueury) 
			begin
				clockReadFifoQueury <= 1'b1;
				fsmStateTransfer <= 8'h2;
				
			end
		end
		
		
		8'h2:	
		begin
			RreqFifoQueury <= 1'b0;
			clockReadFifoQueury <= 1'b0;
			fsmStateTransfer <= 8'h3;
		end
		
		
		8'h3:																			//Control register settings
		begin
			dataLenRamDriver[10:0] <= dataOutFifoQueury[34:24];						
			
			controlRegRamDriver[47] <= dataOutFifoQueury[0];			//1 - a read transaction  0 - a write transaction
			controlRegRamDriver[46] <= 1'b0;									//0 - memory space, 1 - control register space
			controlRegRamDriver[45] <= 1'b0;									//0 - wrapped burst, 1 - linear burst
			controlRegRamDriver[44:36] <= 9'h00;							//not used adress space
			controlRegRamDriver[35:16] <= dataOutFifoQueury[23:4];	//high adress space
			controlRegRamDriver[15:3] <= 13'h00;							//reserverd set to 0
			controlRegRamDriver[2:0] <= dataOutFifoQueury[3:1];		//low adress space
			
			rwModeRamDriver <= dataOutFifoQueury[0];
			
			
			adrInfo[22:0] <= dataOutFifoQueury[23:1];						//output information about actual transaction
			rwFlagInfo <= dataOutFifoQueury[0];								//output information about actual transaction
			
			
			
			fsmStateTransfer <= 8'h4;
			
		end
		
		8'h4:																			//waiting for transfer control end and a latancy end
		begin
			enableRamDriver <= 1'b1;
			if (setupDoneFlagRamDriver) fsmStateTransfer <= 8'h5;
		end
		
		8'h5:
		begin
			if (rwModeRamDriver)													//if transaction type is read from RAM, up read fifo write request
				begin		
					WreqFifoRead <= 1'b1;
					RreqFifoWrite <= 1'b0;	
				end
			else 																		//if transaction type is write to RAM, up write fifo read request
				begin
					WreqFifoRead <= 1'b0;
					RreqFifoWrite <= 1'b1;	
				end												
		
			fsmStateTransfer <= 8'h6;
		end
		
	
		8'h6:																			//we can write error handler here, now that module doing bothing))
		if (!dataTransferFlagRamDriver)
			fsmStateTransfer <= 8'h0;
			
		default: fsmStateTransfer <= 8'h0;
		
	endcase
end


assign transferingStatusInfo = dataTransferFlagRamDriver;

wire [7:0] dataInputFifoRead;

HyperRamFifo HyperRamFifoRead
(	
	.data								(dataInputFifoRead[7:0]),
	.wrclk							(clock400),
	.wrreq							(WreqFifoRead),

	.q									(dataOutFifoRead[7:0]),
	.rdclk							(clockData),
	.rdreq							(RreqFifoRead),

	.aclr								(reset)

);


wire [7:0] dataOutFifoWrite;

HyperRamFifo HyperRamFifoWrite 
(	
	.data								(dataInputFifoWrite[7:0]),
	.wrclk							(clockData),
	.wrreq							(WreqFifoWrite),

	.rdclk							(clock400),
	.rdreq							(RreqFifoWrite),
	.q									(dataOutFifoWrite[7:0]),

	.aclr								(reset)

);


hyperRamDriver hyperRamDriver
(


	.enable								(enableRamDriver),								//Modul's enable
	.clock200							(clock200), 
	.clock200shifted					(clock200Shifted), 
	.clock400							(clock400),
	.rwMode								(rwModeRamDriver),								//Choose read or write mode
	.dataFromFifo						(dataOutFifoWrite[7:0]),						//Input data
	.caInfo								(controlRegRamDriver[47:0]),					//RAM settings register
	.bytesToTransfer					(dataLenRamDriver[10:0]),						//How many bytes module will trasnfer, 1280 max
	.dataToFifo							(dataInputFifoRead[7:0]),						//Output data

	.toRamData							(dataChip[7:0]),									//data connected to chip
	.rwds									(rwdsChip),											//rwds connected to chip

	.toRamCk								(clockChip),										//clock connected to chip (pos in ddr mode)
	.toRamCkInv							(clockChipN),										//clock connected to chip (neg in ddr mode, in common mode is not connected)
	.toRamNrst							(resetnChip),										//chip reset
	.toRamCs								(csChip),											//chip chip select
	
	.csDone								(csDoneFlagRamDriver),							//chip select signal ended, chip ready to config
	.setupDone							(setupDoneFlagRamDriver),						//config ended, chip ready to transfer
	.dataTransfering					(dataTransferFlagRamDriver),					//data transfernig status
	.processDone						(transferEndFlagRamDriver)						//data transfering ended


);



endmodule
