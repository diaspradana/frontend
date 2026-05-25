const dotenv = require('c:\\Users\\Dias Pradana\\Documents\\Project Flutter\\Project_RPL\\backend\\node_modules\\dotenv');
dotenv.config({ path: 'c:\\Users\\Dias Pradana\\Documents\\Project Flutter\\Project_RPL\\backend\\.env' });

const pool = require('c:\\Users\\Dias Pradana\\Documents\\Project Flutter\\Project_RPL\\backend\\config\\db');

async function runSetup() {
  try {
    // 1. Create table tagihan_berkala if not exists
    await pool.query(`
      CREATE TABLE IF NOT EXISTS tagihan_berkala (
        id INT AUTO_INCREMENT PRIMARY KEY,
        id_warga INT NOT NULL,
        bulan VARCHAR(7) NOT NULL,
        jumlah DECIMAL(15,2) NOT NULL DEFAULT 50000.00,
        status ENUM('lunas', 'belum_lunas') NOT NULL DEFAULT 'belum_lunas',
        tanggal_bayar DATE DEFAULT NULL,
        denda DECIMAL(15,2) NOT NULL DEFAULT 0.00,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (id_warga) REFERENCES warga(id) ON DELETE CASCADE,
        UNIQUE KEY unique_warga_bulan (id_warga, bulan)
      )
    `);
    console.log('tagihan_berkala table created or verified.');

    // 2. Fetch warga IDs
    const [wargas] = await pool.query('SELECT id, nama, username FROM warga');
    console.log('Available wargas:', wargas);

    // Clear existing tagihan_berkala entries
    await pool.query('DELETE FROM tagihan_berkala');
    console.log('Cleared existing tagihan_berkala data.');

    // 3. Seed test bills for all wargas
    for (const warga of wargas) {
      // Bill 1: February 2026 - Lunas (paid late on 2026-02-06, 3 days late, denda Rp 6.000)
      await pool.query(
        "INSERT INTO tagihan_berkala (id_warga, bulan, jumlah, status, tanggal_bayar, denda) VALUES (?, '2026-02', 50000.00, 'lunas', '2026-02-06', 6000.00)",
        [warga.id]
      );

      // Bill 2: March 2026 - Lunas (paid on-time on 2026-03-02, denda Rp 0)
      await pool.query(
        "INSERT INTO tagihan_berkala (id_warga, bulan, jumlah, status, tanggal_bayar, denda) VALUES (?, '2026-03', 50000.00, 'lunas', '2026-03-02', 0.00)",
        [warga.id]
      );

      // Bill 3: April 2026 - Belum Lunas (due 2026-04-03, unpaid, dynamic denda computed as of 2026-05-24)
      await pool.query(
        "INSERT INTO tagihan_berkala (id_warga, bulan, jumlah, status, tanggal_bayar, denda) VALUES (?, '2026-04', 50000.00, 'belum_lunas', NULL, 0.00)",
        [warga.id]
      );

      // Bill 4: May 2026 - Belum Lunas (due 2026-05-03, unpaid, dynamic denda computed as of 2026-05-24)
      await pool.query(
        "INSERT INTO tagihan_berkala (id_warga, bulan, jumlah, status, tanggal_bayar, denda) VALUES (?, '2026-05', 50000.00, 'belum_lunas', NULL, 0.00)",
        [warga.id]
      );
    }

    console.log('Seeded tagihan_berkala successfully for all warga.');

    // 4. Verify data
    const [tagihanRows] = await pool.query('SELECT t.*, w.nama FROM tagihan_berkala t JOIN warga w ON t.id_warga = w.id');
    console.log('Current tagihan_berkala data:', tagihanRows);

    process.exit(0);
  } catch (err) {
    console.error('Error during setup:', err);
    process.exit(1);
  }
}

runSetup();
