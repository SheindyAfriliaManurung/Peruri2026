library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cdc_integrity_checker is
    generic (
        ADDR_WIDTH : integer := 8
    );
    port (
        clk                    : in  std_logic;
        rst_n                  : in  std_logic;
        w_en                   : in  std_logic;
        w_full                 : in  std_logic;
        r_en                   : in  std_logic;
        r_empty                : in  std_logic;
        gray_ptr_in            : in  std_logic_vector(ADDR_WIDTH downto 0);
        flag_overflow_attempt  : out std_logic;
        flag_underflow_attempt : out std_logic;
        flag_gray_code_invalid : out std_logic
    );
end entity cdc_integrity_checker;

architecture rtl of cdc_integrity_checker is
    signal prev_gray_ptr : std_logic_vector(ADDR_WIDTH downto 0);
begin

    process(clk, rst_n)
        variable diff_mask : std_logic_vector(ADDR_WIDTH downto 0);
        variable bit_count : integer;
    begin
        if rst_n = '0' then
            prev_gray_ptr          <= (others => '0');
            flag_overflow_attempt  <= '0';
            flag_underflow_attempt <= '0';
            flag_gray_code_invalid <= '0';
        elsif rising_edge(clk) then
            prev_gray_ptr <= gray_ptr_in;

            if w_en = '1' and w_full = '1' then
                flag_overflow_attempt <= '1';
            end if;

            if r_en = '1' and r_empty = '1' then
                flag_underflow_attempt <= '1';
            end if;

            diff_mask := gray_ptr_in xor prev_gray_ptr;
            bit_count := 0;
            for i in 0 to ADDR_WIDTH loop
                if diff_mask(i) = '1' then
                    bit_count := bit_count + 1;
                end if;
            end loop;

            if bit_count > 1 then
                flag_gray_code_invalid <= '1';
            end if;
        end if;
    end process;

end architecture rtl;
