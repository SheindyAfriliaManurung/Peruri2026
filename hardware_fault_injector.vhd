library ieee;
use ieee.std_logic_1164.all;

entity hardware_fault_injector is
    port (
        clk                : in  std_logic;
        rst_n              : in  std_logic;
        serial_in          : in  std_logic;
        serial_out         : out std_logic;
        inject_bit_flip    : in  std_logic;
        inject_frame_drop  : in  std_logic;
        inject_replay      : in  std_logic;
        isolate_link_cmd   : in  std_logic;
        link_isolated_flag : out std_logic
    );
end entity hardware_fault_injector;

architecture rtl of hardware_fault_injector is
    signal latched_bit : std_logic;
begin

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            latched_bit <= '1';
        elsif rising_edge(clk) then
            if inject_replay = '0' then
                latched_bit <= serial_in;
            end if;
        end if;
    end process;

    process(isolate_link_cmd, inject_frame_drop, inject_replay, inject_bit_flip, serial_in, latched_bit)
    begin
        if isolate_link_cmd = '1' then
            serial_out         <= '1';
            link_isolated_flag <= '1';
        else
            link_isolated_flag <= '0';
            if inject_frame_drop = '1' then
                serial_out <= '0';
            elsif inject_replay = '1' then
                serial_out <= latched_bit;
            elsif inject_bit_flip = '1' then
                serial_out <= not serial_in;
            else
                serial_out <= serial_in;
            end if;
        end if;
    end process;

end architecture rtl;