# 🛡️ Verification-First Secure Communication Wrapper
**PERURI Chip Hackathon 2026 - Kategori: IC Chip Design & FPGA Implementation**

Repositori ini berisi kode sumber VHDL untuk purwarupa IP *Hardware Security* yang dirancang khusus untuk mengamankan komunikasi data pada perangkat *embedded* dan IoT. Sistem ini dibangun dengan arsitektur **Verify-Before-Release**, memastikan hanya data yang terverifikasi (bebas *error*, bebas *tampering*, dan *fresh*) yang diizinkan masuk ke sistem tujuan lintas *clock domain* (CDC).

Ditargetkan untuk diimplementasikan pada board **Terasic DE10-Nano (Intel Cyclone V SoC FPGA)**.

## 🌟 Fitur Utama
* **Arsitektur Verify-Before-Release:** Gerbang verifikasi berbasis perangkat keras (FSM) untuk mencegah serangan *replay* dan *malformed frames*.
* **Clock Domain Crossing (CDC) Aman:** Penggunaan Asynchronous FIFO dengan *Gray Code pointer* untuk menjembatani domain pengirim (50 MHz) dan penerima (125 MHz).
* **Paralel & Pipelined (VHDL):** Pemrosesan dilakukan murni di *FPGA Fabric* (tanpa intervensi CPU) menghasilkan latensi deterministik yang jauh lebih cepat dari perangkat lunak.
* **Ultra-Lightweight:** Konsumsi logika sangat rendah, ideal sebagai *IP Core* tambahan pada infrastruktur kritis.

## 📂 Struktur Modul & Berkas (VHDL)
Sistem dipecah menjadi beberapa subsistem fungsional untuk kemudahan verifikasi dan pengembangan berkelanjutan:

### 1. Top-Level & Clocking (Integrasi Sistem)
* `de10_nano_top.vhd` — Pembungkus level teratas untuk pemetaan pin perangkat keras (Switch, LED, Clock) board DE10-Nano.
* `top_level.vhd` — Modul integrasi utama yang merangkai sistem Pengirim (TX) dan Penerima (RX).
* `pll_sys.qip` & `pll_sys.vhd` — Intel FPGA IP (Phase-Locked Loop) untuk mensintesis *clock* 125 MHz dari osilator bawaan 50 MHz.

### 2. Logika Keamanan & Kriptografi
* `secure_wrapper.vhd` — Mesin inti pembungkus kriptografi.
* `secure_framing.vhd` — Penyusun paket data (*framing*) dan pelindung integritas bingkai.
* `security_controller.vhd` — Pengontrol status (FSM) untuk operasi enkripsi dan verifikasi.

### 3. Manajemen Memori & CDC (Clock Domain Crossing)
* `async_fifo.vhd` — Antrean asinkron untuk mentransfer data antar domain frekuensi secara aman.
* `gray_counter.vhd` — Penghitung biner *Gray code* untuk memastikan stabilitas sinkronisasi *pointer* FIFO.
* `cdc_checker.vhd` — Pemantau stabilitas sinyal dan *metastability* lintas *clock*.

### 4. Komunikasi & I/O
* `serdes_interface.vhd` — Antarmuka *Serializer/Deserializer* untuk komunikasi serial antar-modul.

## 🚀 Hasil Implementasi & Performa (Synthesis Output)
Sistem ini telah berhasil disintesis menggunakan **Intel Quartus Prime 25.1 Lite Edition** untuk *chip* `5CSEBA6U23I7` (Cyclone V) dengan hasil metrik sebagai berikut:

### 1. Diagram RTL (Skematik Arsitektur Fisik)
*(Visualisasi pemisahan domain frekuensi `FPGA_CLK1_50` dan `outclk_0` (125 MHz) melalui gerbang `top_level`)*
![RTL Viewer] <img width="1908" height="1139" alt="Screenshot 2026-10-08 115156" src="https://github.com/user-attachments/assets/69713281-1f31-4713-9fe9-ecd04859d10a" />

### 2. Resource Usage (Sangat Efisien)
Modul keamanan ini terbukti **ultra-lightweight** dan tidak akan membebani kapasitas SoC:
* **Logic Utilization:** 32 ALMs (< 1% dari total 41.910 ALMs)
* **Dedicated Logic Registers:** 55
* **I/O Pins:** 15 pin (5%)
* **PLL:** 1 (17%)

![Resource Usage] <img width="1183" height="696" alt="Screenshot 2026-10-08 115036" src="https://github.com/user-attachments/assets/6fa983ad-16ad-44ca-a034-0505894670ae" />
<img width="1186" height="265" alt="Screenshot 2026-10-08 115042" src="https://github.com/user-attachments/assets/f079fed1-2bab-4013-a59c-b40641576ed3" />



### 3. Timing Analysis (Fmax)
Berdasarkan *Slow 1100mV 100C Model*, sirkuit VHDL ini terbukti melampaui target frekuensi operasional dengan *margin* yang sangat aman:
* **Sirkuit Penerima/Kriptografi (`divclk`):** Max **141.06 MHz** (Target: 125 MHz)
* **Sirkuit Pengirim/Sumber (`FPGA_CLK1_50`):** Max **214.22 MHz**

![Fmax Summary] <img width="1194" height="612" alt="Screenshot 2026-10-08 115126" src="https://github.com/user-attachments/assets/d034f36e-a64d-415b-bb54-86fdcf9e2ac9" />


## 🛠️ Cara Menjalankan Kompilasi
1. Klon repositori ini ke komputer Anda: `git clone https://github.com/SheindyAfriliaManurung/Peruri2026.git`
2. Buka aplikasi **Intel Quartus Prime**.
3. Klik **File -> Open Project...** dan pilih file `de10_nano_top.qpf`.
4. Di panel *Tasks*, klik dua kali **Compile Design**.
5. Tunggu hingga proses kompilasi selesai untuk melihat laporan Fitter, Timing, dan RTL Viewer.

*(Catatan: Pre-silicon verifikasi telah dilakukan menggunakan Questa FSE).*

## 👥 Tim Pengembang
* **Agat (Ketua)** — Arsitektur Digital & Integrasi Top-Level
* **Anggota 1** — Logika Keamanan & Kriptografi Hardware
* **Anggota 2** — Manajemen Memori & Sinkronisasi CDC
* **Sheindy Afrilia Manurung** — Antarmuka I/O & Verifikasi Pengujian
