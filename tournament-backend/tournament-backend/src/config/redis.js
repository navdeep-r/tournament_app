const Redis = require('ioredis');
const logger = require('../core/utils/logger');

const createRedisClient = (name) => {
  const client = new Redis(process.env.REDIS_URL, {
    maxRetriesPerRequest: 3,
    retryStrategy(times) {
      if (times > 10) return null;
      return Math.min(times * 100, 3000);
    },
  });

  client.on('connect', () => logger.info(`Redis ${name} connected`));
  client.on('error', (err) => logger.error(`Redis ${name} error`, { err: err.message }));
  client.on('reconnecting', () => logger.warn(`Redis ${name} reconnecting`));

  return client;
};

const redis = createRedisClient('main');
const redisSubscriber = createRedisClient('subscriber');

module.exports = { redis, redisSubscriber };
