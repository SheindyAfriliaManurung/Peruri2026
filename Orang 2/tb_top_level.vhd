library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_top_level is
end entity tb_top_level;

architecture Behavioral of tb_top_level is

    ----------------------------------------------------------------
    -- DUT: TOP LEVEL
    ----------------------------------------------------------------
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

    ----------------------------------------------------------------
    -- CLOCK & RESET
    ----------------------------------------------------------------
    signal clk_send : STD_LOGIC := '0';
    signal clk_recv : STD_LOGIC := '0';
    signal reset    : STD_LOGIC := '1';

    ----------------------------------------------------------------
    -- INPUT
    ----------------------------------------------------------------
    signal data_in       : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal valid_in      : STD_LOGIC := '0';

    ----------------------------------------------------------------
    -- ATTACK INJECTION
    ----------------------------------------------------------------
    signal inject_error  : STD_LOGIC := '0';
    signal inject_replay : STD_LOGIC := '0';

    ----------------------------------------------------------------
    -- OUTPUT
    ----------------------------------------------------------------
    signal data_out      : STD_LOGIC_VECTOR(15 downto 0);
    signal valid_out     : STD_LOGIC;
    signal crc_error     : STD_LOGIC;
    signal replay_err    : STD_LOGIC;

    ----------------------------------------------------------------
    -- CLOCK PERIOD
    ----------------------------------------------------------------
    -- clk_send = 50 MHz
    -- clk_recv = 125 MHz
    ----------------------------------------------------------------
    constant PERIOD_SEND : time := 20 ns;
    constant PERIOD_RECV : time := 8 ns;

begin

    ----------------------------------------------------------------
    -- DEVICE UNDER TEST
    ----------------------------------------------------------------
    uut : top_level
        port map (
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

    ----------------------------------------------------------------
    -- 50 MHz CLOCK
    ----------------------------------------------------------------
    clk_send_process : process
    begin
        clk_send <= '0';
        wait for PERIOD_SEND / 2;

        clk_send <= '1';
        wait for PERIOD_SEND / 2;
    end process;

    ----------------------------------------------------------------
    -- 125 MHz CLOCK
    ----------------------------------------------------------------
    clk_recv_process : process
    begin
        clk_recv <= '0';
        wait for PERIOD_RECV / 2;

        clk_recv <= '1';
        wait for PERIOD_RECV / 2;
    end process;

    ----------------------------------------------------------------
    -- ASSERTION / MONITOR
    ----------------------------------------------------------------
    monitor_proc : process(clk_recv)
    begin
        if rising_edge(clk_recv) then

            --------------------------------------------------------
            -- Monitor valid output
            --------------------------------------------------------
            if valid_out = '1' then
                report "[INFO] Data received: "
                    & integer'image(to_integer(unsigned(data_out)))
                    & " at "
                    & time'image(now)
                    severity note;
            end if;

            --------------------------------------------------------
            -- Bit-flip detection
            --------------------------------------------------------
            if crc_error = '1' then
                report "[PASSED] Bit-Flip Tampering Detected at "
                    & time'image(now)
                    severity note;
            end if;

            --------------------------------------------------------
            -- Replay detection
            --------------------------------------------------------
            if replay_err = '1' then
                report "[PASSED] Replay Attack Detected at "
                    & time'image(now)
                    severity note;
            end if;

        end if;
    end process;

    ----------------------------------------------------------------
    -- TEST STIMULUS
    ----------------------------------------------------------------
    stim_proc : process
    begin

        ----------------------------------------------------------------
        -- TEST 0 : INITIAL RESET
        ----------------------------------------------------------------
        report "========================================"
            severity note;

        report "TEST 0: Initial Reset"
            severity note;

        reset <= '1';
        valid_in <= '0';
        inject_error <= '0';
        inject_replay <= '0';

        wait for 50 ns;

        reset <= '0';

        wait for 20 ns;


        ----------------------------------------------------------------
        -- TEST 1 : GOLDEN FLOW
        ----------------------------------------------------------------
        report "========================================"
            severity note;

        report "TEST 1: Golden Flow Frame"
            severity note;

        --------------------------------------------------------------
        -- Frame 1
        --------------------------------------------------------------
        data_in <= x"A5A5";
        valid_in <= '1';

        wait for PERIOD_SEND;

        --------------------------------------------------------------
        -- Frame 2
        --------------------------------------------------------------
        data_in <= x"1234";

        wait for PERIOD_SEND;

        valid_in <= '0';

        wait for 100 ns;


        ----------------------------------------------------------------
        -- TEST 2 : BIT-FLIP ATTACK
        ----------------------------------------------------------------
        report "========================================"
            severity note;

        report "TEST 2: Fault Injection - Bit Flip"
            severity note;

        data_in <= x"9999";
        inject_error <= '1';
        valid_in <= '1';

        wait for PERIOD_SEND;

        inject_error <= '0';
        valid_in <= '0';

        wait for 100 ns;


        ----------------------------------------------------------------
        -- TEST 3 : REPLAY ATTACK
        ----------------------------------------------------------------
        report "========================================"
            severity note;

        report "TEST 3: Replay Attack Injection"
            severity note;

        data_in <= x"8888";
        inject_replay <= '1';
        valid_in <= '1';

        wait for PERIOD_SEND;

        inject_replay <= '0';
        valid_in <= '0';

        wait for 100 ns;


        ----------------------------------------------------------------
        -- TEST 4 : ABNORMAL RESET MID-TRANSMISSION
        ----------------------------------------------------------------
        report "========================================"
            severity note;

        report "TEST 4: Abnormal Reset Mid-Transmission"
            severity note;

        data_in <= x"FFFF";
        valid_in <= '1';

        wait for 10 ns;

        --------------------------------------------------------------
        -- Reset while transmission is active
        --------------------------------------------------------------
        reset <= '1';

        wait for 40 ns;

        reset <= '0';
        valid_in <= '0';

        wait for 200 ns;


        ----------------------------------------------------------------
        -- TEST COMPLETE
        ----------------------------------------------------------------
        report "========================================"
            severity note;

        report "ALL TEST SCENARIOS COMPLETED"
            severity note;

        report "========================================"
            severity note;

        wait;

    end process;

end architecture Behavioral;