const cron = require('node-cron');
const db = require('../config/db');
const logger = require('../core/utils/logger');

const openRegistrations = async () => {
  try {
    const { rows } = await db.query(
      `UPDATE tournaments
       SET status = 'registration_open', updated_at = NOW()
       WHERE status = 'upcoming'
         AND registration_opens_at IS NOT NULL
         AND registration_opens_at <= NOW()
       RETURNING id, name`
    );
    if (rows.length > 0) {
      logger.info('Auto-opened registration', { tournaments: rows.map((r) => r.name) });
    }
  } catch (err) {
    logger.error('Job error: openRegistrations', { err: err.message });
  }
};

const closeRegistrations = async () => {
  try {
    const { rows } = await db.query(
      `UPDATE tournaments
       SET status = 'registration_closed', updated_at = NOW()
       WHERE status = 'registration_open'
         AND registration_closes_at IS NOT NULL
         AND registration_closes_at <= NOW()
       RETURNING id, name`
    );
    if (rows.length > 0) {
      logger.info('Auto-closed registration', { tournaments: rows.map((r) => r.name) });
    }
  } catch (err) {
    logger.error('Job error: closeRegistrations', { err: err.message });
  }
};

const startJobs = () => {
  // Open registration check — every minute
  cron.schedule('* * * * *', () => {
    logger.debug('Running job: openRegistrations');
    openRegistrations();
  });

  // Close registration check — every minute, staggered 30s
  setTimeout(() => {
    cron.schedule('* * * * *', () => {
      logger.debug('Running job: closeRegistrations');
      closeRegistrations();
    });
  }, 30000);

  logger.info('Background jobs started');
};

module.exports = { startJobs };
