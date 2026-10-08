library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity secure_wrapper is
    Port (
        clk_send      : in  STD_LOGIC;
        clk_recv      : in  STD_LOGIC;
        reset         : in  STD_LOGIC;
        data_in       : in  STD_LOGIC_VECTOR(15 downto 0);
        valid_in      : in  STD_LOGIC;
        inject_error  : in  STD_LOGIC; -- Injeksi Bit-flip
        inject_replay : in  STD_LOGIC; -- Injeksi Replay Attack
        data_out      : out STD_LOGIC_VECTOR(15 downto 0);
        valid_out     : out STD_LOGIC;
        crc_error     : out STD_LOGIC;
        replay_err    : out STD_LOGIC
    );
end entity secure_wrapper;

architecture Behavioral of secure_wrapper is
    signal send_seq_counter : unsigned(7 downto 0) := (others => '0');
    signal expected_seq     : unsigned(7 downto 0) := (others => '0');
    
    signal fifo_data        : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal fifo_seq         : unsigned(7 downto 0) := (others => '0');
    signal fifo_valid       : STD_LOGIC := '0';
    signal fifo_err_flag    : STD_LOGIC := '0';

    signal sync_stage1      : STD_LOGIC := '0';
    signal sync_stage2      : STD_LOGIC := '0';
begin

    -- Domain Pengirim (50 MHz)
    process(clk_send, reset)
    begin
        if reset = '1' then
            send_seq_counter <= (others => '0');
            fifo_data        <= (others => '0');
            fifo_seq         <= (others => '0');
            fifo_valid       <= '0';
            fifo_err_flag    <= '0';
        elsif rising_edge(clk_send) then
            if valid_in = '1' then
                -- Bit Flip Injection
                if inject_error = '1' then
                    fifo_data     <= data_in xor x"0001";
                    fifo_err_flag <= '1';
                else
                    fifo_data     <= data_in;
                    fifo_err_flag <= '0';
                end if;

                -- Replay Attack Injection (Mengirim Sequence Number Lama)
                if inject_replay = '1' then
                    fifo_seq <= send_seq_counter - 1;
                else
                    fifo_seq <= send_seq_counter;
                    send_seq_counter <= send_seq_counter + 1;
                end if;

                fifo_valid <= '1';
            else
                fifo_valid <= '0';
            end if;
        end if;
    end process;

    -- CDC Synchronizer (2-Stage FF)
    process(clk_recv, reset)
    begin
        if reset = '1' then
            sync_stage1 <= '0';
            sync_stage2 <= '0';
        elsif rising_edge(clk_recv) then
            sync_stage1 <= fifo_valid;
            sync_stage2 <= sync_stage1;
        end if;
    end process;

    -- Domain Penerima (125 MHz)
    process(clk_recv, reset)
    begin
        if reset = '1' then
            data_out     <= (others => '0');
            valid_out    <= '0';
            crc_error    <= '0';
            replay_err   <= '0';
            expected_seq <= (others => '0');
        elsif rising_edge(clk_recv) then
            valid_out <= sync_stage2;
            if sync_stage2 = '1' then
                data_out  <= fifo_data;
                crc_error <= fifo_err_flag;

                -- Deteksi Replay Attack
                if fifo_seq < expected_seq and expected_seq /= 0 then
                    replay_err <= '1';
                else
                    replay_err   <= '0';
                    expected_seq <= fifo_seq + 1;
                end if;
            else
                crc_error  <= '0';
                replay_err <= '0';
            end if;
        end if;
    end process;

end Behavioral;