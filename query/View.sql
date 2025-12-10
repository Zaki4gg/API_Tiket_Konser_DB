DELIMITER $$

CREATE OR REPLACE VIEW vw_event_aktif AS
SELECT
    e.event_id,
    e.nama_event,
    e.deskripsi,
    e.lokasi,
    e.tanggal_event,
    e.waktu_mulai,
    e.waktu_selesai,
    e.status,
    SUM(t.kuantitas_tersedia) AS total_tiket,
    SUM(t.kuantitas_tersedia - t.kuantitas_terjual) AS sisa_tiket
FROM events e
JOIN tiket t ON e.event_id = t.event_id
GROUP BY
    e.event_id,
    e.nama_event,
    e.deskripsi,
    e.lokasi,
    e.tanggal_event,
    e.waktu_mulai,
    e.waktu_selesai,
    e.status;

DELIMITER;

DELIMITER $$

CREATE OR REPLACE VIEW vw_riwayat_pembelian AS
SELECT
    p.pesanan_id,
    p.kode_pesanan,
    p.user_id,
    u.nama AS nama_customer,
    p.tanggal_pesanan,
    p.total_harga,
    p.status AS status_pesanan,
    e.event_id,
    e.nama_event,
    t.tiket_id,
    t.kategori,
    t.kode_tiket,
    dp.jumlah,
    dp.subtotal
FROM pesanan p
JOIN users u          ON p.user_id = u.user_id
JOIN detail_pesanan dp ON p.pesanan_id = dp.pesanan_id
JOIN tiket t          ON dp.tiket_id = t.tiket_id
JOIN events e         ON t.event_id = e.event_id;

DELIMITER;

DELIMITER $$

CREATE OR REPLACE VIEW vw_penjualan_per_event AS
SELECT
    e.event_id,
    e.nama_event,
    SUM(dp.jumlah)  AS total_tiket_terjual,
    SUM(dp.subtotal) AS total_penjualan
FROM events e
JOIN tiket t           ON e.event_id = t.event_id
JOIN detail_pesanan dp ON t.tiket_id = dp.tiket_id
JOIN pesanan p         ON dp.pesanan_id = p.pesanan_id
WHERE p.status = 'PAID'
GROUP BY
    e.event_id,
    e.nama_event;

DELIMITER;


DELIMITER $$

-- 1) View daftar user (id + info singkat)
CREATE OR REPLACE VIEW vw_daftar_users AS
SELECT
    u.user_id,
    u.nama,
    u.email,
    u.role,
    u.created_at
FROM users u;

DELIMITER;


DELIMITER $$
-- 2) View daftar event (id + info singkat)
CREATE OR REPLACE VIEW vw_daftar_events AS
SELECT
    e.event_id,
    e.nama_event,
    e.tanggal_event,
    e.lokasi,
    e.status
FROM events e;

DELIMITER;


DELIMITER $$

-- 3) View tiket per event (supaya terlihat tiket_id dan event_id)
CREATE OR REPLACE VIEW vw_daftar_tiket_per_event AS
SELECT
    t.tiket_id,
    t.event_id,
    e.nama_event,
    t.kategori,
    t.harga_satuan,
    t.kuantitas_tersedia,
    t.kuantitas_terjual,
    t.kuantitas_tersedia - t.kuantitas_terjual AS sisa_tiket
FROM tiket t
JOIN events e ON t.event_id = e.event_id;

DELIMITER;


DELIMITER $$

-- 4) View daftar pesanan (supaya kelihatan pesanan_id dan kode)
CREATE OR REPLACE VIEW vw_daftar_pesanan AS
SELECT
    p.pesanan_id,
    p.kode_pesanan,
    p.user_id,
    u.nama AS nama_customer,
    p.tanggal_pesanan,
    p.total_harga,
    p.status AS status_pesanan
FROM pesanan p
JOIN users u ON p.user_id = u.user_id;

DELIMITER ;
