module hyperRamDriver(enable, clock200, clock200shifted, clock400, rwMode,
dataFromFifo, caInfo, dataToFifo, toRamData, rwds, toRamCk, toRamCkInv, toRamNrst, toRamCs,
csDone, setupDone, dataTransfering, processDone,
csCounter, clockMask, ckRamCounter, fastCountNegedge, clock400outInv, bytesToTransfer);

input wire enable;											//Modul's enable
input wire clock200, clock200shifted, clock400;
input wire rwMode;											//Choose read or write mode
input wire [7:0] dataFromFifo;							//Input data
input wire [47:0] caInfo;									//RAM settings register
input wire [10:0] bytesToTransfer;						//How many bytes module will trasnfer, 1280 max
output wire [7:0] dataToFifo;								//Output data
inout wire [7:0] toRamData;								//data connected to chip
inout wire rwds;												//rwds connected to chip
output reg [10:0] fastCountNegedge = 0;
//output wire [7:0] toRamData;
//output wire rwds;

output wire toRamCk;											//clock connected to chip (pos in ddr mode)
output wire toRamCkInv;										//clock connected to chip (neg in ddr mode, in common mode is not connected)
output wire toRamNrst;										//chip reset
output wire toRamCs;											//chip chip select

output wire csDone;											//chip select signal ended, chip ready to config
output wire setupDone;										//config ended, chip ready to transfer
output wire dataTransfering;								//data transfernig status
output wire processDone;

output wire clock400outInv;
assign clock400outInv = ~clock400 & dataTransfering;

//сколько подождать тактов на cs = 1
parameter timeToCs = 2;
///////////////////////////////
output reg [12:0] csCounter = 0;
always_ff@(negedge clock200)
begin
	if(!enable)
		begin
			csCounter <= 0;
		end
	else
		begin
			csCounter <= csCounter + 1;
		end
end

always_comb
begin
	if(csCounter >= timeToCs)
		csDone = 1;
	else
		csDone = 0;
end

//rwmode = 1 - чтение из памяти
//rwmode = 0 - запись в память
//parameter totalTime = 1314;

parameter settingTime = 34;
reg [10:0] totalTime;
always_ff @(posedge enable) totalTime[10:0] <= settingTime + bytesToTransfer[10:0];


always_comb
begin
	if(rwMode)
		begin
			if(fastCountNegedge >= totalTime + 1)
				toRamCs = 1;
			else
				toRamCs = ~csDone;
		end
	else
		begin
			if(fastCountNegedge >= totalTime)
				toRamCs = 1;
			else
				toRamCs = ~csDone;
		end
end

parameter clockDisable = 1;
///////////////////////////////
output wire clockMask;
always_comb
begin
	if(fastCountNegedge > 1)
		clockMask = 1;
	else
		clockMask = 0;
end
assign toRamCk = clock200shifted & clockMask;
assign toRamCkInv = ~toRamCk;

///////////////////////////////
output reg [10:0] ckRamCounter = 0;
always_ff@(negedge toRamCk)
begin
	if(!enable)
		begin
			ckRamCounter <= 0;
		end
	else
		begin
			ckRamCounter <= ckRamCounter + 1;
		end
end

always_comb
begin
	if(rwMode)
		begin
			if(ckRamCounter >= 16 + 1)
				setupDone = 1;
			else
				setupDone = 0;
		end
	else
		begin
			if(ckRamCounter >= 16)
				setupDone = 1;
			else
				setupDone = 0;
		end
end

always_comb
begin
	if(rwMode)
		begin
			if((ckRamCounter >= 16 + 1) && (fastCountNegedge < totalTime + 1))
				begin
					dataTransfering = 1;
				end
			else
				begin
				 dataTransfering = 0;
				end
		end
	else
		begin
			if((ckRamCounter >= 16) && (fastCountNegedge < totalTime))
				begin
					dataTransfering = 1;
				end
			else
				begin
				 dataTransfering = 0;
				end
		end
	
end

///////////////////////////////

always_ff@(negedge clock400)
begin
	if(!enable)
		begin
			fastCountNegedge <= 0;
		end
	else
		begin
			if(csDone)
				begin
					fastCountNegedge <= fastCountNegedge + 1;
				end
			else
				begin
					fastCountNegedge <= 0;
				end
		end
end

parameter afterLatencyTime = 34;
always_comb
begin
	if(fastCountNegedge == 2) 			toRamData = caInfo[47:40];
	else if(fastCountNegedge == 3)	toRamData = caInfo[39:32];
	else if(fastCountNegedge == 4)	toRamData = caInfo[31:24];
	else if(fastCountNegedge == 5)	toRamData = caInfo[23:16];
	else if(fastCountNegedge == 6)	toRamData = caInfo[15:8];
	else if(fastCountNegedge == 7)	toRamData = caInfo[7:0];
	else
		begin
			if(rwMode) //чтение
				begin
					if(fastCountNegedge >= afterLatencyTime)
						begin
							toRamData = {8{1'bz}};
						end
					else
						begin
							toRamData = {8{1'b0}};
						end
				end
			else //запись
				begin
					if(fastCountNegedge >= afterLatencyTime)
						begin
							toRamData = dataFromFifo;
						end
					else
						begin
							toRamData = {8{1'b0}};
						end
				end
		end
end

always_comb
begin
	if((rwMode) && (fastCountNegedge >= afterLatencyTime))
		begin
			dataToFifo = toRamData;
		end
	else
		begin
			dataToFifo = 0;
		end
end

always_comb
begin
	if((fastCountNegedge >= 1)&&(fastCountNegedge < 7))
		begin
			rwds = 1'bz;
		end
	else if (fastCountNegedge >= afterLatencyTime)
		begin
			if(rwMode)
				begin
					rwds = 1'bz;
				end
			else
				begin
					rwds = 1'b0;
				end
		end
	else
		begin
			rwds = 1'bz;
		end
end


always_comb
begin
	if(rwMode)
		begin
			if(fastCountNegedge >= totalTime + 1)
				processDone = 1;
			else
				processDone = 0;
		end
	else
		begin
			if(fastCountNegedge >= totalTime)
				processDone = 1;
			else
				processDone = 0;
		end
	
end

assign toRamNrst = 1;

endmodule
