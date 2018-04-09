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
  #(
    parameter m = 4,
    parameter f = 'b1001
  )
  (
    input wire clk,
    input wire [m - 1:0] S1,
    input wire [m - 1:0] S2,
    input wire [m - 1:0] S3,
    input wire [m - 1:0] S4,
    
    input wire start,
    
    output reg [m - 1:0] u1, // position 1
    output reg [m - 1:0] v1, // value 1
    output reg [m - 1:0] u2, // position 2
    output reg [m - 1:0] v2, // value 2
    output reg error,
    output reg done,
    
    output reg [1:0] error_number
  );
  
  integer state;
  
  reg [m - 1:0] s2s2, s1s3, det2;
  reg [m - 1:0] s2s3, s1s4, numerator_lambda1, lambda1;
  reg [m - 1:0] s2s4, s3s3, numerator_lambda2, lambda2;
  reg [m - 1:0] loc_search_exp, L;
  reg [m - 1:0] L1, L2;
  reg L1_flag, L2_flag;
  
  reg [m - 1:0] s1s1, e1L;
  
  reg [m - 1:0] L1L1, L1L2, L2L2, s1L2, s1L1;
  reg [m - 1:0] s2_l1s1, vc1, vc2, vn1, vn2;
  
  integer i, j;
  integer n;
  integer GF;
  integer feedback;
  
  integer GF_exp [(1 << m) - 2:0];
  integer GF_log [(1 << m) - 1:1];
  
  reg [m - 1:0] MUL_Table [(1 << m) - 1:0][(1 << m) - 1:0];
  reg [m - 1:0] DIV_Table [(1 << m) - 1:0][(1 << m) - 1:0];
  
  initial begin
    done = 0;
    error = 0;
    state <= `ready;
    
    n = (1 << m) - 1;
    GF = 1;
    for (i = 0; i < n; i = i + 1) begin
      GF_exp[i] = GF;
      GF_log[GF] = i;
      feedback = (GF >> (m - 1)) & 1;
      if (feedback) begin
        GF = GF ^ f;
      end
      GF = ((GF << 1) | feedback) & n;
    end
    
    for (i = 0; i < (1 << m); i = i + 1) begin
      for (j = 0; j < (1 << m); j = j + 1) begin
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
  
  always @(posedge clk) begin
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
  
endmodule