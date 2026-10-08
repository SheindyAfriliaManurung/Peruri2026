library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity de10_nano_top is
    Port (
        FPGA_CLK1_50 : in  STD_LOGIC;
        KEY          : in  STD_LOGIC_VECTOR(1 downto 0);
        SW           : in  STD_LOGIC_VECTOR(3 downto 0);
        LEDR         : out STD_LOGIC_VECTOR(7 downto 0)
    );
end entity de10_nano_top;

architecture Structural of de10_nano_top is
    signal clk_125mhz : STD_LOGIC;
    signal reset_sys  : STD_LOGIC;

    component pll_sys
        port (
            refclk   : in  std_logic;
            rst      : in  std_logic;
            outclk_0 : out std_logic
        );
    end component;
begin
    reset_sys <= not KEY(0);

    u_pll : pll_sys port map (refclk => FPGA_CLK1_50, rst => '0', outclk_0 => clk_125mhz);

    u_top_level : entity work.top_level
        port map (
            clk_send      => FPGA_CLK1_50, 
            clk_recv      => clk_125mhz, 
            reset         => reset_sys,
            -- Sudah dikoreksi menjadi 16-bit (4 digit hex)
            data_in       => x"00AB", 
            valid_in      => '1',
            inject_error  => SW(0), 
            inject_replay => SW(1),
            data_out      => open,
            valid_out     => LEDR(0), 
            crc_error     => LEDR(1), 
            replay_err    => LEDR(2),
            fifo_full     => LEDR(3), 
            fifo_empty    => LEDR(4)
        );
        
    LEDR(7 downto 5) <= (others => '0');
end architecture Structural;