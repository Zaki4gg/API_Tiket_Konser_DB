// // api_sp_buat_pemesanan
// app.post('/api/pemesanan', async (req, res) => {
//   const { customer_id, tiket_id, jumlah_pemesanan } = req.body || {};

//   if (!customer_id || !tiket_id || !jumlah_pemesanan) {
//     return res.status(400).json({
//       error: 'customer_id, tiket_id, jumlah_pemesanan wajib diisi',
//     });
//   }

//   try {
//     const [result] = await pool.query(
//       'CALL sp_buat_pemesanan(?, ?, ?)',
//       [Number(customer_id), Number(tiket_id), Number(jumlah_pemesanan)]
//     );

//     const rows = Array.isArray(result) ? result[0] : [];
//     const data = rows?.[0] ?? null;

//     return res.status(201).json({
//       message: 'Pemesanan berhasil diproses',
//       data 
//     });
//   } catch (error) {
//   console.error("SP error:", {
//     sqlState: error.sqlState, errno: error.errno, code: error.code,
//     sqlMessage: error.sqlMessage, message: error.message
//   });
//   const status = error?.sqlState === '45000' ? 400 : 500;
//   return res.status(status).json({
//     error: 'Gagal memproses pemesanan',
//     detail: error.sqlMessage || error.message,   // <— tampilkan pesan SP
//     sqlState: error.sqlState, code: error.code
//   });
// }
// })

// // Get/api_sp_CariEvent
// app.get('/api/events/search', async (req, res) => {
//   const keyword = (req.query.keyword ?? '').trim();
//   if (!keyword) {
//     return res.status(400).json({ error: 'keyword wajib diisi' });
//   }

//   try {
//     const [rows] = await pool.query('CALL CariEvent(?)', [keyword]);
//     const data = Array.isArray(rows) ? rows[0] : rows;

//     return res.status(200).json({
//       message: 'Events fetched',
//       count: Array.isArray(data) ? data.length : 0,
//       data: data
//     });
//   } catch (err) {
//     console.error('CariEvent error:', {
//       code: err.code, errno: err.errno, sqlState: err.sqlState, sqlMessage: err.sqlMessage
//     });
//     const status = err?.sqlState === '45000' ? 400 : (err?.errno === 1305 ? 500 : 500);
//     return res.status(status).json({
//       error: 'Gagal mencari event',
//       detail: err.sqlMessage || err.message
//     });
//   }
// });

// // Post/api_sp_CariEvent
// app.post('/api/events/search', async (req, res) => {
//   const keyword = (req.body?.keyword ?? '').trim();
//   if (!keyword) {
//     return res.status(400).json({ error: 'keyword wajib diisi' });
//   }

//   try {
//     const [rows] = await pool.query('CALL CariEvent(?)', [keyword]);
//     const data = Array.isArray(rows) ? rows[0] : rows;

//     return res.status(200).json({
//       message: 'Events fetched',
//       count: Array.isArray(data) ? data.length : 0,
//       data: data
//     });
//   } catch (err) {
//     console.error('CariEvent error:', {
//       code: err.code, errno: err.errno, sqlState: err.sqlState, sqlMessage: err.sqlMessage
//     });
//     const status = err?.sqlState === '45000' ? 400 : (err?.errno === 1305 ? 500 : 500);
//     return res.status(status).json({
//       error: 'Gagal mencari event',
//       detail: err.sqlMessage || err.message
//     });
//   }
// });


// // api_post_admin_buat_tiket
// app.post('/api/admin/tiket', async (req, res) => {
//   const { event_id, kategori, harga_satuan, kuantitas_tersedia, deskripsi } = req.body || {};

//   const conn = await pool.getConnection();
//   try {
//     await conn.query(
//       'CALL AdminBuatTiket(?, ?, ?, ?, ?)',
//       [event_id, kategori, harga_satuan, kuantitas_tersedia, deskripsi ?? null]
//     );

//     const [[{ id }]] = await conn.query('SELECT LAST_INSERT_ID() AS id');
//     const [[data]] = await conn.query('SELECT * FROM tiket WHERE tiket_id = ?', [id]);
    
//     return res.status(201).json({
//       message: 'Tiket berhasil dibuat',
//       data
//     });
//   } catch (error) {
//     console.error('Error AdminBuatTiket:', { code: err.code, errno: err.errno, sqlState: err.sqlState, sqlMessage: err.sqlMessage });
//     return res.status(500).json({
//       error: 'Internal Server Error'
//     });
//   } finally {
//     conn.release();
//   }
// });



// // app.post('/api/admin/tiket', async (req, res) => {
// //     let {event_id, kategori, harga_satuan, kuantitas_tersedia, deskripsi} = req.body || {};

// //     // validasi basic
// //     if (event_id == null || !kategori || harga_satuan == null || kuantitas_tersedia == null) {
// //         return res.status(400).json({
// //             error: 'event_id, kategori, harga_satuan, kuantitas_tersedia wajib diisi'
// //         });
// //     }

// //     // casting angka
// //     event_id = Number(event_id);
// //     harga_satuan = Number(harga_satuan);
// //     kuantitas_tersedia = Number(kuantitas_tersedia);

// //     if (
// //         Number.isNaN(event_id) ||
// //         Number.isNaN(harga_satuan) ||
// //         Number.isNaN(kuantitas_tersedia) ||
// //         harga_satuan < 0 ||
// //         kuantitas_tersedia <0 
// //     )
// // })


// // app.post('/api/transaksi', async (req, res) => {
// //     const { id_pelanggan, id_menu, metode_pembayaran, diskon, pajak } = req.body;

// //     try {
// //         const result = await pool.query(
// //             'Call sp_buat_transaksi(?, ?, ?, ?, ?)',
// //             [id_pelanggan, id_menu, metode_pembayaran, diskon, pajak]
// //         );
        
// //         // 
// //         const rows = result[0];

// //         const data = rows[0];

// //         return res.status(201).json({
// //             message: 'Transaksi berhasil dibuat',
// //         });
// //     }catch (error) {
// //         console.error(error);
// //         return res.status(500).json({
// //             error: "Internal Server Error"
// //         });
 


// // app.post('/api/tiket', async (req, res) => {
// //     const { event_id, kategori, harga_satuan, kuantitas_tersedia, deskripsi

// // const PORT = process.env.PORT || 3000;
// // app.listen(PORT, () => {
// //     console.log(`Server is running on http://localhost:` + PORT);
// // });

// const PORT = process.env.PORT || 3000;
// app.listen(PORT, () => {
//     console.log(`Server is running on http://localhost:` + PORT);
// });


// Admin: Laporan penjualan per periode -> sp_admin_laporan_penjualan_periode
// app.get('/api/admin/penjualan/periode', async (req, res) => {
//   const { tanggal_mulai, tanggal_selesai } = req.query || {};

//   if (!tanggal_mulai || !tanggal_selesai) {
//     return res.status(400).json({
//       success: false,
//       message: 'tanggal_mulai dan tanggal_selesai wajib diisi (YYYY-MM-DD)',
//     });
//   }

//   try {
//     const [rows] = await adminPool.query(
//       'CALL sp_admin_laporan_penjualan_periode(?, ?)',
//       [tanggal_mulai, tanggal_selesai]
//     );

//     const data = rows[0] || [];

//     return res.json({
//       success: true,
//       count: data.length,
//       data,
//     });
//   } catch (error) {
//     const status = error.sqlState === '45000' ? 400 : 500;
//     return res.status(status).json({
//       success: false,
//       message: error.sqlMessage || error.message,
//     });
//   }
// });

// -- Melihat penjualan per periode (pakau view)
// DELIMITER $$

// CREATE PROCEDURE sp_admin_laporan_penjualan_periode (
//     IN p_tanggal_mulai DATE,
//     IN p_tanggal_selesai DATE
// )
// BEGIN
//     DECLARE exit handler FOR SQLEXCEPTION
//     BEGIN
//         ROLLBACK;
//     END;

//     START TRANSACTION;

//     SELECT
//         vw_penjualan_per_event.event_id,
//         vw_penjualan_per_event.nama_event,
//         vw_penjualan_per_event.total_tiket_terjual,
//         vw_penjualan_per_event.total_penjualan,
//         events.tanggal_event
//     FROM vw_penjualan_per_event
//     JOIN events
//       ON vw_penjualan_per_event.event_id = events.event_id
//     WHERE events.tanggal_event BETWEEN p_tanggal_mulai AND p_tanggal_selesai
//     ORDER BY
//         events.tanggal_event,
//         vw_penjualan_per_event.nama_event;

//     COMMIT;
// END$$

// DELIMITER ;

