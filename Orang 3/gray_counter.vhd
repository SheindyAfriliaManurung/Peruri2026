library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity gray_counter is
    Generic ( WIDTH : integer := 4 );
    Port (
        clk        : in  STD_LOGIC;
        reset      : in  STD_LOGIC;
        enable     : in  STD_LOGIC;
        binary_out : out STD_LOGIC_VECTOR(WIDTH-1 downto 0);
        gray_out   : out STD_LOGIC_VECTOR(WIDTH-1 downto 0)
    );
end entity gray_counter;

architecture Behavioral of gray_counter is
    signal count : unsigned(WIDTH-1 downto 0) := (others => '0');
begin
    process(clk, reset)
    begin
        if reset = '1' then
            count <= (others => '0');
        elsif rising_edge(clk) then
            if enable = '1' then
                count <= count + 1;
            end if;
        end if;
    end process;

    binary_out <= std_logic_vector(count);
    gray_out   <= std_logic_vector(count xor ('0' & count(WIDTH-1 downto 1)));
end Behavioral;