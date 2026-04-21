const { parsePhoneNumber, isValidPhoneNumber } = require('libphonenumber-js');

const parsePhoneE164 = (phone) => {
  try {
    const cleaned = phone.trim();
    const parsed = parsePhoneNumber(cleaned, 'IN');
    if (!parsed || !parsed.isValid()) return null;
    const e164 = parsed.format('E.164');
    // Must start with +91 followed by 6,7,8,9 for valid Indian mobile
    if (!/^\+91[6-9]\d{9}$/.test(e164)) return null;
    return e164;
  } catch {
    return null;
  }
};

const isValidIndianMobile = (phone) => {
  return parsePhoneE164(phone) !== null;
};

module.exports = { parsePhoneE164, isValidIndianMobile };
