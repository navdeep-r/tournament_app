require('dotenv').config();
const db = require('../src/config/db');

async function removeDummy() {
  try {
    const dummyIds = [
      '00000000-0000-0000-0001-000000000001',
      '00000000-0000-0000-0001-000000000002'
    ];
    
    // Unset current_round_id on tournament to avoid FK constraint when deleting rounds
    await db.query(`UPDATE tournaments SET current_round_id = NULL WHERE id = ANY($1)`, [dummyIds]);
    
    // First remove dependencies
    await db.query(`DELETE FROM participants WHERE tournament_id = ANY($1)`, [dummyIds]);
    await db.query(`DELETE FROM rounds WHERE tournament_id = ANY($1)`, [dummyIds]);
    
    // Remove tournaments
    const result = await db.query(`DELETE FROM tournaments WHERE id = ANY($1) RETURNING *`, [dummyIds]);
    console.log(`Deleted ${result.rowCount} dummy tournaments.`);
  } catch (error) {
    console.error('Error removing dummy tournaments:', error);
  } finally {
    process.exit(0);
  }
}

removeDummy();
