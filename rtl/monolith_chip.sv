`default_nettype none

module monolith_chip(
    `ifdef USE_POWER_PINS
    inout wire IOVDD,
    inout wire IOVSS,
    inout wire VDD,
    inout wire VSS,
    `endif
    
    inout wire clk_PAD,
    inout wire rst_PAD,

    inout wire in1_PAD,
    inout wire in2_PAD,
    inout wire hash_or_compress_PAD,
    inout wire go_PAD,

    inout wire out_PAD,
    inout wire valid_PAD
);

    wire clk_P2C;
    wire rst_P2C;
    wire in1_P2C, in2_P2C;
    wire h_or_c_P2C, go_P2C;
    wire out_C2P, valid_C2P;

    wire [30:0] out;
    assign out_C2P = out[14];

    // Power/ground pad instances
    (* keep *)
    sg13g2_IOPadIOVdd iovdd_pad  (
        `ifdef USE_POWER_PINS
        .iovdd  (IOVDD),
        .iovss  (IOVSS),
        .vdd    (VDD),
        .vss    (VSS)
        `endif
    );
    
    (* keep *)
    sg13g2_IOPadIOVss iovss_pad  (
        `ifdef USE_POWER_PINS
        .iovdd  (IOVDD),
        .iovss  (IOVSS),
        .vdd    (VDD),
        .vss    (VSS)
        `endif
    );
    
    (* keep *)
    sg13g2_IOPadVdd vdd_pad  (
        `ifdef USE_POWER_PINS
        .iovdd  (IOVDD),
        .iovss  (IOVSS),
        .vdd    (VDD),
        .vss    (VSS)
        `endif
    );

    (* keep *)
    sg13g2_IOPadVss vss_pad  (
        `ifdef USE_POWER_PINS
        .iovdd  (IOVDD),
        .iovss  (IOVSS),
        .vdd    (VDD),
        .vss    (VSS)
        `endif
    );
    
    // Schmitt trigger
    sg13g2_IOPadIn clk_pad (
        `ifdef USE_POWER_PINS
        .iovdd  (IOVDD),
        .iovss  (IOVSS),
        .vdd    (VDD),
        .vss    (VSS),
        `endif
        .p2c    (clk_P2C),
        .pad    (clk_PAD)
    );
    
    // Normal input
    sg13g2_IOPadIn rst_pad (
        `ifdef USE_POWER_PINS
        .iovdd  (IOVDD),
        .iovss  (IOVSS),
        .vdd    (VDD),
        .vss    (VSS),
        `endif
        .p2c    (rst_P2C),
        .pad    (rst_PAD)
    ); 

	sg13g2_IOPadIn in1_pad (
		`ifdef USE_POWER_PINS
		.iovdd  (IOVDD),
		.iovss  (IOVSS),
		.vdd    (VDD),
		.vss    (VSS),
		`endif
		.p2c    (in1_P2C),
		.pad    (in1_PAD)
	);

	sg13g2_IOPadIn in2_pad (
		`ifdef USE_POWER_PINS
		.iovdd  (IOVDD),
		.iovss  (IOVSS),
		.vdd    (VDD),
		.vss    (VSS),
		`endif
		.p2c    (in2_P2C),
		.pad    (in2_PAD)
	);

	sg13g2_IOPadIn horc_pad (
		`ifdef USE_POWER_PINS
		.iovdd  (IOVDD),
		.iovss  (IOVSS),
		.vdd    (VDD),
		.vss    (VSS),
		`endif
		.p2c    (h_or_c_P2C),
		.pad    (hash_or_compress_PAD)
	);

	sg13g2_IOPadIn go_pad (
		`ifdef USE_POWER_PINS
		.iovdd  (IOVDD),
		.iovss  (IOVSS),
		.vdd    (VDD),
		.vss    (VSS),
		`endif
		.p2c    (go_P2C),
		.pad    (go_PAD)
	);

	sg13g2_IOPadOut30mA out_pad (
		`ifdef USE_POWER_PINS
		.iovdd  (IOVDD),
		.iovss  (IOVSS),
		.vdd    (VDD),
		.vss    (VSS),
		`endif
		.c2p    (out_C2P),
		.pad    (out_PAD)
	);

	sg13g2_IOPadOut30mA valid_pad (
		`ifdef USE_POWER_PINS
		.iovdd  (IOVDD),
		.iovss  (IOVSS),
		.vdd    (VDD),
		.vss    (VSS),
		`endif
		.c2p    (valid_C2P),
		.pad    (valid_PAD)
	);

    (* keep *) monolith_top core (
        .clk(clk_P2C),
        .reset(rst_P2C),
        .in1({31{in1_P2C}}),
        .in2({31{in2_P2C}}),
        .hash_or_compress(h_or_c_P2C),
        .go(go_P2C),
        .out(out),
        .valid(valid_C2P)
    );

endmodule

`default_nettype wire
