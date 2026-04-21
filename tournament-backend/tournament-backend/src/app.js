require('express-async-errors');

const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const compression = require('compression');
const morgan = require('morgan');

const logger = require('./core/utils/logger');
const db = require('./config/db');
const { redis } = require('./config/redis');
const { notFound, errorHandler } = require('./core/middleware/error.middleware');

const app = express();

app.set('trust proxy', 1);

app.use(helmet());
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
  credentials: true,
}));
app.use(compression());
app.use(morgan('combined', { stream: { write: (msg) => logger.info(msg.trim()) } }));
app.use(express.json({ limit: '5mb' }));
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api/auth',        require('./features/auth/auth.routes'));
app.use('/api/tournaments', require('./features/tournaments/tournament.routes'));
app.use('/api/tournaments', require('./features/rounds/round.routes'));
app.use('/api/tournaments', require('./features/participants/participant.routes'));
app.use('/api/participants', require('./features/participants/participant.routes'));
app.use('/api/liveboard',   require('./features/liveboard/liveboard.routes'));
app.use('/api/admin',       require('./features/admin/admin.routes'));

// Health check
app.get('/health', async (req, res) => {
  const dbOk    = await db.query('SELECT 1').then(() => 'ok').catch(() => 'error');
  const redisOk = await redis.ping().then(() => 'ok').catch(() => 'error');
  res.json({
    status: dbOk === 'ok' && redisOk === 'ok' ? 'ok' : 'degraded',
    timestamp: new Date().toISOString(),
    db: dbOk,
    redis: redisOk,
    uptime: process.uptime(),
  });
});

app.use(notFound);
app.use(errorHandler);

module.exports = app;
