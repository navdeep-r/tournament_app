ALTER TABLE tournaments
ADD COLUMN IF NOT EXISTS referral_codes JSONB NOT NULL DEFAULT '[]'::jsonb;

ALTER TABLE participants
ADD COLUMN IF NOT EXISTS referral_code VARCHAR(32),
ADD COLUMN IF NOT EXISTS discount_percent INTEGER NOT NULL DEFAULT 0 CHECK (discount_percent >= 0 AND discount_percent <= 100),
ADD COLUMN IF NOT EXISTS discount_amount_paise INTEGER NOT NULL DEFAULT 0 CHECK (discount_amount_paise >= 0),
ADD COLUMN IF NOT EXISTS amount_paid_paise INTEGER NOT NULL DEFAULT 0 CHECK (amount_paid_paise >= 0);
