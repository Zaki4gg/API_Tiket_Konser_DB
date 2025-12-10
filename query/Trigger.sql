DELIMITER $$

-- Cek stok sebelum insert detail_pesanan
CREATE TRIGGER trg_before_insert_detail_pesanan
BEFORE INSERT ON detail_pesanan
FOR EACH ROW
BEGIN
    DECLARE v_sisa INT;

    SELECT
        tiket.kuantitas_tersedia - tiket.kuantitas_terjual
    INTO v_sisa
    FROM tiket
    WHERE tiket.tiket_id = NEW.tiket_id
    FOR UPDATE;

    IF v_sisa < NEW.jumlah THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Stok tiket tidak mencukupi';
    END IF;
END$$

DELIMITER;

DELIMITER $$

-- Update kuantitas_terjual setelah insert detail_pesanan
CREATE TRIGGER trg_after_insert_detail_pesanan
AFTER INSERT ON detail_pesanan
FOR EACH ROW
BEGIN
    UPDATE tiket
    SET kuantitas_terjual = kuantitas_terjual + NEW.jumlah
    WHERE tiket.tiket_id = NEW.tiket_id;
END$$

DELIMITER;

DELIMITER $$

-- Jika pembayaran BERHASIL → pesanan jadi PAID
CREATE TRIGGER trg_after_insert_pembayaran
AFTER INSERT ON pembayaran
FOR EACH ROW
BEGIN
    IF NEW.status = 'BERHASIL' THEN
        UPDATE pesanan
        SET status = 'PAID'
        WHERE pesanan.pesanan_id = NEW.pesanan_id;
    END IF;
END$$

DELIMITER ;
