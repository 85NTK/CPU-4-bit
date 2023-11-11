module CPU(clk, reset, DataIn, opcode, A, B, DataOut, OpAddOut, ZF, CF, SF, halt);
    input clk, reset;                // Đầu vào xung clock và tín hiệu reset
    input [3:0] DataIn;             // Đầu vào dữ liệu 4-bit
    input [7:0] opcode;             // Đầu vào opcode 8-bit
    output reg [3:0] OpAddOut, DataOut, A, B;  // Đầu ra các thanh ghi và dữ liệu
    output reg ZF, CF, SF, halt;    // Đầu ra các cờ và tín hiệu dừng
    reg [3:0] DATA[15:0], STACK[15:0], DSTACK[15:0];  // Khai báo các thanh ghi và bộ nhớ
    reg [3:0] address, tmp, tmpd, tmpadd;  // Khai báo các biến trung gian

always @(posedge clk) begin  // Luôn thực thi khi có cạnh dương của xung đồng hồ
        if (reset) halt = 0;    // Đặt `halt` về 0 nếu tín hiệu `reset` được kích hoạt

        CF = 0;                  // Đặt cờ tràn CF về 0
        ZF = 0;                  // Đặt cờ zero ZF về 0
        SF = 0;                  // Đặt cờ dấu SF về 0

        if (!halt) begin         // Nếu không bị dừng, thực hiện các hoạt động
            case(opcode[7:4])    // Lựa chọn lệnh dựa trên 4 bit đầu của opcode
                4'b0000: begin   // Lệnh 4'b0000
                    B = opcode[3:0];          // Lấy giá trị B từ 4 bit cuối của opcode
                    if (A+B>15) CF = 1;        // Nếu A + B lớn hơn 15, đặt cờ tràn CF
                    A = A + B;                // Thực hiện phép cộng A và B
                    if (A==0) ZF = 1;         // Nếu A bằng 0, đặt cờ zero ZF

		4'b0001: begin
			B = opcode[3:0];          // Lấy giá trị B từ 4 bit cuối của opcode
			if (A<B) SF = 1;          // Nếu A nhỏ hơn B, đặt cờ dấu SF
			A = A - B;                // Thực hiện phép trừ A và B
			if (A==0) ZF = 1;         // Nếu A bằng 0, đặt cờ zero ZF
		end

		4'b0010: begin
			tmp = B;                  // Sao chép giá trị của B vào biến tạm thời tmp
			B = A;                    // Sao chép giá trị của A vào B
			A = tmp;                  // Sao chép giá trị của biến tạm thời tmp vào A
			if (A==0) ZF = 1;         // Nếu A bằng 0, đặt cờ zero ZF
		end
		4'b0011: begin
			DATA[opcode[3:0]] = 4'b0101;  // Gán giá trị 4'b0101 vào bộ nhớ DATA tại địa chỉ được chỉ định bởi 4 bit cuối của opcode
			DataOut = DATA[opcode[3:0]]; // Đọc giá trị từ bộ nhớ DATA và đặt vào DataOut
			A = DATA[opcode[3:0]];        // Gán giá trị từ bộ nhớ DATA vào thanh ghi A
			if (A==0) ZF = 1;             // Nếu A bằng 0, đặt cờ zero ZF
			if (A<0) SF = 1;              // Nếu A âm, đặt cờ dấu SF
		end

		4'b0100: begin
			DATA[opcode[3:0]] = B;      // Gán giá trị của thanh ghi B vào bộ nhớ DATA tại địa chỉ được chỉ định bởi 4 bit cuối của opcode
			DataOut = B;                // Đặt giá trị của B vào thanh ghi DataOut
		end

		4'b0101: begin
			DataOut = A;                // Đặt giá trị của thanh ghi A vào thanh ghi DataOut
			if (A==0) ZF = 1;           // Nếu A bằng 0, đặt cờ zero ZF
			if (A<0) SF = 1;            // Nếu A âm, đặt cờ dấu SF
		end

		4'b0110: begin
			B = opcode[3:0];            // Lấy giá trị B từ 4 bit cuối của opcode
			if (!A & B) ZF = 1;         // Nếu (NOT A) AND B là đúng, đặt cờ zero ZF
		end

		4'b0111: begin
			B = B | DATA[opcode[3:0]]; // Thực hiện phép OR giữa thanh ghi B và giá trị từ bộ nhớ DATA tại địa chỉ được chỉ định bởi 4 bit cuối của opcode
			DataOut = B;                // Đặt giá trị của B vào thanh ghi DataOut
		End
		4'b1000: begin
			if (ZF==0) begin            // Kiểm tra cờ zero ZF, nếu không đặt (không bằng 0)
				OpAddOut = STACK[tmpadd];// Lấy giá trị từ bộ nhớ STACK tại địa chỉ được chỉ định bởi biến tmpadd và đặt vào thanh ghi OpAddOut
				tmpadd = tmpadd + 1;     // Tăng giá trị của biến tmpadd lên 1
			end
		end

		4'b1001: begin
			OpAddOut = STACK[tmpadd];   // Lấy giá trị từ bộ nhớ STACK tại địa chỉ được chỉ định bởi biến tmpadd và đặt vào thanh ghi OpAddOut
			tmpadd = tmpadd + 1;        // Tăng giá trị của biến tmpadd lên 1
		end
		4'b1010: begin
			A = DataIn;                // Đặt giá trị của đầu vào DataIn vào thanh ghi A
			if (A==0) ZF = 1;           // Nếu A bằng 0, đặt cờ zero ZF
			if (A<0) SF = 1;            // Nếu A âm, đặt cờ dấu SF
		end

		4'b1011: begin
			DSTACK[tmpd] = A;           // Gán giá trị của thanh ghi A vào bộ nhớ DSTACK tại địa chỉ được chỉ định bởi biến tmpd
			A = 0;                      // Đặt giá trị của thanh ghi A về 0
			tmpd = tmpd + 1;            // Tăng giá trị của biến tmpd lên 1
		end

		4'b1100: begin
			tmpd = tmpd - 1;            // Giảm giá trị của biến tmpd đi 1
			A = DSTACK[tmpd];           // Lấy giá trị từ bộ nhớ DSTACK tại địa chỉ được chỉ định bởi biến tmpd và đặt vào thanh ghi A
			tmpd = tmpd + 1;            // Tăng giá trị của biến tmpd lên 1
		end
		4'b1101: begin
			OpAddOut = STACK[opcode[3:0]]; // Lấy giá trị từ bộ nhớ STACK tại địa chỉ được chỉ định bởi 4 bit cuối của opcode và đặt vào thanh ghi OpAddOut
		end

		4'b1110: begin
			tmpd = 0;                   // Đặt giá trị của biến tmpd về 0
			tmpadd = 0;                 // Đặt giá trị của biến tmpadd về 0
		end

		4'b1111: halt = 1;              // Đặt tín hiệu dừng halt thành 1
		endcase:                 // Kết thúc mệnh đề case, đã thực hiện xử lý cho opcode hiện tại

		DATA[address] = A;       // Lưu giá trị của thanh ghi A vào bộ nhớ DATA tại địa chỉ được chỉ định bởi biến address
		STACK[address] = opcode[7:1];  // Lưu giá trị của các bit từ 7 đến 1 của opcode vào bộ nhớ STACK tại địa chỉ được chỉ định bởi biến address
		address = address + 1;  // Tăng giá trị của biến address lên 1 để chuẩn bị cho việc lưu trữ vào các địa chỉ tiếp theo trong bộ nhớ DATA và STACK
		end
    end
endmodule
