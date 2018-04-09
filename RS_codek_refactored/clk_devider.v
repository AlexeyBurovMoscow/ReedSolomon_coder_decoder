module clk_devider (clk, clkout);

input clk;
output clkout;



assign clkout = ~clk;

endmodule