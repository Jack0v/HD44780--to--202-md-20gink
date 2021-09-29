//Author - Jack0v
//E-mail - Jack-ov@inbox.ru
//YouTube chanal - https://www.youtube.com/Jack0v
//Language of commentary - Russian
//Codepage - ANSI 1251
//Project tested for EP4CE6E22C8 by QurtusII 9.1SP2

// - 5х10 не реализовано
// - 4р-шина не реализована
// - управление яркостью
// - доп сегменты (точка, запятая)
// - знакогенератор с памятью
// - кодовая страница ANSI 1251
//`define MODEL_TECH
module LCD(		`ifdef MODEL_TECH
				(*chip_pin = "00"*)input EN,
				(*chip_pin = "00" *)input RS,
				(*chip_pin = "00"*)input RW,
				(*chip_pin = "00, 00, 00, 00, 00, 00, 00, 00"*)input [7:0]DB,
				`endif
			(*chip_pin = "58"*)output nFutabaCLKQ,
			(*chip_pin = "54"*)output nFutabaSIQ,
			(*chip_pin = "52"*)output nFutabaLATQ,
			(*chip_pin = "50"*)output nFutabaBKQ,
					(*chip_pin = "23"*)input C);

	///делитель частоты-----------------
	//C == 50МГц
	//CQ = C / 128 = 390,625КГц
	//wire aR = 0;
	reg [6:0]CTCQ;
	always @(posedge C)
		if(CTCQ == 7'd127) CTCQ <= 0;
			else CTCQ <= CTCQ + 1'd1;
	wire CQ = CTCQ[6];
	//\делитель частоты-----------------
	`ifndef MODEL_TECH
	//`ifdef diag
	wire [7:0]DB;
	wire RW;
	wire RS;
	wire EN;
	wire [10:0]InSSaPQ;
	InSSaP InSSaP(.source(InSSaPQ), .probe(1'd0));
	assign DB = InSSaPQ[7:0];
	assign RW = InSSaPQ[8];
	assign RS = InSSaPQ[9];
	assign EN = InSSaPQ[10];
	`endif
	//флаги
	reg TIDQ = 1'd1;//1-инк., 0-дек.;
	reg TSHQ;		//1-да, 0-нет;
	reg TDQ = 1'd1;	//1-вкл., 0-выкл.;
	reg TCQ = 1'd1;	//0-откл.	1-подчёркивание		0-мигание	1-мигающее подчёркивание
	reg TBQ = 1'd1;	//0			0					1			1;
	reg TSCQ;		//1-дисп., 0-курсор (команда);
	reg TRLQ;		//1-вправо, 0-влево;
	reg TDLQ = 1'd1;//1-8р., 0-4р.;
	reg TNQ = 1'd1;	//1-2строки, 0-1строки;
	reg [1:0]TSLQ;	//[0]:	0-адрес, инф.	1-доп. сегменты	0-яркость	1-адрес, инф.
					//[1]:	0				0				1			1

	reg TNWQ = 0;	//номер записи при 4-р шине
	wire TSyncNWQ;
	wire [1:0]REGSyncNWQ;
	wire TINV_NWQ;
	wire [1:0]REGRDWRQ;
	REG TSyncNW(.Q(TSyncNWQ), .L(1'd1), .D(1'd1), .C(EN), .aR(L_IQ));
	REG #(2) REGSyncNW(.Q(REGSyncNWQ), .L(1'd1), .D({REGSyncNWQ[0], TSyncNWQ}), .C(CQ), .aR(TINV_NWQ));
	TRS TINV_NW(.Q(TINV_NWQ), .R(TINV_NWQ), .S(REGSyncNWQ[1]), .C(CQ), .aR(1'd0));
	REG #(2) REGRDWR(.Q(REGRDWRQ), .L(1'd1), .D({REGRDWRQ[0], RW}), .C(EN), .aR(1'd0));
	
	wire [7:0]REGIRQ;
	wire TSyncIQ;
	wire [1:0]REGSyncIQ;
	wire L_IQ;
	REG #(8) REGIR(.Q(REGIRQ), .L(1'd1), .D(TDLQ? DB : (TNWQ? {REGIRQ[7:4], DB[3:0]} : {DB[7:4], REGIRQ[3:0]})),
																						.C(!(EN & !RS & !RW)), .aR(1'd0));
	REG TSyncI(.Q(TSyncIQ), .L(1'd1), .D(1'd1), .C(!(EN & !RS & !RW) & (TDLQ | (!TDLQ & TNWQ))), .aR(L_IQ));
	REG #(2) REGSyncI(.Q(REGSyncIQ), .L(1'd1), .D({REGSyncIQ[0], TSyncIQ}), .C(CQ), .aR(L_IQ));
	TRS TL_I(.Q(L_IQ), .R(L_IQ), .S(REGSyncIQ[1]), .C(CQ), .aR(1'd0));
	
	//команда "Write Data to RAM"
	wire [7:0]REGDRQ;
	wire TSyncDQ;
	wire [1:0]REGSyncDQ;
	wire L_DQ;
	REG #(8) REGDR(.Q(REGDRQ), .L(1'd1), .D(TDLQ? DB : (TNWQ? {REGIRQ[7:4], DB[3:0]} : {DB[7:4], REGIRQ[3:0]})),
																						.C(!(EN & RS & !RW)), .aR(1'd0));
	REG TSyncD(.Q(TSyncDQ), .L(1'd1), .D(1'd1), .C(!(EN & RS & !RW) & (TDLQ | (!TDLQ & TNWQ))), .aR(L_DQ));
	REG #(2) REGSyncD(.Q(REGSyncDQ), .L(1'd1), .D({REGSyncDQ[0], TSyncDQ}), .C(CQ), .aR(L_DQ));
	TRS TL_D(.Q(L_DQ), .R(L_DQ), .S(REGSyncDQ[1]), .C(CQ), .aR(1'd0));
	wire L_DY = L_DQ & (!TSLQ | &TSLQ);
	wire WR_CGRAMY = L_DY;
	wire WR1_DDRAMY = L_DY;
	wire INC2_CTRAMY = L_DY;
	wire INC1_CTBaseDispY = L_DY;
	wire WR2_DDRAMY = L_DQ & TSLQ==2'd1;
	wire WR_REGBKQ = L_DQ & TSLQ==2'd2;
	
	reg R0_CTRAMY;
	reg R1_CTRAMY;
	reg L_CTCGRAMY;
	reg L_CTRAMY;
	reg INC1_CTRAMY;
	reg DEC1_CTRAMY;
	reg INC0_CTBaseDispY;
	reg DEC0_CTBaseDispY;
	always @*
	begin
		R0_CTRAMY = 0;
		R1_CTRAMY = 0;
		L_CTCGRAMY = 0;
		L_CTRAMY = 0;
		INC1_CTRAMY = 0;
		DEC1_CTRAMY = 0;
		INC0_CTBaseDispY = 0;
		DEC0_CTBaseDispY = 0;
		if(L_IQ)
			casex(REGIRQ)
				8'b00000001: R0_CTRAMY		= 1'd1;					//команда "Clear Display"
				8'b0000001x: R1_CTRAMY		= 1'd1;					//команда "Return Home"
				8'b0001xxxx:										//команда "Cursor or Display Shift"
				begin	
							INC1_CTRAMY		= !TSCQ &  TRLQ;	//курсор вправо
							DEC1_CTRAMY		= !TSCQ & !TRLQ;	//курсор влево
							INC0_CTBaseDispY=  TSCQ &  TRLQ;	//дисплей вправо
							DEC0_CTBaseDispY=  TSCQ & !TRLQ;	//дисплей влево
				end
				8'b01xxxxxx: L_CTCGRAMY = 1'd1;						//команда "Set CGRAM Address"
				8'b1xxxxxxx: L_CTRAMY  = 1'd1;						//команда "Set DDRAM Address"
				default: ;
			endcase
	end
	
	reg TADDRAMQ = 0;
	reg [5:0]CTRAMQ;
	wire [6:0]ACQ = {TADDRAMQ, CTRAMQ};
	reg [5:0]CTCGRAMQ;
	
	reg INC0_CTRAMQ;
	reg WR0_DDRAMQ;
	wire INC_CTRAMY = INC0_CTRAMQ | INC1_CTRAMY	| ( TIDQ & (INC2_CTRAMY & !TSelRAMQ));
	wire DEC_CTRAMY = DEC1_CTRAMY				| (!TIDQ & (INC2_CTRAMY & !TSelRAMQ));
	reg TInvCharQ;
	reg TSelRAMQ = 0;
	reg [17:0]CTSpeedCursorQ;
	wire INC_CTBaseDispY = INC0_CTBaseDispY | (TSHQ &  TIDQ & INC1_CTBaseDispY);
	wire DEC_CTBaseDispY = DEC0_CTBaseDispY | (TSHQ & !TIDQ & INC1_CTBaseDispY);
	reg [5:0]CTBaseDispQ;
	reg [4:0]CTIncQ;
	reg [6:0]REGBKQ = 7'd15;
	wire FutabaDemandY;
	always @(posedge CQ)
	begin
		//Т номера обращения при 4-р шине
		if(TDLQ & TINV_NWQ) TNWQ <= REGRDWRQ[1]^REGRDWRQ[0]? 1'd0 : !TNWQ;
		
		if(L_IQ)
			casex(REGIRQ)
				8'b000001xx: begin TIDQ <= REGIRQ[1];  TSHQ		 <= REGIRQ[0];						end //"Entry Mode Set"
				8'b00001xxx: begin TDQ  <= REGIRQ[2]; {TCQ, TBQ} <= REGIRQ[1:0];					end //"Display ON/OFF Control"
				8'b0001xxxx: begin TSCQ <= REGIRQ[3];  TRLQ 	 <= REGIRQ[1];						end //"Cursor or Display Shift"
				8'b001xxxxx: begin /*TDLQ <= REGIRQ[4];*/  TNQ 		 <= REGIRQ[3]; TSLQ <= REGIRQ[1:0]; end //"Function Set"
				default:	;
			endcase
		//команда "Clear Display"
		if			(ACQ == 7'd103	) INC0_CTRAMQ = 0;
			else if	(R0_CTRAMY		) INC0_CTRAMQ = 1'd1;
		WR0_DDRAMQ = INC0_CTRAMQ;
		
		
		//СЧ RAM
		if(R0_CTRAMY | R1_CTRAMY | (INC_CTRAMY & CTRAMQ==6'd39)) CTRAMQ <= 0;
			else if(L_CTRAMY) CTRAMQ <= REGIRQ[5:0];
				else if(INC_CTRAMY) CTRAMQ <= CTRAMQ + 1'd1;
					else if(DEC_CTRAMY & !CTRAMQ) CTRAMQ <= 6'd39;
						else if(DEC_CTRAMY) CTRAMQ <= CTRAMQ - 1'd1;
		if							(R0_CTRAMY)						   		  TADDRAMQ <= 0;
			else if					(L_CTRAMY)						   		  TADDRAMQ <= REGIRQ[6];
				else if				(INC_CTRAMY & !TADDRAMQ & CTRAMQ==6'd39 ) TADDRAMQ <= 1'd1;
					else if			(INC_CTRAMY &  TADDRAMQ & CTRAMQ==6'd39 ) TADDRAMQ <= 1'd0;
						else if		(DEC_CTRAMY & !TADDRAMQ & !CTRAMQ		) TADDRAMQ <= 1'd1;
							else if	(DEC_CTRAMY &  TADDRAMQ & !CTRAMQ		) TADDRAMQ <= 1'd0;

		//СЧ CGRAM
		if(L_CTCGRAMY) CTCGRAMQ <= REGIRQ[5:0];
			else if(INC2_CTRAMY & TSelRAMQ) CTCGRAMQ <= CTCGRAMQ + 1'd1;
		
		//Т выбора ОЗУ (CGRAM/DDRAM)
		if(L_CTRAMY) TSelRAMQ <= 0;
			else if(L_CTCGRAMY) TSelRAMQ <= 1'd1;

		//СЧ скорости мигания курсора
		if(CTSpeedCursorQ == 18'd195312) CTSpeedCursorQ <= 0;
			else CTSpeedCursorQ <= CTSpeedCursorQ + 1'd1;
		//Т инвертирования символа под курсором
		if(CTSpeedCursorQ == 18'd195312) TInvCharQ <= !TInvCharQ;

		//СЧ базовой позиции дисплея
		//количество знакомест в дисплее - 20, длинна строки - 40
		if(R0_CTRAMY | R1_CTRAMY | (INC_CTBaseDispY & CTBaseDispQ==6'd39)) CTBaseDispQ <= 0;
			else if(INC_CTBaseDispY) CTBaseDispQ <= CTBaseDispQ + 1'd1;
				else if(DEC_CTBaseDispY & !CTBaseDispQ) CTBaseDispQ <= 6'd39;
					else if(DEC_CTBaseDispY) CTBaseDispQ <= CTBaseDispQ - 1'd1;
		
		//СЧ выдачи очередного символа на экран
		if(FutabaDemandY & (CTIncQ == 5'd19)) CTIncQ <= 0;
			else if(FutabaDemandY) CTIncQ <= CTIncQ + 1'd1;

		//РЕГ яркости
		if(WR_REGBKQ) REGBKQ <= REGDRQ<7'd5 ? 7'd5 : (REGDRQ>7'd95 ? 7'd95 : REGDRQ[6:0]);
	end
	
	//Флаг занятости
	wire TBFQ;
	REG TBF(.Q(TBFQ), .L(1'd1), .D(	REGSyncIQ || L_IQ ||
									REGSyncDQ || L_DQ ||
									INC0_CTRAMQ), .C(CQ), .aR(1'd0));
	
	/*assign [7:0]DBY = RS?	TSelRAMQ? CGRAMQ :(ACQ[6]? DDRAMDwQa : DDRAMUpQa)
						:
						{TBFQ, ACQ};
	assign DB = EN & RW?
						TDLQ? DBY : ({TNWQ? DBY[3:0] : DBY[7:4], 4'dz})
						:
						8'dz;
*/
	//DDROM
	wire [63:0]DDROMQ;
	//			 q[63:0]	 address[7:0]
	DDROM DDROM(.q(DDROMQ), .address(REGDRQ), .clock(CQ));
	
	//CGRAM
	wire [63:0]CGRAMQ;
	//			 q[63:0]	 wraddress[5:0]			data[7:0]						 			rdaddress[2:0]
	CGRAM CGRAM(.q(CGRAMQ), .wraddress(CTCGRAMQ), .data(REGDRQ), .wren(TSelRAMQ & WR_CGRAMY), .rdaddress(REGDRQ[2:0]),
																													.clock(CQ));
	wire [63:0]CGQ = {	CGRAMQ[07:00], CGRAMQ[15:08], CGRAMQ[23:16], CGRAMQ[31:24],
						CGRAMQ[39:32], CGRAMQ[47:40], CGRAMQ[55:48], CGRAMQ[63:56]};
																													
																													
	wire [63:0]DDRAMUpQa, DDRAMDwQa;
	wire [63:0]DataY = WR0_DDRAMQ?	
							64'd0
							:
							WR2_DDRAMY? {ACQ[6]? DDRAMDwQa[63:3] : DDRAMUpQa[63:3], REGDRQ[2:0]}
										:
										{(|REGDRQ[7:3]? DDROMQ[63:3] : CGQ[63:3]), ACQ[6]? DDRAMDwQa[2:0] : DDRAMUpQa[2:0]}
							;
	wire WR_DDRAMUpY = !TSelRAMQ & (WR0_DDRAMQ | WR1_DDRAMY | WR2_DDRAMY) & !ACQ[6];
	wire WR_DDRAMDwY = !TSelRAMQ & (WR0_DDRAMQ | WR1_DDRAMY | WR2_DDRAMY) &  ACQ[6];
	
	wire [5:0]PosDispY = CTBaseDispQ + CTIncQ;
	wire [5:0]DDRAMAdrY = (PosDispY > 6'd39)? PosDispY - 6'd40 : PosDispY;
	
	//ОЗУ экрана	
	wire [63:0]DDRAMUpQb, DDRAMDwQb;
	//				 q[63:0],			address[5:0],			data[63:0]
	DDRAM DDRAMUp(	.q_a(DDRAMUpQa),	.address_a(ACQ[5:0]	), .data_a(DataY),	.wren_a(WR_DDRAMUpY),	.clock_a(CQ),
					.q_b(DDRAMUpQb),	.address_b(DDRAMAdrY), .data_b(64'dx),	.wren_b(1'd0),			.clock_b(CQ));
	DDRAM DDRAMDw(	.q_a(DDRAMDwQa),	.address_a(ACQ[5:0]	), .data_a(DataY),	.wren_a(WR_DDRAMDwY),	.clock_a(CQ),
					.q_b(DDRAMDwQb),	.address_b(DDRAMAdrY), .data_b(64'dx),	.wren_b(1'd0),			.clock_b(CQ));

	//курсор
	reg InvCharUpY;
	reg InvCharDwY;
	reg [4:0]UnderlineUpY;
	reg [4:0]UnderlineDwY;
	always @*
		case({TCQ, TBQ})
			2'b00:	//откл
			begin
				InvCharUpY = 0;
				InvCharDwY = 0;
				UnderlineUpY = DDRAMUpQb[12:08];
				UnderlineDwY = DDRAMDwQb[12:08];
			end
			2'b01:	//мигание
			begin
				InvCharUpY = TInvCharQ & ACQ=={1'd0, DDRAMAdrY};
				InvCharDwY = TInvCharQ & ACQ=={1'd1, DDRAMAdrY};
				UnderlineUpY = DDRAMUpQb[12:08];
				UnderlineDwY = DDRAMDwQb[12:08];
			end
			2'b10:	//подчёркивание
			begin
				InvCharUpY = 0;
				InvCharDwY = 0;
				UnderlineUpY = ACQ=={1'd0, DDRAMAdrY}? 5'b11111 : DDRAMUpQb[12:08];
				UnderlineDwY = ACQ=={1'd1, DDRAMAdrY}? 5'b11111 : DDRAMDwQb[12:08];
			end
			2'b11:	//мигающее подчёркивание
			begin
				InvCharUpY = 0;
				InvCharDwY = 0;
				UnderlineUpY = TInvCharQ & ACQ=={1'd0, DDRAMAdrY}? ~DDRAMUpQb[12:08] : DDRAMUpQb[12:08];
				UnderlineDwY = TInvCharQ & ACQ=={1'd1, DDRAMAdrY}? ~DDRAMDwQb[12:08] : DDRAMDwQb[12:08];
			end
		endcase

	wire [37:0]DDRAMUpY = {InvCharUpY?
							  ~{DDRAMUpQb[60:56],	//верхняя строчка {левый пиксиль : правый пиксиль}
								DDRAMUpQb[52:48],
								DDRAMUpQb[44:40],
								DDRAMUpQb[36:32],
								DDRAMUpQb[28:24],
								DDRAMUpQb[20:16],
								UnderlineUpY}
							:
							   {DDRAMUpQb[60:56],	//верхняя строчка {левый пиксиль : правый пиксиль}
								DDRAMUpQb[52:48],
								DDRAMUpQb[44:40],
								DDRAMUpQb[36:32],
								DDRAMUpQb[28:24],
								DDRAMUpQb[20:16],
								UnderlineUpY},
							DDRAMUpQb[02:00]};		//точка, запятая, нижний сегмент
	wire [37:0]DDRAMDwY = {InvCharDwY?
							  ~{DDRAMDwQb[60:56],	//верхняя строчка {левый пиксиль : правый пиксиль}
								DDRAMDwQb[52:48],
								DDRAMDwQb[44:40],
								DDRAMDwQb[36:32],
								DDRAMDwQb[28:24],
								DDRAMDwQb[20:16],
								UnderlineDwY}
							:
							   {DDRAMDwQb[60:56],	//верхняя строчка {левый пиксиль : правый пиксиль}
								DDRAMDwQb[52:48],
								DDRAMDwQb[44:40],
								DDRAMDwQb[36:32],
								DDRAMDwQb[28:24],
								DDRAMDwQb[20:16],
								UnderlineDwY},
							DDRAMDwQb[02:00]};		//точка, запятая, нижний сегмент

	//						 	включить дисплей
	//						 	|				двухстрочный режим
	//						 	|				|
	wire [80:0]PixY = {CTIncQ, TDQ? {DDRAMUpY, TNQ? DDRAMDwY : 38'd0} : 76'd0};

	wire FutabaCLKQ, FutabaSIQ, FutabaLATQ, FutabaBKQ;
	Futaba Futaba(	.TCLKQ(FutabaCLKQ),
					.SIQ(FutabaSIQ),
					.TLATQ(FutabaLATQ),
					.TBKQ(FutabaBKQ),
					.DemandY(FutabaDemandY),
						.Data(PixY),
						.BK(REGBKQ),
							.C(CQ));
	assign nFutabaCLKQ	= !FutabaCLKQ;
	assign nFutabaSIQ	= !FutabaSIQ;
	assign nFutabaLATQ	= !FutabaLATQ;
	assign nFutabaBKQ	= !FutabaBKQ;
endmodule

module REG #(parameter N = 1) (output reg [N-1:0]Q = 0, input L, input [N-1:0]D, input C, aR);
	always @(posedge C or posedge aR)
									if(aR) Q <= 0;
										else
		if(L) Q <= D;
endmodule

module TRS(output reg Q = 0, input R, S, input C, aR);
	always @(posedge C or posedge aR)
									if(aR) Q <= 0;
										else
		if(R) Q <= 0;
			else if(S) Q <= 1'd1;
endmodule