module tb_signext();
    logic [15:0] in;
    logic [31:0] out;

    signext dut (.*);

    initial begin
        $monitor("Time: %0t | in: %h | out: %h", $time, in, out);
        in = 16'h0FFF; #10; // Positive number
        in = 16'h8000; #10; // Negative number
        in = 16'hFFFF; #10; // Negative one
        $finish;
    end
endmodule