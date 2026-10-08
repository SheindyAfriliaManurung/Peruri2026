library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity secure_framing is
    Port (
        clk         : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        payload_in  : in  STD_LOGIC_VECTOR(15 downto 0);
        seq_num     : in  STD_LOGIC_VECTOR(7 downto 0);
        start_tx    : in  STD_LOGIC;
        frame_out   : out STD_LOGIC_VECTOR(39 downto 0);
        frame_valid : out STD_LOGIC
    );
end entity secure_framing;

architecture Behavioral of secure_framing is
    constant HEADER : STD_LOGIC_VECTOR(7 downto 0) := x"A5";
begin
    process(clk, reset)
        variable crc_calc : STD_LOGIC_VECTOR(7 downto 0);
    begin
        if reset = '1' then
            frame_out   <= (others => '0');
            frame_valid <= '0';
        elsif rising_edge(clk) then
            if start_tx = '1' then
                crc_calc := HEADER xor seq_num xor payload_in(15 downto 8) xor payload_in(7 downto 0);
                frame_out   <= HEADER & seq_num & payload_in & crc_calc;
                frame_valid <= '1';
            else
                frame_valid <= '0';
            end if;
        end if;
    end process;
end Behavioral;