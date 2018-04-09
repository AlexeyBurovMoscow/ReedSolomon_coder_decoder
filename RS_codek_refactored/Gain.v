module Err_Module (start_impulse, clk, Data_in,
								Data_out,err, start_imp);
input start_impulse;
input [3:0] Data_in;
input clk;
output reg err = 1'b0;
output reg [3:0] Data_out = 4'b0000;

output reg start_imp = 1'b0;//when this signal equal 1 decoder start

//Service node
wire end_of_work;

//Service registers
reg start_work = 1'b0;
reg device_in_work = 1'b0;
reg reset_device = 1'b0;

//"i" is counter that shown how many clocks will be wasted for doing main actions of this module  
integer i = 0;

//counter for errors. It use in section where error configuration sets up (see down the code)		
integer err_cntr = 0;

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
//-------------	
	if (device_in_work==1'b1)
			begin
					if (i<17)			
					//********************************************************************
					//-------------put here main actions--------------------------------**
					//******************************************************************** 
					begin
								case(i)					//at the each step in this section the error can be added to
								0:						//information message. If "err = 1'b0" => error added, else
								begin					//data in information block is correct.
								err = 1'b0;				//configuration of error described down the code
								start_imp = 1'b1;		
								i = i + 1;
								end
								1:
								begin				
								start_imp = 1'b0;	
								err_cntr = err_cntr + 1;
								err = 1'b1;											
								i = i + 1;
								end
								2:
								begin				
								err = 1'b0;
								i = i + 1;
								end
								3:
								begin				
								err = 1'b0;
								i = i + 1;
								end
								4:
								begin				
								err_cntr = err_cntr + 1;
								err = 1'b1;
								i = i + 1;
								end
								5:
								begin
								err = 1'b0;
								i = i + 1;
								end
								6:
								begin
								err = 1'b0;				
								i = i + 1;
								end
								7:
								begin	
								err = 1'b0;			
								i = i + 1;
								end
								8:
								begin
								err = 1'b0;				
								i = i + 1;
								end
								9:
								begin
								err = 1'b0;				
								i = i + 1;
								end
								10:
								begin	
								err = 1'b0;				
								i = i + 1;
								end
								11:
								begin
								err = 1'b0;				
								i = i + 1;								
								end
								12:
								begin
								err = 1'b0;				
								i = i + 1;								
								end
								13:
								begin
								err = 1'b0;				
								i = i + 1;								
								end
								14:
								begin
								err = 1'b0;				
								i = i + 1;								
								
								end
								15:
								begin
								err = 1'b0;
								i = i + 1;
								reset_device = 1'b1;
								end
								16:
								begin
								err = 1'b0;
								err_cntr = 0;
								Data_out = 	4'b0000;				
								reset_device = 1'b0;
								i = i + 1;
								end
								default://------------put here what will doing this device by default
								begin
								Data_out = 	4'b0000;
								i = 0;
								reset_device = 1'b0;
								device_in_work = 1'b0;
								end
								endcase
					end
					else
					
					begin
					i = 0; 
					device_in_work = 1'b0;
					end
					
					//-----------------------------------------------------------------------------
					//-----------------------------------------------------------------------------
					case (err)
					1'b0:	
					begin 
					Data_out = Data_in; 
					end
					//--------------Section for error configuration---------------------------------
					1'b1: 
					begin
						if (err_cntr == 1)				//in this section error configuration sets up.
						begin							//each bit of information block is changeble by adding symbol "~"
							Data_out[0] = Data_in[0]; 	//Error configurate dependly of error counter. In this project
							Data_out[1] = Data_in[1]; 	//significant of err counter can not be more then 2 else decoder 
							Data_out[2] = Data_in[2]; 	//failing will be happen
							Data_out[3] = ~Data_in[3];
						end
						if (err_cntr == 2)
						begin
							Data_out[0] = Data_in[0]; 
							Data_out[1] = Data_in[1]; 
							Data_out[2] = Data_in[2]; 
							Data_out[3] = ~Data_in[3];					
						end
					end		
					default:
					begin 
					Data_out = Data_in;
					end
					endcase
					
				
			end
		
end	

assign end_of_work = device_in_work && reset_device;								
endmodule
