require('dotenv').config();
const fs = require('fs');
const path = require('path');
const { Pool } = require('pg');

async function seed() {
  const pool = new Pool({ connectionString: process.env.DATABASE_URL });
  try {
    const sql = fs.readFileSync(path.join(__dirname, '../seeds/dev_seed.sql'), 'utf8');
    console.log('Running seed...');
    await pool.query(sql);
    console.log('✓ Seed completed successfully.');
  } catch (err) {
    console.error('Seed failed:', err.message);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

seed();
