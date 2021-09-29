module CD(
		output [1:0] a,
		//управляющие сигналы
		output reg INC_Y,
		output reg INV_TLATY,
		output reg DemandY,
		output reg SH_Y,
		output reg INV_TCLKY,
		output reg S_TBKY,
		output reg L_Y,
		output reg R_TBKY,
		output reg INV_TWordY,
		//осведомительные сигналы
		input CTEq32,
		input CTEq95,
		input C, aR);
	parameter	a0 = 2'd0, a1 = 2'd1, a2 = 2'd2, a3 = 2'd3;
	reg [1:0] CombLogic;

	always @(*)
	begin
		case(a)
			a0:
			begin	//0
				CombLogic = a1;
				INC_Y = 0;
				INV_TLATY = 0;
				DemandY = 0;
				SH_Y = 0;
				INV_TCLKY = 1;
				S_TBKY = 0;
				L_Y = 1;
				R_TBKY = 1;
				INV_TWordY = 0;
			end
			a1:
			begin	//1
				CombLogic = a2;
				INC_Y = 0;
				INV_TLATY = 0;
				DemandY = 0;
				SH_Y = 0;
				INV_TCLKY = 1;
				S_TBKY = 0;
				L_Y = 0;
				R_TBKY = 0;
				INV_TWordY = 0;
			end
			a2:
			begin
				if(!CTEq32 && !CTEq95)
				begin	//2
					CombLogic = a1;
					INC_Y = 1;
					INV_TLATY = 0;
					DemandY = 0;
					SH_Y = 1;
					INV_TCLKY = 1;
					S_TBKY = 0;
					L_Y = 0;
					R_TBKY = 0;
					INV_TWordY = 0;
				end
					else if(CTEq32 && !CTEq95)
					begin	//3
						CombLogic = a1;
						INC_Y = 1;
						INV_TLATY = 0;
						DemandY = 0;
						SH_Y = 1;
						INV_TCLKY = 1;
						S_TBKY = 1;
						L_Y = 0;
						R_TBKY = 0;
						INV_TWordY = 0;
					end
						else if(CTEq95)
						begin	//4
							CombLogic = a3;
							INC_Y = 0;
							INV_TLATY = 1;
							DemandY = 1;
							SH_Y = 0;
							INV_TCLKY = 0;
							S_TBKY = 0;
							L_Y = 0;
							R_TBKY = 0;
							INV_TWordY = 0;
						end
							else
							begin
								CombLogic = a0;
								INC_Y = 0;
								INV_TLATY = 0;
								DemandY = 0;
								SH_Y = 0;
								INV_TCLKY = 0;
								S_TBKY = 0;
								L_Y = 0;
								R_TBKY = 0;
								INV_TWordY = 0;
							end
			end
			a3:
			begin	//5
				CombLogic = a0;
				INC_Y = 1;
				INV_TLATY = 1;
				DemandY = 0;
				SH_Y = 0;
				INV_TCLKY = 0;
				S_TBKY = 0;
				L_Y = 0;
				R_TBKY = 0;
				INV_TWordY = 1;
			end
			default:
			begin
				CombLogic = a0;
				INC_Y = 0;
				INV_TLATY = 0;
				DemandY = 0;
				SH_Y = 0;
				INV_TCLKY = 0;
				S_TBKY = 0;
				L_Y = 0;
				R_TBKY = 0;
				INV_TWordY = 0;
			end
		endcase
	end
	DTT #(2) TT(.Q(a), .D(CombLogic), .C(C), .aR(aR));
endmodule