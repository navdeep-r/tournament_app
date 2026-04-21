const crypto = require('crypto');

const generateOtp = () => {
  return String(crypto.randomInt(100000, 999999));
};

const generateReceipt = () => {
  return 'rcpt_' + crypto.randomBytes(15).toString('base64url').slice(0, 20);
};

module.exports = { generateOtp, generateReceipt };
