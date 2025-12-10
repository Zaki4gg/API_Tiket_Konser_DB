-- Registrasi customer baru
DELIMITER $$

CREATE or REPLACE PROCEDURE sp_registrasi_customer (
    IN p_nama VARCHAR(100),
    IN p_email VARCHAR(100),
    IN p_password VARCHAR(255),
    IN p_no_hp VARCHAR(20)
)
BEGIN
    DECLARE v_jumlah INT DEFAULT 0;

    DECLARE exit handler FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT
        COUNT(*)
    INTO v_jumlah
    FROM users
    WHERE users.email = p_email;

    IF v_jumlah > 0 THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Email sudah terdaftar';
    ELSE
        INSERT INTO users (nama, email, password, no_hp, role)
        VALUES (p_nama, p_email, p_password, p_no_hp, 'CUSTOMER');
        COMMIT;
    END IF;
END$$

DELIMITER ;

--- Login user
DELIMITER $$

CREATE or REPLACE PROCEDURE sp_login_user (
    IN p_email VARCHAR(100),
    IN p_password VARCHAR(255)
)
BEGIN
    DECLARE exit handler FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT
        users.user_id,
        users.nama,
        users.email,
        users.no_hp,
        users.role,
        users.created_at
    FROM users
    WHERE users.email = p_email
      AND users.password = p_password;

    IF ROW_COUNT() = 0 THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Email atau password salah';
    END IF;    

    COMMIT;
END$$

DELIMITER ;


-- Admin Buat Event
DELIMITER $$

CREATE or REPLACE PROCEDURE sp_admin_buat_event (
    IN p_nama_event    VARCHAR(150),
    IN p_deskripsi     TEXT,
    IN p_lokasi        VARCHAR(150),
    IN p_tanggal_event DATE,
    IN p_waktu_mulai   TIME,
    IN p_waktu_selesai TIME
)
BEGIN
    DECLARE exit handler FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
    END;

    START TRANSACTION;

    INSERT INTO events (
        nama_event,
        deskripsi,
        lokasi,
        tanggal_event,
        waktu_mulai,
        waktu_selesai,
        status
    )
    VALUES (
        p_nama_event,
        p_deskripsi,
        p_lokasi,
        p_tanggal_event,
        p_waktu_mulai,
        p_waktu_selesai,
        'PUBLISHED'
    );

    COMMIT;
END$$

DELIMITER ;

-- Admin Update Detail Event
DELIMITER $$

CREATE PROCEDURE sp_admin_update_event (
    IN p_event_id      BIGINT UNSIGNED,
    IN p_nama_event    VARCHAR(150),
    IN p_deskripsi     TEXT,
    IN p_lokasi        VARCHAR(150),
    IN p_tanggal_event DATE,
    IN p_waktu_mulai   TIME,
    IN p_waktu_selesai TIME,
    IN p_status        VARCHAR(20)
)
BEGIN
    DECLARE exit handler FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
    END;

    START TRANSACTION;

    UPDATE events
    SET nama_event    = p_nama_event,
        deskripsi     = p_deskripsi,
        lokasi        = p_lokasi,
        tanggal_event = p_tanggal_event,
        waktu_mulai   = p_waktu_mulai,
        waktu_selesai = p_waktu_selesai,
        status        = p_status
    WHERE events.event_id = p_event_id;

    COMMIT;
END$$

DELIMITER ;

-- Admin Hapus Event
DELIMITER $$

CREATE PROCEDURE sp_admin_hapus_event (
    IN p_event_id BIGINT UNSIGNED
)
BEGIN
    DECLARE exit handler FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
    END;

    START TRANSACTION;

    DELETE FROM events
    WHERE events.event_id = p_event_id;

    COMMIT;
END$$

DELIMITER ;

-- Admin Buat Tiket
DELIMITER $$

CREATE PROCEDURE sp_admin_buat_tiket (
    IN p_event_id           BIGINT UNSIGNED,
    IN p_kategori           VARCHAR(50),
    IN p_harga_satuan       DECIMAL(10,2),
    IN p_kuantitas_tersedia INT,
    IN p_deskripsi          TEXT
)
BEGIN
    DECLARE v_kode_tiket VARCHAR(30);

    DECLARE exit handler FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
    END;

    START TRANSACTION;

    SET v_kode_tiket = fn_generate_ticket_code(p_event_id, p_kategori);

    INSERT INTO tiket (
        event_id,
        kategori,
        harga_satuan,
        kuantitas_tersedia,
        kuantitas_terjual,
        kode_tiket,
        deskripsi
    )
    VALUES (
        p_event_id,
        p_kategori,
        p_harga_satuan,
        p_kuantitas_tersedia,
        0,
        v_kode_tiket,
        p_deskripsi
    );

    COMMIT;
END$$

DELIMITER ;

-- Admin Update Kuantitas Tiket
DELIMITER $$

CREATE or REPLACE PROCEDURE sp_admin_update_kuantitas_tiket (
    IN p_tiket_id           BIGINT UNSIGNED,
    IN p_kuantitas_tersedia INT
)
BEGIN
    DECLARE v_terjual INT DEFAULT 0;

    DECLARE exit handler FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT
        tiket.kuantitas_terjual
    INTO v_terjual
    FROM tiket
    WHERE tiket.tiket_id = p_tiket_id
    FOR UPDATE;

    IF p_kuantitas_tersedia < v_terjual THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Kuantitas tersedia tidak boleh lebih kecil dari jumlah terjual';
    ELSE
        UPDATE tiket
        SET kuantitas_tersedia = p_kuantitas_tersedia
        WHERE tiket.tiket_id = p_tiket_id;

        COMMIT;
    END IF;
END$$

DELIMITER ;


-- Admin Update Harga Tiket
DELIMITER $$

CREATE PROCEDURE sp_admin_update_harga_tiket (
    IN p_tiket_id     BIGINT UNSIGNED,
    IN p_harga_satuan DECIMAL(10,2)
)
BEGIN
    DECLARE exit handler FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
    END;

    START TRANSACTION;

    UPDATE tiket
    SET harga_satuan = p_harga_satuan
    WHERE tiket.tiket_id = p_tiket_id;

    COMMIT;
END$$

DELIMITER ;


-- Mencari Event dengan View
DELIMITER $$

CREATE PROCEDURE sp_cari_event (
    IN p_keyword VARCHAR(100)
)
BEGIN
    DECLARE exit handler FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
    END;

    START TRANSACTION;

    SELECT
        vw_event_aktif.event_id,
        vw_event_aktif.nama_event,
        vw_event_aktif.deskripsi,
        vw_event_aktif.lokasi,
        vw_event_aktif.tanggal_event,
        vw_event_aktif.waktu_mulai,
        vw_event_aktif.waktu_selesai,
        vw_event_aktif.status,
        vw_event_aktif.total_tiket,
        vw_event_aktif.sisa_tiket
    FROM vw_event_aktif
    WHERE vw_event_aktif.nama_event LIKE CONCAT('%', p_keyword, '%')
       OR vw_event_aktif.lokasi     LIKE CONCAT('%', p_keyword, '%')
       OR vw_event_aktif.deskripsi  LIKE CONCAT('%', p_keyword, '%');

    COMMIT;
END$$

DELIMITER ;


-- Melihat Detail Event
DELIMITER $$

CREATE or REPLACE PROCEDURE sp_lihat_detail_event (
    IN p_event_id BIGINT UNSIGNED
)
BEGIN
    DECLARE exit handler FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
    END;

    START TRANSACTION;

    SELECT
        events.event_id,
        events.nama_event,
        events.deskripsi,
        events.lokasi,
        events.tanggal_event,
        events.waktu_mulai,
        events.waktu_selesai,
        events.status
    FROM events e
    WHERE e.event_id = p_event_id;
    
    SELECT
        tiket.tiket_id,
        tiket.kategori,
        tiket.harga_satuan,
        tiket.kuantitas_tersedia,
        tiket.kuantitas_terjual,
        tiket.kode_tiket,
        tiket.deskripsi AS deskripsi_tiket,
        tiket.kuantitas_tersedia - tiket.kuantitas_terjual AS sisa_tiket
    FROM tiket t
    WHERE t.event_id = p_event_id;

    COMMIT;
END$$

DELIMITER ;


-- Memesan Tiket
DELIMITER $$

CREATE PROCEDURE sp_pesan_tiket (
    IN p_user_id  BIGINT UNSIGNED,
    IN p_tiket_id BIGINT UNSIGNED,
    IN p_jumlah   INT
)
BEGIN
    DECLARE v_harga_satuan DECIMAL(10,2);
    DECLARE v_total        DECIMAL(10,2);
    DECLARE v_kode_pesanan VARCHAR(30);
    DECLARE v_pesanan_id   BIGINT UNSIGNED;

    DECLARE exit handler FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
    END;

    START TRANSACTION;

    SELECT
        tiket.harga_satuan
    INTO v_harga_satuan
    FROM tiket
    WHERE tiket.tiket_id = p_tiket_id
    FOR UPDATE;

    IF v_harga_satuan IS NULL THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Tiket tidak ditemukan';
    END IF;

    SET v_total        = v_harga_satuan * p_jumlah;
    SET v_kode_pesanan = fn_generate_order_code(p_user_id);

    INSERT INTO pesanan (
        user_id,
        kode_pesanan,
        tanggal_pesanan,
        total_harga,
        status
    )
    VALUES (
        p_user_id,
        v_kode_pesanan,
        NOW(),
        v_total,
        'PENDING'
    );

    SET v_pesanan_id = LAST_INSERT_ID();

    INSERT INTO detail_pesanan (
        pesanan_id,
        tiket_id,
        jumlah,
        harga_satuan,
        subtotal
    )
    VALUES (
        v_pesanan_id,
        p_tiket_id,
        p_jumlah,
        v_harga_satuan,
        v_total
    );

    COMMIT;
END$$

DELIMITER ;


-- Melakukan Pembayaran
DELIMITER $$

CREATE PROCEDURE sp_bayar_pesanan (
    IN p_pesanan_id   BIGINT UNSIGNED,
    IN p_metode       VARCHAR(50),
    IN p_jumlah_bayar DECIMAL(10,2)
)
BEGIN
    DECLARE v_total DECIMAL(10,2);

    DECLARE exit handler FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
    END;

    START TRANSACTION;

    SELECT
        pesanan.total_harga
    INTO v_total
    FROM pesanan
    WHERE pesanan.pesanan_id = p_pesanan_id
    FOR UPDATE;

    IF v_total IS NULL THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Pesanan tidak ditemukan';
    END IF;

    IF v_total <> p_jumlah_bayar THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Jumlah bayar tidak sama dengan total pesanan';
    END IF;

    INSERT INTO pembayaran (
        pesanan_id,
        metode,
        jumlah_bayar,
        tanggal_bayar,
        status,
        bukti_bayar
    )
    VALUES (
        p_pesanan_id,
        p_metode,
        p_jumlah_bayar,
        NOW(),
        'BERHASIL',
        NULL
    );
    -- Trigger akan mengubah pesanan.status menjadi 'PAID'

    COMMIT;
END$$

DELIMITER ;


-- Melihat Riwayat Pembelian dengan View
DELIMITER $$

CREATE PROCEDURE sp_riwayat_pembelian (
    IN p_user_id BIGINT UNSIGNED
)
BEGIN
    DECLARE exit handler FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
    END;

    START TRANSACTION;

    SELECT
        vw_riwayat_pembelian.pesanan_id,
        vw_riwayat_pembelian.kode_pesanan,
        vw_riwayat_pembelian.user_id,
        vw_riwayat_pembelian.nama_customer,
        vw_riwayat_pembelian.tanggal_pesanan,
        vw_riwayat_pembelian.total_harga,
        vw_riwayat_pembelian.status_pesanan,
        vw_riwayat_pembelian.event_id,
        vw_riwayat_pembelian.nama_event,
        vw_riwayat_pembelian.tiket_id,
        vw_riwayat_pembelian.kategori,
        vw_riwayat_pembelian.kode_tiket,
        vw_riwayat_pembelian.jumlah,
        vw_riwayat_pembelian.subtotal
    FROM vw_riwayat_pembelian
    WHERE vw_riwayat_pembelian.user_id = p_user_id
    ORDER BY vw_riwayat_pembelian.tanggal_pesanan DESC;

    COMMIT;
END$$

DELIMITER ;


-- Melihat E-Ticket
DELIMITER $$

CREATE PROCEDURE sp_lihat_e_tiket (
    IN p_user_id BIGINT UNSIGNED
)
BEGIN
    DECLARE exit handler FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
    END;

    START TRANSACTION;

    SELECT
        pesanan.pesanan_id,
        pesanan.kode_pesanan,
        events.event_id,
        events.nama_event,
        events.tanggal_event,
        events.lokasi,
        tiket.tiket_id,
        tiket.kategori,
        tiket.kode_tiket,
        detail_pesanan.jumlah
    FROM pesanan
    JOIN detail_pesanan ON pesanan.pesanan_id = detail_pesanan.pesanan_id
    JOIN tiket          ON detail_pesanan.tiket_id = tiket.tiket_id
    JOIN events         ON tiket.event_id = events.event_id
    WHERE pesanan.user_id = p_user_id
      AND pesanan.status  = 'PAID'
    ORDER BY
        events.tanggal_event,
        events.nama_event;

    COMMIT;
END$$

DELIMITER ;


-- Admin Melihat Data Penjualan dengan View
DELIMITER $$

CREATE PROCEDURE sp_admin_lihat_data_penjualan ()
BEGIN
    DECLARE exit handler FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
    END;

    START TRANSACTION;

    SELECT
        vw_penjualan_per_event.event_id,
        vw_penjualan_per_event.nama_event,
        vw_penjualan_per_event.total_tiket_terjual,
        vw_penjualan_per_event.total_penjualan
    FROM vw_penjualan_per_event
    ORDER BY vw_penjualan_per_event.nama_event;

    COMMIT;
END$$

DELIMITER ;


-- Melihat riwayat pembelian berdasarkan email (view)
DELIMITER $$

CREATE PROCEDURE sp_riwayat_pembelian_by_email (
    IN p_email VARCHAR(100)
)
BEGIN
    DECLARE v_user_id BIGINT UNSIGNED;

    DECLARE exit handler FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Cari user_id dari email
    SELECT
        users.user_id
    INTO v_user_id
    FROM users
    WHERE users.email = p_email;

    IF v_user_id IS NULL THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'User dengan email tersebut tidak ditemukan';
    END IF;

    -- Tampilkan riwayat dari VIEW, filter pakai user_id
    SELECT
        vw_riwayat_pembelian.pesanan_id,
        vw_riwayat_pembelian.kode_pesanan,
        vw_riwayat_pembelian.user_id,
        vw_riwayat_pembelian.nama_customer,
        vw_riwayat_pembelian.tanggal_pesanan,
        vw_riwayat_pembelian.total_harga,
        vw_riwayat_pembelian.status_pesanan,
        vw_riwayat_pembelian.event_id,
        vw_riwayat_pembelian.nama_event,
        vw_riwayat_pembelian.tiket_id,
        vw_riwayat_pembelian.kategori,
        vw_riwayat_pembelian.kode_tiket,
        vw_riwayat_pembelian.jumlah,
        vw_riwayat_pembelian.subtotal
    FROM vw_riwayat_pembelian
    WHERE vw_riwayat_pembelian.user_id = v_user_id
    ORDER BY vw_riwayat_pembelian.tanggal_pesanan DESC;

    COMMIT;
END$$

DELIMITER ;


-- Melihat E-tiket berdasarkan email
DELIMITER $$

CREATE PROCEDURE sp_lihat_e_tiket_by_email (
    IN p_email VARCHAR(100)
)
BEGIN
    DECLARE v_user_id BIGINT UNSIGNED;

    DECLARE exit handler FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
    END;

    START TRANSACTION;

    SELECT
        users.user_id
    INTO v_user_id
    FROM users
    WHERE users.email = p_email;

    IF v_user_id IS NULL THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'User dengan email tersebut tidak ditemukan';
    END IF;

    SELECT
        pesanan.pesanan_id,
        pesanan.kode_pesanan,
        events.event_id,
        events.nama_event,
        events.tanggal_event,
        events.lokasi,
        tiket.tiket_id,
        tiket.kategori,
        tiket.kode_tiket,
        detail_pesanan.jumlah
    FROM pesanan
    JOIN detail_pesanan ON pesanan.pesanan_id = detail_pesanan.pesanan_id
    JOIN tiket          ON detail_pesanan.tiket_id = tiket.tiket_id
    JOIN events         ON tiket.event_id = events.event_id
    WHERE pesanan.user_id = v_user_id
      AND pesanan.status  = 'PAID'
    ORDER BY
        events.tanggal_event,
        events.nama_event;

    COMMIT;
END$$

DELIMITER ;


-- Ganti password user
DELIMITER $$

CREATE or REPLACE PROCEDURE sp_ganti_password_user (
    IN p_email           VARCHAR(100),
    IN p_password_lama   VARCHAR(255),
    IN p_password_baru   VARCHAR(255)
)
BEGIN
    DECLARE exit handler FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- cek user & password lama
    UPDATE users
    SET password = p_password_baru
    WHERE email    = p_email
      AND password = p_password_lama;

    IF ROW_COUNT() = 0 THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Email atau password lama salah';
    END IF;

    COMMIT;
END$$

DELIMITER ;


-- Customer membatalkan pesanan
DELIMITER $$

CREATE PROCEDURE sp_batalkan_pesanan (
    IN p_pesanan_id BIGINT UNSIGNED,
    IN p_user_id    BIGINT UNSIGNED
)
BEGIN
    DECLARE v_status VARCHAR(20);

    DECLARE exit handler FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
    END;

    START TRANSACTION;

    -- pastikan pesanan milik user ini dan masih PENDING
    SELECT
        pesanan.status
    INTO v_status
    FROM pesanan
    WHERE pesanan.pesanan_id = p_pesanan_id
      AND pesanan.user_id    = p_user_id
    FOR UPDATE;

    IF v_status IS NULL THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Pesanan tidak ditemukan untuk user tersebut';
    END IF;

    IF v_status <> 'PENDING' THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Pesanan sudah tidak dapat dibatalkan';
    END IF;

    -- kembalikan stok terjual
    UPDATE tiket
    JOIN detail_pesanan
      ON tiket.tiket_id = detail_pesanan.tiket_id
    SET tiket.kuantitas_terjual = tiket.kuantitas_terjual - detail_pesanan.jumlah
    WHERE detail_pesanan.pesanan_id = p_pesanan_id;

    -- ubah status pesanan
    UPDATE pesanan
    SET status = 'CANCELLED'
    WHERE pesanan.pesanan_id = p_pesanan_id;

    COMMIT;
END$$

DELIMITER ;


-- melihat daftar user
DELIMITER $$

CREATE or REPLACE PROCEDURE sp_daftar_users (
    IN p_role VARCHAR(10)  -- boleh NULL
)
BEGIN
    DECLARE exit handler FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT
        vw_daftar_users.user_id,
        vw_daftar_users.nama,
        vw_daftar_users.email,
        vw_daftar_users.role,
        vw_daftar_users.created_at
    FROM vw_daftar_users
    WHERE p_role IS NULL
       OR vw_daftar_users.role = p_role
    ORDER BY vw_daftar_users.nama;

    COMMIT;
END$$

DELIMITER ;


-- melihat daftar events
DELIMITER $$

CREATE or REPLACE PROCEDURE sp_daftar_events (
    IN p_status VARCHAR(20)   -- boleh NULL
)
BEGIN
    DECLARE exit handler FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT
        vw_daftar_events.event_id,
        vw_daftar_events.nama_event,
        vw_daftar_events.tanggal_event,
        vw_daftar_events.lokasi,
        vw_daftar_events.status
    FROM vw_daftar_events
    WHERE p_status IS NULL
       OR vw_daftar_events.status = p_status
    ORDER BY
        vw_daftar_events.tanggal_event,
        vw_daftar_events.nama_event;

    COMMIT;
END$$

DELIMITER ;


-- melihat daftar tiket dengan nama event
DELIMITER $$

CREATE or REPLACE PROCEDURE sp_daftar_tiket_event (
    IN p_nama_event VARCHAR(255)
)
BEGIN
    DECLARE exit handler FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT
        vw_daftar_tiket_per_event.tiket_id,
        vw_daftar_tiket_per_event.event_id,
        vw_daftar_tiket_per_event.nama_event,
        vw_daftar_tiket_per_event.kategori,
        vw_daftar_tiket_per_event.harga_satuan,
        vw_daftar_tiket_per_event.kuantitas_tersedia,
        vw_daftar_tiket_per_event.kuantitas_terjual,
        vw_daftar_tiket_per_event.sisa_tiket
    FROM vw_daftar_tiket_per_event
    WHERE p_nama_event IS NULL OR vw_daftar_tiket_per_event.nama_event = p_nama_event
    ORDER BY
        vw_daftar_tiket_per_event.nama_event, vw_daftar_tiket_per_event.kategori;

    COMMIT;
END$$

DELIMITER ;


-- Melihat daftar pesanan
DELIMITER $$

CREATE or REPLACE PROCEDURE sp_daftar_pesanan (
    IN p_user_id BIGINT UNSIGNED,   -- boleh NULL (admin melihat semua)
    IN p_status VARCHAR(20)
)
BEGIN
    DECLARE exit handler FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT
        vw_daftar_pesanan.pesanan_id,
        vw_daftar_pesanan.kode_pesanan,
        vw_daftar_pesanan.user_id,
        vw_daftar_pesanan.nama_customer,
        vw_daftar_pesanan.tanggal_pesanan,
        vw_daftar_pesanan.total_harga,
        vw_daftar_pesanan.status_pesanan
    FROM vw_daftar_pesanan
    WHERE (p_user_id IS NULL OR vw_daftar_pesanan.user_id = p_user_id)
        AND (p_status IS NULL OR vw_daftar_pesanan.status_pesanan = p_status)
    ORDER BY
        vw_daftar_pesanan.tanggal_pesanan DESC,
        vw_daftar_pesanan.pesanan_id DESC;

    COMMIT;
END$$

DELIMITER ;


