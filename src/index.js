// index.js
import express from 'express';
import dotenv from 'dotenv';
import { adminPool, userPool } from '../config/db.js';

dotenv.config();

const app = express();
app.use(express.json());

// ---------------------------------------------------------------------
// Root
// ---------------------------------------------------------------------
app.get('/', (req, res) => {
  return res.json({
    message: 'API Tiket Konser',
    subject: 'Manajemen Basis Data',
  });
});

// =====================================================================
// AUTH & USER
// =====================================================================

// Register Customer -> CALL sp_registrasi_customer
app.post('/api/auth/register/customer', async (req, res) => {
  const { nama, email, password, no_hp } = req.body || {};

  if (!nama || !email || !password) {
    return res.status(400).json({
      success: false,
      message: 'nama, email, dan password wajib diisi',
    });
  }

  try {
    await userPool.query(
      'CALL sp_registrasi_customer(?, ?, ?, ?)',
      [nama, email, password, no_hp || null]
    );

    return res.status(201).json({
      success: true,
      message: 'Registrasi berhasil, silakan login',
    });
  } catch (error) {
    const status = error.sqlState === '45000' ? 400 : 500;
    return res.status(status).json({
      success: false,
      message: error.sqlMessage || error.message,
    });
  }
});

// Login User (ADMIN / CUSTOMER) -> CALL sp_login_user
// Login User Customer
app.post('/api/auth/login/customer', async (req, res) => {
  const { email, password } = req.body || {};

  if (!email || !password) {
    return res.status(400).json({
      success: false,
      message: 'email dan password wajib diisi',
    });
  }

  try {
    const [rows] = await userPool.query(
      'CALL sp_login_user(?, ?)',
      [email, password]
    );

    const data = rows[0]?.[0];

    if (!data) {
      return res.status(401).json({
        success: false,
        message: 'Email atau password salah',
      });
    }

    return res.json({
      success: true,
      message: 'Login berhasil',
      data,
    });
  } catch (error) {
    const status = error.sqlState === '45000' ? 400 : 500;
    return res.status(status).json({
      success: false,
      message: error.sqlMessage || error.message,
    });
  }
});

// Login User Admin
app.post('/api/auth/login/admin', async (req, res) => {
  const { email, password } = req.body || {};

  if (!email || !password) {
    return res.status(400).json({
      success: false,
      message: 'email dan password wajib diisi',
    });
  }

  try {
    const [rows] = await adminPool.query(
      'CALL sp_login_user(?, ?)',
      [email, password]
    );

    const data = rows[0]?.[0];

    if (!data) {
      return res.status(401).json({
        success: false,
        message: 'Email atau password salah',
      });
    }

    return res.json({
      success: true,
      message: 'Login berhasil',
      data,
    });
  } catch (error) {
    const status = error.sqlState === '45000' ? 400 : 500;
    return res.status(status).json({
      success: false,
      message: error.sqlMessage || error.message,
    });
  }
});


// Ganti Password User -> CALL sp_ganti_password_user
app.put('/api/auth/password', async (req, res) => {
  const { email, password_lama, password_baru } = req.body || {};

  if (!email || !password_lama || !password_baru) {
    return res.status(400).json({
      success: false,
      message: 'email, password_lama, password_baru wajib diisi',
    });
  }

  try {
    await userPool.query(
      'CALL sp_ganti_password_user(?, ?, ?)',
      [email, password_lama, password_baru]
    );

    return res.json({
      success: true,
      message: 'Password berhasil diganti',
    });
  } catch (error) {
    const status = error.sqlState === '45000' ? 400 : 500;
    return res.status(status).json({
      success: false,
      message: error.sqlMessage || error.message,
    });
  }
});

// =====================================================================
// EVENT (PUBLIC)
// =====================================================================

// Cari Event (pakai VIEW vw_event_aktif) -> CALL sp_cari_event
// keyword optional: kalau kosong, akan mengembalikan semua event
app.get('/api/events/search', async (req, res) => {
  const keyword = (req.query.keyword || '').trim();

  try {
    const [rows] = await userPool.query(
      'CALL sp_cari_event(?)',
      [keyword]
    );

    const data = rows[0] || [];
    if (data.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Tidak ada event yang cocok dengan keyword tersebut',
        data: [],
      });
    }

    return res.json({
      success: true,
      count: data.length,
      data,
    });
  } catch (error) {
    const status = error.sqlState === '45000' ? 400 : 500;
    return res.status(status).json({
      success: false,
      message: error.sqlMessage || error.message,
    });
  }
});

// Detail Event + daftar tiket -> sp_lihat_detail_event
app.get('/api/events/:event_id', async (req, res) => {
  const { event_id } = req.params;

  try {
    const [rows] = await userPool.query(
      'CALL sp_lihat_detail_event(?)',
      [event_id]
    );

    // rows[0] = resultset pertama (detail event)
    // rows[1] = resultset kedua (daftar tiket)
    const eventRows  = rows[0] || [];
    const tiketRows  = rows[1] || [];

    // Kalau event tidak ditemukan (harusnya SP sudah SIGNAL, tapi kita jaga-jaga)
    if (eventRows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Event tidak ditemukan',
        data: null,
      });
    }

    const event = eventRows[0]; // karena 1 event_id = 1 baris event

    return res.json({
      success: true,
      data: {
        event,      // detail event
        tiket: tiketRows,  // list tiket untuk event itu (bisa kosong)
      },
    });
  } catch (error) {
    const status = error.sqlState === '45000' ? 400 : 500;
    return res.status(status).json({
      success: false,
      message: error.sqlMessage || error.message,
    });
  }
});

// =====================================================================
// ADMIN: EVENT MANAGEMENT
// =====================================================================

// Admin: Buat Event -> sp_admin_buat_event
app.post('/api/admin/events', async (req, res) => {
  const {
    nama_event,
    deskripsi,
    lokasi,
    tanggal_event,
    waktu_mulai,
    waktu_selesai,
  } = req.body || {};

  try {
    await adminPool.query(
      'CALL sp_admin_buat_event(?, ?, ?, ?, ?, ?)',
      [
        nama_event,
        deskripsi || null,
        lokasi,
        tanggal_event,
        waktu_mulai,
        waktu_selesai || null,
      ]
    );

    return res.status(201).json({
      success: true,
      message: 'Event berhasil dibuat (status PUBLISHED)',
    });
  } catch (error) {
    const status = error.sqlState === '45000' ? 400 : 500;
    return res.status(status).json({
      success: false,
      message: error.sqlMessage || error.message,
    });
  }
});

// Admin: Update Event -> sp_admin_update_event
app.put('/api/admin/events/:event_id', async (req, res) => {
  const { event_id } = req.params;
  const {
    nama_event,
    deskripsi,
    lokasi,
    tanggal_event,
    waktu_mulai,
    waktu_selesai,
    status: status_event,
  } = req.body || {};

  if (!nama_event || !lokasi || !tanggal_event || !waktu_mulai || !status_event) {
    return res.status(400).json({
      success: false,
      message:
        'nama_event, lokasi, tanggal_event, waktu_mulai, dan status wajib diisi',
    });
  }

  try {
    await adminPool.query(
      'CALL sp_admin_update_event(?, ?, ?, ?, ?, ?, ?, ?)',
      [
        event_id,
        nama_event,
        deskripsi || null,
        lokasi,
        tanggal_event,
        waktu_mulai,
        waktu_selesai || null,
        status_event,
      ]
    );

    return res.json({
      success: true,
      message: 'Event berhasil diupdate',
    });
  } catch (error) {
    const status = error.sqlState === '45000' ? 400 : 500;
    return res.status(status).json({
      success: false,
      message: error.sqlMessage || error.message,
    });
  }
});

// Admin: Hapus Event -> sp_admin_hapus_event
app.delete('/api/admin/events/:event_id', async (req, res) => {
  const { event_id } = req.params;

  try {
    await adminPool.query(
      'CALL sp_admin_hapus_event(?)',
      [event_id]
    );

    return res.json({
      success: true,
      message: 'Event dan tiket terkait berhasil dihapus',
    });
  } catch (error) {
    const status = error.sqlState === '45000' ? 400 : 500;
    return res.status(status).json({
      success: false,
      message: error.sqlMessage || error.message,
    });
  }
});

// =====================================================================
// ADMIN: TICKET MANAGEMENT
// =====================================================================

// Admin: Buat Tiket -> sp_admin_buat_tiket
app.post('/api/admin/tickets', async (req, res) => {
  const {
    event_id,
    kategori,
    harga_satuan,
    kuantitas_tersedia,
    deskripsi,
  } = req.body || {};

  if (!event_id || !kategori || harga_satuan == null || kuantitas_tersedia == null) {
    return res.status(400).json({
      success: false,
      message:
        'event_id, kategori, harga_satuan, dan kuantitas_tersedia wajib diisi',
    });
  }

  try {
    await adminPool.query(
      'CALL sp_admin_buat_tiket(?, ?, ?, ?, ?)',
      [event_id, kategori, harga_satuan, kuantitas_tersedia, deskripsi || null]
    );

    return res.status(201).json({
      success: true,
      message: 'Tiket berhasil dibuat',
    });
  } catch (error) {
    const status = error.sqlState === '45000' ? 400 : 500;
    return res.status(status).json({
      success: false,
      message: error.sqlMessage || error.message,
    });
  }
});

// Admin: Update Kuantitas Tiket -> sp_admin_update_kuantitas_tiket
app.put('/api/admin/tickets/:tiket_id/kuantitas', async (req, res) => {
  const { tiket_id } = req.params;
  const { kuantitas_tersedia } = req.body || {};

  if (kuantitas_tersedia == null) {
    return res.status(400).json({
      success: false,
      message: 'kuantitas_tersedia wajib diisi',
    });
  }

  try {
    await adminPool.query(
      'CALL sp_admin_update_kuantitas_tiket(?, ?)',
      [tiket_id, kuantitas_tersedia]
    );

    return res.json({
      success: true,
      message: 'Kuantitas tiket berhasil diupdate',
    });
  } catch (error) {
    const status = error.sqlState === '45000' ? 400 : 500;
    return res.status(status).json({
      success: false,
      message: error.sqlMessage || error.message,
    });
  }
});

// Admin: Update Harga Tiket -> sp_admin_update_harga_tiket
app.put('/api/admin/tickets/:tiket_id/harga', async (req, res) => {
  const { tiket_id } = req.params;
  const { harga_satuan } = req.body || {};

  if (harga_satuan == null) {
    return res.status(400).json({
      success: false,
      message: 'harga_satuan wajib diisi',
    });
  }

  try {
    await adminPool.query(
      'CALL sp_admin_update_harga_tiket(?, ?)',
      [tiket_id, harga_satuan]
    );

    return res.json({
      success: true,
      message: 'Harga tiket berhasil diupdate',
    });
  } catch (error) {
    const status = error.sqlState === '45000' ? 400 : 500;
    return res.status(status).json({
      success: false,
      message: error.sqlMessage || error.message,
    });
  }
});

// =====================================================================
// CUSTOMER: PESAN TIKET & PEMBAYARAN
// =====================================================================

// Customer: Buat Pesanan -> sp_pesan_tiket
app.post('/api/orders', async (req, res) => {
  const { user_id, tiket_id, jumlah } = req.body || {};

  if (!user_id || !tiket_id || !jumlah) {
    return res.status(400).json({
      success: false,
      message: 'user_id, tiket_id, dan jumlah wajib diisi',
    });
  }

  try {
    await userPool.query(
      'CALL sp_pesan_tiket(?, ?, ?)',
      [user_id, tiket_id, jumlah]
    );

    return res.status(201).json({
      success: true,
      message: 'Pesanan berhasil dibuat',
    });
  } catch (error) {
    const status = error.sqlState === '45000' ? 400 : 500;
    return res.status(status).json({
      success: false,
      message: error.sqlMessage || error.message,
    });
  }
});

// Customer: Bayar Pesanan -> sp_bayar_pesanan
app.post('/api/orders/:pesanan_id/pay', async (req, res) => {
  const { pesanan_id } = req.params;
  const { metode, jumlah_bayar } = req.body || {};

  if (!metode || jumlah_bayar == null) {
    return res.status(400).json({
      success: false,
      message: 'metode dan jumlah_bayar wajib diisi',
    });
  }

  try {
    await userPool.query(
      'CALL sp_bayar_pesanan(?, ?, ?)',
      [pesanan_id, metode, jumlah_bayar]
    );

    return res.json({
      success: true,
      message: 'Pembayaran berhasil, pesanan menjadi PAID',
    });
  } catch (error) {
    const status = error.sqlState === '45000' ? 400 : 500;
    return res.status(status).json({
      success: false,
      message: error.sqlMessage || error.message,
    });
  }
});

// Customer: Batalkan Pesanan -> sp_batalkan_pesanan
app.post('/api/orders/:pesanan_id/cancel', async (req, res) => {
  const { pesanan_id } = req.params;
  const { user_id } = req.body || {};

  if (!user_id) {
    return res.status(400).json({
      success: false,
      message: 'user_id wajib diisi',
    });
  }

  try {
    await userPool.query(
      'CALL sp_batalkan_pesanan(?, ?)',
      [pesanan_id, user_id]
    );

    return res.json({
      success: true,
      message: 'Pesanan berhasil dibatalkan',
    });
  } catch (error) {
    const status = error.sqlState === '45000' ? 400 : 500;
    return res.status(status).json({
      success: false,
      message: error.sqlMessage || error.message,
    });
  }
});

// =====================================================================
// CUSTOMER: RIWAYAT & E-TICKET
// =====================================================================

// Riwayat pembelian by user_id -> sp_riwayat_pembelian
app.get('/api/orders/history/user/:user_id', async (req, res) => {
  const { user_id } = req.params;

  try {
    const [rows] = await userPool.query(
      'CALL sp_riwayat_pembelian(?)',
      [user_id]
    );

    const data = rows[0] || [];

    return res.json({
      success: true,
      count: data.length,
      data,
    });
  } catch (error) {
    const status = error.sqlState === '45000' ? 400 : 500;
    return res.status(status).json({
      success: false,
      message: error.sqlMessage || error.message,
    });
  }
});

// Riwayat pembelian by email -> sp_riwayat_pembelian_by_email
app.get('/api/orders/history/email/:email', async (req, res) => {
  const { email } = req.params;

  try {
    const [rows] = await userPool.query(
      'CALL sp_riwayat_pembelian_by_email(?)',
      [email]
    );

    const data = rows[0] || [];

    return res.json({
      success: true,
      count: data.length,
      data,
    });
  } catch (error) {
    const status = error.sqlState === '45000' ? 400 : 500;
    return res.status(status).json({
      success: false,
      message: error.sqlMessage || error.message,
    });
  }
});

// E-ticket by user_id -> sp_lihat_e_tiket
app.get('/api/e-tickets/user/:user_id', async (req, res) => {
  const { user_id } = req.params;

  try {
    const [rows] = await userPool.query(
      'CALL sp_lihat_e_tiket(?)',
      [user_id]
    );

    const data = rows[0] || [];

    return res.json({
      success: true,
      count: data.length,
      data,
    });
  } catch (error) {
    const status = error.sqlState === '45000' ? 400 : 500;
    return res.status(status).json({
      success: false,
      message: error.sqlMessage || error.message,
    });
  }
});

// E-ticket by email -> sp_lihat_e_tiket_by_email
app.get('/api/e-tickets/email/:email', async (req, res) => {
  const { email } = req.params;

  try {
    const [rows] = await userPool.query(
      'CALL sp_lihat_e_tiket_by_email(?)',
      [email]
    );

    const data = rows[0] || [];

    return res.json({
      success: true,
      count: data.length,
      data,
    });
  } catch (error) {
    const status = error.sqlState === '45000' ? 400 : 500;
    return res.status(status).json({
      success: false,
      message: error.sqlMessage || error.message,
    });
  }
});

// =====================================================================
// ADMIN: LAPORAN PENJUALAN & DAFTAR DATA (pakai VIEW via SP)
// =====================================================================

// Admin: Data penjualan semua event -> sp_admin_lihat_data_penjualan
app.get('/api/admin/penjualan', async (req, res) => {
  try {
    const [rows] = await adminPool.query(
      'CALL sp_admin_lihat_data_penjualan()'
    );

    const data = rows[0] || [];

    return res.json({
      success: true,
      count: data.length,
      data,
    });
  } catch (error) {
    const status = error.sqlState === '45000' ? 400 : 500;
    return res.status(status).json({
      success: false,
      message: error.sqlMessage || error.message,
    });
  }
});


// Admin: Daftar user -> sp_daftar_users
app.get('/api/admin/users', async (req, res) => {
  const role = req.query.role || null; // ADMIN / CUSTOMER / null

  try {
    const [rows] = await adminPool.query(
      'CALL sp_daftar_users(?)',
      [role]
    );

    const data = rows[0] || [];

    return res.json({
      success: true,
      count: data.length,
      data,
    });
  } catch (error) {
    const status = error.sqlState === '45000' ? 400 : 500;
    return res.status(status).json({
      success: false,
      message: error.sqlMessage || error.message,
    });
  }
});

// Admin: Daftar events -> sp_daftar_events
app.get('/api/admin/events', async (req, res) => {
  const status_event = req.query.status || null; // DRAFT / PUBLISHED / dst

  try {
    const [rows] = await adminPool.query(
      'CALL sp_daftar_events(?)',
      [status_event]
    );

    const data = rows[0] || [];

    return res.json({
      success: true,
      count: data.length,
      data,
    });
  } catch (error) {
    const status = error.sqlState === '45000' ? 400 : 500;
    return res.status(status).json({
      success: false,
      message: error.sqlMessage || error.message,
    });
  }
});

// Admin: Daftar tiket berdasarkan nama event -> sp_daftar_tiket_event
app.get('/api/admin/tickets', async (req, res) => {
  const nama_event = req.query.nama_event || null;

  try {
    const [rows] = await adminPool.query(
      'CALL sp_daftar_tiket_event(?)',
      [nama_event]
    );

    const data = rows[0] || [];

    return res.json({
      success: true,
      count: data.length,
      data,
    });
  } catch (error) {
    const status = error.sqlState === '45000' ? 400 : 500;
    return res.status(status).json({
      success: false,
      message: error.sqlMessage || error.message,
    });
  }
});

// Admin: Daftar pesanan (bisa filter user_id & status) -> sp_daftar_pesanan
app.get('/api/admin/orders', async (req, res) => {
  const user_id = req.query.user_id || null;
  const status_pesanan = req.query.status || null; // PENDING / PAID / CANCELLED / EXPIRED

  try {
    const [rows] = await adminPool.query(
      'CALL sp_daftar_pesanan(?, ?)',
      [user_id, status_pesanan]
    );

    const data = rows[0] || [];

    return res.json({
      success: true,
      count: data.length,
      data,
    });
  } catch (error) {
    const status = error.sqlState === '45000' ? 400 : 500;
    return res.status(status).json({
      success: false,
      message: error.sqlMessage || error.message,
    });
  }
});

// =====================================================================
// START SERVER
// =====================================================================
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log('Server is running on http://localhost:' + PORT);
});