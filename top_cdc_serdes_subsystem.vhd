library ieee;
use ieee.std_logic_1164.all;

entity top_cdc_serdes_subsystem is
    generic (
        DATA_WIDTH : integer := 32
    );
    port (
        tx_clk         : in  std_logic;
        rx_clk         : in  std_logic;
        sys_rst_n      : in  std_logic;

        tx_byte_in     : in  std_logic_vector(7 downto 0);
        tx_val_in      : in  std_logic;

        fifo_rx_data   : out std_logic_vector(DATA_WIDTH-1 downto 0);
        fifo_rx_empty  : out std_logic;
        fifo_rx_rd_en  : in  std_logic;

        inj_bit_flip   : in  std_logic;
        inj_frame_drop : in  std_logic;
        inj_replay     : in  std_logic;
        force_isolate  : in  std_logic;

        flag_overflow  : out std_logic;
        flag_underflow : out std_logic;
        flag_gray_err  : out std_logic;
        flag_isolated  : out std_logic
    );
end entity top_cdc_serdes_subsystem;

architecture rtl of top_cdc_serdes_subsystem is

    signal serial_tx_out    : std_logic;
    signal serial_corrupted : std_logic;
    signal rx_byte_out      : std_logic_vector(7 downto 0);
    signal rx_byte_val      : std_logic;
    signal w_ptr_gray       : std_logic_vector(8 downto 0);
    signal r_ptr_gray       : std_logic_vector(8 downto 0);

    signal fifo_w_data      : std_logic_vector(DATA_WIDTH-1 downto 0);

begin

    fifo_w_data <= (DATA_WIDTH-1 downto 8 => '0') & rx_byte_out;

    u_serdes : entity work.serdes_tt07_adapter
        port map (
            tx_clk           => tx_clk,
            rx_clk           => rx_clk,
            rst_n            => sys_rst_n,
            tx_parallel_data => tx_byte_in,
            tx_val           => tx_val_in,
            tx_serial_out    => serial_tx_out,
            rx_serial_in     => serial_corrupted,
            rx_parallel_data => rx_byte_out,
            rx_val           => rx_byte_val
        );

    u_injector : entity work.hardware_fault_injector
        port map (
            clk                => tx_clk,
            rst_n              => sys_rst_n,
            serial_in          => serial_tx_out,
            serial_out         => serial_corrupted,
            inject_bit_flip    => inj_bit_flip,
            inject_frame_drop  => inj_frame_drop,
            inject_replay      => inj_replay,
            isolate_link_cmd   => force_isolate,
            link_isolated_flag => flag_isolated
        );

    u_async_fifo : entity work.async_fifo_hardened
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            ADDR_WIDTH => 8
        )
        port map (
            w_clk          => rx_clk,
            w_rst_n        => sys_rst_n,
            w_en           => rx_byte_val,
            w_data         => fifo_w_data,
            w_full         => open,
            r_clk          => tx_clk,
            r_rst_n        => sys_rst_n,
            r_en           => fifo_rx_rd_en,
            r_data         => fifo_rx_data,
            r_empty        => fifo_rx_empty,
            w_ptr_gray_out => w_ptr_gray,
            r_ptr_gray_out => r_ptr_gray
        );

    u_checker : entity work.cdc_integrity_checker
        generic map (
            ADDR_WIDTH => 8
        )
        port map (
            clk                    => rx_clk,
            rst_n                  => sys_rst_n,
            w_en                   => rx_byte_val,
            w_full                 => '0',
            r_en                   => fifo_rx_rd_en,
            r_empty                => fifo_rx_empty,
            gray_ptr_in            => w_ptr_gray,
            flag_overflow_attempt  => flag_overflow,
            flag_underflow_attempt => flag_underflow,
            flag_gray_code_invalid => flag_gray_err
        );

end architecture rtl;