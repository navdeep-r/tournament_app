const winston = require('winston');

const isDevelopment = process.env.NODE_ENV !== 'production';

const formats = isDevelopment
  ? winston.format.combine(
      winston.format.colorize(),
      winston.format.timestamp(),
      winston.format.printf(({ timestamp, level, message, ...meta }) => {
        const metaStr = Object.keys(meta).length ? ' ' + JSON.stringify(meta) : '';
        return `${timestamp} [${level}]: ${message}${metaStr}`;
      })
    )
  : winston.format.combine(
      winston.format.timestamp(),
      winston.format.json()
    );

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: formats,
  transports: [new winston.transports.Console()],
});

module.exports = logger;
