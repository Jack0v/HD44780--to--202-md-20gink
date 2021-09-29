module Futaba(	output reg TCLKQ,
				output SIQ,
				output reg TLATQ = 0,
				output reg TBKQ = 0,
				output DemandY,
					input [80:0]Data,
					input [6:0]BK,
							input C);

	wire [1:0]CDa;
	//управляющие сигналы
	wire L_Y;
	wire SH_Y;
	wire INC_Y;
	wire INV_TCLKY;
	wire INV_TLATY;
	wire R_TBKY;
	wire S_TBKY;
	wire INV_TWordY;
	//^wire DemandY;
	//выходы устройств
	wire [31:0]DCY;
	//^reg TCLKQ;
	//^reg TLATQ;
	//^reg TBKQ;
	reg [6:0]CTQ;
	reg [95:0]REGQ;
	assign SIQ = REGQ[95];

	CD CD(	.a(CDa),
			//управляющие сигналы
			.L_Y(L_Y),
			.SH_Y(SH_Y),
			.INC_Y(INC_Y),
			.INV_TCLKY(INV_TCLKY),
			.INV_TLATY(INV_TLATY),
			.R_TBKY(R_TBKY),
			.S_TBKY(S_TBKY),
			.INV_TWordY(INV_TWordY),
			.DemandY(DemandY),
				//осведомительные сигналы
				.CTEq95(CTQ == 7'd95),
				.CTEq32(CTQ == BK),
					.C(C), .aR(1'd0));

	
	DC #(5) DC(.Y(DCY), .X(Data[80:76]), .E(1'd1));
	
	initial TCLKQ <= 1'd1;
	always @(posedge C)
	begin
		if(INV_TCLKY) TCLKQ <= !TCLKQ;
		if(INV_TLATY) TLATQ <= !TLATQ;
		if(R_TBKY) TBKQ  <= 0; else if(S_TBKY) TBKQ  <= 1'd1;
		if(INC_Y & (CTQ == 7'd95)) CTQ <= 0;
			else if(INC_Y) CTQ <= CTQ + 1'd1;
		if(L_Y) REGQ <={DCY[00], DCY[01], DCY[02], DCY[03], DCY[04], DCY[05], DCY[06], DCY[07], DCY[08], DCY[09],
						DCY[10], DCY[11], DCY[12], DCY[13], DCY[14], DCY[15], DCY[16], DCY[17], DCY[18], DCY[19], Data[75:0]};
			else if(SH_Y) REGQ <= {REGQ[94:0], 1'dx};
	end
endmodule

module DTT #(parameter N = 1) (output reg [N-1:0]Q, input [N-1:0]D, input C, aR);
	always @(posedge C or posedge aR)
									if(aR) Q <= 0;
										else
		Q <= D;
endmodule

module DC #(parameter N = 0) (output [(2**N)-1:0]Y, input [N-1:0]X, input E);
	assign Y = E << X;
endmodule