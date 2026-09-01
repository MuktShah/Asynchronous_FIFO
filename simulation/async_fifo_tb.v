`timescale 1ns / 1ps

module async_fifo_tb;

    parameter DATA_WIDTH = 8;
    parameter ADDR_WIDTH = 4;

    // Signals
    reg wr_clk;
    reg rd_clk;
    reg rst;

    reg wr_en;
    reg [DATA_WIDTH-1:0] din;
    wire full;

    reg rd_en;
    wire [DATA_WIDTH-1:0] dout;
    wire empty;


    // DUT
    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .wr_clk(wr_clk),
        .rd_clk(rd_clk),
        .rst(rst),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .din(din),
        .dout(dout),
        .full(full),
        .empty(empty)
    );


    // Write clock
    initial begin
        wr_clk = 0;
        forever #5 wr_clk = ~wr_clk;
    end


    // Read clock
    initial begin
        rd_clk = 0;
        forever #7 rd_clk = ~rd_clk;
    end


    integer i;


    initial begin

        // Initialize
        rst   = 1;
        wr_en = 0;
        rd_en = 0;
        din   = 0;

        // Reset
        #25;
        rst = 0;
        #20;


        // Test 1: Write
        for (i = 0; i < 8; i = i + 1) begin

            @(negedge wr_clk);

            din   = 8'h10 + i;
            wr_en = 1;

            @(negedge wr_clk);

            wr_en = 0;

        end


        // Synchronization delay
        repeat (3) @(posedge rd_clk);


        // Test 2: Read
        for (i = 0; i < 8; i = i + 1) begin

            while (empty)
                @(negedge rd_clk);

            @(negedge rd_clk);
            rd_en = 1;

            @(negedge rd_clk);
            rd_en = 0;

        end


        // Wait until empty
        repeat (3) @(posedge rd_clk);


        // Test 3: Simultaneous read/write
        fork

            // Write process
            begin : WRITE_PROCESS

                integer w;

                for (w = 0; w < 8; w = w + 1) begin

                    while (full)
                        @(negedge wr_clk);

                    @(negedge wr_clk);

                    din   = 8'hA0 + w;
                    wr_en = 1;

                    @(negedge wr_clk);

                    wr_en = 0;

                end

            end


            // Read process
            begin : READ_PROCESS

                integer r;

                while (empty)
                    @(negedge rd_clk);

                for (r = 0; r < 8; r = r + 1) begin

                    while (empty)
                        @(negedge rd_clk);

                    @(negedge rd_clk);

                    rd_en = 1;

                    @(negedge rd_clk);

                    rd_en = 0;

                end

            end

        join


        #100;

        $finish;

    end

endmodule