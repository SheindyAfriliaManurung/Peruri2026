library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity security_controller is
    Port (
        clk           : in  STD_LOGIC;
        reset         : in  STD_LOGIC;
        crc_error     : in  STD_LOGIC;
        replay_err    : in  STD_LOGIC;
        clear_alarm   : in  STD_LOGIC;
        enable_tx     : out STD_LOGIC;
        alarm_led     : out STD_LOGIC;
        status_vector : out STD_LOGIC_VECTOR(1 downto 0)
    );
end entity security_controller;

architecture Behavioral of security_controller is
    type state_type is (STATE_NORMAL, STATE_LOCKDOWN);
    signal current_state : state_type := STATE_NORMAL;
begin
    process(clk, reset)
    begin
        if reset = '1' then
            current_state <= STATE_NORMAL;
        elsif rising_edge(clk) then
            case current_state is
                when STATE_NORMAL =>
                    if crc_error = '1' or replay_err = '1' then
                        current_state <= STATE_LOCKDOWN;
                    end if;

                when STATE_LOCKDOWN =>
                    if clear_alarm = '1' then
                        current_state <= STATE_NORMAL;
                    end if;
            end case;
        end if;
    end process;

    enable_tx <= '1' when current_state = STATE_NORMAL else '0';
    alarm_led <= '1' when current_state = STATE_LOCKDOWN else '0';

    with current_state select
        status_vector <= "00" when STATE_NORMAL,
                         "11" when STATE_LOCKDOWN,
                         "00" when others;
end Behavioral;