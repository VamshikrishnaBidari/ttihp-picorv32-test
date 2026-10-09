/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_example (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    wire resetn = rst_n & ena;

    wire        mem_valid;
    wire        mem_instr;
    wire        mem_ready;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [3:0]  mem_wstrb;
    reg  [31:0] mem_rdata;

    reg [31:0] result;

    // Immediate-response memory interface.
    assign mem_ready = mem_valid;

    // Small instruction ROM. All instructions are RV32I.
    always @* begin
        mem_rdata = 32'h00000013; // NOP by default

        if (mem_addr < 32'd24) begin
            case (mem_addr[7:2])
                6'd0: mem_rdata = 32'h00001137; // lui  x2, 1
                6'd1: mem_rdata = 32'h00100093; // addi x1, x0, 1
                6'd2: mem_rdata = 32'h00112023; // sw   x1, 0(x2)
                6'd3: mem_rdata = 32'h00108093; // addi x1, x1, 1
                6'd4: mem_rdata = 32'h00112023; // sw   x1, 0(x2)
                6'd5: mem_rdata = 32'hff9ff06f; // jal  x0, -8
                default: mem_rdata = 32'h00000013;
            endcase
        end
    end

    // Observable memory-mapped output register at address 0x1000.
    always @(posedge clk) begin
        if (!resetn) begin
            result <= 32'b0;
        end else if (mem_valid && mem_ready &&
                     mem_wstrb != 4'b0000 &&
                     mem_addr == 32'h00001000) begin
            result <= mem_wdata;
        end
    end

    picorv32 #(
        .ENABLE_COUNTERS     (0),
        .ENABLE_COUNTERS64   (0),
        .ENABLE_REGS_16_31   (0),
        .ENABLE_REGS_DUALPORT(0),
        .TWO_STAGE_SHIFT     (0),
        .COMPRESSED_ISA      (0),
        .CATCH_MISALIGN      (1),
        .CATCH_ILLINSN       (1),
        .ENABLE_PCPI         (0),
        .ENABLE_MUL          (0),
        .ENABLE_FAST_MUL     (0),
        .ENABLE_DIV          (0),
        .ENABLE_IRQ          (0),
        .ENABLE_IRQ_QREGS    (0),
        .ENABLE_IRQ_TIMER    (0),
        .ENABLE_TRACE        (0),
        .PROGADDR_RESET      (32'h00000000)
    ) cpu (
        .clk          (clk),
        .resetn       (resetn),
        .trap         (),
        .mem_valid    (mem_valid),
        .mem_instr    (mem_instr),
        .mem_ready    (mem_ready),
        .mem_addr     (mem_addr),
        .mem_wdata    (mem_wdata),
        .mem_wstrb    (mem_wstrb),
        .mem_rdata    (mem_rdata),

        .mem_la_read  (),
        .mem_la_write (),
        .mem_la_addr  (),
        .mem_la_wdata (),
        .mem_la_wstrb (),

        .pcpi_valid   (),
        .pcpi_insn    (),
        .pcpi_rs1     (),
        .pcpi_rs2     (),
        .pcpi_wr      (1'b0),
        .pcpi_rd      (32'b0),
        .pcpi_wait    (1'b0),
        .pcpi_ready   (1'b0),

        .irq          (32'b0),
        .eoi          (),
        .trace_valid  (),
        .trace_data   ()
    );

    assign uo_out  = result[7:0];
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;
    assign mem_ready = mem_valid;

    // Unused Tiny Tapeout inputs.
    wire unused = ^{ui_in, uio_in, mem_instr};

endmodule
