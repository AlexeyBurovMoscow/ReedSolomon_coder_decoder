//------------------------------------------------------------
							//************************************************************
							//----------------Reed_Solomon 11, 15 decoder-----------------
							//----------------Created by Alexey Burov(c)------------------
							//************************************************************


							//-----------------------------------------------------------------------
							//					This is top level-module. This module contains
							//description of algoritm that perform procedure RS-decoding 			
							//with correcting errors in incoming message
							
							
							//This decoder operate with generate polynomial:
							//g(x) = x^4 + x^3(alpha^12) + x^2(alpha^4) + x(1) + alpha^6 =
							// = g(x) = x^4 + 15*x^3 + 3*x^2 + x + 12.
							//During processing it calculates 4 mes that show errors occurence:
							//if all syndromes are equals to 0 => no errors in received message, else
							//if anyone of calculaded syndromes is not equal to 0 => error happened. 

module RS_Decoder(start_impulse, clk, Data_in,
					Data_out, error, done, total_err, end_of_work, err_pos0, err_pos1, err_amp_0, err_amp_1,
					//for test----------------------------------------
					main_ram_wr_ena, main_ram_rd_ena, main_ram_adr, multiply_factor, xor_to_syndrome_ram, g_mult_ena, 
					syndr_RAM_wr_ena, syndr_RAM_rd_ena, syndr_RAM_ADR,
					syndrome_0_0, syndrome_0_1, syndrome_0_2, syndrome_0_3, syndrome_1_0,syndrome_1_1, syndrome_1_2, syndrome_1_3, 
					syndrome_2_0, syndrome_2_1, syndrome_2_2, syndrome_2_3, syndrome_3_0,syndrome_3_1, syndrome_3_2, syndrome_3_3, 
					start_locator, multiplier_to_xor, main_ram_to_multiplier, 
					kill_error, repair_ena, kill_amplitude, cut_tail, tab1_ena, tab2_ena
					);
					
					
input start_impulse;		//Start impulse should be given to this node
input clk;					//Input clock should be given to this node
input [3:0] Data_in;		//Inform bits from info channel should be given to this nodes 
output [3:0] Data_out; 		//Decoded message should be readed from this nodes
output error; 				//Show high level impulse in the case errors during decoding
output done;				//Show high level impulse when decoding process is over			 
output [1:0] total_err;//Show total count of searched errors (no more then two - see special theory).
output wire end_of_work;	//Show positive impulse when full work cycle is over

//inside service wires, buses
wire main_ram_cnt_ena;
output wire [3:0] main_ram_to_multiplier;
wire [3:0] main_ram_to_multiplier_d;
output wire [3:0] multiplier_to_xor;
wire [3:0] m_f;
wire [3:0] t_err_pos0;
wire [3:0] t_err_pos1;
output wire tab1_ena;
output wire tab2_ena;
output wire kill_error;

output wire repair_ena;
output wire [0:3] kill_amplitude;
output wire cut_tail;
//uninteresting wires (for test and debug)
output wire syndr_RAM_wr_ena; 
output wire syndr_RAM_rd_ena; 
output wire [3:0] syndr_RAM_ADR;
output wire main_ram_wr_ena;
output wire main_ram_rd_ena;
output wire[3:0] main_ram_adr;
output wire [3:0] multiply_factor;
output wire [0:3] xor_to_syndrome_ram;//
output wire g_mult_ena;

output wire syndrome_0_0;
output wire syndrome_0_1;
output wire syndrome_0_2;
output wire syndrome_0_3;

output wire syndrome_1_0;
output wire syndrome_1_1;
output wire syndrome_1_2;
output wire syndrome_1_3;

output wire syndrome_2_0;
output wire syndrome_2_1;
output wire syndrome_2_2;
output wire syndrome_2_3;

output wire syndrome_3_0;
output wire syndrome_3_1;
output wire syndrome_3_2;
output wire syndrome_3_3;

output wire start_locator;
output wire [0:3] err_pos0; 
output wire [0:3] err_pos1; 
output wire [0:3] err_amp_0; 
output wire [0:3] err_amp_1;
//-----------------------------------------------------------------------------------------------------------------
D_CONTROLLER	dec_controller(
								.START_DECODING(start_impulse), 		//INPUT
								.CLK(clk), 								//INPUT
								.MAIN_RAM_WR(main_ram_wr_ena),			//OUTPUT
								.MAIN_RAM_RD(main_ram_rd_ena),			//OUTPUT
								.MAIN_RAM_ADR(main_ram_adr),			//OUTPUT
								.END_OF_WORK(end_of_work),				//OUTPUT
								.MULTIPLYER(m_f),
								.G_ENA(g_mult_ena),
								.SYNDROME_RAM_WR_ENA(syndr_RAM_wr_ena),
								.SYNDROME_RAM_RD_ENA(syndr_RAM_rd_ena),
								.SYNDROME_RAM_ADR(syndr_RAM_ADR),
								.START_LOCATOR(start_locator),
								.TAB1_ENA(tab1_ena),
								.TAB2_ENA(tab2_ena),
								.POSITION_ERROR_0(err_pos0), 
								.POSITION_ERROR_1(err_pos1), 
								.AMPLITUDE_ERROR_0(err_amp_0), 
								.AMPLITUDE_ERROR_1(err_amp_1), 
								.KILL_ERROR(kill_error), 
								.REPAIR_ENABLE(repair_ena),
								.KILL_AMPLITUDE(kill_amplitude),
								.CUT_TAIL(cut_tail)
								);
//-----------------------------------------------------------------------------------------------------------------
MAIN_RAM		main_RAM(
								.WR_ENA(main_ram_wr_ena),				//INPUT
								.RD_ENA(main_ram_rd_ena),				//INPUT
								.CLK(clk),								//INPUT
								.DATA_IN(Data_in),					//BUS INPUT
								.ADR(main_ram_adr),				//BUS INPUT
								.DATA_OUT(main_ram_to_multiplier),		//BUS OUTPUT
								.reset(end_of_work)
								);
//-----------------------------------------------------------------------------------------------------------------
MULTIPLYER_GALUA decode_multiplier(	.ena(g_mult_ena),					//INPUT
									.clk(clk),							//INPUT
									.Data_in_0(main_ram_to_multiplier[0]),	//INPUT
									.Data_in_1(main_ram_to_multiplier[1]),	//INPUT
									.Data_in_2(main_ram_to_multiplier[2]),	//INPUT
									.Data_in_3(main_ram_to_multiplier[3]),	//INPUT
									.Multiply_factor(multiply_factor),	//INPUT
									.Data_out(multiplier_to_xor),		//OUTPUT
									.reset (end_of_work)
									);
//-----------------------------------------------------------------------------------------------------------------
PROC_XOR decoderXOR(		.ena(g_mult_ena),
							.clk(clk),
							.Data_in(multiplier_to_xor),
							.repair(repair_ena),
							.Kill_amplitude(kill_amplitude),
							.kill(kill_error),
							.Data_OZU(main_ram_to_multiplier),
							.Delayed_data_OZU(main_ram_to_multiplier_d),
							.cut_tail(cut_tail),
							.Data_out(xor_to_syndrome_ram),
							.Repaired_data_out(Data_out)
									);
//------------------------------------------------------------------------------------------------------------------
DTRIGGER				Trig0(
							.DATA_IN(m_f[0]),							//INPUT
							.CLK(clk),									//INPUT
							.DATA_OUT(multiply_factor[0])					//OUTPUT
							);
//------------------------------------------------------------------------------------------------------------------
DTRIGGER				Trig1(
							.DATA_IN(m_f[1]),							//INPUT
							.CLK(clk),									//INPUT
							.DATA_OUT(multiply_factor[1])					//OUTPUT
							);
//------------------------------------------------------------------------------------------------------------------
DTRIGGER				Trig2(
							.DATA_IN(m_f[2]),							//INPUT
							.CLK(clk),									//INPUT
							.DATA_OUT(multiply_factor[2])					//OUTPUT
							);
//------------------------------------------------------------------------------------------------------------------
DTRIGGER				Trig3(
							.DATA_IN(m_f[3]),							//INPUT
							.CLK(clk),									//INPUT
							.DATA_OUT(multiply_factor[3])					//OUTPUT
							);
//------------------------------------------------------------------------------------------------------------------
DTRIGGER				Trig4(
							.DATA_IN(main_ram_to_multiplier[0]),							//INPUT
							.CLK(clk),									//INPUT
							.DATA_OUT(main_ram_to_multiplier_d[0])					//OUTPUT
							);
//------------------------------------------------------------------------------------------------------------------
DTRIGGER				Trig5(
							.DATA_IN(main_ram_to_multiplier[1]),							//INPUT
							.CLK(clk),									//INPUT
							.DATA_OUT(main_ram_to_multiplier_d[1])					//OUTPUT
							);
//------------------------------------------------------------------------------------------------------------------
DTRIGGER				Trig6(
							.DATA_IN(main_ram_to_multiplier[2]),							//INPUT
							.CLK(clk),									//INPUT
							.DATA_OUT(main_ram_to_multiplier_d[2])					//OUTPUT
							);
//------------------------------------------------------------------------------------------------------------------
DTRIGGER				Trig7(
							.DATA_IN(main_ram_to_multiplier[3]),							//INPUT
							.CLK(clk),									//INPUT
							.DATA_OUT(main_ram_to_multiplier_d[3])					//OUTPUT
							);
//------------------------------------------------------------------------------------------------------------------


SYNDROME_RAM syndrome_memory(
							.wr_ena(syndr_RAM_wr_ena),
							.rd_ena(syndr_RAM_rd_ena),
							.clk(clk),
							.Data_in(xor_to_syndrome_ram),
							.Adr(syndr_RAM_ADR), 
							
							.Data_out0_0(syndrome_0_0),
							.Data_out0_1(syndrome_0_1),
							.Data_out0_2(syndrome_0_2),
							.Data_out0_3(syndrome_0_3),
							
							.Data_out1_0(syndrome_1_0),
							.Data_out1_1(syndrome_1_1),
							.Data_out1_2(syndrome_1_2),
							.Data_out1_3(syndrome_1_3),
							
							.Data_out2_0(syndrome_2_0),
							.Data_out2_1(syndrome_2_1),
							.Data_out2_2(syndrome_2_2),
							.Data_out2_3(syndrome_2_3),
							
							.Data_out3_0(syndrome_3_0),
							.Data_out3_1(syndrome_3_1),
							.Data_out3_2(syndrome_3_2),
							.Data_out3_3(syndrome_3_3),
							.reset(end_of_work)
							);
//-----------------------------------------------------------------------------------------------------------------
RS_Locator	rsloc

  (
							.clk(clk),
							.reset(end_of_work),
							.S1_0(syndrome_0_3),
							.S1_1(syndrome_0_2),
							.S1_2(syndrome_0_1),
							.S1_3(syndrome_0_0),
							
							.S2_0(syndrome_1_3),
							.S2_1(syndrome_1_2),
							.S2_2(syndrome_1_1),
							.S2_3(syndrome_1_0),
							
							.S3_0(syndrome_2_3),
							.S3_1(syndrome_2_2),
							.S3_2(syndrome_2_1),
							.S3_3(syndrome_2_0),
							
							.S4_0(syndrome_3_3),
							.S4_1(syndrome_3_2),
							.S4_2(syndrome_3_1),
							.S4_3(syndrome_3_0),
							
							.start(start_locator),
							
							.u1(t_err_pos0), // position 1
							.v1(err_amp_0), // value 1
							.u2(t_err_pos1), // position 2
							.v2(err_amp_1), // value 2
							.error(error),
							.done(done),
							.error_number(total_err)
						  );

//-----------------------------------------------------------------------------------------------------------------
TABLE tab1
			(
			
			.Data_in(t_err_pos0),
			.Data_out(err_pos0),
			.clk(clk),
			.enable(tab1_ena),
			);
//-----------------------------------------------------------------------------------------------------------------
TABLE tab2
			(
			.Data_in(t_err_pos1),
			.Data_out(err_pos1),
			.clk(clk),
			.enable(tab2_ena),
			);
//-----------------------------------------------------------------------------------------------------------------
endmodule
//-----------------------------------------------------------------------------------------------------------------
							//************************************************************
							//----------------Reed_Solomon 11, 15 controller-----------------
							//************************************************************
module D_CONTROLLER(START_DECODING, CLK, 
						MAIN_RAM_WR, MAIN_RAM_RD, MAIN_RAM_ADR, END_OF_WORK, MULTIPLYER, G_ENA, 
						SYNDROME_RAM_WR_ENA, SYNDROME_RAM_RD_ENA, SYNDROME_RAM_ADR, START_LOCATOR, TAB1_ENA,
						TAB2_ENA, POSITION_ERROR_0, POSITION_ERROR_1, AMPLITUDE_ERROR_0, AMPLITUDE_ERROR_1, KILL_ERROR, REPAIR_ENABLE, 
						KILL_AMPLITUDE, CUT_TAIL );
//inputs
input CLK;
input START_DECODING;
input [3:0] POSITION_ERROR_0; 
input [3:0] POSITION_ERROR_1; 
input [3:0] AMPLITUDE_ERROR_0;
input [3:0] AMPLITUDE_ERROR_1;
//outputs
output SYNDROME_RAM_WR_ENA;
output SYNDROME_RAM_RD_ENA;
output [3:0] SYNDROME_RAM_ADR;
output MAIN_RAM_WR; 
output MAIN_RAM_RD;
output END_OF_WORK;
output [3:0] MAIN_RAM_ADR;
output [3:0] MULTIPLYER;
output G_ENA;
output START_LOCATOR;
output TAB1_ENA;
output TAB2_ENA;
output KILL_ERROR; 
output REPAIR_ENABLE;
output [0:3] KILL_AMPLITUDE;
output CUT_TAIL;
//Service registers
reg start_work = 1'b0;
reg device_in_work = 1'b0;
reg reset_device = 1'b0;
reg MR_WE_0 = 1'b0;			//MRWE is main RAM write enable (because process of main ram reading controls from different segments of code)
reg MR_WE_1 = 1'b0;			//MRWE is main RAM write enable
reg MR_RE = 1'b0;			//MRRE is main RAM read enable
reg [3:0] MR_ADR = 4'b0000;		//MR_ADR is main RAM adress at each step
reg [3:0] MF = 4'b0000;			//MF is multiply factor at each step
reg GMXE = 1'b0;				//GMXE is G_alua M_ultiplier and X_or processor enabled
reg SR_WE = 1'b0;						//SR_WE is syndrome ram write enable
reg SR_RE = 1'b0;						//SR_RE is syndrome RAM read enable. Also it is enable signal for error locator module
reg [3:0] SR_ADR= 4'b0000;			//SR_ADR is syndrome RAM_adress
reg SL = 1'b0;						//SL is start_locator
reg T1E = 1'b0;						//T1E is Table 1 enable
reg T2E = 1'b0;						//T2E is Table 2 enable
reg KE = 1'b0;						//KE is "kill error" signal  
reg RE = 1'b0;						//RE is "repair enable" signal
reg CT = 1'b0;						//CT is "cut tail signal"
reg [3:0] ERR_AMP_0;
reg [3:0] ERR_AMP_1;
reg [3:0] ERR_POS_0;
reg [3:0] ERR_POS_1;
reg [3:0] K_AMP = 4'b0000;
//counters
integer i = 0;

always @ (posedge START_DECODING or posedge END_OF_WORK)
begin

		if (END_OF_WORK)
		begin
		start_work = 1'b0;
		end
		else
		begin
		start_work = 1'b1;
		end

end


always @ (posedge CLK)
begin
	case (start_work)
	1'b1:
	begin
	device_in_work = 1'b1;
	end
	
	1'b0:
	begin
	device_in_work = 1'b0;	
	end
	
	default:
	begin
	device_in_work = 1'b0;
	MR_WE_1 = 1'b0;
	end
	endcase
	
	
	if (device_in_work==1'b1)
			begin
					if (i<150)			
							//-----------------------------------------------------------------------
							//********* All process of decoding is broken to the 150 steps: ***********

					begin
								//--------------------------------------------------------------------------
								//----------WRITING TO MAIN RAM CYCLE---------------------------------------
								//**************************************************************************
								case(i)
								0:						//i >=0 && i<15 => incoming word writing to main RAM
								begin
								MR_WE_1 = 1'b1;
								reset_device = 1'b0;
								i = i + 1;
								end
								
								1:
								begin
								i = i + 1;
								MR_ADR = MR_ADR + 1'b1;
								end
								
								2:
								begin
								i = i + 1;
								MR_ADR = MR_ADR + 1'b1;
								end	
														
								3:
								begin
								i = i + 1;
								MR_ADR = MR_ADR + 1'b1;
								end
								4:
								begin
								i = i + 1;
								MR_ADR = MR_ADR + 1'b1;
								end
								5:
								begin
								i = i + 1;
								MR_ADR = MR_ADR + 1'b1;
								end
								6:
								begin
								i = i + 1;
								MR_ADR = MR_ADR + 1'b1;
								end
								7:
								begin
								i = i + 1;
								MR_ADR = MR_ADR + 1'b1;
								end
								8:
								begin
								i = i + 1;
								MR_ADR = MR_ADR + 1'b1;
								end
								9:
								begin
								i = i + 1;
								MR_ADR = MR_ADR + 1'b1;
								end
								10:
								begin
								i = i + 1;
								MR_ADR = MR_ADR + 1'b1;
								end
								11:
								begin
								i = i + 1;
								MR_ADR = MR_ADR + 1'b1;
								end
								12:
								begin
								i = i + 1;
								MR_ADR = MR_ADR + 1'b1;
								end
								13:
								begin
								i = i + 1;
								MR_ADR = MR_ADR + 1'b1;
								end
								14:
								begin
								i = i + 1;
								MR_ADR = MR_ADR + 1'b1;
								end
								
								15:
								begin
								MR_ADR = 4'b0000;//reset main adress of RAM
								MR_WE_1 = 1'b0;	//end of writing to main RAM. MR_WE_0 and MR_WE_1 controls this process by xoring itself (see down the code)
								i = i + 1;
								end
								//--------------------------------------------------------------------------
								//----------READING FROM MAIN RAM CYCLE WITH ALPHA = 0----------------------
								//**************************************************************************
								16:
								begin
								MR_RE = 1'b1;	//i >= 16 && i<32	
												//reading written codeword from RAM and in the same time calcule syndromes
												//alpha is 0 (see special teory) 
								GMXE = 1'b1;	//Galua_Multiplier and XOR processor is enabled
								i = i + 1;
								end
								
								17:				//alpha is 0 
								begin
								i = i + 1;
								MR_ADR = MR_ADR + 1'b1;
								end
								
								18:				//alpha is 0 
								begin
								i = i + 1;
								MR_ADR = MR_ADR + 1'b1;
								end
								
								19:				//alpha is 0
								begin
								i = i + 1;
								MR_ADR = MR_ADR + 1'b1;
								end	
								
								20:				//alpha is 0
								begin
								i = i + 1;
								MR_ADR = MR_ADR + 1'b1;
								end
								
								21:				//alpha is 0
								begin
								i = i + 1;
								MR_ADR = MR_ADR + 1'b1;
								end
								
								22:				//alpha is 0
								begin
								i = i + 1;
								MR_ADR = MR_ADR + 1'b1;
								end
								
								23:				//alpha is 0
								begin
								i = i + 1;
								MR_ADR = MR_ADR + 1'b1;
								end
								
								24:				//alpha is 0
								begin
								i = i + 1;
								MR_ADR = MR_ADR + 1'b1;
								end
								
								25:				//alpha is 0
								begin
								i = i + 1;
								MR_ADR = MR_ADR + 1'b1;
								end
								
								26:				//alpha is 0
								begin
								i = i + 1;
								MR_ADR = MR_ADR + 1'b1;
								end
								
								27:				//alpha is 0
								begin
								i = i + 1;
								MR_ADR = MR_ADR + 1'b1;
								end
								
								28:				//alpha is 0
								begin
								i = i + 1;
								MR_ADR = MR_ADR + 1'b1;
								end
								
								29:				//alpha is 0
								begin
								i = i + 1;
								MR_ADR = MR_ADR + 1'b1;
								end
								
								30:				//alpha is 0
								begin
								i = i + 1;
								MR_ADR = MR_ADR + 1'b1;
								end
								
								31:				//alpha is 0
								begin
								i = i + 1;
								MR_ADR = MR_ADR + 1'b1;
								
								end
							
								32:				//------clks for stabilizing
								begin
								i = i + 1;
								MR_RE = 1'b0;
								MR_ADR = 4'b0000;
								end
								
								33:
								begin
								i = i + 1;
								end
								
								34:
								begin
								i = i + 1;
								GMXE = 1'b0;	//Galua_Multiplier and XOR processor is disabled
								SR_WE = 1'b1;
								end
								
								35:
								begin
								i = i + 1;
								SR_WE = 1'b0;

								
				
								end
								//--------------------------------------------------------------------------
								//----------READING FROM MAIN RAM CYCLE WITH ALPHA = 1----------------------
								//**************************************************************************
								
								36:				//// in this step alpha 0 changes to alpha 1 alpha is 1
								begin
								SR_ADR = SR_ADR + 1'b1;
								MR_RE = 1'b1;	//i >= 36 && i<52	
												//reading written codeword from RAM and in the same time calcule syndromes
												//alpha is 0 (see special teory)
								MF = 4'b1001;//x^14
								
								GMXE = 1'b1;	//Galua_Multiplier and XOR processor is enabled
								i = i + 1;
								end
								
								37:				//alpha is 1
								begin
								i = i + 1;
								MF = 4'b1101;//x^13
								
								MR_ADR = MR_ADR + 1'b1;
								end
								
								38:				//alpha is 1
								begin
								i = i + 1;
								MF = 4'b1111;//x^12
								
								MR_ADR = MR_ADR + 1'b1;
								end
								
								39:				//alpha is 1
								begin
								i = i + 1;
								MF = 4'b1110;//x^11
								
								MR_ADR = MR_ADR + 1'b1;
								end
								
								40:				//alpha is 1
								begin
								i = i + 1;
								MF = 4'b0111;//x^10
								
								MR_ADR = MR_ADR + 1'b1;
								end
								
								41:				//alpha is 1
								begin
								i = i + 1;
								MF = 4'b1010;//x^9
								
								MR_ADR = MR_ADR + 1'b1;
								end
								
								42:				//alpha is 1
								begin
								i = i + 1;
								MF = 4'b0101;
								
								MR_ADR = MR_ADR + 1'b1;
								end
								
								43:				//alpha is 1
								begin
								i = i + 1;
								MF = 4'b1011;
								
								MR_ADR = MR_ADR + 1'b1;
								end
								
								44:				//alpha is 1
								begin
								i = i + 1;
								MF = 4'b1100;
								
								MR_ADR = MR_ADR + 1'b1;
								end
								
								45:				//alpha is 1
								begin
								i = i + 1;
								MF = 4'b0110;
								
								MR_ADR = MR_ADR + 1'b1;
								end
								
								46:				//alpha is 1
								begin
								i = i + 1;
								MF = 4'b0011;
								
								MR_ADR = MR_ADR + 1'b1;
								end
								
								47:				//alpha is 1
								begin
								i = i + 1;
								MF = 4'b1000;
								
								MR_ADR = MR_ADR + 1'b1;
								end
								
								48:				//alpha is 1
								begin
								i = i + 1;
								MF = 4'b0100;
								
								MR_ADR = MR_ADR + 1'b1;
								end
								
								49:				//alpha is 1
								begin
								i = i + 1;
								MF = 4'b0010;
								
								MR_ADR = MR_ADR + 1'b1;
								end
								
								50:				//alpha is 1
								begin
								i = i + 1;
								MF = 4'b0000;	
								
								MR_ADR = MR_ADR + 1'b1;
								end
														
								51:				// alpha is 1
								begin
								i = i + 1;
								
								MR_ADR = MR_ADR + 1'b1;
								
								end	
								
								52:			//clks for stabilizing
								begin
								MR_RE = 1'b0;
								MR_ADR = 4'b0000;
								i = i + 1;
								
								end
								
								53:
								begin
								i = i + 1;
								end
								
								54:
								begin
								i = i + 1;
								GMXE = 1'b0;	//Galua_Multiplier and XOR processor is disabled
								SR_WE = 1'b1;
								end
								
								55:
								begin
								i = i + 1;						
								SR_WE = 1'b0;
								
								end
								//--------------------------------------------------------------------------
								//----------READING FROM MAIN RAM CYCLE WITH ALPHA = 2----------------------
								//**************************************************************************
								56:				//i >= 56 && i<72	
												//reading written codeword from RAM and in the same time calcule syndromes
												//alpha is 2 (see special teory)
								begin
								
								SR_ADR = SR_ADR + 1'b1;
								MR_RE = 1'b1;
								MF = 4'b1101;
								
								GMXE = 1'b1;	//Galua_Multiplier and XOR processor is enabled
								i = i + 1;
								end
								
								57:				//alpha is 2 
								begin
								i = i + 1;
								MF = 4'b1110;
								
								MR_ADR = MR_ADR + 1'b1;
								end
								
								58:				//alpha is 2 
								begin
								i = i + 1;
								MF = 4'b1010;
								
								MR_ADR = MR_ADR + 1'b1;
								end
								
								59:				//alpha is 2 
								begin
								i = i + 1;
								MF = 4'b1011;
								
								MR_ADR = MR_ADR + 1'b1;
								end
								
								60:				//alpha is 2 
								begin
								i = i + 1;
								MF = 4'b0110;
								
								MR_ADR = MR_ADR + 1'b1;
								end
								
								61:				//alpha is 2 
								begin
								i = i + 1;
								MF = 4'b1000;
								
								MR_ADR = MR_ADR + 1'b1;
								end
								
								62:				//alpha is 2 
								begin
								i = i + 1;
								MF = 4'b0010;
								
								MR_ADR = MR_ADR + 1'b1;
								end
								
								63:				//alpha is 2 
								begin
								i = i + 1;
								MF = 4'b1001;
								
								MR_ADR = MR_ADR + 1'b1;
								end
								
								64:				//alpha is 2 
								begin
								i = i + 1;
								MF = 4'b1111;
								
								MR_ADR = MR_ADR + 1'b1;
								end
								
								65:				//alpha is 2 
								begin
								i = i + 1;
								MF = 4'b0111;
								
								MR_ADR = MR_ADR + 1'b1;
								end
								
								66:				//alpha is 2 
								begin
								i = i + 1;
								MF = 4'b0101;
								
								MR_ADR = MR_ADR + 1'b1;
								end
								
								67:				//alpha is 2 
								begin
								i = i + 1;
								MF = 4'b1100;
								
								MR_ADR = MR_ADR + 1'b1;
								end
								
								68:				//alpha is 2 
								begin
								i = i + 1;
								MF = 4'b0011;
								
								MR_ADR = MR_ADR + 1'b1;
								end
								
								69:				//alpha is 2 
								begin
								i = i + 1;
								MF = 4'b0100;
								
								MR_ADR = MR_ADR + 1'b1;
								end
								
								70:				//alpha is 2 
								begin
								i = i + 1;
								MF = 4'b0000;
								
								MR_ADR = MR_ADR + 1'b1;
								end
								
								71:				//alpha is 2 
								begin
								
								MR_ADR = MR_ADR + 1'b1;
								i = i + 1;
								end
								
								72:				//clks for stabilizing
								begin
								MR_RE = 1'b0;
								MR_ADR = 4'b0000;
								i = i + 1;
								
								end
								
								73:
								begin
								i = i + 1;
								end
								
								74:
								begin
								i = i + 1;
								GMXE = 1'b0;	//Galua_Multiplier and XOR processor is disabled
								SR_WE = 1'b1;
								end
								
								75:
								begin
								i = i + 1;		
								SR_WE = 1'b0;
								end
								
								//--------------------------------------------------------------------------
								//----------READING FROM MAIN RAM CYCLE WITH ALPHA = 3----------------------
								//**************************************************************************
								76:				//i >= 76 && i<92	
												//reading written codeword from RAM and in the same time calcule syndromes
												//alpha is 3 (see special teory)
								begin
								
								SR_ADR = SR_ADR + 1'b1;
								MR_RE = 1'b1;
								
								MF = 4'b1111;
								GMXE = 1'b1;	//Galua_Multiplier and XOR processor is enabled
								i = i + 1;
								end
								
								77:				//alpha is 3
								begin
								i = i + 1;
								MF = 4'b1010;
								
								MR_ADR = MR_ADR + 1'b1;
								end
								
								78:				//alpha is 3
								begin
								i = i + 1;
								MF = 4'b1100;
							
								MR_ADR = MR_ADR + 1'b1;
								end
								
								79:				//alpha is 3
								begin
								i = i + 1;
								MF = 4'b1000;
								
								MR_ADR = MR_ADR + 1'b1;
								end
								
								80:				//alpha is 3
								begin
								i = i + 1;
								MF = 4'b0000;
								
								MR_ADR = MR_ADR + 1'b1;
								end
								
								81:				//alpha is 3
								begin
								i = i + 1;
								MF = 4'b1111;
								
								MR_ADR = MR_ADR + 1'b1;
								end
								
								82:				//alpha is 3
								begin
								i = i + 1;
								MF = 4'b1010;
								
								MR_ADR = MR_ADR + 1'b1;
								end
								
								83:				//alpha is 3
								begin
								i = i + 1;
								MF = 4'b1100;
								
								MR_ADR = MR_ADR + 1'b1;
								end
								
								84:				//alpha is 3
								begin
								i = i + 1;
								MF = 4'b1000;
								
								MR_ADR = MR_ADR + 1'b1;
								end
								
								85:				//alpha is 3
								begin
								i = i + 1;
								MF = 4'b0000;
								
								MR_ADR = MR_ADR + 1'b1;
								end
								
								86:				//alpha is 3
								begin
								i = i + 1;
								MF = 4'b1111;
								
								MR_ADR = MR_ADR + 1'b1;
								end
								
								87:				//alpha is 3
								begin
								i = i + 1;
								MF = 4'b1010;
								
								MR_ADR = MR_ADR + 1'b1;
								end
								
								88:				//alpha is 3
								begin
								i = i + 1;
								MF = 4'b1100;
							
								MR_ADR = MR_ADR + 1'b1;
								end
								
								89:				//alpha is 3
								begin
								i = i + 1;
								MF = 4'b1000;
								
								MR_ADR = MR_ADR + 1'b1;
								end
								
								90:				//alpha is 3
								begin
								i = i + 1;
								MF = 4'b0000;
							
								MR_ADR = MR_ADR + 1'b1;
								end
								
								91:				//alpha is 3
								begin
								MR_ADR = MR_ADR + 1'b1;
								
								i = i + 1;
								end
								
								92:				//clks for stabilizing
								begin
								MR_RE = 1'b0;
								MR_ADR = 4'b0000;
								i = i + 1;
								end
								
								93:
								begin
								i = i + 1;
								end
								
								94:
								begin
								i = i + 1;
								GMXE = 1'b0;	//Galua_Multiplier and XOR processor is disabled
								SR_WE = 1'b1;
								end
								
								95:
								begin
								i = i + 1;		
								SR_WE = 1'b0;
								end
								
								96:					
								begin	
								i = i + 1;
							
								end
								
								97:
								begin
								i = i + 1;
								SR_ADR = 2'b00;
								end
								
								98:
								begin
								i = i + 1;
								SR_RE = 1'b1;	//overwrites all calculated syndromes to SYNDROME RAM to error locator
								end
								
								99:
								begin
								SR_RE = 1'b0;
								i = i + 1;
								end
								
								100:
								begin
								
								i = i + 1;
								end
								
								101:
								begin
								i = i + 1;
								end
								
								102:
								begin
								SL = 1'b1;		//start locator = 1
								i = i + 1;
								end
								
								103:
								begin
								i = i + 1;
								SL = 1'b0;		//start locator = 0
								end
								
								104:
								begin
								i = i + 1;
								end
								
								105:
								begin
								i = i + 1;
								end
								
								106:
								begin
								i = i + 1;
								end
								
								107:
								begin
								i = i + 1;
								end
								
								108:
								begin
								i = i + 1;
								end
								
								109:
								begin
								i = i + 1;
								end
								
								110:
								begin
								i = i + 1;
								end
								
								111:
								begin
								i = i + 1;
								end
								
								112:
								begin
								i = i + 1;
								end
								
								113:
								begin
								i = i + 1;
								end
								
								114:
								begin
								i = i + 1;
								end
								
								115:
								begin
								i = i + 1;
								end
								
								116:
								begin
								i = i + 1;
								end
								
								117:
								begin
								i = i + 1;
								end
								
								118:
								begin
								i = i + 1;							
								end
								
								119:
								begin
								i = i + 1;
								end
								
								120:
								begin
								i = i + 1;
								end
								
								121:
								begin
								i = i + 1;
								end
								
								122:
								begin
								i = i + 1;
								end
								
								123:
								begin
								i = i + 1;
								end

								124:
								begin	
								i = i + 1;
								end
								
								125:
								begin
								i = i + 1;
								T1E = 1'b1;
								T2E = 1'b1;	
								end
								
								126:
								begin
								i = i + 1;
								end
								
								127:
								begin
								i = i + 1;
								end
								
								128:
								begin
								i = i + 1;
								end
								
								129:
								begin
								i = i + 1;
								end
								
								130:				//catch error amplitudes and location positions of errors, reading and repairing damaged (or undamaged) message from main RAM
								begin
								i = i + 1;
								ERR_AMP_0 = AMPLITUDE_ERROR_0;
								ERR_AMP_1 = AMPLITUDE_ERROR_1;
								ERR_POS_0 = POSITION_ERROR_0;
								ERR_POS_1 = POSITION_ERROR_1;
								MR_RE = 1'b1;
								RE = 1'b1;
								GMXE = 1'b1;
								end
								
								131:	//1
								begin
								i = i + 1;
								
											if (MR_ADR==ERR_POS_0)
											begin
												KE = 1'b1;
												K_AMP = ERR_AMP_0;
											end
											else if(MR_ADR==ERR_POS_1)
											begin
												KE = 1'b1;
												K_AMP = ERR_AMP_1;
											end
											else
											begin
												KE = 1'b0;
												K_AMP = 4'b0000;							
											end
								MR_ADR = MR_ADR + 1'b1;
								end
								
								132:	//2
								begin
								i = i + 1;
											if (MR_ADR==ERR_POS_0)
											begin
												KE = 1'b1;
												K_AMP = ERR_AMP_0;
											end
											else if(MR_ADR==ERR_POS_1)
											begin
												KE = 1'b1;
												K_AMP = ERR_AMP_1;
											end
											else
											begin
												KE = 1'b0;
												K_AMP = 4'b0000;							
											end
								MR_ADR = MR_ADR + 1'b1;
								end
								
								133:	//3
								begin
								i = i + 1;
											if (MR_ADR==ERR_POS_0)
											begin
												KE = 1'b1;
												K_AMP = ERR_AMP_0;
											end
											else if(MR_ADR==ERR_POS_1)
											begin
												KE = 1'b1;
												K_AMP = ERR_AMP_1;
											end
											else
											begin
												KE = 1'b0;
												K_AMP = 4'b0000;							
											end
								MR_ADR = MR_ADR + 1'b1;
								end
								
								134:	//4
								begin
								i = i + 1;
											if (MR_ADR==ERR_POS_0)
											begin
												KE = 1'b1;
												K_AMP = ERR_AMP_0;
											end
											else if(MR_ADR==ERR_POS_1)
											begin
												KE = 1'b1;
												K_AMP = ERR_AMP_1;
											end
											else
											begin
												KE = 1'b0;
												K_AMP = 4'b0000;							
											end
								MR_ADR = MR_ADR + 1'b1;
								end
								
								135:	//5
								begin
								i = i + 1;
											if (MR_ADR==ERR_POS_0)
											begin
												KE = 1'b1;
												K_AMP = ERR_AMP_0;
											end
											else if(MR_ADR==ERR_POS_1)
											begin
												KE = 1'b1;
												K_AMP = ERR_AMP_1;
											end
											else
											begin
												KE = 1'b0;
												K_AMP = 4'b0000;							
											end
								MR_ADR = MR_ADR + 1'b1;
								end
								
								136:	//6
								begin
								i = i + 1;
											if (MR_ADR==ERR_POS_0)
											begin
												KE = 1'b1;
												K_AMP = ERR_AMP_0;
											end
											else if(MR_ADR==ERR_POS_1)
											begin
												KE = 1'b1;
												K_AMP = ERR_AMP_1;
											end
											else
											begin
												KE = 1'b0;
												K_AMP = 4'b0000;							
											end
								MR_ADR = MR_ADR + 1'b1;
								end
								
								137:	//7
								begin
								i = i + 1;
											if (MR_ADR==ERR_POS_0)
											begin
												KE = 1'b1;
												K_AMP = ERR_AMP_0;
											end
											else if(MR_ADR==ERR_POS_1)
											begin
												KE = 1'b1;
												K_AMP = ERR_AMP_1;
											end
											else
											begin
												KE = 1'b0;
												K_AMP = 4'b0000;							
											end
								MR_ADR = MR_ADR + 1'b1;
								end
								
								138:	//8
								begin
								i = i + 1;	
											if (MR_ADR==ERR_POS_0)
											begin
												KE = 1'b1;
												K_AMP = ERR_AMP_0;
											end
											else if(MR_ADR==ERR_POS_1)
											begin
												KE = 1'b1;
												K_AMP = ERR_AMP_1;
											end
											else
											begin
												KE = 1'b0;
												K_AMP = 4'b0000;							
											end
								MR_ADR = MR_ADR + 1'b1;							
								end
								
								139:	//9
								begin
								i = i + 1;
											if (MR_ADR==ERR_POS_0)
											begin
												KE = 1'b1;
												K_AMP = ERR_AMP_0;
											end
											else if(MR_ADR==ERR_POS_1)
											begin
												KE = 1'b1;
												K_AMP = ERR_AMP_1;
											end
											else
											begin
												KE = 1'b0;
												K_AMP = 4'b0000;							
											end
								MR_ADR = MR_ADR + 1'b1;
								end
								
								140:	//10
								begin
								i = i + 1;
											if (MR_ADR==ERR_POS_0)
											begin
												KE = 1'b1;
												K_AMP = ERR_AMP_0;
											end
											else if(MR_ADR==ERR_POS_1)
											begin
												KE = 1'b1;
												K_AMP = ERR_AMP_1;
											end
											else
											begin
												KE = 1'b0;
												K_AMP = 4'b0000;							
											end
								MR_ADR = MR_ADR + 1'b1;
								end
								
								141:	//11
								begin
								i = i + 1;
											if (MR_ADR==ERR_POS_0)
											begin
												KE = 1'b1;
												K_AMP = ERR_AMP_0;
											end
											else if(MR_ADR==ERR_POS_1)
											begin
												KE = 1'b1;
												K_AMP = ERR_AMP_1;
											end
											else
											begin
												KE = 1'b0;
												K_AMP = 4'b0000;							
											end
								MR_ADR = MR_ADR + 1'b1;
								end
								
								142:	//12
								begin
								i = i + 1;
											
											if (MR_ADR==ERR_POS_0)
											begin
												KE = 1'b1;
												K_AMP = ERR_AMP_0;
											end
											else if(MR_ADR==ERR_POS_1)
											begin
												KE = 1'b1;
												K_AMP = ERR_AMP_1;
											end
											else
											begin
												KE = 1'b0;
												K_AMP = 4'b0000;							
											end
								MR_ADR = MR_ADR + 1'b1;
								end
								
								143:		//13
								begin
								i = i + 1;
											
											if (MR_ADR==ERR_POS_0)
											begin
												KE = 1'b1;
												K_AMP = ERR_AMP_0;
											end
											else if(MR_ADR==ERR_POS_1)
											begin
												KE = 1'b1;
												K_AMP = ERR_AMP_1;
											end
											else
											begin
												KE = 1'b0;
												K_AMP = 4'b0000;							
											end
								MR_ADR = MR_ADR + 1'b1;
								end
								
								144:		//14
								begin
								
								i = i + 1;
											CT = 1'b1;
											if (MR_ADR==ERR_POS_0)
											begin
												KE = 1'b1;
												K_AMP = ERR_AMP_0;
											end
											else if(MR_ADR==ERR_POS_1)
											begin
												KE = 1'b1;
												K_AMP = ERR_AMP_1;
											end
											else
											begin
												KE = 1'b0;
												K_AMP = 4'b0000;							
											end
								MR_ADR = MR_ADR + 1'b1;
								end
								
								145:		//15
								begin
								i = i + 1;
											if (MR_ADR==ERR_POS_0)
											begin
												KE = 1'b1;
												K_AMP = ERR_AMP_0;
											end
											else if(MR_ADR==ERR_POS_1)
											begin
												KE = 1'b1;
												K_AMP = ERR_AMP_1;
											end
											else
											begin
												KE = 1'b0;
												K_AMP = 4'b0000;							
											end
								MR_ADR = MR_ADR + 1'b1;
								end
								
								146:
								begin
								GMXE = 1'b0;
								MR_RE = 1'b0;
								MR_ADR = 4'b0000;
								i = i + 1;
								end
								//-------Here is over of decoding cycle, generating impulse "EOW" - end of work
								147:
								begin
								i = i + 1;
								MR_ADR = 4'b0000;
								//reset_device = 1'b1;
								end
								
								148:
								begin
								i = i + 1;
								//reset_device = 1'b0;

								MR_ADR = 4'b0000;
								end
								
								149:		//this is a last clk of cycle. All registers must be zero (reset_device only must be 1)
								begin
								//reset_device = 1'b0;
								reset_device = 1'b1;
								MF = 4'b0000;
								MR_RE = 1'b0;
								MR_ADR = 4'b0000;
								MF = 4'b0000;
								GMXE = 1'b0;	
								SR_WE = 1'b0;
								SR_ADR = 2'b00;
								SR_RE = 1'b0;
								T1E = 1'b0;
								T2E = 1'b0;
								KE = 1'b0;						
								RE = 1'b0;						
								CT = 1'b0;						
								ERR_AMP_0 = 4'b0000;
								ERR_AMP_1 = 4'b0000;
								ERR_POS_0 = 4'b0000;
								ERR_POS_1 = 4'b0000;
								K_AMP = 4'b0000;
								i = i + 1;
								end
								
								default://------------put here what will doing this device by default
								begin
								reset_device = 1'b0;
								device_in_work = 1'b0;
								MF = 4'b0000;
								MR_WE_1 = 1'b0;
								MR_RE = 1'b0;
								MR_ADR = 4'b0000;
								MF = 4'b0000;
								GMXE = 1'b0;
								SR_ADR = 2'b00;
								SR_RE = 1'b0;
								T1E = 1'b0;
								T2E = 1'b0;
								KE = 1'b0;						
								RE = 1'b0;						
								CT = 1'b0;						
								ERR_AMP_0 = 4'b0000;
								ERR_AMP_1 = 4'b0000;
								ERR_POS_0 = 4'b0000;
								ERR_POS_1 = 4'b0000;
								K_AMP = 4'b0000;
								end
								endcase
					end
					else
					
					begin
					i = 0; 
					device_in_work = 1'b0;
					MR_WE_1 = 1'b0;
					MR_RE = 1'b0;
					MR_ADR = 4'b0000;
					GMXE = 1'b0;
					KE = 1'b0;						
					RE = 1'b0;						
					CT = 1'b0;						
					ERR_AMP_0 = 4'b0000;
					ERR_AMP_1 = 4'b0000;
					ERR_POS_0 = 4'b0000;
					ERR_POS_1 = 4'b0000;
					K_AMP = 4'b0000;
					end
			end
end	


assign START_LOCATOR = SL;
assign SYNDROME_RAM_WR_ENA = SR_WE;
assign SYNDROME_RAM_RD_ENA = SR_RE;
assign SYNDROME_RAM_ADR[0] = SR_ADR[0];
assign SYNDROME_RAM_ADR[1] = SR_ADR[1];
assign SYNDROME_RAM_ADR[2] = SR_ADR[2];
assign SYNDROME_RAM_ADR[3] = SR_ADR[3];
assign MAIN_RAM_ADR[0] = MR_ADR[0];
assign MAIN_RAM_ADR[1] = MR_ADR[1];
assign MAIN_RAM_ADR[2] = MR_ADR[2];
assign MAIN_RAM_ADR[3] = MR_ADR[3];
assign MULTIPLYER[0] = MF[3];
assign MULTIPLYER[1] = MF[2];
assign MULTIPLYER[2] = MF[1];
assign MULTIPLYER[3] = MF[0];
assign G_ENA = GMXE;
assign END_OF_WORK = device_in_work && reset_device;
assign MAIN_RAM_WR = MR_WE_1;
assign MAIN_RAM_RD = MR_RE;
assign TAB1_ENA = T1E;
assign TAB2_ENA = T2E;

assign KILL_AMPLITUDE[0] = K_AMP[0];
assign KILL_AMPLITUDE[1] = K_AMP[1];
assign KILL_AMPLITUDE[2] = K_AMP[2];
assign KILL_AMPLITUDE[3] = K_AMP[3];

assign KILL_ERROR = KE;
assign REPAIR_ENABLE = RE;
assign CUT_TAIL = CT;
endmodule

//------------------------------------------------------------------
//--------------------------main RAM--------------------------------
//This module saves 15 words x 4 bits (as a long of coded message)


module MAIN_RAM (		input WR_ENA,
						input reset,
						input RD_ENA,				
						input CLK,								
						input [3:0] DATA_IN,					
						input [3:0] ADR,				
								output reg [3:0] DATA_OUT	);
					     				          	    														
reg [3:0] dreg [15:0];   	

always @ (posedge CLK)

begin

		
						case (WR_ENA)
							1'b1:
								begin
								dreg [ADR] = DATA_IN[3:0];    
								end
							1'b0:
								begin
								DATA_OUT = 4'b0000;
								end
							default:
								begin
								DATA_OUT = 4'b0000;
								end
						endcase
						case (RD_ENA)
							1'b1:
								begin
								DATA_OUT[3:0] = dreg [ADR];   				
								end
							1'b0:
								begin
								DATA_OUT[3:0] = 4'b0000;
								end
							
							default:
								begin
								DATA_OUT[3:0] = 4'b0000;
								end
							endcase
						case (reset)
							1'b1:
								begin
								dreg [4'b1111] = 4'b0000;
								dreg [4'b0111] = 4'b0000;
								dreg [4'b1011] = 4'b0000;
								dreg [4'b0011] = 4'b0000;
								dreg [4'b1101] = 4'b0000;
								dreg [4'b0101] = 4'b0000;
								dreg [4'b1001] = 4'b0000;
								dreg [4'b0001] = 4'b0000;
								dreg [4'b1110] = 4'b0000;
								dreg [4'b0110] = 4'b0000;
								dreg [4'b1010] = 4'b0000;
								dreg [4'b0010] = 4'b0000;
								dreg [4'b1100] = 4'b0000;
								dreg [4'b0100] = 4'b0000;
								dreg [4'b1000] = 4'b0000;
								dreg [4'b0000] = 4'b0000;

								end
							1'b0:
								begin
								
								end
							default:
								begin
								
								end
							endcase
	
end
endmodule

//------------------------------------------------------------------
//--------------------Galua Multiplier------------------------------
//This module work like a simple multiply table---------------------
module MULTIPLYER_GALUA (ena,reset,clk, Data_in_0, Data_in_1,Data_in_2, Data_in_3, Multiply_factor,
								Data_out);
input clk;
input reset;
input ena;
input Data_in_0; input Data_in_1; input Data_in_2; input Data_in_3;
input [3:0] Multiply_factor;
output reg[3:0] Data_out;
reg [3:0] Data_in;
always @(posedge clk)
begin
		if (reset)
		begin
		Data_out = 4'b0000;
		end
		
		if(ena)
		begin
				Data_in[0] = Data_in_0; 
				Data_in[1] = Data_in_1; 
				Data_in[2] = Data_in_2; 
				Data_in[3] = Data_in_3;
				case (Multiply_factor)
				4'b0000:
						begin
						Data_out = Data_in;
						end
				4'b0100:
						begin
								case (Data_in)
								4'b0000:
								begin		//a^1 * 0 = 0
								Data_out = 4'b0000;
								end
								4'b0100:
								begin		//a^1 * a^1 = a^2
								Data_out = 4'b0010;
								end
								4'b0010:
								begin		//a^1 * a^2 = a^3
								Data_out = 4'b0001;
								end
								4'b0001:
								begin		//a^1 * a^3 = a^4
								Data_out = 4'b1100;
								end
								4'b1100:
								begin		//a^1 * a^4 = a^5
								Data_out = 4'b0110;
								end
								4'b0110:
								begin		//a^1 * a^5 = a^6
								Data_out = 4'b0011;
								end
								4'b0011:
								begin		//a^1 * a^6 = a^7
								Data_out = 4'b1101;
								end
								4'b1101:
								begin		//a^1 * a^7 = a^8
								Data_out = 4'b1010;
								end
								4'b1010:
								begin		//a^1 * a^8 = a^9
								Data_out = 4'b0101;
								end
								4'b0101:
								begin		//a^1 * a^9 = a^10
								Data_out = 4'b1110;
								end
								4'b1110:
								begin		//a^1 * a^10 = a^11
								Data_out = 4'b0111;
								end
								4'b0111:
								begin		//a^1 * a^11 = a^12
								Data_out = 4'b1111;
								end
								4'b1111:
								begin		//a^1 * a^12 = a^13
								Data_out = 4'b1011;
								end
								4'b1011:
								begin		//a^1 * a^13 = a^14
								Data_out = 4'b1001;
								end
								4'b1001:
								begin		//a^1 * a^14 = a^15
								Data_out = 4'b1000;
								end
								4'b1000:	//a^1 * a^15 = a^16 = a^1
								begin
								Data_out = 4'b0100;
								end
								default:
								begin
								Data_out = 4'b0000;
								end
								endcase
						end
				4'b0010:
						begin
								case (Data_in)
								4'b0000:
								begin		//a^2 * 0 = 0
								Data_out = 4'b0000;
								end
								4'b0100:
								begin		//a^2 * a^1 = a^3
								Data_out = 4'b0001;
								end
								4'b0010:
								begin		//a^2 * a^2 = a^4
								Data_out = 4'b1100;
								end
								4'b0001:
								begin		//a^2 * a^3 = a^5
								Data_out = 4'b0110;
								end
								4'b1100:
								begin		//a^2 * a^4 = a^6
								Data_out = 4'b0011;
								end
								4'b0110:
								begin		//a^2 * a^5 = a^7
								Data_out = 4'b1101;
								end
								4'b0011:
								begin		//a^2 * a^6 = a^8
								Data_out = 4'b1010;
								end
								4'b1101:
								begin		//a^2 * a^7 = a^9
								Data_out = 4'b0101;
								end
								4'b1010:
								begin		//a^2 * a^8 = a^10
								Data_out = 4'b1110;
								end
								4'b0101:
								begin		//a^2 * a^9 = a^11
								Data_out = 4'b0111;
								end
								4'b1110:
								begin		//a^2 * a^10 = a^12
								Data_out = 4'b1111;
								end
								4'b0111:
								begin		//a^2 * a^11 = a^13
								Data_out = 4'b1011;
								end
								4'b1111:
								begin		//a^2 * a^12 = a^14
								Data_out = 4'b1001;
								end
								4'b1011:
								begin		//a^2 * a^13 = a^15
								Data_out = 4'b1000;
								end
								4'b1001:
								begin		//a^2 * a^14 = a^16 = a^1
								Data_out = 4'b0100;
								end
								4'b1000:
								begin		//a^2 * a^15 = a^17 = a^2
								Data_out = 4'b0010;
								end
								default:
								begin
								Data_out = 4'b0000;
								end
								endcase
						end
				4'b0001:
						begin
								case (Data_in)
								4'b0000:
								begin		//a^3 * 0 = 0
								Data_out = 4'b0000;
								end
								4'b0100:
								begin		//a^3 * a^1 = a^4
								Data_out = 4'b1100;
								end
								4'b0010:
								begin		//a^3 * a^2 = a^5
								Data_out = 4'b0110;
								end
								4'b0001:
								begin		//a^3 * a^3 = a^6
								Data_out = 4'b0011;
								end
								4'b1100:
								begin		//a^3 * a^4 = a^7
								Data_out = 4'b1101;
								end
								4'b0110:
								begin		//a^3 * a^5 = a^8
								Data_out = 4'b1010;
								end
								4'b0011:
								begin		//a^3 * a^6 = a^9
								Data_out = 4'b0101;
								end
								4'b1101:
								begin		//a^3 * a^7 = a^10
								Data_out = 4'b1110;
								end
								4'b1010:
								begin		//a^3 * a^8 = a^11
								Data_out = 4'b0111;
								end
								4'b0101:
								begin		//a^3 * a^9 = a^12
								Data_out = 4'b1111;
								end
								4'b1110:
								begin		//a^3 * a^10 = a^13
								Data_out = 4'b1011;
								end
								4'b0111:
								begin		//a^3 * a^11 = a^14
								Data_out = 4'b1001;
								end
								4'b1111:
								begin		//a^3 * a^12 = a^15
								Data_out = 4'b1000;
								end
								4'b1011:
								begin		//a^3 * a^13 = a^16 = a^1
								Data_out = 4'b0100;
								end
								4'b1001:
								begin		//a^3 * a^14 = a^17 = a^2
								Data_out = 4'b0010;
								end
								4'b1000:
								begin		//a^3 * a^15 = a^18 = a^3
								Data_out = 4'b0001;
								end
								default:
								begin		
								Data_out = 4'b0000;
								end
								endcase
						end
				4'b1100:
						begin
								case (Data_in)
								4'b0000:
								begin		//a^4 * 0 = 0
								Data_out = 4'b0000;
								end
								4'b0100:
								begin		//a^4 * a^1 = a^5
								Data_out = 4'b0110;
								end
								4'b0010:
								begin		//a^4 * a^2 = a^6
								Data_out = 4'b0011;
								end
								4'b0001:
								begin		//a^4 * a^3 = a^7
								Data_out = 4'b1101;
								end
								4'b1100:
								begin		//a^4 * a^4 = a^8
								Data_out = 4'b1010;
								end
								4'b0110:
								begin		//a^4 * a^5 = a^9
								Data_out = 4'b0101;
								end
								4'b0011:
								begin		//a^4 * a^6 = a^10
								Data_out = 4'b1110;
								end
								4'b1101:
								begin		//a^4 * a^7 = a^11
								Data_out = 4'b0111;
								end
								4'b1010:
								begin		//a^4 * a^8 = a^12
								Data_out = 4'b1111;
								end
								4'b0101:
								begin		//a^4 * a^9 = a^13
								Data_out = 4'b1011;
								end
								4'b1110:
								begin		//a^4 * a^10 = a^14
								Data_out = 4'b1001;
								end
								4'b0111:
								begin		//a^4 * a^11 = a^15
								Data_out = 4'b1000;
								end
								4'b1111:
								begin		//a^4 * a^12 = a^16 = a^1
								Data_out = 4'b0100;
								end
								4'b1011:
								begin		//a^4 * a^13 = a^17 = a^2
								Data_out = 4'b0010;
								end
								4'b1001:
								begin		//a^4 * a^14 = a^18 = a^3
								Data_out = 4'b0001;
								end
								4'b1000:
								begin		//a^4 * a^15 = a^19 = a^4
								Data_out = 4'b1100;
								end
								default:
								begin
								Data_out = 4'b0000;
								end
								endcase
						end
				4'b0110:
						begin
								case (Data_in)
								4'b0000:
								begin		//a^5 * 0 = 0
								Data_out = 4'b0000;
								end
								4'b0100:
								begin		//a^5 * a^1 = a^6
								Data_out = 4'b0011;
								end
								4'b0010:
								begin		//a^5 * a^2 = a^7
								Data_out = 4'b1101;
								end
								4'b0001:
								begin		//a^5 * a^3 = a^8
								Data_out = 4'b1010;
								end
								4'b1100:
								begin		//a^5 * a^4 = a^9
								Data_out = 4'b0101;
								end
								4'b0110:
								begin		//a^5 * a^5 = a^10
								Data_out = 4'b1110;
								end
								4'b0011:
								begin		//a^5 * a^6 = a^11
								Data_out = 4'b0111;
								end
								4'b1101:
								begin		//a^5 * a^7 = a^12
								Data_out = 4'b1111;
								end
								4'b1010:
								begin		//a^5 * a^8 = a^13
								Data_out = 4'b1011;
								end
								4'b0101:
								begin		//a^5 * a^9 = a^14
								Data_out = 4'b1001;
								end
								4'b1110:
								begin		//a^5 * a^10 = a^15
								Data_out = 4'b1000;
								end
								4'b0111:
								begin		//a^5 * a^11 = a^16 = a^1
								Data_out = 4'b0100;
								end
								4'b1111:
								begin		//a^5 * a^12 = a^17 = a^2
								Data_out = 4'b0010;
								end
								4'b1011:
								begin		//a^5 * a^13 = a^18 = a^3
								Data_out = 4'b0001;
								end
								4'b1001:
								begin		//a^5 * a^14 = a^19 = a^4
								Data_out = 4'b1100;
								end
								4'b1000:
								begin		//a^5 * a^15 = a^20 = a^5
								Data_out = 4'b0110;
								end
								default:
								begin
								Data_out = 4'b0000;
								end
								endcase
						end
				4'b0011:
						begin
								case (Data_in)
								4'b0000:
								begin		//a^6 * 0 =0
								Data_out = 4'b0000;
								end
								4'b0100:
								begin		//a^6 * a^1 = a^7
								Data_out = 4'b1101;
								end
								4'b0010:
								begin		//a^6 * a^2 = a^8
								Data_out = 4'b1010;
								end
								4'b0001:
								begin		//a^6 * a^3 = a^9
								Data_out = 4'b0101;
								end
								4'b1100:
								begin		//a^6 * a^4 = a^10
								Data_out = 4'b1110;
								end
								4'b0110:
								begin		//a^6 * a^5 = a^11
								Data_out = 4'b0111;
								end
								4'b0011:
								begin		//a^6 * a^6 = a^12
								Data_out = 4'b1111;
								end
								4'b1101:
								begin		//a^6 * a^7 = a^13
								Data_out = 4'b1011;
								end
								4'b1010:
								begin		//a^6 * a^8 = a^14
								Data_out = 4'b1001;
								end
								4'b0101:
								begin		//a^6 * a^9 = a^15
								Data_out = 4'b1000;
								end
								4'b1110:
								begin		//a^6 * a^10 = a^16 = a^1
								Data_out = 4'b0100;
								end
								4'b0111:
								begin		//a^6 * a^11 = a^17 = a^2
								Data_out = 4'b0010;
								end
								4'b1111:
								begin		//a^6 * a^12 = a^18 = a^3
								Data_out = 4'b0001;
								end
								4'b1011:
								begin		//a^6 * a^13 = a^19 = a^4
								Data_out = 4'b1100;
								end
								4'b1001:
								begin		//a^6 * a^14 = a^20 = a^5
								Data_out = 4'b0110;
								end
								4'b1000:
								begin		//a^6 * a^15 = a^21 = a^6
								Data_out = 4'b0011;
								end
								default:
								begin
								Data_out = 4'b0000;
								end
								endcase
						end
				4'b1101:
						begin
								case (Data_in)
								4'b0000:
								begin		//a^7 * 0 = 0
								Data_out = 4'b0000;
								end
								4'b0100:
								begin		//a^7 * a^1 = a^8
								Data_out = 4'b1010;
								end
								4'b0010:
								begin		//a^7 * a^2 = a^9
								Data_out = 4'b0101;
								end
								4'b0001:
								begin		//a^7 * a^3 = a^10
								Data_out = 4'b1110;
								end
								4'b1100:
								begin		//a^7 * a^4 = a^11
								Data_out = 4'b0111;
								end
								4'b0110:
								begin		//a^7 * a^5 = a^12
								Data_out = 4'b1111;
								end
								4'b0011:
								begin		//a^7 * a^6 = a^13
								Data_out = 4'b1011;
								end
								4'b1101:
								begin		//a^7 * a^7 = a^14
								Data_out = 4'b1001;
								end
								4'b1010:
								begin		//a^7 * a^8 = a^15
								Data_out = 4'b1000;
								end
								4'b0101:
								begin		//a^7 * a^9 = a^16 = a^1
								Data_out = 4'b0100;
								end
								4'b1110:
								begin		//a^7 * a^10 = a^17 = a^2
								Data_out = 4'b0010;
								end
								4'b0111:
								begin		//a^7 * a^11 = a^18 = a^3
								Data_out = 4'b0001;
								end
								4'b1111:
								begin		//a^7 * a^12 = a^19 = a^4
								Data_out = 4'b1100;
								end
								4'b1011:
								begin		//a^7 * a^13 = a^20 = a^5
								Data_out = 4'b0110;
								end
								4'b1001:
								begin		//a^7 * a^14 = a^21 = a^6
								Data_out = 4'b0011;
								end
								4'b1000:
								begin		//a^7 * a^15 = a^22 = a^7
								Data_out = 4'b1101;
								end
								default:
								begin
								Data_out = 4'b0000;
								end
								endcase
						end
				4'b1010:
						begin
								case (Data_in)
								4'b0000:
								begin		//a^8 * 0 = 0
								Data_out = 4'b0000;
								end
								4'b0100:
								begin		//a^8 * a^1 = a^9
								Data_out = 4'b0101;
								end
								4'b0010:
								begin		//a^8 * a^2 = a^10
								Data_out = 4'b1110;
								end
								4'b0001:
								begin		//a^8 * a^3 = a^11
								Data_out = 4'b0111;
								end
								4'b1100:
								begin		//a^8 * a^4 = a^12
								Data_out = 4'b1111;
								end
								4'b0110:
								begin		//a^8 * a^5 = a^13
								Data_out = 4'b1011;
								end
								4'b0011:
								begin		//a^8 * a^6 = a^14
								Data_out = 4'b1001;
								end
								4'b1101:
								begin		//a^8 * a^7 = a^15
								Data_out = 4'b1000;
								end
								4'b1010:
								begin		//a^8 * a^8 = a^16 = a^1
								Data_out = 4'b0100;
								end
								4'b0101:
								begin		//a^8 * a^9 = a^17 = a^2
								Data_out = 4'b0010;
								end
								4'b1110:
								begin		//a^8 * a^10 = a^18 = a^3
								Data_out = 4'b0001;
								end
								4'b0111:
								begin		//a^8 * a^11 = a^19 = a^4
								Data_out = 4'b1100;
								end
								4'b1111:	
								begin		//a^8 * a^12 = a^20 = a^5
								Data_out = 4'b0110;
								end
								4'b1011:
								begin		//a^8 * a^13 = a^21 = a^6		
								Data_out = 4'b0011;
								end
								4'b1001:
								begin		//a^8 * a^14 = a^22 = a^7
								Data_out = 4'b1101;
								end
								4'b1000:
								begin		//a^8 * a^15 = a^23 = a^8
								Data_out = 4'b1010;
								end
								default:
								begin
								Data_out = 4'b0000;
								end
								endcase
						end
				4'b0101:
						begin
								case (Data_in)
								4'b0000:
								begin		//a^9 * 0 = 0
								Data_out = 4'b0000;
								end
								4'b0100:
								begin		//a^9 * a^1 = a^10
								Data_out = 4'b1110;
								end
								4'b0010:
								begin		//a^9 * a^2 = a^11
								Data_out = 4'b0111;
								end
								4'b0001:
								begin		//a^9 * a^3 = a^12
								Data_out = 4'b1111;
								end
								4'b1100:
								begin		//a^9 * a^4 = a^13
								Data_out = 4'b1011;
								end
								4'b0110:
								begin		//a^9 * a^5 = a^14
								Data_out = 4'b1001;
								end
								4'b0011:
								begin		//a^9 * a^6 = a^15
								Data_out = 4'b1000;
								end
								4'b1101:
								begin		//a^9 * a^7 = a^16 = a^1
								Data_out = 4'b0100;
								end
								4'b1010:
								begin		//a^9 * a^8 = a^17 = a^2
								Data_out = 4'b0010;
								end
								4'b0101:
								begin		//a^9 * a^9 = a^18 = a^3
								Data_out = 4'b0001;
								end
								4'b1110:
								begin		//a^9 * a^10 = a^19 = a^4
								Data_out = 4'b1100;
								end
								4'b0111:
								begin		//a^9 * a^11 = a^20 = a^5
								Data_out = 4'b0110;
								end
								4'b1111:
								begin		//a^9 * a^12 = a^21 = a^6
								Data_out = 4'b0011;
								end
								4'b1011:
								begin		//a^9 * a^13 = a^22 = a^7
								Data_out = 4'b1101;
								end
								4'b1001:
								begin		//a^9 * a^14 = a^23 = a^8
								Data_out = 4'b1010;
								end
								4'b1000:
								begin		//a^9 * a^15 = a^24 = a^9
								Data_out = 4'b0101;
								end
								default:
								begin
								Data_out = 4'b0000;
								end
								endcase
						end
				4'b1110:
						begin
								case (Data_in)
								4'b0000:
								begin		//a^10 * 0 = 0
								Data_out = 4'b0000;
								end
								4'b0100:
								begin		//a^10 * a^1 = a^11
								Data_out = 4'b0111;
								end
								4'b0010:
								begin		//a^10 * a^2 = a^12
								Data_out = 4'b1111;
								end
								4'b0001:
								begin		//a^10 * a^3 = a^13
								Data_out = 4'b1011;
								end
								4'b1100:
								begin		//a^10 * a^4 = a^14
								Data_out = 4'b1001;
								end
								4'b0110:
								begin		//a^10 * a^5 = a^15
								Data_out = 4'b1000;
								end
								4'b0011:
								begin		//a^10 * a^6 = a^16 = a^1
								Data_out = 4'b0100;
								end
								4'b1101:
								begin		//a^10 * a^7 = a^17 = a^2
								Data_out = 4'b0010;
								end
								4'b1010:
								begin		//a^10 * a^8 = a^18 = a^3
								Data_out = 4'b0001;
								end
								4'b0101:
								begin		//a^10 * a^9 = a^19 = a^4
								Data_out = 4'b1100;
								end
								4'b1110:
								begin		//a^10 * a^10 = a^20 = a^5
								Data_out = 4'b0110;
								end
								4'b0111:
								begin		//a^10 * a^11 = a^21 = a^6
								Data_out = 4'b0011;
								end
								4'b1111:
								begin		//a^10 * a^12 = a^22 = a^7
								Data_out = 4'b1101;
								end
								4'b1011:
								begin		//a^10 * a^13 = a^23 = a^8
								Data_out = 4'b1010;
								end
								4'b1001:
								begin		//a^10 * a^14 = a^24 = a^9
								Data_out = 4'b0101;
								end
								4'b1000:
								begin		//a^10 * a^15 = a^25 = a^10
								Data_out = 4'b1110;
								end
								default:
								begin
								Data_out = 4'b0000;
								end
								endcase
						end
				4'b0111:
						begin
								case (Data_in)
								4'b0000:
								begin		//a^11 * 0 = 0
								Data_out = 4'b0000;
								end
								4'b0100:
								begin		//a^11 * a^1 = a^12
								Data_out = 4'b1111;
								end
								4'b0010:
								begin		//a^11 * a^2 = a^13
								Data_out = 4'b1011;
								end
								4'b0001:
								begin		//a^11 * a^3 = a^14
								Data_out = 4'b1001;
								end
								4'b1100:
								begin		//a^11 * a^4 = a^15
								Data_out = 4'b1000;
								end
								4'b0110:
								begin		//a^11 * a^5 = a^16 = a^1
								Data_out = 4'b0100;
								end
								4'b0011:
								begin		//a^11 * a^6 = a^17 = a^2
								Data_out = 4'b0010;
								end
								4'b1101:
								begin		//a^11 * a^7 = a^18 = a^3
								Data_out = 4'b0001;
								end
								4'b1010:
								begin		//a^11 * a^8 = a^19 = a^4
								Data_out = 4'b1100;
								end
								4'b0101:
								begin		//a^11 * a^9 = a^20 = a^5
								Data_out = 4'b0110;
								end
								4'b1110:
								begin		//a^11 * a^10 = a^21 = a^6
								Data_out = 4'b0011;
								end
								4'b0111:
								begin		//a^11 * a^11 = a^22 = a^7
								Data_out = 4'b1101;
								end
								4'b1111:
								begin		//a^11 * a^12 = a^23 = a^8
								Data_out = 4'b1010;
								end
								4'b1011:
								begin		//a^11 * a^13 = a^24 = a^9
								Data_out = 4'b0101;
								end
								4'b1001:
								begin		//a^11 * a^14 = a^25 = a^10
								Data_out = 4'b1110;
								end
								4'b1000:
								begin		//a^11 * a^15 = a^26 = a^11
								Data_out = 4'b0111;
								end
								default:
								begin
								Data_out = 4'b0000;
								end
								endcase
						end
				4'b1111:
						begin
								case (Data_in)
								4'b0000:
								begin		//a^12 * 0 = 0
								Data_out = 4'b0000;
								end
								4'b0100:
								begin		//a^12 * a^1 = a^13
								Data_out = 4'b1011;
								end
								4'b0010:
								begin		//a^12 * a^2 = a^14
								Data_out = 4'b1001;
								end
								4'b0001:
								begin		//a^12 * a^3 = a^15
								Data_out = 4'b1000;
								end
								4'b1100:
								begin		//a^12 * a^4 = a^16 = a^1
								Data_out = 4'b0100;
								end
								4'b0110:
								begin		//a^12 * a^5 = a^17 = a^2
								Data_out = 4'b0010;
								end
								4'b0011:
								begin		//a^12 * a^6 = a^18 = a^3		
								Data_out = 4'b0001;
								end
								4'b1101:
								begin		//a^12 * a^7 = a^19 = a^4
								Data_out = 4'b1100;
								end
								4'b1010:
								begin		//a^12 * a^8 = a^20 = a^5
								Data_out = 4'b0110;
								end
								4'b0101:
								begin		//a^12 * a^9 = a^21 = a^6
								Data_out = 4'b0011;
								end
								4'b1110:
								begin		//a^12 * a^10 = a^22 = a^7
								Data_out = 4'b1101;
								end
								4'b0111:
								begin		//a^12 * a^11 = a^23 = a^8
								Data_out = 4'b1010;
								end
								4'b1111:
								begin		//a^12 * a^12 = a^24 = a^9
								Data_out = 4'b0101;
								end
								4'b1011:
								begin		//a^12 * a^13 = a^25 = a^10
								Data_out = 4'b1110;
								end
								4'b1001:
								begin		//a^12 * a^14 = a^26 = a^11
								Data_out = 4'b0111;
								end
								4'b1000:
								begin		//a^12 * a^15 = a^27 = a^12
								Data_out = 4'b1111;
								end
								default:
								begin
								Data_out = 4'b0000;
								end
								endcase
						end
				4'b1011:
						begin
								case (Data_in)
								4'b0000:
								begin		//a^13 * 0 = 0
								Data_out = 4'b0000;
								end
								4'b0100:
								begin		//a^13 * a^1 = a^14
								Data_out = 4'b1001;
								end
								4'b0010:
								begin		//a^13 * a^2 = a^15
								Data_out = 4'b1000;
								end
								4'b0001:
								begin		//a^13 * a^3 = a^16 = a^1
								Data_out = 4'b0100;
								end
								4'b1100:
								begin		//a^13 * a^4 = a^17 = a^2
								Data_out = 4'b0010;
								end
								4'b0110:
								begin		//a^13 * a^5 = a^18 = a^3 
								Data_out = 4'b0001;
								end
								4'b0011:
								begin		//a^13 * a^6 = a^19 = a^4
								Data_out = 4'b1100;
								end
								4'b1101:
								begin		//a^13 * a^7 = a^20 = a^5
								Data_out = 4'b0110;
								end
								4'b1010:
								begin		//a^13 * a^8 = a^21 = a^6
								Data_out = 4'b0011;
								end
								4'b0101:
								begin		//a^13 * a^9 = a^22 = a^7
								Data_out = 4'b1101;
								end
								4'b1110:
								begin		//a^13 * a^10 = a^23 = a^8
								Data_out = 4'b1010;
								end
								4'b0111:
								begin		//a^13 * a^11 = a^24 = a^9
								Data_out = 4'b0101;
								end
								4'b1111:
								begin		//a^13 * a^12 = a^25 = a^10
								Data_out = 4'b1110;
								end
								4'b1011:
								begin		//a^13 * a^13 = a^26 = a^11
								Data_out = 4'b0111;
								end
								4'b1001:
								begin		//a^13 * a^14 = a^27 = a^12
								Data_out = 4'b1111;
								end
								4'b1000:
								begin		//a^13 * a^15 = a^28 = a^13
								Data_out = 4'b1011;
								end
								default:
								begin
								Data_out = 4'b0000;
								end
								endcase
						end
				4'b1001:
						begin
								case (Data_in)
								4'b0000:
								begin		//a^14 * 0 = 0000
								Data_out = 4'b0000;
								end
								4'b0100:
								begin		//a^14 * a^1 = a^15
								Data_out = 4'b1000;
								end
								4'b0010:
								begin		//a^14 * a^2 = a^16 = a^1
								Data_out = 4'b0100;
								end
								4'b0001:
								begin		//a^14 * a^3 = a^17 = a^2
								Data_out = 4'b0010;
								end
								4'b1100:
								begin		//a^14 * a^4 = a^18 = a^3
								Data_out = 4'b0001;
								end
								4'b0110:
								begin		//a^14 * a^5 = a^19 = a^4
								Data_out = 4'b1100;
								end
								4'b0011:
								begin		//a^14 * a^6 = a^20 = a^5
								Data_out = 4'b0110;
								end
								4'b1101:
								begin		//a^14 * a^7 = a^21 = a^6
								Data_out = 4'b0011;
								end
								4'b1010:
								begin		//a^14 * a^8 = a^22 = a^7
								Data_out = 4'b1101;
								end
								4'b0101:
								begin		//a^14 * a^9 = a^23 = a^8
								Data_out = 4'b1010;
								end
								4'b1110:
								begin		//a^14 * a^10 = a^24 = a^9
								Data_out = 4'b0101;
								end
								4'b0111:
								begin		//a^14 * a^11 = a^25 = a^10
								Data_out = 4'b1110;
								end
								4'b1111:
								begin		//a^14 * a^12 = a^26 = a^11
								Data_out = 4'b0111;
								end
								4'b1011:
								begin		//a^14 * a^13 = a^27 = a^12
								Data_out = 4'b1111;
								end
								4'b1001:
								begin		//a^14 * a^14 = a^28 = a^13
								Data_out = 4'b1011;
								end
								4'b1000:
								begin		//a^14 * a^15 = a^29 = a^14
								Data_out = 4'b1001;
								end
								default:
								begin
								Data_out = 4'b0000;
								end
								endcase
						end
				4'b1000:
						begin
								case (Data_in)
								4'b0000:
								begin		//a^15 * 0 = 0000
								Data_out = 4'b0000;
								end
								4'b0100:
								begin		//a^15 * a^1 = a^16 = a^1
								Data_out = 4'b0100;
								end
								4'b0010:
								begin		//a^15 * a^2 = a^17 = a^2
								Data_out = 4'b0010;
								end
								4'b0001:
								begin		//a^15 * a^3 = a^18 = a^3
								Data_out = 4'b0001;
								end
								4'b1100:
								begin		//a^15 * a^4 = a^19 = a^4
								Data_out = 4'b1100;
								end
								4'b0110:
								begin		//a^15 * a^5 = a^20 = a^5
								Data_out = 4'b0110;
								end
								4'b0011:
								begin		//a^15 * a^6 = a^21 = a^6
								Data_out = 4'b0011;
								end
								4'b1101:
								begin		//a^15 * a^7 = a^22 = a^7
								Data_out = 4'b1101;
								end
								4'b1010:
								begin		//a^15 * a^8 = a^23 = a^8
								Data_out = 4'b1010;
								end
								4'b0101:
								begin		//a^15 * a^9 = a^24 = a^9
								Data_out = 4'b0101;
								end
								4'b1110:
								begin		//a^15 * a^10 = a^25 = a^10
								Data_out = 4'b1110;
								end
								4'b0111:
								begin		//a^15 * a^11 = a^26 = a^11
								Data_out = 4'b0111;
								end
								4'b1111:
								begin		//a^15 * a^12 = a^27 = a^12
								Data_out = 4'b1111;
								end
								4'b1011:
								begin		//a^15 * a^13 = a^28 = a^13
								Data_out = 4'b1011;
								end
								4'b1001:
								begin		//a^15 * a^14 = a^29 = a^14
								Data_out = 4'b1001;
								end
								4'b1000:
								begin		//a^15 * a^15 = a^30 = a^15
								Data_out = 4'b1000;
								end
								default:
								begin
								Data_out = 4'b0000;
								end
								endcase
						end
				default:
				begin
				Data_out = 4'b0000;
				end
				endcase
				
				
		end
		
		else
		begin
		Data_out = 4'b0000;
		end
end

 
endmodule
//-----------------------------------------------------------------------
//-------------------XOR processor---------------------------------------
module PROC_XOR(ena, clk, Data_in, Delayed_data_OZU, repair, Kill_amplitude, kill, Data_OZU, cut_tail, Data_out, Repaired_data_out);
input ena;
input clk;
input [3:0] Data_in;
input repair;
input [3:0] Kill_amplitude;
input kill;
input [3:0] Data_OZU;
input [3:0] Delayed_data_OZU;
input cut_tail;
output reg [3:0] Data_out = 4'b0000;
reg [3:0] Repaired_data;
output reg [3:0] Repaired_data_out = 4'b0000;
reg [3:0] xoringA;
reg [3:0] xoringB;
reg [3:0] xored;

wire [3:0] Repaired_data_wire;

integer i = 0;
integer j = 0;
always @ (posedge clk)
begin
	case (ena)
	1'b1:
	begin	
		xoringA = Data_in;
		if (i == 1)
		begin
		xored = xoringA ^ 4'b0000;
		end
		else
		begin
		xoringB = Data_out;
		xored = xoringA ^ xoringB;
		end
		Data_out = xored;
		i = i + 1;
	end

			
	default:
	begin
	i = 0;
	Data_out = Data_in ^ xored;
	end
	endcase
	
	case (repair)
	1'b1:
	begin
			case(kill)
			1'b1:
			begin
			Repaired_data = Delayed_data_OZU ^ Kill_amplitude;
			end
			default:
			begin
			Repaired_data = Delayed_data_OZU;
			end
			endcase
		
	end
	default:
	begin
		Repaired_data = 4'b0000;
	end
	endcase
end

always @ (posedge clk)
begin
	if (cut_tail)
	
	begin
	Repaired_data_out = 4'b0000;
	end
	else
	begin
	Repaired_data_out = Repaired_data_wire;
	end
	
end

assign Repaired_data_wire[0] = Repaired_data[0];
assign Repaired_data_wire[1] = Repaired_data[1];
assign Repaired_data_wire[2] = Repaired_data[2];
assign Repaired_data_wire[3] = Repaired_data[3];
endmodule
//----------------------------------------------------
//DTRIGGER-
//----------------------------------------------------
module DTRIGGER(	input DATA_IN,							
					input CLK,									
					output reg DATA_OUT	);				
always @ (posedge CLK)
begin
DATA_OUT = DATA_IN;
end
endmodule

//----------------------------------------------------
//SYNDROME_MEMORY
//----------------------------------------------------
module SYNDROME_RAM (wr_ena, rd_ena, clk, Data_in, Adr, 
                 Data_out0_0, Data_out0_1, Data_out0_2, Data_out0_3,
                 Data_out1_0, Data_out1_1, Data_out1_2, Data_out1_3,
                 Data_out2_0, Data_out2_1, Data_out2_2, Data_out2_3,
                 Data_out3_0, Data_out3_1, Data_out3_2, Data_out3_3,
                 reset);
					     				          	
input reset;
input clk;      		
input wire [3:0] Data_in;		
input wire [3:0] Adr;	
reg [3:0] Data_out0;
reg [3:0] Data_out1;
reg [3:0] Data_out2;
reg [3:0] Data_out3;   
 	
input wire wr_ena;				
input wire rd_ena;	

output Data_out0_0; output Data_out0_1; output Data_out0_2; output Data_out0_3;
output Data_out1_0; output Data_out1_1; output Data_out1_2; output Data_out1_3;
output Data_out2_0; output Data_out2_1; output Data_out2_2; output Data_out2_3;
output Data_out3_0; output Data_out3_1; output Data_out3_2; output Data_out3_3;					  	
reg [3:0] dreg [3:0];
always @ (posedge clk)

begin
		
						case (wr_ena)
							1'b1:
								begin
								dreg [Adr] = Data_in[3:0];    
								end
							1'b0:
								begin
								Data_out0[3:0] = 4'b0000;
								Data_out1[3:0] = 4'b0000;
								Data_out2[3:0] = 4'b0000;
								Data_out3[3:0] = 4'b0000;
								end
							default:
								begin
								Data_out0[3:0] = 4'b0000;
								Data_out1[3:0] = 4'b0000;
								Data_out2[3:0] = 4'b0000;
								Data_out3[3:0] = 4'b0000;
								end
						endcase
						case (rd_ena)
							1'b1:
								begin
								Data_out0[3:0] = dreg [0];
								Data_out1[3:0] = dreg [1];
								Data_out2[3:0] = dreg [2];
								Data_out3[3:0] = dreg [3];   				
								end
							1'b0:
								begin
								Data_out0[3:0] = dreg [0];
								Data_out1[3:0] = dreg [1];
								Data_out2[3:0] = dreg [2];
								Data_out3[3:0] = dreg [3];
								
								end
							
							default:
								begin
								Data_out0[3:0] = 4'b0000;
								Data_out1[3:0] = 4'b0000;
								Data_out2[3:0] = 4'b0000;
								Data_out3[3:0] = 4'b0000;
								
								end
							endcase
						case (reset)
							1'b1:
								begin
								if (reset)
								begin
								dreg [4'b0000] = 4'b0000;    
								dreg [4'b0001] = 4'b0000; 
								dreg [4'b0010] = 4'b0000; 
								dreg [4'b0011] = 4'b0000;
								end
								end
							1'b0:
								begin
								
								end
							default:
								begin
								
								end
							endcase
	
end
assign Data_out0_0 = Data_out0[0]; 
assign Data_out0_1 = Data_out0[1];
assign Data_out0_2 = Data_out0[2];
assign Data_out0_3 = Data_out0[3];

assign Data_out1_0 = Data_out1[0];
assign Data_out1_1 = Data_out1[1];
assign Data_out1_2 = Data_out1[2];
assign Data_out1_3 = Data_out1[3];

assign Data_out2_0 = Data_out2[0];
assign Data_out2_1 = Data_out2[1];
assign Data_out2_2 = Data_out2[2]; 
assign Data_out2_3 = Data_out2[3];

assign Data_out3_0 = Data_out3[0];
assign Data_out3_1 = Data_out3[1];
assign Data_out3_2 = Data_out3[2];
assign Data_out3_3 = Data_out3[3];
endmodule

//-------------------------------------------------------
//-----Error locator by Andrey---------------------------
`define ready 0
`define error 200
`define det2_mul 1
`define det2_add 2
`define det2_compare 3

`define e1_loc 100
`define e1_loc2 101
`define e1_div 102

`define e2_loc1_mul 4
`define e2_loc2_mul 5
`define e2_loc_add 6
`define e2_loc_div 7
`define e2_loc_search 8
`define e2_pos 9
`define e2_val_s2_l1s1 10
`define e2_val1_mul 11
`define e2_val2_mul 13
`define e2_val_div 14

module RS_Locator

  (
    
    input wire clk,

    input wire S1_0,
    input wire S1_1,
    input wire S1_2,
    input wire S1_3,
    
    input wire S2_0,
    input wire S2_1,
    input wire S2_2,
    input wire S2_3,
    
    input wire S3_0,
    input wire S3_1,
    input wire S3_2,
    input wire S3_3,
    
    input wire S4_0,
    input wire S4_1,
    input wire S4_2,
    input wire S4_3,
    
    input wire start,
    input wire reset,
    output reg [3:0] u1, // position 1
    output reg [3:0] v1, // value 1
    output reg [3:0] u2, // position 2
    output reg [3:0] v2, // value 2
    output reg error,
    output reg done,
    
    output reg [1:0] error_number
    
  );
  
    wire [3:0] S1;
    wire [3:0] S2;
    wire [3:0] S3;
    wire [3:0] S4;
    
  integer state;
  
  reg [3:0] s2s2, s1s3, det2;
  reg [3:0] s2s3, s1s4, numerator_lambda1, lambda1;
  reg [3:0] s2s4, s3s3, numerator_lambda2, lambda2;
  reg [3:0] loc_search_exp, L;
  reg [3:0] L1, L2;
  reg L1_flag, L2_flag;
  
  reg [3:0] s1s1, e1L;
  
  reg [3:0] L1L1, L1L2, L2L2, s1L2, s1L1;
  reg [3:0] s2_l1s1, vc1, vc2, vn1, vn2;
  
  integer i, j;
  integer n;
  integer GF;
  integer feedback;
  
  integer GF_exp [(1 << 4) - 2:0];
  integer GF_log [(1 << 4) - 1:1];
  
  reg [3:0] MUL_Table [(1 << 4) - 1:0][(1 << 4) - 1:0];
  reg [3:0] DIV_Table [(1 << 4) - 1:0][(1 << 4) - 1:0];
  
  initial begin
    done = 0;
    error = 0;
    state <= `ready;
    
    n = (1 << 4) - 1;
    GF = 1;
    for (i = 0; i < n; i = i + 1) begin
      GF_exp[i] = GF;
      GF_log[GF] = i;
      feedback = (GF >> (4 - 1)) & 1;
      if (feedback) begin
        GF = GF ^ 4'b1001;
      end
      GF = ((GF << 1) | feedback) & n;
    end
    
    for (i = 0; i < (1 << 4); i = i + 1) begin
      for (j = 0; j < (1 << 4); j = j + 1) begin
        if (i == 0 || j == 0) begin
          MUL_Table[i][j] = 0;
          DIV_Table[i][j] = 0;
        end else begin
          MUL_Table[i][j] = GF_exp[(GF_log[i] + GF_log[j]) % n];
          DIV_Table[i][j] = GF_exp[(GF_log[i] - GF_log[j] + n) % n];
        end
      end
    end
  end
  


  //normal conditions
always @(posedge clk)
begin
		case (reset)
		1'b0:
		begin
    
					if (state == `ready && start) begin
					  done = 0;
					  state <= `det2_mul;
					end
					if (state == `det2_mul) begin
					  s2s2 = MUL_Table[S2][S2];
					  s1s3 = MUL_Table[S1][S3];
					  state <= `det2_add;
					end
					if (state == `det2_add) begin
					  det2 = s2s2 ^ s1s3;
					  state <= `det2_compare;
					end
					if (state == `det2_compare) begin
					  if (det2 == 0) begin
						state <= `e1_loc;
						error_number = 1;
					  end else begin
						state <= `e2_loc1_mul;
						error_number = 2;
					  end
					end
					if (state == `e1_loc) begin
					  s1s1 = MUL_Table[S1][S1];
					  u1 = (GF_log[S2] - GF_log[S1] + n) % n;
					  state <= `e1_loc2;
					end
					if (state == `e1_loc2) begin
					  e1L = DIV_Table[S2][GF_exp[u1]];
					  state <= `e1_div;
					end
					if (state == `e1_div) begin
					  v1 = DIV_Table[s1s1][e1L];
					  done = 1;
					  state <= `ready;
					end
					
					if (state == `e2_loc1_mul) begin
					  s2s3 = MUL_Table[S2][S3];
					  s1s4 = MUL_Table[S1][S4];
					  state <= `e2_loc2_mul;
					end
					if (state == `e2_loc2_mul) begin
					  s2s4 = MUL_Table[S2][S4];
					  s3s3 = MUL_Table[S3][S3];
					  state <= `e2_loc_add;
					end
					if (state == `e2_loc_add) begin
					  numerator_lambda1 = s2s3 ^ s1s4;
					  numerator_lambda2 = s2s4 ^ s3s3;
					  state <= `e2_loc_div;
					end
					if (state == `e2_loc_div) begin
					  lambda1 = DIV_Table[numerator_lambda1][det2];
					  lambda2 = DIV_Table[numerator_lambda2][det2];
					  loc_search_exp = 0;
					  L1_flag = 0; L2_flag = 0;
					  state <= `e2_loc_search;
					end
					if (state == `e2_loc_search) begin
					  L = 1 ^ MUL_Table[lambda1][GF_exp[loc_search_exp]] ^ MUL_Table[lambda2][GF_exp[(2 * loc_search_exp) % 15]];
					  if (L == 0) begin
						if (L1_flag == 0) begin
						  L1 = GF_exp[loc_search_exp];
						  L1_flag = 1;
						end else begin
						  L2 = GF_exp[loc_search_exp];
						  L2_flag = 1;
						  state <= `e2_pos;
						end
					  end
					  if (loc_search_exp == 14 && L2_flag == 0 && L1_flag == 0) begin
						error = 1;
						state <= `error;
					  end
					  loc_search_exp = loc_search_exp + 1;
					end
					if (state == `e2_pos) begin
					  u1 = (GF_log[1] - GF_log[L1] + n) % n;
					  u2 = (GF_log[1] - GF_log[L2] + n) % n;
					  state <= `e2_val_s2_l1s1;
					end
					if (state == `e2_val_s2_l1s1) begin
					  s2_l1s1 = S2 ^ MUL_Table[lambda1][S1];
					  state <= `e2_val1_mul;
					end
					if (state == `e2_val1_mul) begin
					  vc1 = S1 ^ MUL_Table[L1][s2_l1s1];
					  vn1 = MUL_Table[L1][lambda1];
					  state <= `e2_val2_mul;
					end
					if (state == `e2_val2_mul) begin
					  vc2 = S1 ^ MUL_Table[L2][s2_l1s1];
					  vn2 = MUL_Table[L2][lambda1];
					  state <= `e2_val_div;
					end
					if (state == `e2_val_div) begin
					  v1 = DIV_Table[vc1][vn1];
					  v2 = DIV_Table[vc2][vn2];
					  done = 1;
					  state <= `ready;
					end
			end
			
			1'b1:
			begin
			state <= `ready;
			end
			default:
			begin
			state <= `ready;
			end
			
			endcase
			
end


assign S1[0] = S1_0;
assign S1[1] = S1_1;
assign S1[2] = S1_2;
assign S1[3] = S1_3;

assign S2[0] = S2_0;
assign S2[1] = S2_1;
assign S2[2] = S2_2;
assign S2[3] = S2_3;

assign S3[0] = S3_0;
assign S3[1] = S3_1;
assign S3[2] = S3_2;
assign S3[3] = S3_3;

assign S4[0] = S4_0;
assign S4[1] = S4_1;
assign S4[2] = S4_2;
assign S4[3] = S4_3; 
  
endmodule






//-------Head - To- Ass - table-----------------------------------------
// this table does renumeration of pos-errors`symbols from back to front 
//**********************************************************************
module TABLE(clk, enable, Data_in, Data_out);
input clk;
input enable;
input [0:3] Data_in;
output reg[0:3] Data_out;

always @ (posedge clk)
	begin
		if (enable)
		begin
				case(Data_in)
				4'b1111: begin Data_out = 4'b0000; end
				4'b0111: begin Data_out = 4'b1000; end
				4'b1011: begin Data_out = 4'b0100; end
				4'b0011: begin Data_out = 4'b1100; end
				4'b1101: begin Data_out = 4'b0010; end
				4'b0101: begin Data_out = 4'b1010; end
				4'b1001: begin Data_out = 4'b0110; end
				4'b0001: begin Data_out = 4'b1110; end
				4'b1110: begin Data_out = 4'b0001; end
				4'b0110: begin Data_out = 4'b1001; end
				4'b1010: begin Data_out = 4'b0101; end
				4'b0010: begin Data_out = 4'b1101; end
				4'b1100: begin Data_out = 4'b0011; end
				4'b0100: begin Data_out = 4'b1011; end
				4'b1000: begin Data_out = 4'b0111; end
				4'b0000: begin Data_out = 4'b1111; end
				default: begin Data_out = 4'b0000; end
				endcase
				
		
		end
		else
		begin
		Data_out = 4'b0000;
		end

	end
endmodule