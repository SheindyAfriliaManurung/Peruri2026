library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity serdes_tt07_adapter is
    port (
        tx_clk           : in  std_logic;
        rx_clk           : in  std_logic;
        rst_n            : in  std_logic;
        tx_parallel_data : in  std_logic_vector(7 downto 0);
        tx_val           : in  std_logic;
        tx_serial_out    : out std_logic;
        rx_serial_in     : in  std_logic;
        rx_parallel_data : out std_logic_vector(7 downto 0);
        rx_val           : out std_logic
    );
end entity serdes_tt07_adapter;

architecture rtl of serdes_tt07_adapter is
    signal tx_shift_reg : std_logic_vector(7 downto 0);
    signal tx_bit_cnt   : integer range 0 to 7;

    signal rx_shift_reg : std_logic_vector(7 downto 0);
    signal rx_bit_cnt   : integer range 0 to 7;
begin

    process(tx_clk, rst_n)
    begin
        if rst_n = '0' then
            tx_shift_reg  <= (others => '0');
            tx_bit_cnt    <= 0;
            tx_serial_out <= '1';
        elsif rising_edge(tx_clk) then
            if tx_bit_cnt = 0 and tx_val = '1' then
                tx_shift_reg  <= tx_parallel_data;
                tx_bit_cnt    <= 7;
                tx_serial_out <= tx_parallel_data(0);
            elsif tx_bit_cnt > 0 then
                tx_shift_reg  <= '0' & tx_shift_reg(7 downto 1);
                tx_serial_out <= tx_shift_reg(1);
                tx_bit_cnt    <= tx_bit_cnt - 1;
            else
                tx_serial_out <= '1';
            end if;
        end if;
    end process;

    process(rx_clk, rst_n)
    begin
        if rst_n = '0' then
            rx_shift_reg     <= (others => '0');
            rx_bit_cnt       <= 0;
            rx_parallel_data <= (others => '0');
            rx_val           <= '0';
        elsif rising_edge(rx_clk) then
            rx_shift_reg <= rx_serial_in & rx_shift_reg(7 downto 1);
            if rx_bit_cnt = 7 then
                rx_parallel_data <= rx_serial_in & rx_shift_reg(7 downto 1);
                rx_val           <= '1';
                rx_bit_cnt       <= 0;
            else
                rx_val     <= '0';
                rx_bit_cnt <= rx_bit_cnt + 1;
            end if;
        end if;
    end process;

end architecture rtl;