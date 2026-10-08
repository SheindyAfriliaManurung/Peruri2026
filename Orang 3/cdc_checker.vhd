library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity cdc_checker is
    Port (
        clk        : in  STD_LOGIC;
        reset      : in  STD_LOGIC;
        fifo_full  : in  STD_LOGIC;
        fifo_empty : in  STD_LOGIC;
        wr_en      : in  STD_LOGIC;
        rd_en      : in  STD_LOGIC;
        overflow   : out STD_LOGIC;
        underflow  : out STD_LOGIC
    );
end entity cdc_checker;

architecture Behavioral of cdc_checker is
begin
    process(clk, reset)
    begin
        if reset = '1' then
            overflow  <= '0';
            underflow <= '0';
        elsif rising_edge(clk) then
            if fifo_full = '1' and wr_en = '1' then
                overflow <= '1';
            else
                overflow <= '0';
            end if;

            if fifo_empty = '1' and rd_en = '1' then
                underflow <= '1';
            else
                underflow <= '0';
            end if;
        end if;
    end process;
end Behavioral;