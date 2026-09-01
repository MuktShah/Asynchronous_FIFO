module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    // Clocks and reset
    input  wire                  wr_clk,
    input  wire                  rd_clk,
    input  wire                  rst,

    // Write signals
    input  wire                  wr_en,
    input  wire [DATA_WIDTH-1:0] din,
    output reg                   full,

    // Read signals
    input  wire                  rd_en,
    output reg  [DATA_WIDTH-1:0] dout,
    output reg                   empty
);

    // FIFO depth
    localparam DEPTH = (1 << ADDR_WIDTH);


    // FIFO memory
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];


    // Write pointers
    reg  [ADDR_WIDTH:0] wr_ptr_bin;
    reg  [ADDR_WIDTH:0] wr_ptr_gray;

    wire [ADDR_WIDTH:0] wr_ptr_bin_next;
    wire [ADDR_WIDTH:0] wr_ptr_gray_next;

    wire                full_next;


    // Read pointers
    reg  [ADDR_WIDTH:0] rd_ptr_bin;
    reg  [ADDR_WIDTH:0] rd_ptr_gray;

    wire [ADDR_WIDTH:0] rd_ptr_bin_next;
    wire [ADDR_WIDTH:0] rd_ptr_gray_next;

    wire                empty_next;


    // Synchronizer registers
    reg [ADDR_WIDTH:0] rd_ptr_gray_sync1;
    reg [ADDR_WIDTH:0] rd_ptr_gray_sync2;

    reg [ADDR_WIDTH:0] wr_ptr_gray_sync1;
    reg [ADDR_WIDTH:0] wr_ptr_gray_sync2;


    // Write pointer logic
    assign wr_ptr_bin_next =
            wr_ptr_bin + ((wr_en && !full) ? 1'b1 : 1'b0);

    // Binary to Gray code
    assign wr_ptr_gray_next =
            (wr_ptr_bin_next >> 1) ^ wr_ptr_bin_next;


    // Full condition
    assign full_next =
        (wr_ptr_gray_next ==
        {
            ~rd_ptr_gray_sync2[ADDR_WIDTH:ADDR_WIDTH-1],
             rd_ptr_gray_sync2[ADDR_WIDTH-2:0]
        });


    // Write operation
    always @(posedge wr_clk or posedge rst) begin
        if (rst) begin
            wr_ptr_bin  <= 0;
            wr_ptr_gray <= 0;
            full        <= 0;
        end
        else begin
            // Write data
            if (wr_en && !full)
                mem[wr_ptr_bin[ADDR_WIDTH-1:0]] <= din;

            // Update pointers
            wr_ptr_bin  <= wr_ptr_bin_next;
            wr_ptr_gray <= wr_ptr_gray_next;

            // Update full flag
            full <= full_next;
        end
    end


    // Read pointer logic
    assign rd_ptr_bin_next =
            rd_ptr_bin + ((rd_en && !empty) ? 1'b1 : 1'b0);

    // Binary to Gray code
    assign rd_ptr_gray_next =
            (rd_ptr_bin_next >> 1) ^ rd_ptr_bin_next;


    // Empty condition
    assign empty_next =
            (rd_ptr_gray_next == wr_ptr_gray_sync2);


    // Read operation
    always @(posedge rd_clk or posedge rst) begin
        if (rst) begin
            rd_ptr_bin  <= 0;
            rd_ptr_gray <= 0;
            dout        <= 0;
            empty       <= 1;
        end
        else begin
            // Read data
            if (rd_en && !empty)
                dout <= mem[rd_ptr_bin[ADDR_WIDTH-1:0]];

            // Update pointers
            rd_ptr_bin  <= rd_ptr_bin_next;
            rd_ptr_gray <= rd_ptr_gray_next;

            // Update empty flag
            empty <= empty_next;
        end
    end


    // Sync read pointer to write clock
    always @(posedge wr_clk or posedge rst) begin
        if (rst) begin
            rd_ptr_gray_sync1 <= 0;
            rd_ptr_gray_sync2 <= 0;
        end
        else begin
            rd_ptr_gray_sync1 <= rd_ptr_gray;
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
        end
    end


    // Sync write pointer to read clock
    always @(posedge rd_clk or posedge rst) begin
        if (rst) begin
            wr_ptr_gray_sync1 <= 0;
            wr_ptr_gray_sync2 <= 0;
        end
        else begin
            wr_ptr_gray_sync1 <= wr_ptr_gray;
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
        end
    end

endmodule