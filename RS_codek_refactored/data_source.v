module Data_Source(start_impulse, clk, 
                 Data_out, end_of_work);

//Start impulse should be given to this node
input start_impulse;

//Input clock should be given to this node
input clk;

output reg [0:3] Data_out = 4'b0000;

//Service node that forming order to device for waiting next start impulse 
//and tell you about process of message transmission is already finished
output wire end_of_work;

//Service registers
reg start_work = 1'b0;
reg device_in_work = 1'b0;
reg reset_device = 1'b0;

//"i" is counter that shown how many clocks will be wasted for doing main actions of this module  
integer i = 0;		


always @ (posedge start_impulse or posedge end_of_work)
begin

		if (end_of_work)
		begin
		start_work = 1'b0;
		end
		else
		begin
		start_work = 1'b1;
		end

end


always @ (posedge clk)
begin
	case (start_work)
	1:
	begin
	device_in_work = 1'b1;
	end
	
	0:
	begin
	device_in_work = 1'b0;		
	end
	
	default:
	begin
	device_in_work = 1'b0;
	end
	endcase
	
	
	if (device_in_work==1'b1)
			begin
					if (i<13)			
					//********************************************************************
					//-------------put here main actions--------------------------------**
					//******************************************************************** 
					
					//              In this section forming information message for coding
					//				with Reed-Solomon algoritm. In real project you should  
					//				remove this verilog module and connect this place to decoder module
					//				4xbits data bus, but for example let think that this module
					//				is a data bus. In accordance with GF table 2^4 let wrote
					//				every group of bits as a:
					//------------------------------------------------------------------------
					//									X^0	| X^1 | X^2 | X^3
					//------------------------------------------------------------------------

					begin
								case(i)
								0:
								begin
								Data_out = 					4'b1000;		//X^0 in GF(16)
								i = i + 1;
								end
								1:
								begin
								Data_out =					4'b0100;		//X^1 in GF(16)
								i = i + 1;
								end
								2:
								begin
								Data_out = 					4'b1100;		//X^4 in GF(16)
								i = i + 1;
								end
								3:
								begin
								Data_out =					4'b0010;		//X^2 in GF(16)
								i = i + 1;
								end
								4:
								begin
								Data_out = 					4'b1010;		//X^8 in GF(16)
								i = i + 1;
								end
								5:
								begin
								Data_out = 					4'b0110;		//X^5 in GF(16)
								i = i + 1;
								end
								6:
								begin
								Data_out = 					4'b1110;		//X^10 in GF(16)
								i = i + 1;
								end
								7:
								begin
								Data_out = 					4'b0001;		//X^3 in GF(16)
								i = i + 1;
								end
								8:
								begin
								Data_out = 					4'b1001;		//X^14 in GF(16)
								i = i + 1;
								end
								9:
								begin
								Data_out = 					4'b0101;		//X^9 in GF(16)
								i = i + 1;
								end
								10:
								begin
								Data_out = 					4'b1101;		//X^7 in GF(16)
								i = i + 1;
								end
								11:
								begin
								Data_out = 					4'b0000;
								reset_device = 1'b1;
								i = i + 1;
								end
								default://------------put here what will doing this device by default
								begin
								Data_out = 					4'b0000;
								i = 0;
								reset_device = 1'b0;
								end
								endcase
					end
					else
					
					begin
					i = 0; 
					device_in_work = 1'b0;
					end
			end
end	

assign end_of_work = device_in_work && reset_device;
endmodule