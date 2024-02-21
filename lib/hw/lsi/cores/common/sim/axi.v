task axi_write;
    input [31:0] addr;
    input [31:0] data;
    begin
        S_AXI_AWADDR <= addr;
        S_AXI_WDATA <= data;
        S_AXI_AWVALID <= 1'b1;
        S_AXI_WVALID <= 1'b1;
        S_AXI_BREADY <= 1'b1;
        S_AXI_WSTRB <= 4'hF;

        wait(S_AXI_WREADY || S_AXI_AWREADY);

        @(posedge S_AXI_ACLK);
        if(S_AXI_WREADY&&S_AXI_AWREADY) begin
            S_AXI_AWVALID<=0;
            S_AXI_WVALID<=0;
        end
        else begin
            if(S_AXI_WREADY) begin
                S_AXI_WVALID<=0;
                wait(S_AXI_AWREADY);
            end
            else if(S_AXI_AWREADY) begin
                S_AXI_AWVALID<=0;
                wait(S_AXI_WREADY);
            end
            @ (posedge S_AXI_ACLK);
            S_AXI_AWVALID<=0;
            S_AXI_WVALID<=0;
        end

        S_AXI_WSTRB<=0;

        wait(S_AXI_BVALID);

        @(posedge S_AXI_ACLK);

        S_AXI_BREADY<=0;

    end
endtask

task axi_read;
    input [31:0] addr;
    output reg [31:0] data;
    begin
        S_AXI_ARADDR <= addr;
        S_AXI_ARVALID <= 1;
        S_AXI_WSTRB <= 4'hF;
        S_AXI_RREADY <= 1;
        wait(S_AXI_ARREADY);
        wait(S_AXI_RVALID);
        @(posedge S_AXI_ACLK) #1;
        data <= S_AXI_RDATA;

        S_AXI_ARVALID <= 0;
        S_AXI_RREADY <= 0;
        S_AXI_WSTRB<=0;
        @(posedge S_AXI_ACLK) #1;

    end
endtask

