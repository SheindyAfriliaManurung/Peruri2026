library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_top_level is
end tb_top_level;

architecture Behavioral of tb_top_level is
    component top_level
        Port (
            clk_send, clk_recv, reset : in STD_LOGIC;
            data_in       : in  STD_LOGIC_VECTOR(15 downto 0);
            valid_in, inject_error, inject_replay : in STD_LOGIC;
            data_out      : out STD_LOGIC_VECTOR(15 downto 0);
            valid_out, crc_error, replay_err, fifo_full, fifo_empty : out STD_LOGIC
        );
    end component;

    signal clk_send, clk_recv : STD_LOGIC := '0';
    signal reset : STD_LOGIC := '1';
    signal data_in : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal valid_in, inject_error, inject_replay : STD_LOGIC := '0';
    signal data_out : STD_LOGIC_VECTOR(15 downto 0);
    signal valid_out, crc_error, replay_err, fifo_full, fifo_empty : STD_LOGIC;
    signal crc_cnt, rep_cnt : integer := 0;
    constant PERIOD_SEND : time := 20 ns;
    constant PERIOD_RECV : time := 8 ns;
begin
    uut: top_level port map (clk_send, clk_recv, reset, data_in, valid_in,
        inject_error, inject_replay, data_out, valid_out, crc_error, replay_err,
        fifo_full, fifo_empty);

    clk_send_process : process begin
        clk_send <= '0'; wait for PERIOD_SEND/2; clk_send <= '1'; wait for PERIOD_SEND/2;
    end process;

    clk_recv_process : process begin
        clk_recv <= '0'; wait for PERIOD_RECV/2; clk_recv <= '1'; wait for PERIOD_RECV/2;
    end process;

    monitor : process(clk_recv) begin
        if rising_edge(clk_recv) then
            if crc_error = '1'  then crc_cnt <= crc_cnt + 1; end if;
            if replay_err = '1' then rep_cnt <= rep_cnt + 1; end if;
        end if;
    end process;

    stim_proc: process
        variable c0, r0 : integer;
    begin
        reset <= '1'; wait for 50 ns; reset <= '0'; wait for 20 ns;

        -- T1: frame normal (3 frame)
        data_in <= x"ABCD"; valid_in <= '1'; wait for PERIOD_SEND;
        data_in <= x"1234"; wait for PERIOD_SEND;
        data_in <= x"5678"; wait for PERIOD_SEND;
        valid_in <= '0'; wait for 200 ns;
        report "T1 normal: siklus replay_err = " & integer'image(rep_cnt) &
               ", crc_error = " & integer'image(crc_cnt);

        -- T2: bit flip
        c0 := crc_cnt;
        inject_error <= '1'; data_in <= x"AAAA"; valid_in <= '1'; wait for PERIOD_SEND;
        valid_in <= '0'; inject_error <= '0'; wait for 100 ns;
        assert crc_cnt > c0 report "T2 GAGAL: bit flip tidak terdeteksi" severity error;

        -- T3: replay
        r0 := rep_cnt;
        inject_replay <= '1'; data_in <= x"BBBB"; valid_in <= '1'; wait for PERIOD_SEND;
        valid_in <= '0'; inject_replay <= '0'; wait for 100 ns;
        assert rep_cnt > r0 report "T3 GAGAL: replay tidak terdeteksi" severity error;

        -- T6: reset di tengah transmisi
        data_in <= x"CCCC"; valid_in <= '1'; wait for PERIOD_SEND;
        reset <= '1'; wait for 30 ns; reset <= '0'; valid_in <= '0'; wait for 100 ns;
        assert valid_out = '0' report "T6 GAGAL: valid_out aktif setelah reset" severity error;

        report "SELESAI" severity note;
        wait;
    end process;
end Behavioral;