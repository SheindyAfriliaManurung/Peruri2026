library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_level is
    Port (
        ----------------------------------------------------------------
        -- CLOCK & RESET
        ----------------------------------------------------------------
        clk_send      : in  STD_LOGIC;  -- 50 MHz clock domain
        clk_recv      : in  STD_LOGIC;  -- 125 MHz clock domain
        reset         : in  STD_LOGIC;

        ----------------------------------------------------------------
        -- DATA INPUT
        ----------------------------------------------------------------
        data_in       : in  STD_LOGIC_VECTOR(15 downto 0);
        valid_in      : in  STD_LOGIC;

        ----------------------------------------------------------------
        -- SECURITY / ATTACK INJECTION
        ----------------------------------------------------------------
        inject_error  : in  STD_LOGIC;
        inject_replay : in  STD_LOGIC;

        ----------------------------------------------------------------
        -- DATA OUTPUT
        ----------------------------------------------------------------
        data_out      : out STD_LOGIC_VECTOR(15 downto 0);
        valid_out     : out STD_LOGIC;

        ----------------------------------------------------------------
        -- SECURITY STATUS
        ----------------------------------------------------------------
        crc_error     : out STD_LOGIC;
        replay_err    : out STD_LOGIC

        ----------------------------------------------------------------
        -- FUTURE:
        -- Status/error signals from FIFO, SerDes, CDC checker,
        -- security controller, etc. can be added here later.
        ----------------------------------------------------------------
    );
end entity top_level;


architecture Behavioral of top_level is

    --------------------------------------------------------------------
    -- INTERNAL SIGNALS
    --
    -- These signals are deliberately named according to their
    -- functional role so that additional modules can be inserted
    -- between secure_wrapper and the external interface later.
    --------------------------------------------------------------------

    -- Output of secure_wrapper
    signal secure_data_out  : STD_LOGIC_VECTOR(15 downto 0);
    signal secure_valid_out : STD_LOGIC;
    signal secure_crc_error : STD_LOGIC;
    signal secure_replay_err : STD_LOGIC;

begin

    --------------------------------------------------------------------
    -- SECURE WRAPPER
    --
    -- Current integration stage:
    --
    --             50 MHz
    --                |
    --                v
    --        +----------------+
    -- data ->| secure_wrapper |-> data_out
    --        +----------------+
    --                ^
    --                |
    --             125 MHz
    --
    -- The secure_wrapper currently handles:
    --   1. Sequence number generation
    --   2. Replay injection
    --   3. Bit-flip injection
    --   4. CDC valid synchronization
    --   5. Replay detection
    --   6. Error indication
    --------------------------------------------------------------------

    secure_wrapper_inst : entity work.secure_wrapper
        port map (
            clk_send      => clk_send,
            clk_recv      => clk_recv,
            reset         => reset,

            data_in       => data_in,
            valid_in      => valid_in,

            inject_error  => inject_error,
            inject_replay => inject_replay,

            data_out      => secure_data_out,
            valid_out     => secure_valid_out,

            crc_error     => secure_crc_error,
            replay_err    => secure_replay_err
        );


    --------------------------------------------------------------------
    -- CURRENT OUTPUT CONNECTION
    --
    -- At this stage there are no external FIFO/SerDes modules yet.
    -- Therefore the secure_wrapper output is directly connected to
    -- the top-level output.
    --
    -- Later, these connections can be replaced by:
    --
    -- secure_wrapper
    --       |
    --       v
    --   async_fifo
    --       |
    --       v
    --   SerDes
    --       |
    --       v
    --   output
    --------------------------------------------------------------------

    data_out   <= secure_data_out;
    valid_out  <= secure_valid_out;

    crc_error  <= secure_crc_error;
    replay_err <= secure_replay_err;


end architecture Behavioral;