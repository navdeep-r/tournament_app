require('dotenv').config();

const http = require('http');
const app = require('./app');
const db = require('./config/db');
const { redis, redisSubscriber } = require('./config/redis');
const WebSocketManager = require('./features/liveboard/ws.manager');
const LiveboardService = require('./features/liveboard/liveboard.service');
const logger = require('./core/utils/logger');

const server = http.createServer(app);

// WebSocket + liveboard setup
const liveboardService = new LiveboardService({ query: db.query });
const wsManager = new WebSocketManager(server, redisSubscriber, redis, liveboardService);
app.set('wsManager', wsManager);

// Start background jobs
require('./jobs/tournamentStatus.job').startJobs();

// Start listening
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  logger.info('Server running', { port: PORT, env: process.env.NODE_ENV });
  logger.info(`WebSocket ready at ws://localhost:${PORT}/ws/tournament/:id`);
});

// Graceful shutdown
async function shutdown(signal) {
  logger.info('Shutdown initiated', { signal });
  server.close(async () => {
    try {
      await db.pool.end();
      await redis.quit();
      await redisSubscriber.quit();
      logger.info('Graceful shutdown complete');
      process.exit(0);
    } catch (err) {
      logger.error('Error during shutdown', { err: err.message });
      process.exit(1);
    }
  });

  // Force shutdown after 10s
  setTimeout(() => {
    logger.error('Forced shutdown after timeout');
    process.exit(1);
  }, 10000);
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT',  () => shutdown('SIGINT'));

process.on('uncaughtException', (err) => {
  logger.error('Uncaught exception', { err: err.message, stack: err.stack });
  if (process.env.NODE_ENV === 'production') shutdown('uncaughtException');
  else process.exit(1);
});

process.on('unhandledRejection', (reason) => {
  logger.error('Unhandled rejection', { reason: String(reason) });
});
