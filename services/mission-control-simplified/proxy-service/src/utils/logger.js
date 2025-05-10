/**
 * Logging utility for the proxy service
 * 
 * Creates a standardized logger with consistent formatting and log levels.
 */

const winston = require('winston');

/**
 * Create a logger instance
 * @param {string} [module] - Optional module name for the logger
 * @returns {winston.Logger} - Winston logger instance
 */
function createLogger(module = 'proxy-service') {
  const logger = winston.createLogger({
    level: process.env.LOG_LEVEL || 'info',
    format: winston.format.combine(
      winston.format.timestamp(),
      winston.format.errors({ stack: true }),
      winston.format.json()
    ),
    defaultMeta: { service: 'niche-scout-proxy', module },
    transports: [
      new winston.transports.Console({
        format: winston.format.combine(
          winston.format.colorize(),
          winston.format.printf(({ timestamp, level, message, module, ...meta }) => {
            return `${timestamp} [${level}] [${module}]: ${message} ${
              Object.keys(meta).length ? JSON.stringify(meta, null, 2) : ''
            }`;
          })
        )
      })
    ]
  });

  return logger;
}

module.exports = { createLogger };