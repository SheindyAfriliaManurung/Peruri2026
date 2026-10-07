library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity async_fifo_hardened is
    generic (
        DATA_WIDTH : integer := 32;
        ADDR_WIDTH : integer := 8
    );
    port (
        w_clk          : in  std_logic;
        w_rst_n        : in  std_logic;
        w_en           : in  std_logic;
        w_data         : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        w_full         : out std_logic;
        
        r_clk          : in  std_logic;
        r_rst_n        : in  std_logic;
        r_en           : in  std_logic;
        r_data         : out std_logic_vector(DATA_WIDTH-1 downto 0);
        r_empty        : out std_logic;

        w_ptr_gray_out : out std_logic_vector(ADDR_WIDTH downto 0);
        r_ptr_gray_out : out std_logic_vector(ADDR_WIDTH downto 0)
    );
end entity async_fifo_hardened;

architecture rtl of async_fifo_hardened is
    constant DEPTH : integer := 2**ADDR_WIDTH;
    type mem_type is array (0 to DEPTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal mem : mem_type;

    signal w_rst_reg, r_rst_reg : std_logic_vector(1 downto 0);
    signal w_rst_n_sync, r_rst_n_sync : std_logic;

    signal w_ptr_bin, w_ptr_bin_next : unsigned(ADDR_WIDTH downto 0);
    signal r_ptr_bin, r_ptr_bin_next : unsigned(ADDR_WIDTH downto 0);

    signal w_ptr_gray, w_ptr_gray_next : std_logic_vector(ADDR_WIDTH downto 0);
    signal r_ptr_gray, r_ptr_gray_next : std_logic_vector(ADDR_WIDTH downto 0);

    signal w_ptr_gray_sync1, w_ptr_gray_sync2 : std_logic_vector(ADDR_WIDTH downto 0);
    signal r_ptr_gray_sync1, r_ptr_gray_sync2 : std_logic_vector(ADDR_WIDTH downto 0);

    signal w_full_int, r_empty_int : std_logic;

    function bin_to_gray(bin : unsigned) return std_logic_vector is
        variable vec : std_logic_vector(bin'range);
    begin
        vec := std_logic_vector(bin);
        return vec xor ('0' & vec(vec'left downto 1));
    end function;

begin

    process(w_clk, w_rst_n)
    begin
        if w_rst_n = '0' then
            w_rst_reg    <= "00";
            w_rst_n_sync <= '0';
        elsif rising_edge(w_clk) then
            w_rst_reg    <= w_rst_reg(0) & '1';
            w_rst_n_sync <= w_rst_reg(1);
        end if;
    end process;

    process(r_clk, r_rst_n)
    begin
        if r_rst_n = '0' then
            r_rst_reg    <= "00";
            r_rst_n_sync <= '0';
        elsif rising_edge(r_clk) then
            r_rst_reg    <= r_rst_reg(0) & '1';
            r_rst_n_sync <= r_rst_reg(1);
        end if;
    end process;

    process(w_clk, w_rst_n_sync)
    begin
        if w_rst_n_sync = '0' then
            w_ptr_bin  <= (others => '0');
            w_ptr_gray <= (others => '0');
        elsif rising_edge(w_clk) then
            if w_en = '1' and w_full_int = '0' then
                mem(to_integer(w_ptr_bin(ADDR_WIDTH-1 downto 0))) <= w_data;
                w_ptr_bin  <= w_ptr_bin_next;
                w_ptr_gray <= w_ptr_gray_next;
            end if;
        end if;
    end process;

    w_ptr_bin_next  <= w_ptr_bin + 1;
    w_ptr_gray_next <= bin_to_gray(w_ptr_bin_next);

    process(w_clk, w_rst_n_sync)
    begin
        if w_rst_n_sync = '0' then
            r_ptr_gray_sync1 <= (others => '0');
            r_ptr_gray_sync2 <= (others => '0');
        elsif rising_edge(w_clk) then
            r_ptr_gray_sync1 <= r_ptr_gray;
            r_ptr_gray_sync2 <= r_ptr_gray_sync1;
        end if;
    end process;

    process(r_clk, r_rst_n_sync)
    begin
        if r_rst_n_sync = '0' then
            r_ptr_bin  <= (others => '0');
            r_ptr_gray <= (others => '0');
        elsif rising_edge(r_clk) then
            if r_en = '1' and r_empty_int = '0' then
                r_ptr_bin  <= r_ptr_bin_next;
                r_ptr_gray <= r_ptr_gray_next;
            end if;
        end if;
    end process;

    r_ptr_bin_next  <= r_ptr_bin + 1;
    r_ptr_gray_next <= bin_to_gray(r_ptr_bin_next);
    r_data          <= mem(to_integer(r_ptr_bin(ADDR_WIDTH-1 downto 0)));

    process(r_clk, r_rst_n_sync)
    begin
        if r_rst_n_sync = '0' then
            w_ptr_gray_sync1 <= (others => '0');
            w_ptr_gray_sync2 <= (others => '0');
        elsif rising_edge(r_clk) then
            w_ptr_gray_sync1 <= w_ptr_gray;
            w_ptr_gray_sync2 <= w_ptr_gray_sync1;
        end if;
    end process;

    w_full_int <= '1' when w_ptr_gray_next = ((not r_ptr_gray_sync2(ADDR_WIDTH downto ADDR_WIDTH-1)) & r_ptr_gray_sync2(ADDR_WIDTH-2 downto 0)) else '0';
    r_empty_int <= '1' when r_ptr_gray = w_ptr_gray_sync2 else '0';

    w_full  <= w_full_int;
    r_empty <= r_empty_int;

    w_ptr_gray_out <= w_ptr_gray;
    r_ptr_gray_out <= r_ptr_gray;

end architecture rtl;
