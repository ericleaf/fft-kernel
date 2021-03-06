//////////////////////////////////////////////////
//
// NOTE:
// twiddle multiplier
//
//////////////////////////////////////////////////

module dif_radix2_64p_tm
#(
    parameter DATA_WIDTH_IN = 10,
    parameter DATA_WIDTH_OUT = DATA_WIDTH_IN + 1
)(
    input wire                      clk,
    input wire                      rst_n,
    input wire                      halt_ctrl,
    input wire [5:0]                tm64_ctrl,
    input wire [DATA_WIDTH_IN-1:0]  din_real,
    input wire [DATA_WIDTH_IN-1:0]  din_imag,
    output reg [DATA_WIDTH_OUT-1:0] dout_real,
    output reg [DATA_WIDTH_OUT-1:0] dout_imag
);

localparam ORIGIN   = 6'b00_0000,
           SW_RN_IN = 6'b00_0001,
           SW_RN    = 6'b00_0010,
           SW_IN    = 6'b00_0100,
           SW       = 6'b00_1000,
           RN_IN    = 6'b01_0000,
           RN       = 6'b10_0000;

reg [5:0] cal_type;
reg [5:0] twiddle;

always @(tm64_ctrl)
begin
    casex(tm64_ctrl)
        6'b000xxx: twiddle = 0;
        6'bxxx000: twiddle = 0;

        // column 4
        6'b001001: twiddle = 4;
        6'b001010: twiddle = 8;
        6'b001011: twiddle = 4;
        6'b001100: twiddle = 0;
        6'b001101: twiddle = 4;
        6'b001110: twiddle = 8;
        6'b001111: twiddle = 4;

        // column 2
        6'b010001: twiddle = 2;
        6'b010010: twiddle = 4;
        6'b010011: twiddle = 6;
        6'b010100: twiddle = 8;
        6'b010101: twiddle = 6;
        6'b010110: twiddle = 4;
        6'b010111: twiddle = 2;

        // column 6
        6'b011001: twiddle = 6;
        6'b011010: twiddle = 4;
        6'b011011: twiddle = 2;
        6'b011100: twiddle = 8;
        6'b011101: twiddle = 2;
        6'b011110: twiddle = 4;
        6'b011111: twiddle = 6;

        // column 1
        6'b100001: twiddle = 1;
        6'b100010: twiddle = 2;
        6'b100011: twiddle = 3;
        6'b100100: twiddle = 4;
        6'b100101: twiddle = 5;
        6'b100110: twiddle = 6;
        6'b100111: twiddle = 7;

        // column 5
        6'b101001: twiddle = 5;
        6'b101010: twiddle = 6;
        6'b101011: twiddle = 1;
        6'b101100: twiddle = 4;
        6'b101101: twiddle = 7;
        6'b101110: twiddle = 2;
        6'b101111: twiddle = 3;

        // column 3
        6'b110001: twiddle = 3;
        6'b110010: twiddle = 6;
        6'b110011: twiddle = 7;
        6'b110100: twiddle = 4;
        6'b110101: twiddle = 1;
        6'b110110: twiddle = 2;
        6'b110111: twiddle = 5;

        // column 7
        6'b111001: twiddle = 7;
        6'b111010: twiddle = 2;
        6'b111011: twiddle = 5;
        6'b111100: twiddle = 4;
        6'b111101: twiddle = 3;
        6'b111110: twiddle = 6;
        6'b111111: twiddle = 1;

        default:   twiddle = 0;
  endcase
end

always @(tm64_ctrl)
begin
    casex(tm64_ctrl)
        6'bx00xxx: cal_type = ORIGIN;
        6'bxxx00x: cal_type = ORIGIN;

        // column 4
        6'b001010: cal_type = ORIGIN;
        6'b001011: cal_type = SW_RN_IN;
        6'b001100: cal_type = SW_RN_IN;
        6'b001101: cal_type = SW_IN;
        6'b001110: cal_type = SW_IN;
        6'b001111: cal_type = RN;

        // column 2
        6'b010010: cal_type = ORIGIN;
        6'b010011: cal_type = ORIGIN;
        6'b010100: cal_type = ORIGIN;
        6'b010101: cal_type = SW_RN_IN;
        6'b010110: cal_type = SW_RN_IN;
        6'b010111: cal_type = SW_RN_IN;

        // column 6
        6'b011010: cal_type = SW_RN_IN;
        6'b011011: cal_type = SW_IN;
        6'b011100: cal_type = SW_IN;
        6'b011101: cal_type = RN;
        6'b011110: cal_type = RN_IN;
        6'b011111: cal_type = SW;

        // column 5
        6'b101010: cal_type = SW_RN_IN;
        6'b101011: cal_type = SW_RN_IN;
        6'b101100: cal_type = SW_IN;
        6'b101101: cal_type = RN;
        6'b101110: cal_type = RN;
        6'b101111: cal_type = RN_IN;

        // column 3
        6'b110010: cal_type = ORIGIN;
        6'b110011: cal_type = SW_RN_IN;
        6'b110100: cal_type = SW_RN_IN;
        6'b110101: cal_type = SW_RN_IN;
        6'b110110: cal_type = SW_IN;
        6'b110111: cal_type = SW_IN;

        // column 7
        6'b111010: cal_type = SW_RN_IN;
        6'b111011: cal_type = SW_IN;
        6'b111100: cal_type = RN;
        6'b111101: cal_type = RN_IN;
        6'b111110: cal_type = SW;
        6'b111111: cal_type = SW_RN;

        default:   cal_type = ORIGIN;
    endcase 
end

wire signed [DATA_WIDTH_IN-1:0] tw_din_real [8:0];
wire signed [DATA_WIDTH_IN-1:0] tw_din_imag [8:0];
wire signed [DATA_WIDTH_IN-1:0] tw_dout_rere [8:0];
wire signed [DATA_WIDTH_IN-1:0] tw_dout_imim [8:0];
wire signed [DATA_WIDTH_IN-1:0] tw_dout_reim [8:0];
wire signed [DATA_WIDTH_IN-1:0] tw_dout_imre [8:0];

generate
    genvar i;
    for(i = 0; i < 9; i = i + 1)
    begin: gen
        assign tw_din_real[i] = (twiddle == i) ? din_real : 0;
        assign tw_din_imag[i] = (twiddle == i) ? din_imag : 0;
    end
endgenerate

wire signed [DATA_WIDTH_IN-1:0] const_dout_rere;
wire signed [DATA_WIDTH_IN-1:0] const_dout_imim;
wire signed [DATA_WIDTH_IN-1:0] const_dout_reim;
wire signed [DATA_WIDTH_IN-1:0] const_dout_imre;

assign const_dout_rere = tw_dout_rere[0] | tw_dout_rere[1] | tw_dout_rere[2] | tw_dout_rere[3] | tw_dout_rere[4] | 
                         tw_dout_rere[5] | tw_dout_rere[6] | tw_dout_rere[7] | tw_dout_rere[8];
assign const_dout_imim = tw_dout_imim[0] | tw_dout_imim[1] | tw_dout_imim[2] | tw_dout_imim[3] | tw_dout_imim[4] | 
                         tw_dout_imim[5] | tw_dout_imim[6] | tw_dout_imim[7] | tw_dout_imim[8];
assign const_dout_reim = tw_dout_reim[0] | tw_dout_reim[1] | tw_dout_reim[2] | tw_dout_reim[3] | tw_dout_reim[4] | 
                         tw_dout_reim[5] | tw_dout_reim[6] | tw_dout_reim[7] | tw_dout_reim[8];
assign const_dout_imre = tw_dout_imre[0] | tw_dout_imre[1] | tw_dout_imre[2] | tw_dout_imre[3] | tw_dout_imre[4] | 
                         tw_dout_imre[5] | tw_dout_imre[6] | tw_dout_imre[7] | tw_dout_imre[8];


always @(posedge clk)
begin
    if(!rst_n)
    begin
        dout_real <= 0;
        dout_imag <= 0;
    end
    else if(halt_ctrl)
    begin
        case(cal_type)
            ORIGIN:
            begin
                dout_real <= const_dout_rere - const_dout_imim;
                dout_imag <= const_dout_reim + const_dout_imre;
            end

            SW_RN_IN:
            begin
                dout_real <= const_dout_imre - const_dout_reim;
                dout_imag <= - const_dout_rere - const_dout_imim;
            end

            SW_RN:
            begin
                dout_real <= - const_dout_imre - const_dout_reim;
                dout_imag <= const_dout_rere - const_dout_imim;
            end

            SW_IN:
            begin
                dout_real <= const_dout_imre + const_dout_reim;
                dout_imag <= const_dout_imim - const_dout_rere;
            end

            SW:
            begin
                dout_real <= const_dout_reim - const_dout_imre;
                dout_imag <= const_dout_imim - const_dout_rere;
            end

            RN_IN:
            begin
                dout_real <= const_dout_imim - const_dout_rere;
                dout_imag <= - const_dout_reim - const_dout_imre;
            end

            RN:
            begin
                dout_real <= - const_dout_rere - const_dout_imim;
                dout_imag <= const_dout_reim - const_dout_imre;
            end
        endcase
    end
    else
    begin
        dout_real <= dout_real;
        dout_imag <= dout_imag;
    end
end

twiddle64_0
#(
    .DATA_WIDTH(DATA_WIDTH_IN)
) twiddle64_0 (
    .din_real(tw_din_real[0]),
    .din_imag(tw_din_imag[0]),
    .dout_rere(tw_dout_rere[0]),
    .dout_imim(tw_dout_imim[0]),
    .dout_reim(tw_dout_reim[0]),
    .dout_imre(tw_dout_imre[0])
);

twiddle64_1
#(
    .DATA_WIDTH(DATA_WIDTH_IN)
) twiddle64_1 (
    .din_real(tw_din_real[1]),
    .din_imag(tw_din_imag[1]),
    .dout_rere(tw_dout_rere[1]),
    .dout_imim(tw_dout_imim[1]),
    .dout_reim(tw_dout_reim[1]),
    .dout_imre(tw_dout_imre[1])
);

twiddle64_2
#(
    .DATA_WIDTH(DATA_WIDTH_IN)
) twiddle64_2 (
    .din_real(tw_din_real[2]),
    .din_imag(tw_din_imag[2]),
    .dout_rere(tw_dout_rere[2]),
    .dout_imim(tw_dout_imim[2]),
    .dout_reim(tw_dout_reim[2]),
    .dout_imre(tw_dout_imre[2])
);

twiddle64_3
#(
    .DATA_WIDTH(DATA_WIDTH_IN)
) twiddle64_3 (
    .din_real(tw_din_real[3]),
    .din_imag(tw_din_imag[3]),
    .dout_rere(tw_dout_rere[3]),
    .dout_imim(tw_dout_imim[3]),
    .dout_reim(tw_dout_reim[3]),
    .dout_imre(tw_dout_imre[3])
);

twiddle64_4
#(
    .DATA_WIDTH(DATA_WIDTH_IN)
) twiddle64_4 (
    .din_real(tw_din_real[4]),
    .din_imag(tw_din_imag[4]),
    .dout_rere(tw_dout_rere[4]),
    .dout_imim(tw_dout_imim[4]),
    .dout_reim(tw_dout_reim[4]),
    .dout_imre(tw_dout_imre[4])
);

twiddle64_5
#(
    .DATA_WIDTH(DATA_WIDTH_IN)
) twiddle64_5 (
    .din_real(tw_din_real[5]),
    .din_imag(tw_din_imag[5]),
    .dout_rere(tw_dout_rere[5]),
    .dout_imim(tw_dout_imim[5]),
    .dout_reim(tw_dout_reim[5]),
    .dout_imre(tw_dout_imre[5])
);

twiddle64_6
#(
    .DATA_WIDTH(DATA_WIDTH_IN)
) twiddle64_6 (
    .din_real(tw_din_real[6]),
    .din_imag(tw_din_imag[6]),
    .dout_rere(tw_dout_rere[6]),
    .dout_imim(tw_dout_imim[6]),
    .dout_reim(tw_dout_reim[6]),
    .dout_imre(tw_dout_imre[6])
);

twiddle64_7
#(
    .DATA_WIDTH(DATA_WIDTH_IN)
) twiddle64_7 (
    .din_real(tw_din_real[7]),
    .din_imag(tw_din_imag[7]),
    .dout_rere(tw_dout_rere[7]),
    .dout_imim(tw_dout_imim[7]),
    .dout_reim(tw_dout_reim[7]),
    .dout_imre(tw_dout_imre[7])
);

twiddle64_8
#(
    .DATA_WIDTH(DATA_WIDTH_IN)
) twiddle64_8 (
    .din_real(tw_din_real[8]),
    .din_imag(tw_din_imag[8]),
    .dout_rere(tw_dout_rere[8]),
    .dout_imim(tw_dout_imim[8]),
    .dout_reim(tw_dout_reim[8]),
    .dout_imre(tw_dout_imre[8])
);

endmodule