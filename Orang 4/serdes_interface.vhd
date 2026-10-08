library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity serdes_interface is
    Port (
        clk_fast  : in  STD_LOGIC;
        reset     : in  STD_LOGIC;
        data_in   : in  STD_LOGIC_VECTOR(15 downto 0);
        valid_in  : in  STD_LOGIC;
        tx_serial : out STD_LOGIC;
        data_out  : out STD_LOGIC_VECTOR(15 downto 0);
        valid_out : out STD_LOGIC
    );
end entity serdes_interface;

architecture Behavioral of serdes_interface is
    signal shift_reg : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal bit_cnt   : unsigned(3 downto 0) := (others => '0');
    signal rx_reg    : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal serial_wire : STD_LOGIC := '0';
begin
    -- Serializer (TX)
    process(clk_fast, reset)
    begin
        if reset = '1' then
            shift_reg   <= (others => '0');
            bit_cnt     <= (others => '0');
            serial_wire <= '0';
        elsif rising_edge(clk_fast) then
            if valid_in = '1' and bit_cnt = 0 then
                shift_reg   <= data_in;
                serial_wire <= data_in(15);
                bit_cnt     <= bit_cnt + 1;
            elsif bit_cnt > 0 then
                serial_wire <= shift_reg(15 - to_integer(bit_cnt));
                if bit_cnt = 15 then
                    bit_cnt <= (others => '0');
                else
                    bit_cnt <= bit_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    tx_serial <= serial_wire;

    -- Deserializer (RX Loopback)
    process(clk_fast, reset)
    begin
        if reset = '1' then
            rx_reg    <= (others => '0');
            data_out  <= (others => '0');
            valid_out <= '0';
        elsif rising_edge(clk_fast) then
            rx_reg <= rx_reg(14 downto 0) & serial_wire;
            if bit_cnt = 15 then
                data_out  <= rx_reg(14 downto 0) & serial_wire;
                valid_out <= '1';
            else
                valid_out <= '0';
            end if;
        end if;
    end process;
end Behavioral;