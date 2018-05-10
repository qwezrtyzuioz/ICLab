module MS(
	rst_n,
	clk,
	in_valid,
	maze,
	player_x,
	player_y,
	prize_x_1,
	prize_y_1,
	prize_x_2,
	prize_y_2,
	prize_x_3,
	prize_y_3,
	out_valid,
	out_x,
	out_y
);

//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION                         
//---------------------------------------------------------------------	

input rst_n, clk, in_valid;
input [14:0] maze;
input [3:0] player_x, player_y;
input [3:0] prize_x_1, prize_y_1;
input [3:0] prize_x_2, prize_y_2;
input [3:0] prize_x_3, prize_y_3;
output reg out_valid;
output reg [3:0]out_x, out_y;

//---------------------------------------------------------------------
//   Parameters Declaration                            
//---------------------------------------------------------------------

parameter	ST_IDLE		=	4'd0,
			ST_INPUT	=	4'd1,
			ST_PRE		= 	4'd2,
			ST_EXE		= 	4'd3,
			ST_DUMP		= 	4'd4,
			ST_REST		= 	4'd5,
			ST_OUTPUT	=	4'd6,
			ST_FINAL	=	4'd7;

//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION                             
//---------------------------------------------------------------------

integer i, j;

wire	  WEN;
wire[7:0] Q, A;

reg		  finish, finish_d,
		  pre_counter, exe_counter,
		  wall[14: 0][14: 0], gray[15: 0][15: 0];
reg[1: 0] dir[14: 0][14: 0],
		  num_exe, found;	
reg[3: 0] cs, ns,
		  init_x, init_y,
		  p1_x, p1_y, p2_x, p2_y, p3_x, p3_y,
		  visitable,
		  
		  now_x, now_y,
		  t_x, t_y;
reg[4: 0] p_start, p_end;
reg[7: 0] D,
		  out_counter,
		  dump_counter, mem[255: 0], point[2: 0];
reg[8: 0] queue[31: 0];


//---------------------------------------------------------------------
//   Finite State Machine                                       
//---------------------------------------------------------------------
		 
always@(posedge clk or negedge rst_n) begin
	
	if(!rst_n) 
		cs<= ST_IDLE;
	else
		cs<= ns;
end

always@(*) begin
	
	case(cs)
		
		ST_IDLE: begin
			
			if(in_valid)
				ns= ST_INPUT;
			else
				ns= ST_IDLE;
		end
		
		ST_INPUT: begin
			if(in_valid)
				ns= ST_INPUT;
			else
				ns= ST_PRE;
		end
		
		ST_PRE: begin
			if(pre_counter== 1'd1)
				ns= ST_EXE;
			else
				ns= ST_PRE;
		end
		
		ST_EXE: begin
			if(finish)
				ns= ST_DUMP;
			else
				ns= ST_EXE;		
		end
		
		ST_DUMP: begin
			if(!finish_d)
				ns= ST_DUMP;
			else if(num_exe== 2'd2)
				ns= ST_REST;
			else
				ns= ST_PRE;
		end
		
		ST_REST: 
			ns= ST_OUTPUT;
		
		ST_OUTPUT: begin
			if(out_counter== (point[1]+ 8'd1)) 
				ns= ST_FINAL;
			else
				ns= ST_OUTPUT;
		end
		
		ST_FINAL: begin
			ns= ST_IDLE;
		end
		
		default: ns= ST_IDLE;
		
	endcase
	
end
		 
//---------------------------------------------------------------------
//   Input Logic                                        
//---------------------------------------------------------------------

always@(posedge clk or negedge rst_n) begin
	
	if(!rst_n) begin
		
		for(i= 0; i< 16; i= i+ 1)
			for(j= 0; j< 16; j= j+ 1)
				wall[i][j]<= 1'b0;
		
	end
	else if(in_valid) begin
		
		for(i= 0; i< 15; i= i+ 1)
			wall[i][14]<= maze[i];
		
		for(j= 0; j< 14; j= j+ 1)
			for(i= 0; i< 15; i= i+ 1)
				wall[i][j]<= wall[i][j+ 1];
		
	end
	else begin
		
		for(i= 0; i< 16; i= i+ 1)
			for(j= 0; j< 16; j= j+ 1)
				wall[i][j]<= wall[i][j];

	end

end

always@(posedge clk or negedge rst_n) begin
	
	if(!rst_n) begin

		p1_x<= 4'd0;
		p1_y<= 4'd0;
		p2_x<= 4'd0;
		p2_y<= 4'd0;
		p3_x<= 4'd0;
		p3_y<= 4'd0;
		
	end
	else if(in_valid) begin
		
		p1_x<= prize_x_1;
		p1_y<= prize_y_1;
		p2_x<= prize_x_2;
		p2_y<= prize_y_2; 
		p3_x<= prize_x_3;
		p3_y<= prize_y_3;
		
	end
	else if(ns== ST_PRE) begin
	
		case(found)
			2'd0: begin 
				p1_x<= p1_x;
				p1_y<= p1_y;
				p2_x<= p2_x;
				p2_y<= p2_y;
				p3_x<= p3_x;
				p3_y<= p3_y;
			end
			
			2'd1: begin 
				p1_x<= 4'd15;
				p1_y<= 4'd15;
				p2_x<= p2_x;
				p2_y<= p2_y;
				p3_x<= p3_x;
				p3_y<= p3_y;
			end
			2'd2: begin 
				p1_x<= p1_x;
				p1_y<= p1_y;
				p2_x<= 4'd15;
				p2_y<= 4'd15;
				p3_x<= p3_x;
				p3_y<= p3_y;
			end
			2'd3: begin 
				p1_x<= p1_x;
				p1_y<= p1_y;
				p2_x<= p2_x;
				p2_y<= p2_y;
				p3_x<= 4'd15;
				p3_y<= 4'd15;
			end
		endcase
		
	end
	else begin
	
		p1_x<= p1_x;
		p1_y<= p1_y;
		p2_x<= p2_x;
		p2_y<= p2_y;
		p3_x<= p3_x;
		p3_y<= p3_y;
	
	end

end

always@(posedge clk or negedge rst_n) begin
	
	if(!rst_n) begin
		
		init_x<= 4'd0;
		init_y<= 4'd0;
				
	end
	else if(in_valid) begin
		
		init_x<= player_x;
		init_y<= player_y;
		
	end
	else if(finish_d && cs== ST_DUMP) begin
		init_x<= now_x;
		init_y<= now_y;
	end
	else begin
	
		init_x<= init_x;
		init_y<= init_y;
	
	end
end

//---------------------------------------------------------------------
//   Queue Logic                                        
//---------------------------------------------------------------------

always@(posedge clk or negedge rst_n) begin

	if(!rst_n) begin

		p_start<= 5'd0;
		p_end<= 5'd0; 
		
		for(i= 0; i< 32; i= i+ 1) begin
			queue[i]<= 8'd0;
		end
		
		for(i= 0; i< 16; i= i+ 1) begin
			for(j= 0; j< 16; j= j+ 1) begin
				gray[i][j]<= 1'b1;
			end
		end
		
		for(i= 0; i< 15; i= i+ 1) begin
			for(j= 0; j< 15; j= j+ 1) begin
				dir[i][j]<= 4'd0;
			end
		end
		
	end	
	else if(ns== ST_PRE) begin

		p_start<= 5'd0;
		p_end<= 5'd1;
		
		queue[0]<= {init_x, init_y};
		
		for(j= 0; j< 15; j= j+ 1) begin
			for(i= 0; i< 15; i= i+ 1) begin
				if(i== init_x && j== init_y)
					gray[i][j]<= 1'b1;
				else
					gray[i][j]<= wall[i][j];
			end
		end
		
	end
	else if(ns== ST_EXE && exe_counter== 1'b1) begin
		
		p_start<= p_start+ 5'd1;
	
		case(visitable)
			
			4'b0000: begin 
				p_end<= p_end;
				for(i= 0; i< 16; i= i+ 1) begin
					for(j= 0; j< 16; j= j+ 1) begin
						gray[i][j]<= gray[i][j];
					end
				end
			end
			
			4'b0001: begin 
				p_end<= p_end+ 4'd1;
				queue[p_end]<= {now_x, (now_y- 4'd1)};
				gray[now_x][now_y- 4'd1]<= 1'b1;
				dir[now_x][now_y- 4'd1]<= 2'd2;
			end
			
			4'b0010: begin 
				p_end<= p_end+ 4'd1;
				queue[p_end]<= {(now_x+ 4'd1), now_y};
				gray[now_x+ 4'd1][now_y]<= 1'b1;
				dir[now_x+ 4'd1][now_y]<= 2'd3;
			end
			
			4'b0011: begin
				p_end<= p_end+ 4'd2;
				queue[p_end]<= {now_x, (now_y- 4'd1)};
				queue[p_end+ 4'd1]<= {(now_x+ 4'd1), now_y};
				gray[now_x][now_y- 4'd1]<= 1'b1;
				gray[now_x+ 4'd1][now_y]<= 1'b1;
				dir[now_x][now_y- 4'd1]<= 2'd2;
				dir[now_x+ 4'd1][now_y]<= 2'd3;
			end
			
			4'b0100: begin 
				p_end<= p_end+ 4'd1;
				queue[p_end]<= {now_x, (now_y+ 4'd1)};
				gray[now_x][now_y+ 4'd1]<= 1'b1;
				dir[now_x][now_y+ 4'd1]<= 2'd0;
			end
			
			4'b0101: begin 
				p_end<= p_end+ 4'd2;
				queue[p_end]<= {now_x, (now_y- 4'd1)};
				queue[p_end+ 4'd1]<= {now_x, (now_y+ 4'd1)};
				gray[now_x][now_y- 4'd1]<= 1'b1;
				gray[now_x][now_y+ 4'd1]<= 1'b1;
				dir[now_x][now_y- 4'd1]<= 2'd2;
				dir[now_x][now_y+ 4'd1]<= 2'd0;
			end
			
			4'b0110: begin 
				p_end<= p_end+ 4'd2;
				queue[p_end]<= {(now_x+ 4'd1), now_y};
				queue[p_end+ 4'd1]<= {now_x, (now_y+ 4'd1)};
				gray[now_x+ 4'd1][now_y]<= 1'b1;
				gray[now_x][now_y+ 4'd1]<= 1'b1;
				dir[now_x+ 4'd1][now_y]<= 2'd3;
				dir[now_x][now_y+ 4'd1]<= 2'd0;
			end
			
			4'b0111: begin 
				p_end<= p_end+ 4'd3;
				queue[p_end]<= {now_x, (now_y- 4'd1)};
				queue[p_end+ 4'd1]<= {(now_x+ 4'd1), now_y};
				queue[p_end+ 4'd2]<= {now_x, (now_y+ 4'd1)};
				gray[now_x][now_y- 4'd1]<= 1'b1;
				gray[now_x+ 4'd1][now_y]<= 1'b1;
				gray[now_x][now_y+ 4'd1]<= 1'b1;
				dir[now_x][now_y- 4'd1]<= 2'd2;
				dir[now_x+ 4'd1][now_y]<= 2'd3;
				dir[now_x][now_y+ 4'd1]<= 2'd0;
			end
			
			4'b1000: begin 
				p_end<= p_end+ 4'd1;
				queue[p_end]<= {(now_x- 4'd1), now_y};
				gray[now_x- 4'd1][now_y]<= 1'b1;
				dir[now_x- 4'd1][now_y]<= 2'd1;
			end
			
			4'b1001: begin 
				p_end<= p_end+ 4'd2;
				queue[p_end]<= {now_x, (now_y- 4'd1)};
				queue[p_end+ 4'd1]<= {(now_x- 4'd1), now_y};
				gray[now_x][now_y- 4'd1]<= 1'b1;
				gray[now_x- 4'd1][now_y]<= 1'b1;
				dir[now_x][now_y- 4'd1]<= 2'd2;
				dir[now_x- 4'd1][now_y]<= 2'd1;
			end
			
			4'b1010: begin 
				p_end<= p_end+ 4'd2;
				queue[p_end]<= {(now_x+ 4'd1), now_y};
				queue[p_end+ 4'd1]<= {(now_x- 4'd1), now_y};
				gray[now_x+ 4'd1][now_y]<= 1'b1;
				gray[now_x- 4'd1][now_y]<= 1'b1;
				dir[now_x+ 4'd1][now_y]<= 2'd3;
				dir[now_x- 4'd1][now_y]<= 2'd1;
			end
			
			4'b1011: begin 
				p_end<= p_end+ 4'd3;
				queue[p_end]<= {now_x, (now_y- 4'd1)};
				queue[p_end+ 4'd1]<= {(now_x+ 4'd1), now_y};
				queue[p_end+ 4'd2]<= {(now_x- 4'd1), now_y};
				gray[now_x][now_y- 4'd1]<= 1'b1;
				gray[now_x+ 4'd1][now_y]<= 1'b1;
				gray[now_x- 4'd1][now_y]<= 1'b1;
				dir[now_x][now_y- 4'd1]<= 2'd2;
				dir[now_x+ 4'd1][now_y]<= 2'd3;
				dir[now_x- 4'd1][now_y]<= 2'd1;
			end
			
			4'b1100: begin 
				p_end<= p_end+ 4'd2;
				queue[p_end]<= {now_x, (now_y+ 4'd1)};
				queue[p_end+ 4'd1]<= {(now_x- 4'd1), now_y};
				gray[now_x][now_y+ 4'd1]<= 1'b1;
				gray[now_x- 4'd1][now_y]<= 1'b1;
				dir[now_x][now_y+ 4'd1]<= 2'd0;
				dir[now_x- 4'd1][now_y]<= 2'd1;
			end
			
			4'b1101: begin 
				p_end<= p_end+ 4'd3;
				queue[p_end]<= {now_x, (now_y- 4'd1)};
				queue[p_end+ 4'd1]<= {now_x, (now_y+ 4'd1)};
				queue[p_end+ 4'd2]<= {(now_x- 4'd1), now_y};
				gray[now_x][now_y- 4'd1]<= 1'b1;
				gray[now_x][now_y+ 4'd1]<= 1'b1;
				gray[now_x- 4'd1][now_y]<= 1'b1;
				dir[now_x][now_y- 4'd1]<= 2'd2;
				dir[now_x][now_y+ 4'd1]<= 2'd0;
				dir[now_x- 4'd1][now_y]<= 2'd1;
			end
			
			4'b1110: begin 
				p_end<= p_end+ 4'd3;
				queue[p_end]<= {(now_x+ 4'd1), now_y};
				queue[p_end+ 4'd1]<= {now_x, (now_y+ 4'd1)};
				queue[p_end+ 4'd2]<= {(now_x- 4'd1), now_y};
				gray[now_x+ 4'd1][now_y]<= 1'b1;
				gray[now_x][now_y+ 4'd1]<= 1'b1;
				gray[now_x- 4'd1][now_y]<= 1'b1;
				dir[now_x+ 4'd1][now_y]<= 2'd3;
				dir[now_x][now_y+ 4'd1]<= 2'd0;
				dir[now_x- 4'd1][now_y]<= 2'd1;
			end
			
			4'b1111: begin 
				p_end<= p_end+ 4'd4;
				queue[p_end]<= {now_x, (now_y- 4'd1)};
				queue[p_end+ 4'd1]<= {(now_x+ 4'd1), now_y};
				queue[p_end+ 4'd2]<= {now_x, (now_y+ 4'd1)};
				queue[p_end+ 4'd3]<= {(now_x- 4'd1), now_y};
				gray[now_x][now_y- 4'd1]<= 1'b1;
				gray[now_x+ 4'd1][now_y]<= 1'b1;
				gray[now_x][now_y+ 4'd1]<= 1'b1;
				gray[now_x- 4'd1][now_y]<= 1'b1;
				dir[now_x][now_y- 4'd1]<= 2'd2;
				dir[now_x+ 4'd1][now_y]<= 2'd3;
				dir[now_x][now_y+ 4'd1]<= 2'd0;
				dir[now_x- 4'd1][now_y]<= 2'd1;
			end

		endcase	
	end
	else begin
	
		p_start<= p_start;
		p_end<= p_end; 
		
		for(i= 0; i< 32; i= i+ 1) begin
			queue[i]<= queue[i];
		end
		
		for(i= 0; i< 16; i= i+ 1) begin
			for(j= 0; j< 16; j= j+ 1) begin
				gray[i][j]<= gray[i][j];
			end
		end
	
	end

end

always@(*) begin
	
	now_x= queue[p_start][7: 4];
	now_y= queue[p_start][3: 0];

end

always@(posedge clk or negedge rst_n) begin

	if(!rst_n) begin
		visitable[0]<= 1'b0;
		visitable[1]<= 1'b0;
		visitable[2]<= 1'b0;
		visitable[3]<= 1'b0;
	end
	else begin
		visitable[0]<= (~gray[now_x][now_y- 4'd1]);
		visitable[1]<= (~gray[now_x+ 4'd1][now_y]);
		visitable[2]<= (~gray[now_x][now_y+ 4'd1]);
		visitable[3]<= (~gray[now_x- 4'd1][now_y]);
	end
	
end

//---------------------------------------------------------------------
//   Terminate Logic                                        
//---------------------------------------------------------------------

always@(*) begin
	
	if({now_x, now_y}== {p1_x, p1_y}|| 
	   {now_x, now_y}== {p2_x, p2_y}|| 
	   {now_x, now_y}== {p3_x, p3_y})
		finish= 1'b1;
	else
		finish= 1'b0;
end

always@(*) begin
	
	if(D== {init_x, init_y})
		finish_d= 1'b1;
	else
		finish_d= 1'b0;
end

//---------------------------------------------------------------------
//   Counter Logic                                        
//---------------------------------------------------------------------

always@(posedge clk or negedge rst_n) begin
	
	if(!rst_n) begin
		num_exe<= 2'd0;
	end
	else if(cs== ST_DUMP && finish_d) begin
		num_exe<= num_exe+ 2'd1;
	end
	else begin
		num_exe<= num_exe;
	end
	
end

always@(posedge clk or negedge rst_n) begin
	
	if(!rst_n) 
		exe_counter<= 1'd0;
	else if(cs== ST_EXE)
		exe_counter<= exe_counter+ 1'b1;
	else
		exe_counter<= 1'b0;
	
end

always@(posedge clk or negedge rst_n) begin
	
	if(!rst_n) begin
		pre_counter<= 1'd0;
	end
	else if(cs== ST_PRE) begin
		pre_counter<= 1'd1;
	end
	else begin
		pre_counter<= 1'd0;
	end
	
end

always@(posedge clk or negedge rst_n) begin
	
	if(!rst_n) begin
		dump_counter<= 8'd0;
	end
	else if(cs== ST_DUMP) begin
		dump_counter<= dump_counter+ 8'd1;
	end
	else begin
		dump_counter<= dump_counter;
	end
	
end

always@(posedge clk or negedge rst_n) begin
	
	if(!rst_n) begin
		out_counter<= 8'd0;
	end
	else if(ns== ST_REST) begin
		out_counter<= point[0];
	end
	else if(ns== ST_OUTPUT) begin
		if(out_counter== 8'd1)
			out_counter<= point[1];
		else if(out_counter== (point[0]+ 8'd2)) 
			out_counter<= point[2];
		else
			out_counter<= out_counter- 8'd1;
	end
	else begin
		out_counter<= 8'd0;
	end
	
end

always@(posedge clk or negedge rst_n) begin
	
	if(!rst_n) begin
		point[0]<= 8'd0;
		point[1]<= 8'd0;
		point[2]<= 8'd0;
	end
	else if(cs== ST_DUMP) begin
		point[num_exe]<= dump_counter;
	end
	else begin
		point[0]<= point[0];
		point[1]<= point[1];
		point[2]<= point[2];
	end
	
end

//---------------------------------------------------------------------
//   Found Logic                                        
//---------------------------------------------------------------------

always@(posedge clk or negedge rst_n) begin
	
	if(!rst_n) begin
		found<= 2'd0;
	end
	else if(cs== ST_DUMP && finish_d) begin
		if({now_x, now_y}== {p1_x, p1_y})
			found<= 2'd1;
		else if({now_x, now_y}== {p2_x, p2_y})
			found<= 2'd2;
		else if({now_x, now_y}== {p3_x, p3_y})
			found<= 2'd3;
		else
			found<= 2'd0;
	end
	else begin
		found<= found;
	end
	
end

//---------------------------------------------------------------------
//   Dump Logic                                        
//---------------------------------------------------------------------

assign WEN= (cs== ST_DUMP || cs== ST_EXE)? 1'b0: 1'b1;
assign A= (cs== ST_OUTPUT || cs== ST_REST)? out_counter: dump_counter;

RA1SH U_SRAM(
	.A(A),
	.D(D),
	.CLK(clk),
	.CEN(1'b0),
	.WEN(WEN),
	.OEN(1'b0),
	.Q(Q)
);

always@(posedge clk or negedge rst_n) begin
	
	if(!rst_n) begin
		D<= 8'd0;
	end
	else begin
		D<= {t_x, t_y};
	end
	
end

//always@(posedge clk or negedge rst_n) begin
//	
//	if(!rst_n) begin
//	
//		for(i= 0; i< 256; i= i+ 1)
//			mem[i]<= 8'd0;
//	end
//	else if(cs== ST_DUMP) begin
//	
//		mem[dump_counter]<= D;
//	end
//	else begin
//	
//		for(i= 0; i< 256; i= i+ 1)
//			mem[i]<= mem[i];
//	end
//	
//end

always@(*) begin
	
	if(cs!= ST_DUMP) begin
		t_x= now_x;
		t_y= now_y;
	end
	else begin
		case(dir[D[7: 4]][D[3: 0]])
			2'd0: begin 
				t_x= D[7: 4];
				t_y= D[3: 0]- 4'd1;
			end
			2'd1: begin 
				t_x= D[7: 4]+ 4'd1;
				t_y= D[3: 0];
			end
			2'd2: begin 
				t_x= D[7: 4];
				t_y= D[3: 0]+ 4'd1;
			end
			2'd3: begin 
				t_x= D[7: 4]- 4'd1;
				t_y= D[3: 0];
			end
		endcase
	end
end

//---------------------------------------------------------------------
//   Output Logic                                        
//---------------------------------------------------------------------

always@(posedge clk or negedge rst_n) begin
	
	if(!rst_n) begin
		out_valid<= 1'b0;
		out_x<= 4'b0;
		out_y<= 4'b0;
	end
	else if(cs== ST_OUTPUT) begin
		out_valid<= 1'b1;
		out_x<= Q[7: 4];
		out_y<= Q[3: 0];
	end
	else if(cs== ST_FINAL) begin
		out_valid<= 1'b1;
		out_x<= Q[7: 4];
		out_y<= Q[3: 0];
	end
	else begin
		out_valid<= 1'b0;
		out_x<= 4'b0;
		out_y<= 4'b0;
	end
end

endmodule