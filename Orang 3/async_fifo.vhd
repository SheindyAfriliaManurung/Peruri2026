library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity async_fifo is
    Generic (
        DATA_WIDTH : integer := 16;
        ADDR_WIDTH : integer := 4
    );
    Port (
        wr_clk : in  STD_LOGIC;
        rd_clk : in  STD_LOGIC;
        reset  : in  STD_LOGIC;
        wr_en  : in  STD_LOGIC;
        rd_en  : in  STD_LOGIC;
        din    : in  STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
        dout   : out STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
        full   : out STD_LOGIC;
        empty  : out STD_LOGIC
    );
end entity async_fifo;

architecture Behavioral of async_fifo is
    type mem_type is array (0 to (2**ADDR_WIDTH)-1) of STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
    signal mem : mem_type := (others => (others => '0'));

    signal wr_ptr, rd_ptr : unsigned(ADDR_WIDTH downto 0) := (others => '0');
begin
    -- Write Domain
    process(wr_clk, reset)
    begin
        if reset = '1' then
            wr_ptr <= (others => '0');
        elsif rising_edge(wr_clk) then
            if wr_en = '1' and (wr_ptr(ADDR_WIDTH-1 downto 0) /= rd_ptr(ADDR_WIDTH-1 downto 0) or wr_ptr(ADDR_WIDTH) = rd_ptr(ADDR_WIDTH)) then
                mem(to_integer(wr_ptr(ADDR_WIDTH-1 downto 0))) <= din;
                wr_ptr <= wr_ptr + 1;
            end if;
        end if;
    end process;

    -- Read Domain
    process(rd_clk, reset)
    begin
        if reset = '1' then
            rd_ptr <= (others => '0');
            dout   <= (others => '0');
        elsif rising_edge(rd_clk) then
            if rd_en = '1' and wr_ptr /= rd_ptr then
                dout   <= mem(to_integer(rd_ptr(ADDR_WIDTH-1 downto 0)));
                rd_ptr <= rd_ptr + 1;
            end if;
        end if;
    end process;

    full  <= '1' when (wr_ptr(ADDR_WIDTH) /= rd_ptr(ADDR_WIDTH)) and (wr_ptr(ADDR_WIDTH-1 downto 0) = rd_ptr(ADDR_WIDTH-1 downto 0)) else '0';
    empty <= '1' when wr_ptr = rd_ptr else '0';
end Behavioral;