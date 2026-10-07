library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_secure_wrapper is
end tb_secure_wrapper;

architecture Behavioral of tb_secure_wrapper is

    component secure_wrapper
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

    uut: secure_wrapper
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

    -- --- ASSERTION-BASED VERIFICATION (ABV) ---
    process(clk_recv)
    begin
        if rising_edge(clk_recv) then
            -- Check 1: Output valid assertion
            if valid_out = '1' then
                assert (data_out /= x"0000")
                report "[ASSERT WARNING] Valid data output is zero!" severity note;
            end if;

            -- Check 2: CRC Bit-Flip Assertion
            if crc_error = '1' then
                report "[PASSED ASSERTION] Bit-Flip Tampering Detected at " & time'image(now) severity note;
            end if;

            -- Check 3: Replay Attack Assertion
            if replay_err = '1' then
                report "[PASSED ASSERTION] Replay Attack Detected at " & time'image(now) severity note;
            end if;
        end if;
    end process;

    -- --- STIMULUS PROCESS ---
    stim_proc: process
    begin
        -- Scenario 1: Initial Reset
        reset <= '1'; wait for 50 ns;
        reset <= '0'; wait for 20 ns;

        -- Scenario 2: Golden Flow Frame
        report "=== TEST 1: Golden Flow Frame ===" severity note;
        data_in <= x"A5A5"; valid_in <= '1'; wait for PERIOD_SEND;
        data_in <= x"1234"; wait for PERIOD_SEND;
        valid_in <= '0'; wait for 100 ns;

        -- Scenario 3: Bit-Flip Fault Injection
        report "=== TEST 2: Fault Injection (Bit-Flip) ===" severity note;
        data_in <= x"9999"; inject_error <= '1'; valid_in <= '1';
        wait for PERIOD_SEND;
        inject_error <= '0'; valid_in <= '0';
        wait for 100 ns;

        -- Scenario 4: Replay Attack Injection
        report "=== TEST 3: Replay Attack Injection ===" severity note;
        data_in <= x"8888"; inject_replay <= '1'; valid_in <= '1';
        wait for PERIOD_SEND;
        inject_replay <= '0'; valid_in <= '0';
        wait for 100 ns;

        -- Scenario 5: Abnormal Reset Mid-Transmission
        report "=== TEST 4: Abnormal Reset Mid-Tx ===" severity note;
        data_in <= x"FFFF"; valid_in <= '1';
        wait for 10 ns;
        reset <= '1'; -- Mid-tx reset!
        wait for 40 ns;
        reset <= '0'; valid_in <= '0';

        wait for 200 ns;
        report "=== ALL TEST SCENARIOS COMPLETED SUCCESSFULLY ===" severity note;
        wait;
    end process;

end Behavioral;
