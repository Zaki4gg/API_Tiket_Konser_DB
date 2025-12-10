DELIMITER $$

CREATE FUNCTION fn_generate_ticket_code (
    p_event_id BIGINT UNSIGNED,
    p_kategori VARCHAR(50)
)
RETURNS VARCHAR(30)
DETERMINISTIC
BEGIN
    DECLARE v_kode VARCHAR(30);
    SET v_kode = CONCAT(
        'E',
        p_event_id,
        '-',
        UPPER(LEFT(p_kategori, 3)),
        '-',
        DATE_FORMAT(NOW(), '%y%m%d%H%i%s')
    );
    RETURN v_kode;
END$$

DELIMITER;

DELIMITER $$

CREATE FUNCTION fn_generate_order_code (
    p_user_id BIGINT UNSIGNED
)
RETURNS VARCHAR(30)
DETERMINISTIC
BEGIN
    DECLARE v_kode VARCHAR(30);
    SET v_kode = CONCAT(
        'ORD',
        LPAD(p_user_id, 3, '0'),
        '-',
        DATE_FORMAT(NOW(), '%y%m%d%H%i%s')
    );
    RETURN v_kode;
END$$

DELIMITER ;

