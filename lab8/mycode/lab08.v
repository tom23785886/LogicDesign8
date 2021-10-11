`define silence   32'd50000000
`define hc  32'd524   // C5
`define hd  32'd588   // D5
`define he  32'd660   // E5
`define hf  32'd698   // F5
`define hg  32'd784   // G5
`define ha  32'd880   // A5
`define hb  32'd988   // B5

`define c   32'd262   // C4
`define d   32'd294   // D4
`define e   32'd330   // E4
`define f   32'd349   // F4
`define g   32'd392   // G4
`define a   32'd440   // A4
`define b   32'd494   // B4
`define l   32'd370   // sharp F4
`define k   32'd415   // sharp G4
`define m   32'd466   //sharp B4
`define n   32'd247   //sharp B3
`define dash 32'd3
`define sil   32'd50000000 // slience
module lab08(
    clk, // clock from crystal
    rst, // active high reset: BTNC
    _play, // SW: Play/Pause
    _mute, // SW: Mute
    _repeat, // SW: Repeat
    _music, // SW: Music
    _volUP, // BTN: Vol up
    _volDOWN, // BTN: Vol down
    _led_vol, // LED: volume
    audio_mclk, // master clock
    audio_lrck, // left-right clock
    audio_sck, // serial clock
    audio_sdin, // serial audio data input
    DISPLAY, // 7-seg
    DIGIT // 7-seg
);

    // I/O declaration
    input clk;  // clock from the crystal
    input rst;  // active high reset
    input _play, _mute, _repeat, _music, _volUP, _volDOWN;
    output [4:0] _led_vol;
    output audio_mclk; // master clock
    output audio_lrck; // left-right clock
    output audio_sck; // serial clock
    output audio_sdin; // serial audio data input
    output [6:0] DISPLAY;
    output [3:0] DIGIT;
    
    // Modify these
    

    // Internal Signal
    wire [15:0] audio_in_left, audio_in_right;
    wire volup_de;
    wire voldown_de;
    wire volup_pul;
    wire voldown_pul;
    wire clk13;
    reg [2:0]level;
    reg [2:0]nextlevel;
    wire [2:0]tmplevel;
    wire [31:0]BCD0;
    wire [31:0]BCD1;
    wire [31:0]BCD2;
    wire [31:0]BCD3;
    reg [6:0]display;
    reg [3:0]digit;
    reg [31:0]val;
    assign tmplevel=level;
    debounce de1(.pb_debounced(volup_de),.pb(_volUP),.clk(clk));
    onepulse on1(.signal(volup_de),.clk(clk),.op(volup_pul));
    debounce de2(.pb_debounced(voldown_de),.pb(_volDOWN),.clk(clk));
    onepulse on2(.signal(voldown_de),.clk(clk),.op(voldown_pul));
    
    wire clkDiv22;
    wire [11:0] ibeatNum; // Beat counter
    wire [31:0] freqL, freqR; // Raw frequency, produced by music module
    wire [21:0] freq_outL, freq_outR; // Processed Frequency, adapted to the clock rate of Basys3

    assign freq_outL = 50000000 / (_mute ? `silence : freqL); // Note gen makes no sound, if freq_out = 50000000 / `silence = 1
    assign freq_outR = 50000000 / (_mute ? `silence : freqR);
    assign _led_vol=(tmplevel==3'b000||_mute)?5'b00000:(tmplevel==3'b001)?5'b00001:(tmplevel==3'b010)?5'b00011:(tmplevel==3'b011)?5'b00111:(tmplevel==3'b100)?5'b01111:(tmplevel==3'b101)?5'b11111:5'b00000;
    clock_divider #(.n(22)) clock_22(
        .clk(clk),
        .clk_div(clkDiv22)
    );
    clock_divider#(13) clk2(.clk(clk),.clk_div(clk13));

    // Player Control
    player_control #(.LEN(576)) playerCtrl_00 ( 
        .clk(clkDiv22),
        .reset(rst),
        ._play(_play),
        ._repeat(_repeat),
        .ibeat(ibeatNum),
        .music(_music)
    );

    // Music module
    // [in]  beat number and en
    // [out] left & right raw frequency
    music_example music_00 (
        .ibeatNum(ibeatNum),
        .en(_play),
        .toneL(freqL),
        .toneR(freqR),
        .music(_music)
    );
    // Note generation
    // [in]  processed frequency
    // [out] audio wave signal (using square wave here)
    note_gen noteGen_00(
        .clk(clk), // clock from crystal
        .rst(rst), // active high reset
        .note_div_left(freq_outL),
        .note_div_right(freq_outR),
        .audio_left(audio_in_left), // left sound audio
        .audio_right(audio_in_right),
        .volume(tmplevel) // 3 bits for 5 levels
    );

    // Speaker controller
    speaker_control sc(
        .clk(clk),  // clock from the crystal
        .rst(rst),  // active high reset
        .audio_in_left(audio_in_left), // left channel audio data input
        .audio_in_right(audio_in_right), // right channel audio data input
        .audio_mclk(audio_mclk), // master clock
        .audio_lrck(audio_lrck), // left-right clock
        .audio_sck(audio_sck), // serial clock
        .audio_sdin(audio_sdin) // serial audio data input
    );

    always@(*)
        begin
            if(rst)
                begin
                    nextlevel=3'b011;
                end
            else
                begin
                    if(volup_pul)
                        begin
                            if(level==3'b101) begin nextlevel=level; end
                            else begin nextlevel=level+1; end
                        end
                    else if(voldown_pul)
                        begin
                            if(level==3'b001) begin nextlevel=level; end
                            else begin nextlevel=level-1; end
                        end
                    else
                        begin
                            nextlevel=level;
                        end
                end

            case(val)
                `hc:begin display=7'b0100111; end
                `hd:begin display=7'b0100001; end
                `he:begin display=7'b0000110; end
                `hf:begin display=7'b0001110; end
                `hg:begin display=7'b1000010; end
                `ha:begin display=7'b0100000; end
                `hb:begin display=7'b0000011; end
                
                `c:begin display=7'b0100111; end
                `d:begin display=7'b0100001; end
                `e:begin display=7'b0000110; end
                `f:begin display=7'b0001110; end
                `g:begin display=7'b1000010; end
                `a:begin display=7'b0100000; end
                `b:begin display=7'b0000011; end

                `l:begin display=7'b0001110; end
                `k:begin display=7'b1000010; end
                `m:begin display=7'b0000011; end
                `n:begin display=7'b0000011; end
                `dash:begin display=7'b0111111; end
                default: begin display=7'b1111111; end

            endcase
        end

    always@(posedge clk or posedge rst)
        begin
            if(rst)
                begin
                    level<=3'b011;
                end
            else
                begin
                    level<=nextlevel;
                end
        end
    always@(posedge clk13)
        begin
            case(digit)
                4'b1110: begin val=BCD1; digit=4'b1101; end
                4'b1101: begin val=BCD2; digit=4'b1011; end
                4'b1011: begin val=BCD3; digit=4'b0111; end
                4'b0111: begin val=BCD0; digit=4'b1110; end
                default: begin val=BCD0; digit=4'b1110; end 
            endcase
        end
    assign DISPLAY=display;
    assign DIGIT=digit;
    assign BCD0=freqR;
    assign BCD1=(_play==1)?`dash:32'b0;
    assign BCD2=(_play==1)?`dash:32'b0;
    assign BCD3=(_play==1)?`dash:32'b0;

endmodule


module music_example (
	input [11:0] ibeatNum,
	input en,
    input music,
	output reg [31:0] toneL,
    output reg [31:0] toneR
    
);

    always @* begin
        if(music==1'b0)
            begin
                if(en == 1) 
                    begin
                        case(ibeatNum)
                            // --- Measure 1 ---
                            12'd0: toneR = `g; 12'd1: toneR = `g; 12'd2: toneR = `g; 12'd3: toneR = `g;
                            12'd4: toneR = `g; 12'd5: toneR = `g; 12'd6: toneR = `g; 12'd7: toneR = `g;
                            12'd8: toneR = `g; 12'd9: toneR = `g; 12'd10: toneR = `g; 12'd11: toneR = `g;
                            12'd12: toneR = `g; 12'd13: toneR = `g; 12'd14: toneR = `g; 12'd15: toneR = `g;

                            12'd16: toneR = `sil; 12'd17: toneR = `sil; 12'd18: toneR = `sil; 12'd19: toneR = `sil;
                            12'd20: toneR = `sil; 12'd21: toneR = `sil; 12'd22: toneR = `sil; 12'd23: toneR = `sil;
                            12'd24: toneR = `c; 12'd25: toneR = `c; 12'd26: toneR = `c; 12'd27: toneR = `c;
                            12'd28: toneR = `c; 12'd29: toneR = `c; 12'd30: toneR = `c; 12'd31: toneR = `sil;

                            12'd32: toneR = `c; 12'd33: toneR = `c; 12'd34: toneR = `c; 12'd35: toneR = `c;
                            12'd36: toneR = `c; 12'd37: toneR = `c; 12'd38: toneR = `c; 12'd39: toneR = `c;
                            12'd40: toneR = `m; 12'd41: toneR = `m; 12'd42: toneR = `m; 12'd43: toneR = `m;
                            12'd44: toneR = `m; 12'd45: toneR = `m; 12'd46: toneR = `m; 12'd47: toneR = `sil;

                            12'd48: toneR = `m; 12'd49: toneR = `m; 12'd50: toneR = `m; 12'd51: toneR = `m;
                            12'd52: toneR = `m; 12'd53: toneR = `m; 12'd54: toneR = `m; 12'd55: toneR = `m;
                            12'd56: toneR = `g; 12'd57: toneR = `g; 12'd58: toneR = `g; 12'd59: toneR = `g;
                            12'd60: toneR = `g; 12'd61: toneR = `g; 12'd62: toneR = `g; 12'd63: toneR = `g;

                            12'd64: toneR = `a; 12'd65: toneR = `a; 12'd66: toneR = `a; 12'd67: toneR = `a;
                            12'd68: toneR = `a; 12'd69: toneR = `a; 12'd70: toneR = `a; 12'd71: toneR = `a;
                            12'd72: toneR = `sil; 12'd73: toneR = `sil; 12'd74: toneR = `sil; 12'd75: toneR = `sil;
                            12'd76: toneR = `sil; 12'd77: toneR = `sil; 12'd78: toneR = `sil; 12'd79: toneR = `sil;

                            12'd80: toneR = `sil; 12'd81: toneR = `sil; 12'd82: toneR = `sil; 12'd83: toneR = `sil;
                            12'd84: toneR = `sil; 12'd85: toneR = `sil; 12'd86: toneR = `sil; 12'd87: toneR = `sil;
                            12'd88: toneR = `c; 12'd89: toneR = `c; 12'd90: toneR = `c; 12'd91: toneR = `c;
                            12'd92: toneR = `c; 12'd93: toneR = `c; 12'd94: toneR = `c; 12'd95: toneR = `sil;

                            12'd96: toneR = `c; 12'd97: toneR = `c; 12'd98: toneR = `c; 12'd99: toneR = `c;
                            12'd100: toneR = `c; 12'd101: toneR = `c; 12'd102: toneR = `c; 12'd103: toneR = `c;
                            12'd104: toneR = `a; 12'd105: toneR = `a; 12'd106: toneR = `a; 12'd107: toneR = `a;
                            12'd108: toneR = `a; 12'd109: toneR = `a; 12'd110: toneR = `a; 12'd111: toneR = `sil;

                            12'd112: toneR = `a; 12'd113: toneR = `a; 12'd114: toneR = `a; 12'd115: toneR = `a;
                            12'd116: toneR = `a; 12'd117: toneR = `a; 12'd118: toneR = `a; 12'd119: toneR = `a;
                            12'd120: toneR = `g; 12'd121: toneR = `g; 12'd122: toneR = `g; 12'd123: toneR = `g;
                            12'd124: toneR = `g; 12'd125: toneR = `g; 12'd126: toneR = `g; 12'd127: toneR = `sil;

                            12'd128: toneR = `g; 12'd129: toneR = `g; 12'd130: toneR = `g; 12'd131: toneR = `g;
                            12'd132: toneR = `g; 12'd133: toneR = `g; 12'd134: toneR = `g; 12'd135: toneR = `g;
                            12'd136: toneR = `sil; 12'd137: toneR = `sil; 12'd138: toneR = `sil; 12'd139: toneR = `sil;
                            12'd140: toneR = `sil; 12'd141: toneR = `sil; 12'd142: toneR = `sil; 12'd143: toneR = `sil;

                            12'd144: toneR = `sil; 12'd145: toneR = `sil; 12'd146: toneR = `sil; 12'd147: toneR = `sil;
                            12'd148: toneR = `sil; 12'd149: toneR = `sil; 12'd150: toneR = `sil; 12'd151: toneR = `sil;
                            12'd152: toneR = `g; 12'd153: toneR = `g; 12'd154: toneR = `g; 12'd155: toneR = `g;
                            12'd156: toneR = `g; 12'd157: toneR = `g; 12'd158: toneR = `g; 12'd159: toneR = `sil;

                            12'd160: toneR = `g; 12'd161: toneR = `g; 12'd162: toneR = `g; 12'd163: toneR = `g;
                            12'd164: toneR = `g; 12'd165: toneR = `g; 12'd166: toneR = `g; 12'd167: toneR = `g;
                            12'd168: toneR = `a; 12'd169: toneR = `a; 12'd170: toneR = `a; 12'd171: toneR = `a;
                            12'd172: toneR = `a; 12'd173: toneR = `a; 12'd174: toneR = `a; 12'd175: toneR = `a;

                            12'd176: toneR = `m; 12'd177: toneR = `m; 12'd178: toneR = `m; 12'd179: toneR = `m;
                            12'd180: toneR = `m; 12'd181: toneR = `m; 12'd182: toneR = `m; 12'd183: toneR = `m;
                            12'd184: toneR = `hc; 12'd185: toneR = `hc; 12'd186: toneR = `hc; 12'd187: toneR = `hc;
                            12'd188: toneR = `hc; 12'd189: toneR = `hc; 12'd190: toneR = `hc; 12'd191: toneR = `hc;

                            12'd192: toneR = `f; 12'd193: toneR = `f; 12'd194: toneR = `f; 12'd195: toneR = `f;
                            12'd196: toneR = `f; 12'd197: toneR = `f; 12'd198: toneR = `f; 12'd199: toneR = `f;
                            12'd200: toneR = `f; 12'd201: toneR = `f; 12'd202: toneR = `f; 12'd203: toneR = `f;
                            12'd204: toneR = `f; 12'd205: toneR = `f; 12'd206: toneR = `f; 12'd207: toneR = `f;

                            12'd208: toneR = `e; 12'd209: toneR = `e; 12'd210: toneR = `e; 12'd211: toneR = `e;
                            12'd212: toneR = `e; 12'd213: toneR = `e; 12'd214: toneR = `e; 12'd215: toneR = `e;
                            12'd216: toneR = `e; 12'd217: toneR = `e; 12'd218: toneR = `e; 12'd219: toneR = `e;
                            12'd220: toneR = `f; 12'd221: toneR = `f; 12'd222: toneR = `f; 12'd223: toneR = `f;

                            12'd224: toneR = `f; 12'd225: toneR = `f; 12'd226: toneR = `f; 12'd227: toneR = `f;
                            12'd228: toneR = `f; 12'd229: toneR = `f; 12'd230: toneR = `f; 12'd231: toneR = `f;
                            12'd232: toneR = `f; 12'd233: toneR = `f; 12'd234: toneR = `f; 12'd235: toneR = `f;
                            12'd236: toneR = `sil; 12'd237: toneR = `sil; 12'd238: toneR = `sil; 12'd239: toneR = `sil;

                            12'd240: toneR = `hc; 12'd241: toneR = `hc; 12'd242: toneR = `hc; 12'd243: toneR = `hc;
                            12'd244: toneR = `hc; 12'd245: toneR = `hc; 12'd246: toneR = `hc; 12'd247: toneR = `hc;
                            12'd248: toneR = `hc; 12'd249: toneR = `hc; 12'd250: toneR = `hc; 12'd251: toneR = `hc;
                            12'd252: toneR = `hc; 12'd253: toneR = `hc; 12'd254: toneR = `hc; 12'd255: toneR = `sil;

                            12'd256: toneR = `hc; 12'd257: toneR = `hc; 12'd258: toneR = `hc; 12'd259: toneR = `hc;
                            12'd260: toneR = `hc; 12'd261: toneR = `hc; 12'd262: toneR = `hc; 12'd263: toneR = `hc;
                            12'd264: toneR = `hc; 12'd265: toneR = `hc; 12'd266: toneR = `hc; 12'd267: toneR = `hc;
                            12'd268: toneR = `hc; 12'd269: toneR = `hc; 12'd270: toneR = `hc; 12'd271: toneR = `hc;

                            12'd272: toneR = `sil; 12'd273: toneR = `sil; 12'd274: toneR = `sil; 12'd275: toneR = `sil;
                            12'd276: toneR = `sil; 12'd277: toneR = `sil; 12'd278: toneR = `sil; 12'd279: toneR = `sil;
                            12'd280: toneR = `a; 12'd281: toneR = `a; 12'd282: toneR = `a; 12'd283: toneR = `a;
                            12'd284: toneR = `a; 12'd285: toneR = `a; 12'd286: toneR = `a; 12'd287: toneR = `a;

                            12'd288: toneR = `a; 12'd289: toneR = `a; 12'd290: toneR = `a; 12'd291: toneR = `a;
                            12'd292: toneR = `a; 12'd293: toneR = `a; 12'd294: toneR = `a; 12'd295: toneR = `a;
                            12'd296: toneR = `m; 12'd297: toneR = `m; 12'd298: toneR = `m; 12'd299: toneR = `m;
                            12'd300: toneR = `m; 12'd301: toneR = `m; 12'd302: toneR = `m; 12'd303: toneR = `m;

                            12'd304: toneR = `hc; 12'd305: toneR = `hc; 12'd306: toneR = `hc; 12'd307: toneR = `hc;
                            12'd308: toneR = `hc; 12'd309: toneR = `hc; 12'd310: toneR = `hc; 12'd311: toneR = `hc;
                            12'd312: toneR = `hd; 12'd313: toneR = `hd; 12'd314: toneR = `hd; 12'd315: toneR = `hd;
                            12'd316: toneR = `hd; 12'd317: toneR = `hd; 12'd318: toneR = `hd; 12'd319: toneR = `hd;

                            12'd320: toneR = `f; 12'd321: toneR = `f; 12'd322: toneR = `f; 12'd323: toneR = `f;
                            12'd324: toneR = `f; 12'd325: toneR = `f; 12'd326: toneR = `f; 12'd327: toneR = `f;
                            12'd328: toneR = `sil; 12'd329: toneR = `sil; 12'd330: toneR = `sil; 12'd331: toneR = `sil;
                            12'd332: toneR = `sil; 12'd333: toneR = `sil; 12'd334: toneR = `sil; 12'd335: toneR = `sil;

                            12'd336: toneR = `sil; 12'd337: toneR = `sil; 12'd338: toneR = `sil; 12'd339: toneR = `sil;
                            12'd340: toneR = `sil; 12'd341: toneR = `sil; 12'd342: toneR = `sil; 12'd343: toneR = `sil;
                            12'd344: toneR = `e; 12'd345: toneR = `e; 12'd346: toneR = `e; 12'd347: toneR = `e;
                            12'd348: toneR = `e; 12'd349: toneR = `e; 12'd350: toneR = `e; 12'd351: toneR = `e;

                            12'd352: toneR = `e; 12'd353: toneR = `e; 12'd354: toneR = `e; 12'd355: toneR = `e;
                            12'd356: toneR = `e; 12'd357: toneR = `e; 12'd358: toneR = `e; 12'd359: toneR = `e;
                            12'd360: toneR = `f; 12'd361: toneR = `f; 12'd362: toneR = `f; 12'd363: toneR = `f;
                            12'd364: toneR = `f; 12'd365: toneR = `f; 12'd366: toneR = `f; 12'd367: toneR = `f;

                            12'd368: toneR = `a; 12'd369: toneR = `a; 12'd370: toneR = `a; 12'd371: toneR = `a;
                            12'd372: toneR = `a; 12'd373: toneR = `a; 12'd374: toneR = `a; 12'd375: toneR = `a;
                            12'd376: toneR = `hd; 12'd377: toneR = `hd; 12'd378: toneR = `hd; 12'd379: toneR = `hd;
                            12'd380: toneR = `hd; 12'd381: toneR = `hd; 12'd382: toneR = `hd; 12'd383: toneR = `hd;

                            12'd384: toneR = `hc; 12'd385: toneR = `hc; 12'd386: toneR = `hc; 12'd387: toneR = `hc;
                            12'd388: toneR = `hc; 12'd389: toneR = `hc; 12'd390: toneR = `hc; 12'd391: toneR = `hc;
                            12'd392: toneR = `hc; 12'd393: toneR = `hc; 12'd394: toneR = `hc; 12'd395: toneR = `hc;
                            12'd396: toneR = `hc; 12'd397: toneR = `hc; 12'd398: toneR = `hc; 12'd399: toneR = `hc;

                            12'd400: toneR = `g; 12'd401: toneR = `g; 12'd402: toneR = `g; 12'd403: toneR = `g;
                            12'd404: toneR = `g; 12'd405: toneR = `g; 12'd406: toneR = `g; 12'd407: toneR = `g;
                            12'd408: toneR = `g; 12'd409: toneR = `g; 12'd410: toneR = `g; 12'd411: toneR = `g;
                            12'd412: toneR = `g; 12'd413: toneR = `g; 12'd414: toneR = `g; 12'd415: toneR = `g;

                            12'd416: toneR = `a; 12'd417: toneR = `a; 12'd418: toneR = `a; 12'd419: toneR = `a;
                            12'd420: toneR = `a; 12'd421: toneR = `a; 12'd422: toneR = `a; 12'd423: toneR = `a;
                            12'd424: toneR = `a; 12'd425: toneR = `a; 12'd426: toneR = `a; 12'd427: toneR = `a;
                            12'd428: toneR = `a; 12'd429: toneR = `a; 12'd430: toneR = `a; 12'd431: toneR = `a;

                            12'd432: toneR = `sil; 12'd433: toneR = `sil; 12'd434: toneR = `sil; 12'd435: toneR = `sil;
                            12'd436: toneR = `sil; 12'd437: toneR = `sil; 12'd438: toneR = `sil; 12'd439: toneR = `sil;
                            12'd440: toneR = `a; 12'd441: toneR = `a; 12'd442: toneR = `a; 12'd443: toneR = `a;
                            12'd444: toneR = `a; 12'd445: toneR = `a; 12'd446: toneR = `a; 12'd447: toneR = `a;

                            12'd448: toneR = `hc; 12'd449: toneR = `hc; 12'd450: toneR = `hc; 12'd451: toneR = `hc;
                            12'd452: toneR = `hc; 12'd453: toneR = `hc; 12'd454: toneR = `hc; 12'd455: toneR = `hc;
                            12'd456: toneR = `m; 12'd457: toneR = `m; 12'd458: toneR = `m; 12'd459: toneR = `m;
                            12'd460: toneR = `m; 12'd461: toneR = `m; 12'd462: toneR = `m; 12'd463: toneR = `m;

                            12'd464: toneR = `a; 12'd465: toneR = `a; 12'd466: toneR = `a; 12'd467: toneR = `a;
                            12'd468: toneR = `a; 12'd469: toneR = `a; 12'd470: toneR = `a; 12'd471: toneR = `a;
                            12'd472: toneR = `m; 12'd473: toneR = `m; 12'd474: toneR = `m; 12'd475: toneR = `m;
                            12'd476: toneR = `m; 12'd477: toneR = `m; 12'd478: toneR = `m; 12'd479: toneR = `m;

                            12'd480: toneR = `a; 12'd481: toneR = `a; 12'd482: toneR = `a; 12'd483: toneR = `a;
                            12'd484: toneR = `a; 12'd485: toneR = `a; 12'd486: toneR = `a; 12'd487: toneR = `a;
                            12'd488: toneR = `a; 12'd489: toneR = `a; 12'd490: toneR = `a; 12'd491: toneR = `a;
                            12'd492: toneR = `a; 12'd493: toneR = `a; 12'd494: toneR = `a; 12'd495: toneR = `a;

                            12'd496: toneR = `f; 12'd497: toneR = `f; 12'd498: toneR = `f; 12'd499: toneR = `f;
                            12'd500: toneR = `f; 12'd501: toneR = `f; 12'd502: toneR = `f; 12'd503: toneR = `f;
                            12'd504: toneR = `f; 12'd505: toneR = `f; 12'd506: toneR = `f; 12'd507: toneR = `f;
                            12'd508: toneR = `f; 12'd509: toneR = `f; 12'd510: toneR = `f; 12'd511: toneR = `f;

                            12'd512: toneR = `g; 12'd513: toneR = `g; 12'd514: toneR = `g; 12'd515: toneR = `g;
                            12'd516: toneR = `g; 12'd517: toneR = `g; 12'd518: toneR = `g; 12'd519: toneR = `g;
                            12'd520: toneR = `g; 12'd521: toneR = `g; 12'd522: toneR = `g; 12'd523: toneR = `g;
                            12'd524: toneR = `g; 12'd525: toneR = `g; 12'd526: toneR = `g; 12'd527: toneR = `g;

                            12'd528: toneR = `f; 12'd529: toneR = `f; 12'd530: toneR = `f; 12'd531: toneR = `f;
                            12'd532: toneR = `f; 12'd533: toneR = `f; 12'd534: toneR = `f; 12'd535: toneR = `f;
                            12'd536: toneR = `c; 12'd537: toneR = `c; 12'd538: toneR = `c; 12'd539: toneR = `c;
                            12'd540: toneR = `c; 12'd541: toneR = `c; 12'd542: toneR = `c; 12'd543: toneR = `sil;

                            12'd544: toneR = `c; 12'd545: toneR = `c; 12'd546: toneR = `c; 12'd547: toneR = `c;
                            12'd548: toneR = `c; 12'd549: toneR = `c; 12'd550: toneR = `c; 12'd551: toneR = `c;
                            12'd552: toneR = `m; 12'd553: toneR = `m; 12'd554: toneR = `m; 12'd555: toneR = `m;
                            12'd556: toneR = `m; 12'd557: toneR = `m; 12'd558: toneR = `m; 12'd559: toneR = `sil;

                            12'd560: toneR = `m; 12'd561: toneR = `m; 12'd562: toneR = `m; 12'd563: toneR = `m;
                            12'd564: toneR = `m; 12'd565: toneR = `m; 12'd566: toneR = `m; 12'd567: toneR = `m;
                            12'd568: toneR = `g; 12'd569: toneR = `g; 12'd570: toneR = `g; 12'd571: toneR = `g;
                            12'd572: toneR = `g; 12'd573: toneR = `g; 12'd574: toneR = `g; 12'd575: toneR = `g;
                            default: toneR = `sil;
                        endcase
                    end 
                else 
                    begin
                        toneR = `sil;
                    end    
            end
        else
            begin
                if(en == 1)
                    begin
                        case(ibeatNum)
                            12'd0: toneR = `sil; 12'd1: toneR = `sil; 12'd2: toneR = `sil; 12'd3: toneR = `sil;
                            12'd4: toneR = `sil; 12'd5: toneR = `sil; 12'd6: toneR = `sil; 12'd7: toneR = `sil;
                            12'd8: toneR = `sil; 12'd9: toneR = `sil; 12'd10: toneR = `sil; 12'd11: toneR = `sil;
                            12'd12: toneR = `sil; 12'd13: toneR = `sil; 12'd14: toneR = `sil; 12'd15: toneR = `sil;

                            12'd16: toneR = `sil; 12'd17: toneR = `sil; 12'd18: toneR = `sil; 12'd19: toneR = `sil;
                            12'd20: toneR = `sil; 12'd21: toneR = `sil; 12'd22: toneR = `sil; 12'd23: toneR = `sil;
                            12'd24: toneR = `sil; 12'd25: toneR = `sil; 12'd26: toneR = `sil; 12'd27: toneR = `sil;
                            12'd28: toneR = `sil; 12'd29: toneR = `sil; 12'd30: toneR = `sil; 12'd31: toneR = `sil;

                            12'd32: toneR = `sil; 12'd33: toneR = `sil; 12'd34: toneR = `sil; 12'd35: toneR = `sil;
                            12'd36: toneR = `sil; 12'd37: toneR = `sil; 12'd38: toneR = `sil; 12'd39: toneR = `sil;
                            12'd40: toneR = `g; 12'd41: toneR = `g; 12'd42: toneR = `g; 12'd43: toneR = `g;
                            12'd44: toneR = `g; 12'd45: toneR = `g; 12'd46: toneR = `g; 12'd47: toneR = `g;

                            12'd48: toneR = `hf; 12'd49: toneR = `hf; 12'd50: toneR = `hf; 12'd51: toneR = `hf;
                            12'd52: toneR = `hf; 12'd53: toneR = `hf; 12'd54: toneR = `hf; 12'd55: toneR = `hf;
                            12'd56: toneR = `he; 12'd57: toneR = `he; 12'd58: toneR = `he; 12'd59: toneR = `he;
                            12'd60: toneR = `he; 12'd61: toneR = `he; 12'd62: toneR = `he; 12'd63: toneR = `he;

                            12'd64: toneR = `he; 12'd65: toneR = `he; 12'd66: toneR = `he; 12'd67: toneR = `he;
                            12'd68: toneR = `he; 12'd69: toneR = `he; 12'd70: toneR = `he; 12'd71: toneR = `he;
                            12'd72: toneR = `he; 12'd73: toneR = `he; 12'd74: toneR = `he; 12'd75: toneR = `he;
                            12'd76: toneR = `he; 12'd77: toneR = `he; 12'd78: toneR = `he; 12'd79: toneR = `he;

                            12'd80: toneR = `hf; 12'd81: toneR = `hf; 12'd82: toneR = `hf; 12'd83: toneR = `hf;
                            12'd84: toneR = `hf; 12'd85: toneR = `hf; 12'd86: toneR = `hf; 12'd87: toneR = `hf;
                            12'd88: toneR = `he; 12'd89: toneR = `he; 12'd90: toneR = `he; 12'd91: toneR = `he;
                            12'd92: toneR = `he; 12'd93: toneR = `he; 12'd94: toneR = `he; 12'd95: toneR = `he;

                            12'd96: toneR = `he; 12'd97: toneR = `he; 12'd98: toneR = `he; 12'd99: toneR = `he;
                            12'd100: toneR = `he; 12'd101: toneR = `he; 12'd102: toneR = `he; 12'd103: toneR = `he;
                            12'd104: toneR = `hd; 12'd105: toneR = `hd; 12'd106: toneR = `hd; 12'd107: toneR = `hd;
                            12'd108: toneR = `hd; 12'd109: toneR = `hd; 12'd110: toneR = `hd; 12'd111: toneR = `hd;

                            12'd112: toneR = `hd; 12'd113: toneR = `hd; 12'd114: toneR = `hd; 12'd115: toneR = `hd;
                            12'd116: toneR = `hd; 12'd117: toneR = `hd; 12'd118: toneR = `hd; 12'd119: toneR = `hd;
                            12'd120: toneR = `hc; 12'd121: toneR = `hc; 12'd122: toneR = `hc; 12'd123: toneR = `hc;
                            12'd124: toneR = `hc; 12'd125: toneR = `hc; 12'd126: toneR = `hc; 12'd127: toneR = `hc;

                            12'd128: toneR = `hc; 12'd129: toneR = `hc; 12'd130: toneR = `hc; 12'd131: toneR = `hc;
                            12'd132: toneR = `hc; 12'd133: toneR = `hc; 12'd134: toneR = `hc; 12'd135: toneR = `hc;
                            12'd136: toneR = `hc; 12'd137: toneR = `hc; 12'd138: toneR = `hc; 12'd139: toneR = `hc;
                            12'd140: toneR = `hc; 12'd141: toneR = `hc; 12'd142: toneR = `hc; 12'd143: toneR = `hc;

                            12'd144: toneR = `hd; 12'd145: toneR = `hd; 12'd146: toneR = `hd; 12'd147: toneR = `hd;
                            12'd148: toneR = `hd; 12'd149: toneR = `hd; 12'd150: toneR = `hd; 12'd151: toneR = `hd;
                            12'd152: toneR = `he; 12'd153: toneR = `he; 12'd154: toneR = `he; 12'd155: toneR = `he;
                            12'd156: toneR = `he; 12'd157: toneR = `he; 12'd158: toneR = `he; 12'd159: toneR = `he;

                            12'd160: toneR = `he; 12'd161: toneR = `he; 12'd162: toneR = `he; 12'd163: toneR = `he;
                            12'd164: toneR = `he; 12'd165: toneR = `he; 12'd166: toneR = `he; 12'd167: toneR = `he;
                            12'd168: toneR = `hc; 12'd169: toneR = `hc; 12'd170: toneR = `hc; 12'd171: toneR = `hc;
                            12'd172: toneR = `hc; 12'd173: toneR = `hc; 12'd174: toneR = `hc; 12'd175: toneR = `hc;

                            12'd176: toneR = `hc; 12'd177: toneR = `hc; 12'd178: toneR = `hc; 12'd179: toneR = `hc;
                            12'd180: toneR = `hc; 12'd181: toneR = `hc; 12'd182: toneR = `hc; 12'd183: toneR = `hc;
                            12'd184: toneR = `g; 12'd185: toneR = `g; 12'd186: toneR = `g; 12'd187: toneR = `g;
                            12'd188: toneR = `g; 12'd189: toneR = `g; 12'd190: toneR = `g; 12'd191: toneR = `g;

                            12'd192: toneR = `a; 12'd193: toneR = `a; 12'd194: toneR = `a; 12'd195: toneR = `a;
                            12'd196: toneR = `a; 12'd197: toneR = `a; 12'd198: toneR = `a; 12'd199: toneR = `a;
                            12'd200: toneR = `a; 12'd201: toneR = `a; 12'd202: toneR = `a; 12'd203: toneR = `a;
                            12'd204: toneR = `a; 12'd205: toneR = `a; 12'd206: toneR = `a; 12'd207: toneR = `a;

                            12'd208: toneR = `hc; 12'd209: toneR = `hc; 12'd210: toneR = `hc; 12'd211: toneR = `hc;
                            12'd212: toneR = `hc; 12'd213: toneR = `hc; 12'd214: toneR = `hc; 12'd215: toneR = `hc;
                            12'd216: toneR = `hg; 12'd217: toneR = `hg; 12'd218: toneR = `hg; 12'd219: toneR = `hg;
                            12'd220: toneR = `hg; 12'd221: toneR = `hg; 12'd222: toneR = `hg; 12'd223: toneR = `hg;

                            12'd224: toneR = `hg; 12'd225: toneR = `hg; 12'd226: toneR = `hg; 12'd227: toneR = `hg;
                            12'd228: toneR = `hg; 12'd229: toneR = `hg; 12'd230: toneR = `hg; 12'd231: toneR = `hg;
                            12'd232: toneR = `hc; 12'd233: toneR = `hc; 12'd234: toneR = `hc; 12'd235: toneR = `hc;
                            12'd236: toneR = `hc; 12'd237: toneR = `hc; 12'd238: toneR = `hc; 12'd239: toneR = `hc;

                            12'd240: toneR = `he; 12'd241: toneR = `he; 12'd242: toneR = `he; 12'd243: toneR = `he;
                            12'd244: toneR = `he; 12'd245: toneR = `he; 12'd246: toneR = `he; 12'd247: toneR = `sil;
                            12'd248: toneR = `he; 12'd249: toneR = `he; 12'd250: toneR = `he; 12'd251: toneR = `he;
                            12'd252: toneR = `he; 12'd253: toneR = `he; 12'd254: toneR = `he; 12'd255: toneR = `he;

                            12'd256: toneR = `he; 12'd257: toneR = `he; 12'd258: toneR = `he; 12'd259: toneR = `he;
                            12'd260: toneR = `he; 12'd261: toneR = `he; 12'd262: toneR = `he; 12'd263: toneR = `he;
                            12'd264: toneR = `he; 12'd265: toneR = `he; 12'd266: toneR = `he; 12'd267: toneR = `he;
                            12'd268: toneR = `he; 12'd269: toneR = `he; 12'd270: toneR = `he; 12'd271: toneR = `he;

                            12'd272: toneR = `he; 12'd273: toneR = `he; 12'd274: toneR = `he; 12'd275: toneR = `he;
                            12'd276: toneR = `he; 12'd277: toneR = `he; 12'd278: toneR = `he; 12'd279: toneR = `he;
                            12'd280: toneR = `he; 12'd281: toneR = `he; 12'd282: toneR = `he; 12'd283: toneR = `he;
                            12'd284: toneR = `he; 12'd285: toneR = `he; 12'd286: toneR = `he; 12'd287: toneR = `he;

                            12'd288: toneR = `sil; 12'd289: toneR = `sil; 12'd290: toneR = `sil; 12'd291: toneR = `sil;
                            12'd292: toneR = `sil; 12'd293: toneR = `sil; 12'd294: toneR = `sil; 12'd295: toneR = `sil;
                            12'd296: toneR = `g; 12'd297: toneR = `g; 12'd298: toneR = `g; 12'd299: toneR = `g;
                            12'd300: toneR = `g; 12'd301: toneR = `g; 12'd302: toneR = `g; 12'd303: toneR = `g;

                            12'd304: toneR = `hf; 12'd305: toneR = `hf; 12'd306: toneR = `hf; 12'd307: toneR = `hf;
                            12'd308: toneR = `hf; 12'd309: toneR = `hf; 12'd310: toneR = `hf; 12'd311: toneR = `hf;
                            12'd312: toneR = `he; 12'd313: toneR = `he; 12'd314: toneR = `he; 12'd315: toneR = `he;
                            12'd316: toneR = `he; 12'd317: toneR = `he; 12'd318: toneR = `he; 12'd319: toneR = `he;

                            12'd320: toneR = `he; 12'd321: toneR = `he; 12'd322: toneR = `he; 12'd323: toneR = `he;
                            12'd324: toneR = `he; 12'd325: toneR = `he; 12'd326: toneR = `he; 12'd327: toneR = `he;
                            12'd328: toneR = `he; 12'd329: toneR = `he; 12'd330: toneR = `he; 12'd331: toneR = `he;
                            12'd332: toneR = `he; 12'd333: toneR = `he; 12'd334: toneR = `he; 12'd335: toneR = `he;

                            12'd336: toneR = `hf; 12'd337: toneR = `hf; 12'd338: toneR = `hf; 12'd339: toneR = `hf;
                            12'd340: toneR = `hf; 12'd341: toneR = `hf; 12'd342: toneR = `hf; 12'd343: toneR = `hf;
                            12'd344: toneR = `he; 12'd345: toneR = `he; 12'd346: toneR = `he; 12'd347: toneR = `he;
                            12'd348: toneR = `he; 12'd349: toneR = `he; 12'd350: toneR = `he; 12'd351: toneR = `he;

                            12'd352: toneR = `he; 12'd353: toneR = `he; 12'd354: toneR = `he; 12'd355: toneR = `he;
                            12'd356: toneR = `he; 12'd357: toneR = `he; 12'd358: toneR = `he; 12'd359: toneR = `he;
                            12'd360: toneR = `hd; 12'd361: toneR = `hd; 12'd362: toneR = `hd; 12'd363: toneR = `hd;
                            12'd364: toneR = `hd; 12'd365: toneR = `hd; 12'd366: toneR = `hd; 12'd367: toneR = `hd;

                            12'd368: toneR = `hd; 12'd369: toneR = `hd; 12'd370: toneR = `hd; 12'd371: toneR = `hd;
                            12'd372: toneR = `hd; 12'd373: toneR = `hd; 12'd374: toneR = `hd; 12'd375: toneR = `hd;
                            12'd376: toneR = `hc; 12'd377: toneR = `hc; 12'd378: toneR = `hc; 12'd379: toneR = `hc;
                            12'd380: toneR = `hc; 12'd381: toneR = `hc; 12'd382: toneR = `hc; 12'd383: toneR = `hc;

                            12'd384: toneR = `hc; 12'd385: toneR = `hc; 12'd386: toneR = `hc; 12'd387: toneR = `hc;
                            12'd388: toneR = `hc; 12'd389: toneR = `hc; 12'd390: toneR = `hc; 12'd391: toneR = `hc;
                            12'd392: toneR = `hc; 12'd393: toneR = `hc; 12'd394: toneR = `hc; 12'd395: toneR = `hc;
                            12'd396: toneR = `hc; 12'd397: toneR = `hc; 12'd398: toneR = `hc; 12'd399: toneR = `hc;

                            12'd400: toneR = `hd; 12'd401: toneR = `hd; 12'd402: toneR = `hd; 12'd403: toneR = `hd;
                            12'd404: toneR = `hd; 12'd405: toneR = `hd; 12'd406: toneR = `hd; 12'd407: toneR = `hd;
                            12'd408: toneR = `he; 12'd409: toneR = `he; 12'd410: toneR = `he; 12'd411: toneR = `he;
                            12'd412: toneR = `he; 12'd413: toneR = `he; 12'd414: toneR = `he; 12'd415: toneR = `he;

                            12'd416: toneR = `he; 12'd417: toneR = `he; 12'd418: toneR = `he; 12'd419: toneR = `he;
                            12'd420: toneR = `he; 12'd421: toneR = `he; 12'd422: toneR = `he; 12'd423: toneR = `he;
                            12'd424: toneR = `ha; 12'd425: toneR = `ha; 12'd426: toneR = `ha; 12'd427: toneR = `ha;
                            12'd428: toneR = `ha; 12'd429: toneR = `ha; 12'd430: toneR = `ha; 12'd431: toneR = `ha;

                            12'd432: toneR = `ha; 12'd433: toneR = `ha; 12'd434: toneR = `ha; 12'd435: toneR = `ha;
                            12'd436: toneR = `ha; 12'd437: toneR = `ha; 12'd438: toneR = `ha; 12'd439: toneR = `ha;
                            12'd440: toneR = `ha; 12'd441: toneR = `ha; 12'd442: toneR = `ha; 12'd443: toneR = `ha;
                            12'd444: toneR = `ha; 12'd445: toneR = `ha; 12'd446: toneR = `ha; 12'd447: toneR = `ha;

                            12'd448: toneR = `he; 12'd449: toneR = `he; 12'd450: toneR = `he; 12'd451: toneR = `he;
                            12'd452: toneR = `he; 12'd453: toneR = `he; 12'd454: toneR = `he; 12'd455: toneR = `he;
                            12'd456: toneR = `he; 12'd457: toneR = `he; 12'd458: toneR = `he; 12'd459: toneR = `he;
                            12'd460: toneR = `he; 12'd461: toneR = `he; 12'd462: toneR = `he; 12'd463: toneR = `he;

                            12'd464: toneR = `a; 12'd465: toneR = `a; 12'd466: toneR = `a; 12'd467: toneR = `a;
                            12'd468: toneR = `a; 12'd469: toneR = `a; 12'd470: toneR = `a; 12'd471: toneR = `a;
                            12'd472: toneR = `hc; 12'd473: toneR = `hc; 12'd474: toneR = `hc; 12'd475: toneR = `hc;
                            12'd476: toneR = `hc; 12'd477: toneR = `hc; 12'd478: toneR = `hc; 12'd479: toneR = `hc;

                            12'd480: toneR = `hc; 12'd481: toneR = `hc; 12'd482: toneR = `hc; 12'd483: toneR = `hc;
                            12'd484: toneR = `hc; 12'd485: toneR = `hc; 12'd486: toneR = `hc; 12'd487: toneR = `hc;
                            12'd488: toneR = `hd; 12'd489: toneR = `hd; 12'd490: toneR = `hd; 12'd491: toneR = `hd;
                            12'd492: toneR = `hd; 12'd493: toneR = `hd; 12'd494: toneR = `hd; 12'd495: toneR = `hd;

                            12'd496: toneR = `hd; 12'd497: toneR = `hd; 12'd498: toneR = `hd; 12'd499: toneR = `hd;
                            12'd500: toneR = `hd; 12'd501: toneR = `hd; 12'd502: toneR = `hd; 12'd503: toneR = `hd;
                            12'd504: toneR = `hc; 12'd505: toneR = `hc; 12'd506: toneR = `hc; 12'd507: toneR = `hc;
                            12'd508: toneR = `hc; 12'd509: toneR = `hc; 12'd510: toneR = `hc; 12'd511: toneR = `hc;

                            12'd512: toneR = `hc; 12'd513: toneR = `hc; 12'd514: toneR = `hc; 12'd515: toneR = `hc;
                            12'd516: toneR = `hc; 12'd517: toneR = `hc; 12'd518: toneR = `hc; 12'd519: toneR = `hc;
                            12'd520: toneR = `hc; 12'd521: toneR = `hc; 12'd522: toneR = `hc; 12'd523: toneR = `hc;
                            12'd524: toneR = `hc; 12'd525: toneR = `hc; 12'd526: toneR = `hc; 12'd527: toneR = `hc;

                            12'd528: toneR = `hc; 12'd529: toneR = `hc; 12'd530: toneR = `hc; 12'd531: toneR = `hc;
                            12'd532: toneR = `hc; 12'd533: toneR = `hc; 12'd534: toneR = `hc; 12'd535: toneR = `hc;
                            12'd536: toneR = `hc; 12'd537: toneR = `hc; 12'd538: toneR = `hc; 12'd539: toneR = `hc;
                            12'd540: toneR = `hc; 12'd541: toneR = `hc; 12'd542: toneR = `hc; 12'd543: toneR = `hc;

                            12'd544: toneR = `sil; 12'd545: toneR = `sil; 12'd546: toneR = `sil; 12'd547: toneR = `sil;
                            12'd548: toneR = `sil; 12'd549: toneR = `sil; 12'd550: toneR = `sil; 12'd551: toneR = `sil;
                            12'd552: toneR = `sil; 12'd553: toneR = `sil; 12'd554: toneR = `sil; 12'd555: toneR = `sil;
                            12'd556: toneR = `sil; 12'd557: toneR = `sil; 12'd558: toneR = `sil; 12'd559: toneR = `sil;

                            12'd560: toneR = `sil; 12'd561: toneR = `sil; 12'd562: toneR = `sil; 12'd563: toneR = `sil;
                            12'd564: toneR = `sil; 12'd565: toneR = `sil; 12'd566: toneR = `sil; 12'd567: toneR = `sil;
                            12'd568: toneR = `sil; 12'd569: toneR = `sil; 12'd570: toneR = `sil; 12'd571: toneR = `sil;
                            12'd572: toneR = `sil; 12'd573: toneR = `sil; 12'd574: toneR = `sil; 12'd575: toneR = `sil;
                            default: toneR = `sil;
                        endcase
                    end
                else
                    begin
                        toneR=`sil;
                    end
            end
        
    end

    always @(*) begin
        if(music==1'b0)
            begin
                if(en==1)
                    begin
                        case(ibeatNum)
                            12'd0: toneL = `sil; 12'd1: toneL = `sil; 12'd2: toneL = `sil; 12'd3: toneL = `sil;
                            12'd4: toneL = `sil; 12'd5: toneL = `sil; 12'd6: toneL = `sil; 12'd7: toneL = `sil;
                            12'd8: toneL = `b; 12'd9: toneL = `b; 12'd10: toneL = `b; 12'd11: toneL = `b;
                            12'd12: toneL = `b; 12'd13: toneL = `b; 12'd14: toneL = `b; 12'd15: toneL = `sil;

                            12'd16: toneL = `b; 12'd17: toneL = `b; 12'd18: toneL = `b; 12'd19: toneL = `b;
                            12'd20: toneL = `b; 12'd21: toneL = `b; 12'd22: toneL = `b; 12'd23: toneL = `sil;
                            12'd24: toneL = `b; 12'd25: toneL = `b; 12'd26: toneL = `b; 12'd27: toneL = `b;
                            12'd28: toneL = `b; 12'd29: toneL = `b; 12'd30: toneL = `b; 12'd31: toneL = `sil;

                            12'd32: toneL = `b; 12'd33: toneL = `b; 12'd34: toneL = `b; 12'd35: toneL = `b;
                            12'd36: toneL = `b; 12'd37: toneL = `b; 12'd38: toneL = `b; 12'd39: toneL = `b;
                            12'd40: toneL = `sil; 12'd41: toneL = `sil; 12'd42: toneL = `sil; 12'd43: toneL = `sil;
                            12'd44: toneL = `sil; 12'd45: toneL = `sil; 12'd46: toneL = `sil; 12'd47: toneL = `sil;

                            12'd48: toneL = `sil; 12'd49: toneL = `sil; 12'd50: toneL = `sil; 12'd51: toneL = `sil;
                            12'd52: toneL = `sil; 12'd53: toneL = `sil; 12'd54: toneL = `sil; 12'd55: toneL = `sil;
                            12'd56: toneL = `sil; 12'd57: toneL = `sil; 12'd58: toneL = `sil; 12'd59: toneL = `sil;
                            12'd60: toneL = `sil; 12'd61: toneL = `sil; 12'd62: toneL = `sil; 12'd63: toneL = `sil;

                            12'd64: toneL = `f; 12'd65: toneL = `f; 12'd66: toneL = `f; 12'd67: toneL = `f;
                            12'd68: toneL = `f; 12'd69: toneL = `f; 12'd70: toneL = `f; 12'd71: toneL = `f;
                            12'd72: toneL = `hc; 12'd73: toneL = `hc; 12'd74: toneL = `hc; 12'd75: toneL = `hc;
                            12'd76: toneL = `hc; 12'd77: toneL = `hc; 12'd78: toneL = `hc; 12'd79: toneL = `hc;

                            12'd80: toneL = `hg; 12'd81: toneL = `hg; 12'd82: toneL = `hg; 12'd83: toneL = `hg;
                            12'd84: toneL = `hg; 12'd85: toneL = `hg; 12'd86: toneL = `hg; 12'd87: toneL = `hg;
                            12'd88: toneL = `hc; 12'd89: toneL = `hc; 12'd90: toneL = `hc; 12'd91: toneL = `hc;
                            12'd92: toneL = `hc; 12'd93: toneL = `hc; 12'd94: toneL = `hc; 12'd95: toneL = `hc;

                            12'd96: toneL = `f; 12'd97: toneL = `f; 12'd98: toneL = `f; 12'd99: toneL = `f;
                            12'd100: toneL = `f; 12'd101: toneL = `f; 12'd102: toneL = `f; 12'd103: toneL = `f;
                            12'd104: toneL = `hc; 12'd105: toneL = `hc; 12'd106: toneL = `hc; 12'd107: toneL = `hc;
                            12'd108: toneL = `hc; 12'd109: toneL = `hc; 12'd110: toneL = `hc; 12'd111: toneL = `hc;

                            12'd112: toneL = `hg; 12'd113: toneL = `hg; 12'd114: toneL = `hg; 12'd115: toneL = `hg;
                            12'd116: toneL = `hg; 12'd117: toneL = `hg; 12'd118: toneL = `hg; 12'd119: toneL = `hg;
                            12'd120: toneL = `c; 12'd121: toneL = `c; 12'd122: toneL = `c; 12'd123: toneL = `c;
                            12'd124: toneL = `c; 12'd125: toneL = `c; 12'd126: toneL = `c; 12'd127: toneL = `c;

                            12'd128: toneL = `e; 12'd129: toneL = `e; 12'd130: toneL = `e; 12'd131: toneL = `e;
                            12'd132: toneL = `e; 12'd133: toneL = `e; 12'd134: toneL = `e; 12'd135: toneL = `e;
                            12'd136: toneL = `hc; 12'd137: toneL = `hc; 12'd138: toneL = `hc; 12'd139: toneL = `hc;
                            12'd140: toneL = `hc; 12'd141: toneL = `hc; 12'd142: toneL = `hc; 12'd143: toneL = `hc;

                            12'd144: toneL = `he; 12'd145: toneL = `he; 12'd146: toneL = `he; 12'd147: toneL = `he;
                            12'd148: toneL = `he; 12'd149: toneL = `he; 12'd150: toneL = `he; 12'd151: toneL = `he;
                            12'd152: toneL = `hc; 12'd153: toneL = `hc; 12'd154: toneL = `hc; 12'd155: toneL = `hc;
                            12'd156: toneL = `hc; 12'd157: toneL = `hc; 12'd158: toneL = `hc; 12'd159: toneL = `hc;

                            12'd160: toneL = `e; 12'd161: toneL = `e; 12'd162: toneL = `e; 12'd163: toneL = `e;
                            12'd164: toneL = `e; 12'd165: toneL = `e; 12'd166: toneL = `e; 12'd167: toneL = `e;
                            12'd168: toneL = `hc; 12'd169: toneL = `hc; 12'd170: toneL = `hc; 12'd171: toneL = `hc;
                            12'd172: toneL = `hc; 12'd173: toneL = `hc; 12'd174: toneL = `hc; 12'd175: toneL = `hc;

                            12'd176: toneL = `he; 12'd177: toneL = `he; 12'd178: toneL = `he; 12'd179: toneL = `he;
                            12'd180: toneL = `he; 12'd181: toneL = `he; 12'd182: toneL = `he; 12'd183: toneL = `he;
                            12'd184: toneL = `hc; 12'd185: toneL = `hc; 12'd186: toneL = `hc; 12'd187: toneL = `hc;
                            12'd188: toneL = `hc; 12'd189: toneL = `hc; 12'd190: toneL = `hc; 12'd191: toneL = `hc;

                            12'd192: toneL = `d; 12'd193: toneL = `d; 12'd194: toneL = `d; 12'd195: toneL = `d;
                            12'd196: toneL = `d; 12'd197: toneL = `d; 12'd198: toneL = `d; 12'd199: toneL = `d;
                            12'd200: toneL = `a; 12'd201: toneL = `a; 12'd202: toneL = `a; 12'd203: toneL = `a;
                            12'd204: toneL = `a; 12'd205: toneL = `a; 12'd206: toneL = `a; 12'd207: toneL = `a;

                            12'd208: toneL = `hd; 12'd209: toneL = `hd; 12'd210: toneL = `hd; 12'd211: toneL = `hd;
                            12'd212: toneL = `hd; 12'd213: toneL = `hd; 12'd214: toneL = `hd; 12'd215: toneL = `hd;
                            12'd216: toneL = `a; 12'd217: toneL = `a; 12'd218: toneL = `a; 12'd219: toneL = `a;
                            12'd220: toneL = `a; 12'd221: toneL = `a; 12'd222: toneL = `a; 12'd223: toneL = `a;

                            12'd224: toneL = `d; 12'd225: toneL = `d; 12'd226: toneL = `d; 12'd227: toneL = `d;
                            12'd228: toneL = `d; 12'd229: toneL = `d; 12'd230: toneL = `d; 12'd231: toneL = `d;
                            12'd232: toneL = `a; 12'd233: toneL = `a; 12'd234: toneL = `a; 12'd235: toneL = `a;
                            12'd236: toneL = `a; 12'd237: toneL = `a; 12'd238: toneL = `a; 12'd239: toneL = `a;

                            12'd240: toneL = `hd; 12'd241: toneL = `hd; 12'd242: toneL = `hd; 12'd243: toneL = `hd;
                            12'd244: toneL = `hd; 12'd245: toneL = `hd; 12'd246: toneL = `hd; 12'd247: toneL = `hd;
                            12'd248: toneL = `a; 12'd249: toneL = `a; 12'd250: toneL = `a; 12'd251: toneL = `a;
                            12'd252: toneL = `a; 12'd253: toneL = `a; 12'd254: toneL = `a; 12'd255: toneL = `a;

                            12'd256: toneL = `c; 12'd257: toneL = `c; 12'd258: toneL = `c; 12'd259: toneL = `c;
                            12'd260: toneL = `c; 12'd261: toneL = `c; 12'd262: toneL = `c; 12'd263: toneL = `c;
                            12'd264: toneL = `a; 12'd265: toneL = `a; 12'd266: toneL = `a; 12'd267: toneL = `a;
                            12'd268: toneL = `a; 12'd269: toneL = `a; 12'd270: toneL = `a; 12'd271: toneL = `a;

                            12'd272: toneL = `hc; 12'd273: toneL = `hc; 12'd274: toneL = `hc; 12'd275: toneL = `hc;
                            12'd276: toneL = `hc; 12'd277: toneL = `hc; 12'd278: toneL = `hc; 12'd279: toneL = `hc;
                            12'd280: toneL = `a; 12'd281: toneL = `a; 12'd282: toneL = `a; 12'd283: toneL = `a;
                            12'd284: toneL = `a; 12'd285: toneL = `a; 12'd286: toneL = `a; 12'd287: toneL = `a;

                            12'd288: toneL = `c; 12'd289: toneL = `c; 12'd290: toneL = `c; 12'd291: toneL = `c;
                            12'd292: toneL = `c; 12'd293: toneL = `c; 12'd294: toneL = `c; 12'd295: toneL = `c;
                            12'd296: toneL = `a; 12'd297: toneL = `a; 12'd298: toneL = `a; 12'd299: toneL = `a;
                            12'd300: toneL = `a; 12'd301: toneL = `a; 12'd302: toneL = `a; 12'd303: toneL = `a;

                            12'd304: toneL = `hc; 12'd305: toneL = `hc; 12'd306: toneL = `hc; 12'd307: toneL = `hc;
                            12'd308: toneL = `hc; 12'd309: toneL = `hc; 12'd310: toneL = `hc; 12'd311: toneL = `hc;
                            12'd312: toneL = `a; 12'd313: toneL = `a; 12'd314: toneL = `a; 12'd315: toneL = `a;
                            12'd316: toneL = `a; 12'd317: toneL = `a; 12'd318: toneL = `a; 12'd319: toneL = `a;

                            12'd320: toneL = `n; 12'd321: toneL = `n; 12'd322: toneL = `n; 12'd323: toneL = `n;
                            12'd324: toneL = `n; 12'd325: toneL = `n; 12'd326: toneL = `n; 12'd327: toneL = `n;
                            12'd328: toneL = `f; 12'd329: toneL = `f; 12'd330: toneL = `f; 12'd331: toneL = `f;
                            12'd332: toneL = `f; 12'd333: toneL = `f; 12'd334: toneL = `f; 12'd335: toneL = `f;

                            12'd336: toneL = `b; 12'd337: toneL = `b; 12'd338: toneL = `b; 12'd339: toneL = `b;
                            12'd340: toneL = `b; 12'd341: toneL = `b; 12'd342: toneL = `b; 12'd343: toneL = `b;
                            12'd344: toneL = `f; 12'd345: toneL = `f; 12'd346: toneL = `f; 12'd347: toneL = `f;
                            12'd348: toneL = `f; 12'd349: toneL = `f; 12'd350: toneL = `f; 12'd351: toneL = `f;

                            12'd352: toneL = `n; 12'd353: toneL = `n; 12'd354: toneL = `n; 12'd355: toneL = `n;
                            12'd356: toneL = `n; 12'd357: toneL = `n; 12'd358: toneL = `n; 12'd359: toneL = `n;
                            12'd360: toneL = `f; 12'd361: toneL = `f; 12'd362: toneL = `f; 12'd363: toneL = `f;
                            12'd364: toneL = `f; 12'd365: toneL = `f; 12'd366: toneL = `f; 12'd367: toneL = `f;

                            12'd368: toneL = `b; 12'd369: toneL = `b; 12'd370: toneL = `b; 12'd371: toneL = `b;
                            12'd372: toneL = `b; 12'd373: toneL = `b; 12'd374: toneL = `b; 12'd375: toneL = `b;
                            12'd376: toneL = `f; 12'd377: toneL = `f; 12'd378: toneL = `f; 12'd379: toneL = `f;
                            12'd380: toneL = `f; 12'd381: toneL = `f; 12'd382: toneL = `f; 12'd383: toneL = `f;

                            12'd384: toneL = `n; 12'd385: toneL = `n; 12'd386: toneL = `n; 12'd387: toneL = `n;
                            12'd388: toneL = `n; 12'd389: toneL = `n; 12'd390: toneL = `n; 12'd391: toneL = `n;
                            12'd392: toneL = `e; 12'd393: toneL = `e; 12'd394: toneL = `e; 12'd395: toneL = `e;
                            12'd396: toneL = `e; 12'd397: toneL = `e; 12'd398: toneL = `e; 12'd399: toneL = `e;

                            12'd400: toneL = `g; 12'd401: toneL = `g; 12'd402: toneL = `g; 12'd403: toneL = `g;
                            12'd404: toneL = `g; 12'd405: toneL = `g; 12'd406: toneL = `g; 12'd407: toneL = `g;
                            12'd408: toneL = `e; 12'd409: toneL = `e; 12'd410: toneL = `e; 12'd411: toneL = `e;
                            12'd412: toneL = `e; 12'd413: toneL = `e; 12'd414: toneL = `e; 12'd415: toneL = `e;

                            12'd416: toneL = `d; 12'd417: toneL = `d; 12'd418: toneL = `d; 12'd419: toneL = `d;
                            12'd420: toneL = `d; 12'd421: toneL = `d; 12'd422: toneL = `d; 12'd423: toneL = `d;
                            12'd424: toneL = `a; 12'd425: toneL = `a; 12'd426: toneL = `a; 12'd427: toneL = `a;
                            12'd428: toneL = `a; 12'd429: toneL = `a; 12'd430: toneL = `a; 12'd431: toneL = `a;

                            12'd432: toneL = `ha; 12'd433: toneL = `ha; 12'd434: toneL = `ha; 12'd435: toneL = `ha;
                            12'd436: toneL = `ha; 12'd437: toneL = `ha; 12'd438: toneL = `ha; 12'd439: toneL = `ha;
                            12'd440: toneL = `a; 12'd441: toneL = `a; 12'd442: toneL = `a; 12'd443: toneL = `a;
                            12'd444: toneL = `a; 12'd445: toneL = `a; 12'd446: toneL = `a; 12'd447: toneL = `a;

                            12'd448: toneL = `n; 12'd449: toneL = `n; 12'd450: toneL = `n; 12'd451: toneL = `n;
                            12'd452: toneL = `n; 12'd453: toneL = `n; 12'd454: toneL = `n; 12'd455: toneL = `n;
                            12'd456: toneL = `f; 12'd457: toneL = `f; 12'd458: toneL = `f; 12'd459: toneL = `f;
                            12'd460: toneL = `f; 12'd461: toneL = `f; 12'd462: toneL = `f; 12'd463: toneL = `f;

                            12'd464: toneL = `b; 12'd465: toneL = `b; 12'd466: toneL = `b; 12'd467: toneL = `b;
                            12'd468: toneL = `b; 12'd469: toneL = `b; 12'd470: toneL = `b; 12'd471: toneL = `b;
                            12'd472: toneL = `f; 12'd473: toneL = `f; 12'd474: toneL = `f; 12'd475: toneL = `f;
                            12'd476: toneL = `f; 12'd477: toneL = `f; 12'd478: toneL = `f; 12'd479: toneL = `f;

                            12'd480: toneL = `n; 12'd481: toneL = `n; 12'd482: toneL = `n; 12'd483: toneL = `n;
                            12'd484: toneL = `n; 12'd485: toneL = `n; 12'd486: toneL = `n; 12'd487: toneL = `n;
                            12'd488: toneL = `f; 12'd489: toneL = `f; 12'd490: toneL = `f; 12'd491: toneL = `f;
                            12'd492: toneL = `f; 12'd493: toneL = `f; 12'd494: toneL = `f; 12'd495: toneL = `f;

                            12'd496: toneL = `b; 12'd497: toneL = `b; 12'd498: toneL = `b; 12'd499: toneL = `b;
                            12'd500: toneL = `b; 12'd501: toneL = `b; 12'd502: toneL = `b; 12'd503: toneL = `b;
                            12'd504: toneL = `f; 12'd505: toneL = `f; 12'd506: toneL = `f; 12'd507: toneL = `f;
                            12'd508: toneL = `f; 12'd509: toneL = `f; 12'd510: toneL = `f; 12'd511: toneL = `f;

                            12'd512: toneL = `c; 12'd513: toneL = `c; 12'd514: toneL = `c; 12'd515: toneL = `c;
                            12'd516: toneL = `c; 12'd517: toneL = `c; 12'd518: toneL = `c; 12'd519: toneL = `c;
                            12'd520: toneL = `g; 12'd521: toneL = `g; 12'd522: toneL = `g; 12'd523: toneL = `g;
                            12'd524: toneL = `g; 12'd525: toneL = `g; 12'd526: toneL = `g; 12'd527: toneL = `g;

                            12'd528: toneL = `hd; 12'd529: toneL = `hd; 12'd530: toneL = `hd; 12'd531: toneL = `hd;
                            12'd532: toneL = `hd; 12'd533: toneL = `hd; 12'd534: toneL = `hd; 12'd535: toneL = `hd;
                            12'd536: toneL = `hf; 12'd537: toneL = `hf; 12'd538: toneL = `hf; 12'd539: toneL = `hf;
                            12'd540: toneL = `hf; 12'd541: toneL = `hf; 12'd542: toneL = `hf; 12'd543: toneL = `hf;

                            12'd544: toneL = `g; 12'd545: toneL = `g; 12'd546: toneL = `g; 12'd547: toneL = `g;
                            12'd548: toneL = `g; 12'd549: toneL = `g; 12'd550: toneL = `g; 12'd551: toneL = `g;
                            12'd552: toneL = `g; 12'd553: toneL = `g; 12'd554: toneL = `g; 12'd555: toneL = `g;
                            12'd556: toneL = `g; 12'd557: toneL = `g; 12'd558: toneL = `g; 12'd559: toneL = `g;

                            12'd560: toneL = `g; 12'd561: toneL = `g; 12'd562: toneL = `g; 12'd563: toneL = `g;
                            12'd564: toneL = `g; 12'd565: toneL = `g; 12'd566: toneL = `g; 12'd567: toneL = `g;
                            12'd568: toneL = `g; 12'd569: toneL = `g; 12'd570: toneL = `g; 12'd571: toneL = `g;
                            12'd572: toneL = `g; 12'd573: toneL = `g; 12'd574: toneL = `g; 12'd575: toneL = `g;
                            default: toneL = `sil;
                        endcase
                    end
                else 
                    begin
                        toneL = `sil;
                    end
            end
        else
            begin
                if(en==1)
                    begin
                        case(ibeatNum)
                            12'd0: toneL = `sil; 12'd1: toneL = `sil; 12'd2: toneL = `sil; 12'd3: toneL = `sil;
                            12'd4: toneL = `sil; 12'd5: toneL = `sil; 12'd6: toneL = `sil; 12'd7: toneL = `sil;
                            12'd8: toneL = `sil; 12'd9: toneL = `sil; 12'd10: toneL = `sil; 12'd11: toneL = `sil;
                            12'd12: toneL = `sil; 12'd13: toneL = `sil; 12'd14: toneL = `sil; 12'd15: toneL = `sil;

                            12'd16: toneL = `sil; 12'd17: toneL = `sil; 12'd18: toneL = `sil; 12'd19: toneL = `sil;
                            12'd20: toneL = `sil; 12'd21: toneL = `sil; 12'd22: toneL = `sil; 12'd23: toneL = `sil;
                            12'd24: toneL = `sil; 12'd25: toneL = `sil; 12'd26: toneL = `sil; 12'd27: toneL = `sil;
                            12'd28: toneL = `sil; 12'd29: toneL = `sil; 12'd30: toneL = `sil; 12'd31: toneL = `sil;

                            12'd32: toneL = `sil; 12'd33: toneL = `sil; 12'd34: toneL = `sil; 12'd35: toneL = `sil;
                            12'd36: toneL = `sil; 12'd37: toneL = `sil; 12'd38: toneL = `sil; 12'd39: toneL = `sil;
                            12'd40: toneL = `sil; 12'd41: toneL = `sil; 12'd42: toneL = `sil; 12'd43: toneL = `sil;
                            12'd44: toneL = `sil; 12'd45: toneL = `sil; 12'd46: toneL = `sil; 12'd47: toneL = `sil;

                            12'd48: toneL = `sil; 12'd49: toneL = `sil; 12'd50: toneL = `sil; 12'd51: toneL = `sil;
                            12'd52: toneL = `sil; 12'd53: toneL = `sil; 12'd54: toneL = `sil; 12'd55: toneL = `sil;
                            12'd56: toneL = `sil; 12'd57: toneL = `sil; 12'd58: toneL = `sil; 12'd59: toneL = `sil;
                            12'd60: toneL = `sil; 12'd61: toneL = `sil; 12'd62: toneL = `sil; 12'd63: toneL = `sil;

                            12'd64: toneL = `c; 12'd65: toneL = `c; 12'd66: toneL = `c; 12'd67: toneL = `c;
                            12'd68: toneL = `c; 12'd69: toneL = `c; 12'd70: toneL = `c; 12'd71: toneL = `c;
                            12'd72: toneL = `e; 12'd73: toneL = `e; 12'd74: toneL = `e; 12'd75: toneL = `e;
                            12'd76: toneL = `e; 12'd77: toneL = `e; 12'd78: toneL = `e; 12'd79: toneL = `e;

                            12'd80: toneL = `g; 12'd81: toneL = `g; 12'd82: toneL = `g; 12'd83: toneL = `g;
                            12'd84: toneL = `g; 12'd85: toneL = `g; 12'd86: toneL = `g; 12'd87: toneL = `g;
                            12'd88: toneL = `g; 12'd89: toneL = `g; 12'd90: toneL = `g; 12'd91: toneL = `g;
                            12'd92: toneL = `g; 12'd93: toneL = `g; 12'd94: toneL = `g; 12'd95: toneL = `g;

                            12'd96: toneL = `e; 12'd97: toneL = `e; 12'd98: toneL = `e; 12'd99: toneL = `e;
                            12'd100: toneL = `e; 12'd101: toneL = `e; 12'd102: toneL = `e; 12'd103: toneL = `e;
                            12'd104: toneL = `l; 12'd105: toneL = `l; 12'd106: toneL = `l; 12'd107: toneL = `l;
                            12'd108: toneL = `l; 12'd109: toneL = `l; 12'd110: toneL = `l; 12'd111: toneL = `l;

                            12'd112: toneL = `b; 12'd113: toneL = `b; 12'd114: toneL = `b; 12'd115: toneL = `b;
                            12'd116: toneL = `b; 12'd117: toneL = `b; 12'd118: toneL = `b; 12'd119: toneL = `b;
                            12'd120: toneL = `a; 12'd121: toneL = `a; 12'd122: toneL = `a; 12'd123: toneL = `a;
                            12'd124: toneL = `a; 12'd125: toneL = `a; 12'd126: toneL = `a; 12'd127: toneL = `a;

                            12'd128: toneL = `a; 12'd129: toneL = `a; 12'd130: toneL = `a; 12'd131: toneL = `a;
                            12'd132: toneL = `a; 12'd133: toneL = `a; 12'd134: toneL = `a; 12'd135: toneL = `a;
                            12'd136: toneL = `e; 12'd137: toneL = `e; 12'd138: toneL = `e; 12'd139: toneL = `e;
                            12'd140: toneL = `e; 12'd141: toneL = `e; 12'd142: toneL = `e; 12'd143: toneL = `e;

                            12'd144: toneL = `a; 12'd145: toneL = `a; 12'd146: toneL = `a; 12'd147: toneL = `a;
                            12'd148: toneL = `a; 12'd149: toneL = `a; 12'd150: toneL = `a; 12'd151: toneL = `a;
                            12'd152: toneL = `a; 12'd153: toneL = `a; 12'd154: toneL = `a; 12'd155: toneL = `a;
                            12'd156: toneL = `a; 12'd157: toneL = `a; 12'd158: toneL = `a; 12'd159: toneL = `a;

                            12'd160: toneL = `a; 12'd161: toneL = `a; 12'd162: toneL = `a; 12'd163: toneL = `a;
                            12'd164: toneL = `a; 12'd165: toneL = `a; 12'd166: toneL = `a; 12'd167: toneL = `a;
                            12'd168: toneL = `hc; 12'd169: toneL = `hc; 12'd170: toneL = `hc; 12'd171: toneL = `hc;
                            12'd172: toneL = `hc; 12'd173: toneL = `hc; 12'd174: toneL = `hc; 12'd175: toneL = `hc;

                            12'd176: toneL = `g; 12'd177: toneL = `g; 12'd178: toneL = `g; 12'd179: toneL = `g;
                            12'd180: toneL = `g; 12'd181: toneL = `g; 12'd182: toneL = `g; 12'd183: toneL = `g;
                            12'd184: toneL = `e; 12'd185: toneL = `e; 12'd186: toneL = `e; 12'd187: toneL = `e;
                            12'd188: toneL = `e; 12'd189: toneL = `e; 12'd190: toneL = `e; 12'd191: toneL = `e;

                            12'd192: toneL = `f; 12'd193: toneL = `f; 12'd194: toneL = `f; 12'd195: toneL = `f;
                            12'd196: toneL = `f; 12'd197: toneL = `f; 12'd198: toneL = `f; 12'd199: toneL = `f;
                            12'd200: toneL = `a; 12'd201: toneL = `a; 12'd202: toneL = `a; 12'd203: toneL = `a;
                            12'd204: toneL = `a; 12'd205: toneL = `a; 12'd206: toneL = `a; 12'd207: toneL = `a;

                            12'd208: toneL = `a; 12'd209: toneL = `a; 12'd210: toneL = `a; 12'd211: toneL = `a;
                            12'd212: toneL = `a; 12'd213: toneL = `a; 12'd214: toneL = `a; 12'd215: toneL = `a;
                            12'd216: toneL = `hc; 12'd217: toneL = `hc; 12'd218: toneL = `hc; 12'd219: toneL = `hc;
                            12'd220: toneL = `hc; 12'd221: toneL = `hc; 12'd222: toneL = `hc; 12'd223: toneL = `hc;

                            12'd224: toneL = `g; 12'd225: toneL = `g; 12'd226: toneL = `g; 12'd227: toneL = `g;
                            12'd228: toneL = `g; 12'd229: toneL = `g; 12'd230: toneL = `g; 12'd231: toneL = `g;
                            12'd232: toneL = `g; 12'd233: toneL = `g; 12'd234: toneL = `g; 12'd235: toneL = `g;
                            12'd236: toneL = `g; 12'd237: toneL = `g; 12'd238: toneL = `g; 12'd239: toneL = `g;

                            12'd240: toneL = `g; 12'd241: toneL = `g; 12'd242: toneL = `g; 12'd243: toneL = `g;
                            12'd244: toneL = `g; 12'd245: toneL = `g; 12'd246: toneL = `g; 12'd247: toneL = `g;
                            12'd248: toneL = `g; 12'd249: toneL = `g; 12'd250: toneL = `g; 12'd251: toneL = `g;
                            12'd252: toneL = `g; 12'd253: toneL = `g; 12'd254: toneL = `g; 12'd255: toneL = `g;

                            12'd256: toneL = `g; 12'd257: toneL = `g; 12'd258: toneL = `g; 12'd259: toneL = `g;
                            12'd260: toneL = `g; 12'd261: toneL = `g; 12'd262: toneL = `g; 12'd263: toneL = `g;
                            12'd264: toneL = `g; 12'd265: toneL = `g; 12'd266: toneL = `g; 12'd267: toneL = `g;
                            12'd268: toneL = `g; 12'd269: toneL = `g; 12'd270: toneL = `g; 12'd271: toneL = `g;

                            12'd272: toneL = `e; 12'd273: toneL = `e; 12'd274: toneL = `e; 12'd275: toneL = `e;
                            12'd276: toneL = `e; 12'd277: toneL = `e; 12'd278: toneL = `e; 12'd279: toneL = `e;
                            12'd280: toneL = `g; 12'd281: toneL = `g; 12'd282: toneL = `g; 12'd283: toneL = `g;
                            12'd284: toneL = `g; 12'd285: toneL = `g; 12'd286: toneL = `g; 12'd287: toneL = `g;

                            12'd288: toneL = `b; 12'd289: toneL = `b; 12'd290: toneL = `b; 12'd291: toneL = `b;
                            12'd292: toneL = `b; 12'd293: toneL = `b; 12'd294: toneL = `b; 12'd295: toneL = `b;
                            12'd296: toneL = `b; 12'd297: toneL = `b; 12'd298: toneL = `b; 12'd299: toneL = `b;
                            12'd300: toneL = `b; 12'd301: toneL = `b; 12'd302: toneL = `b; 12'd303: toneL = `b;

                            12'd304: toneL = `b; 12'd305: toneL = `b; 12'd306: toneL = `b; 12'd307: toneL = `b;
                            12'd308: toneL = `b; 12'd309: toneL = `b; 12'd310: toneL = `b; 12'd311: toneL = `b;
                            12'd312: toneL = `b; 12'd313: toneL = `b; 12'd314: toneL = `b; 12'd315: toneL = `b;
                            12'd316: toneL = `b; 12'd317: toneL = `b; 12'd318: toneL = `b; 12'd319: toneL = `b;

                            12'd320: toneL = `c; 12'd321: toneL = `c; 12'd322: toneL = `c; 12'd323: toneL = `c;
                            12'd324: toneL = `c; 12'd325: toneL = `c; 12'd326: toneL = `c; 12'd327: toneL = `c;
                            12'd328: toneL = `e; 12'd329: toneL = `e; 12'd330: toneL = `e; 12'd331: toneL = `e;
                            12'd332: toneL = `e; 12'd333: toneL = `e; 12'd334: toneL = `e; 12'd335: toneL = `e;

                            12'd336: toneL = `g; 12'd337: toneL = `g; 12'd338: toneL = `g; 12'd339: toneL = `g;
                            12'd340: toneL = `g; 12'd341: toneL = `g; 12'd342: toneL = `g; 12'd343: toneL = `g;
                            12'd344: toneL = `g; 12'd345: toneL = `g; 12'd346: toneL = `g; 12'd347: toneL = `g;
                            12'd348: toneL = `g; 12'd349: toneL = `g; 12'd350: toneL = `g; 12'd351: toneL = `g;

                            12'd352: toneL = `e; 12'd353: toneL = `e; 12'd354: toneL = `e; 12'd355: toneL = `e;
                            12'd356: toneL = `e; 12'd357: toneL = `e; 12'd358: toneL = `e; 12'd359: toneL = `e;
                            12'd360: toneL = `k; 12'd361: toneL = `k; 12'd362: toneL = `k; 12'd363: toneL = `k;
                            12'd364: toneL = `k; 12'd365: toneL = `k; 12'd366: toneL = `k; 12'd367: toneL = `k;

                            12'd368: toneL = `b; 12'd369: toneL = `b; 12'd370: toneL = `b; 12'd371: toneL = `b;
                            12'd372: toneL = `b; 12'd373: toneL = `b; 12'd374: toneL = `b; 12'd375: toneL = `b;
                            12'd376: toneL = `a; 12'd377: toneL = `a; 12'd378: toneL = `a; 12'd379: toneL = `a;
                            12'd380: toneL = `a; 12'd381: toneL = `a; 12'd382: toneL = `a; 12'd383: toneL = `a;

                            12'd384: toneL = `a; 12'd385: toneL = `a; 12'd386: toneL = `a; 12'd387: toneL = `a;
                            12'd388: toneL = `a; 12'd389: toneL = `a; 12'd390: toneL = `a; 12'd391: toneL = `a;
                            12'd392: toneL = `e; 12'd393: toneL = `e; 12'd394: toneL = `e; 12'd395: toneL = `e;
                            12'd396: toneL = `e; 12'd397: toneL = `e; 12'd398: toneL = `e; 12'd399: toneL = `e;

                            12'd400: toneL = `a; 12'd401: toneL = `a; 12'd402: toneL = `a; 12'd403: toneL = `a;
                            12'd404: toneL = `a; 12'd405: toneL = `a; 12'd406: toneL = `a; 12'd407: toneL = `a;
                            12'd408: toneL = `a; 12'd409: toneL = `a; 12'd410: toneL = `a; 12'd411: toneL = `a;
                            12'd412: toneL = `a; 12'd413: toneL = `a; 12'd414: toneL = `a; 12'd415: toneL = `a;

                            12'd416: toneL = `a; 12'd417: toneL = `a; 12'd418: toneL = `a; 12'd419: toneL = `a;
                            12'd420: toneL = `a; 12'd421: toneL = `a; 12'd422: toneL = `a; 12'd423: toneL = `a;
                            12'd424: toneL = `he; 12'd425: toneL = `he; 12'd426: toneL = `he; 12'd427: toneL = `he;
                            12'd428: toneL = `he; 12'd429: toneL = `he; 12'd430: toneL = `he; 12'd431: toneL = `he;

                            12'd432: toneL = `hc; 12'd433: toneL = `hc; 12'd434: toneL = `hc; 12'd435: toneL = `hc;
                            12'd436: toneL = `hc; 12'd437: toneL = `hc; 12'd438: toneL = `hc; 12'd439: toneL = `hc;
                            12'd440: toneL = `a; 12'd441: toneL = `a; 12'd442: toneL = `a; 12'd443: toneL = `a;
                            12'd444: toneL = `a; 12'd445: toneL = `a; 12'd446: toneL = `a; 12'd447: toneL = `a;

                            12'd448: toneL = `c; 12'd449: toneL = `c; 12'd450: toneL = `c; 12'd451: toneL = `c;
                            12'd452: toneL = `c; 12'd453: toneL = `c; 12'd454: toneL = `c; 12'd455: toneL = `c;
                            12'd456: toneL = `e; 12'd457: toneL = `e; 12'd458: toneL = `e; 12'd459: toneL = `e;
                            12'd460: toneL = `e; 12'd461: toneL = `e; 12'd462: toneL = `e; 12'd463: toneL = `e;

                            12'd464: toneL = `g; 12'd465: toneL = `g; 12'd466: toneL = `g; 12'd467: toneL = `g;
                            12'd468: toneL = `g; 12'd469: toneL = `g; 12'd470: toneL = `g; 12'd471: toneL = `g;
                            12'd472: toneL = `hc; 12'd473: toneL = `hc; 12'd474: toneL = `hc; 12'd475: toneL = `hc;
                            12'd476: toneL = `hc; 12'd477: toneL = `hc; 12'd478: toneL = `hc; 12'd479: toneL = `hc;

                            12'd480: toneL = `hd; 12'd481: toneL = `hd; 12'd482: toneL = `hd; 12'd483: toneL = `hd;
                            12'd484: toneL = `hd; 12'd485: toneL = `hd; 12'd486: toneL = `hd; 12'd487: toneL = `hd;
                            12'd488: toneL = `g; 12'd489: toneL = `g; 12'd490: toneL = `g; 12'd491: toneL = `g;
                            12'd492: toneL = `g; 12'd493: toneL = `g; 12'd494: toneL = `g; 12'd495: toneL = `g;

                            12'd496: toneL = `b; 12'd497: toneL = `b; 12'd498: toneL = `b; 12'd499: toneL = `b;
                            12'd500: toneL = `b; 12'd501: toneL = `b; 12'd502: toneL = `b; 12'd503: toneL = `b;
                            12'd504: toneL = `sil; 12'd505: toneL = `sil; 12'd506: toneL = `sil; 12'd507: toneL = `sil;
                            12'd508: toneL = `sil; 12'd509: toneL = `sil; 12'd510: toneL = `sil; 12'd511: toneL = `sil;

                            12'd512: toneL = `hc; 12'd513: toneL = `hc; 12'd514: toneL = `hc; 12'd515: toneL = `hc;
                            12'd516: toneL = `hc; 12'd517: toneL = `hc; 12'd518: toneL = `hc; 12'd519: toneL = `hc;
                            12'd520: toneL = `hc; 12'd521: toneL = `hc; 12'd522: toneL = `hc; 12'd523: toneL = `hc;
                            12'd524: toneL = `hc; 12'd525: toneL = `hc; 12'd526: toneL = `hc; 12'd527: toneL = `hc;

                            12'd528: toneL = `hc; 12'd529: toneL = `hc; 12'd530: toneL = `hc; 12'd531: toneL = `hc;
                            12'd532: toneL = `hc; 12'd533: toneL = `hc; 12'd534: toneL = `hc; 12'd535: toneL = `hc;
                            12'd536: toneL = `hc; 12'd537: toneL = `hc; 12'd538: toneL = `hc; 12'd539: toneL = `hc;
                            12'd540: toneL = `hc; 12'd541: toneL = `hc; 12'd542: toneL = `hc; 12'd543: toneL = `hc;

                            12'd544: toneL = `sil; 12'd545: toneL = `sil; 12'd546: toneL = `sil; 12'd547: toneL = `sil;
                            12'd548: toneL = `sil; 12'd549: toneL = `sil; 12'd550: toneL = `sil; 12'd551: toneL = `sil;
                            12'd552: toneL = `sil; 12'd553: toneL = `sil; 12'd554: toneL = `sil; 12'd555: toneL = `sil;
                            12'd556: toneL = `sil; 12'd557: toneL = `sil; 12'd558: toneL = `sil; 12'd559: toneL = `sil;

                            12'd560: toneL = `sil; 12'd561: toneL = `sil; 12'd562: toneL = `sil; 12'd563: toneL = `sil;
                            12'd564: toneL = `sil; 12'd565: toneL = `sil; 12'd566: toneL = `sil; 12'd567: toneL = `sil;
                            12'd568: toneL = `sil; 12'd569: toneL = `sil; 12'd570: toneL = `sil; 12'd571: toneL = `sil;
                            12'd572: toneL = `sil; 12'd573: toneL = `sil; 12'd574: toneL = `sil; 12'd575: toneL = `sil;
                            default: toneL = `sil;
                        endcase
                    end
                else 
                    begin
                        toneL = `sil;
                    end
            end
    end
endmodule

module clock_divider(clk, clk_div);   
    parameter n = 26;     
    input clk;   
    output clk_div;   
    
    reg [n-1:0] num;
    wire [n-1:0] next_num;
    
    always@(posedge clk)begin
    	num<=next_num;
    end
    
    assign next_num = num +1;
    assign clk_div = num[n-1];
    
endmodule

module note_gen(
    clk, // clock from crystal
    rst, // active high reset
    note_div_left, // div for note generation
    note_div_right,
    audio_left,
    audio_right,
    volume
);

    // I/O declaration
    input clk; // clock from crystal
    input rst; // active low reset
    input [21:0] note_div_left, note_div_right; // div for note generation
    output [15:0] audio_left, audio_right;
    input [2:0] volume;

    // Declare internal signals
    reg [21:0] clk_cnt_next, clk_cnt;
    reg [21:0] clk_cnt_next_2, clk_cnt_2;
    reg b_clk, b_clk_next;
    reg c_clk, c_clk_next;

    // Note frequency generation
    always @(posedge clk or posedge rst)
        if (rst == 1'b1)
            begin
                clk_cnt <= 22'd0;
                clk_cnt_2 <= 22'd0;
                b_clk <= 1'b0;
                c_clk <= 1'b0;
            end
        else
            begin
                clk_cnt <= clk_cnt_next;
                clk_cnt_2 <= clk_cnt_next_2;
                b_clk <= b_clk_next;
                c_clk <= c_clk_next;
            end
        
    always @*
        if (clk_cnt == note_div_left)
            begin
                clk_cnt_next = 22'd0;
                b_clk_next = ~b_clk;
            end
        else
            begin
                clk_cnt_next = clk_cnt + 1'b1;
                b_clk_next = b_clk;
            end

    always @*
        if (clk_cnt_2 == note_div_right)
            begin
                clk_cnt_next_2 = 22'd0;
                c_clk_next = ~c_clk;
            end
        else
            begin
                clk_cnt_next_2 = clk_cnt_2 + 1'b1;
                c_clk_next = c_clk;
            end

    // Assign the amplitude of the note
    // Volume is controlled here
    wire [15:0]posnum;
    wire [15:0]negnum;
    assign posnum=(volume==3'b000)?16'h0000:(volume==3'b001)?16'h0100:(volume==3'b010)?16'h0220:(volume==3'b011)?16'h0620:
                (volume==3'b100)?16'h0920:(volume==3'b101)?16'h0C20:16'h0620;
    assign negnum=(volume==3'b000)?16'h0000:(volume==3'b001)?16'hFFE0:(volume==3'b010)?16'hFDE0:(volume==3'b011)?16'hF9E0:
                (volume==3'b100)?16'hF6E0:(volume==3'b101)?16'hF3E0:16'hF9E0;
    assign audio_left = (note_div_left == 22'd1) ? 16'h0000 : (b_clk == 1'b0) ? negnum : posnum;
    assign audio_right = (note_div_right == 22'd1) ? 16'h0000 : (c_clk == 1'b0) ? negnum : posnum;
endmodule

module onepulse(signal, clk, op);
    input signal, clk;
    output op;
    
    reg op;
    reg delay;
    
    always @(posedge clk) begin
        if((signal == 1) & (delay == 0)) op <= 1;
        else op <= 0; 
        delay = signal;
    end
endmodule

module player_control (
	input clk,
	input reset,
	input _play,
	input _repeat,
    input music,
	output reg [11:0] ibeat
);
	parameter LEN = 4095;
    reg [11:0] next_ibeat;
    reg nowmusic;

    always @(*) begin
        if(reset) begin next_ibeat=0;  end
        else if(_play==1'b0) begin next_ibeat=ibeat; end
        else
            begin
                next_ibeat = (music!=nowmusic)?12'd0:(ibeat+1<LEN)?(ibeat + 1):((ibeat+1>=LEN)&&_repeat==1'b1)?12'd0:((ibeat+1==LEN)&&_repeat==1'b0)?(ibeat+1):ibeat;
            end
    end

	always @(posedge clk, posedge reset) begin
		if (reset)
            begin
			    ibeat <= 0;
                nowmusic<=0;
            end
		else begin
            ibeat <= next_ibeat;
            nowmusic<=music;
		end
	end

    

endmodule

module debounce(pb_debounced, pb ,clk);
    output pb_debounced;
    input pb;
    input clk;
    
    reg [6:0] shift_reg;
    always @(posedge clk) begin
        shift_reg[6:1] <= shift_reg[5:0];
        shift_reg[0] <= pb;
    end
    
    assign pb_debounced = shift_reg == 7'b111_1111 ? 1'b1 : 1'b0;
endmodule

module speaker_control(
    clk,  // clock from the crystal
    rst,  // active high reset
    audio_in_left, // left channel audio data input
    audio_in_right, // right channel audio data input
    audio_mclk, // master clock
    audio_lrck, // left-right clock, Word Select clock, or sample rate clock
    audio_sck, // serial clock
    audio_sdin // serial audio data input
);

    // I/O declaration
    input clk;  // clock from the crystal
    input rst;  // active high reset
    input [15:0] audio_in_left; // left channel audio data input
    input [15:0] audio_in_right; // right channel audio data input
    output audio_mclk; // master clock
    output audio_lrck; // left-right clock
    output audio_sck; // serial clock
    output audio_sdin; // serial audio data input
    reg audio_sdin;

    // Declare internal signal nodes 
    wire [8:0] clk_cnt_next;
    reg [8:0] clk_cnt;
    reg [15:0] audio_left, audio_right;

    // Counter for the clock divider
    assign clk_cnt_next = clk_cnt + 1'b1;

    always @(posedge clk or posedge rst)
        if (rst == 1'b1)
            clk_cnt <= 9'd0;
        else
            clk_cnt <= clk_cnt_next;

    // Assign divided clock output
    assign audio_mclk = clk_cnt[1];
    assign audio_lrck = clk_cnt[8];
    assign audio_sck = 1'b1; // use internal serial clock mode

    // audio input data buffer
    always @(posedge clk_cnt[8] or posedge rst)
        if (rst == 1'b1)
            begin
                audio_left <= 16'd0;
                audio_right <= 16'd0;
            end
        else
            begin
                audio_left <= audio_in_left;
                audio_right <= audio_in_right;
            end

    always @*
        case (clk_cnt[8:4])
            5'b00000: audio_sdin = audio_right[0];
            5'b00001: audio_sdin = audio_left[15];
            5'b00010: audio_sdin = audio_left[14];
            5'b00011: audio_sdin = audio_left[13];
            5'b00100: audio_sdin = audio_left[12];
            5'b00101: audio_sdin = audio_left[11];
            5'b00110: audio_sdin = audio_left[10];
            5'b00111: audio_sdin = audio_left[9];
            5'b01000: audio_sdin = audio_left[8];
            5'b01001: audio_sdin = audio_left[7];
            5'b01010: audio_sdin = audio_left[6];
            5'b01011: audio_sdin = audio_left[5];
            5'b01100: audio_sdin = audio_left[4];
            5'b01101: audio_sdin = audio_left[3];
            5'b01110: audio_sdin = audio_left[2];
            5'b01111: audio_sdin = audio_left[1];
            5'b10000: audio_sdin = audio_left[0];
            5'b10001: audio_sdin = audio_right[15];
            5'b10010: audio_sdin = audio_right[14];
            5'b10011: audio_sdin = audio_right[13];
            5'b10100: audio_sdin = audio_right[12];
            5'b10101: audio_sdin = audio_right[11];
            5'b10110: audio_sdin = audio_right[10];
            5'b10111: audio_sdin = audio_right[9];
            5'b11000: audio_sdin = audio_right[8];
            5'b11001: audio_sdin = audio_right[7];
            5'b11010: audio_sdin = audio_right[6];
            5'b11011: audio_sdin = audio_right[5];
            5'b11100: audio_sdin = audio_right[4];
            5'b11101: audio_sdin = audio_right[3];
            5'b11110: audio_sdin = audio_right[2];
            5'b11111: audio_sdin = audio_right[1];
            default: audio_sdin = 1'b0;
        endcase

endmodule
