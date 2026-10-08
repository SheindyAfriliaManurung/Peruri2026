library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_top_level is
end tb_top_level;

architecture Behavioral of tb_top_level is

    component top_level
        Port (
            clk_send      : in  STD_LOGIC;
            clk_recv      : in  STD_LOGIC;
            reset         : in  STD_LOGIC;
            data_in       : in  STD_LOGIC_VECTOR(15 downto 0);
            valid_in      : in  STD_LOGIC;
            inject_error  : in  STD_LOGIC;
            inject_replay : in  STD_LOGIC;
            data_out      : out STD_LOGIC_VECTOR(15 downto 0);
            valid_out     : out STD_LOGIC;
            crc_error     : out STD_LOGIC;
            replay_err    : out STD_LOGIC
        );
    end component;

    signal clk_send      : STD_LOGIC := '0';
    signal clk_recv      : STD_LOGIC := '0';
    signal reset         : STD_LOGIC := '1';
    signal data_in       : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal valid_in      : STD_LOGIC := '0';
    signal inject_error  : STD_LOGIC := '0';
    signal inject_replay : STD_LOGIC := '0';
    signal data_out      : STD_LOGIC_VECTOR(15 downto 0);
    signal valid_out     : STD_LOGIC;
    signal crc_error     : STD_LOGIC;
    signal replay_err    : STD_LOGIC;

    constant PERIOD_SEND : time := 20 ns;
    constant PERIOD_RECV : time := 8 ns;

begin

    uut: top_level
        Port Map (
            clk_send      => clk_send,
            clk_recv      => clk_recv,
            reset         => reset,
            data_in       => data_in,
            valid_in      => valid_in,
            inject_error  => inject_error,
            inject_replay => inject_replay,
            data_out      => data_out,
            valid_out     => valid_out,
            crc_error     => crc_error,
            replay_err    => replay_err
        );

    clk_send_process : process
    begin
        clk_send <= '0'; wait for PERIOD_SEND/2;
        clk_send <= '1'; wait for PERIOD_SEND/2;
    end process;

    clk_recv_process : process
    begin
        clk_recv <= '0'; wait for PERIOD_RECV/2;
        clk_recv <= '1'; wait for PERIOD_RECV/2;
    end process;

    stim_proc: process
    begin
        reset <= '1'; wait for 50 ns;
        reset <= '0'; wait for 20 ns;

        -- Pengiriman Data Normal
        data_in <= x"ABCD"; valid_in <= '1';
        wait for PERIOD_SEND;
        data_in <= x"1234";
        wait for PERIOD_SEND;
        valid_in <= '0';

        wait for 400 ns;
        wait;
    end process;

end Behavioral;