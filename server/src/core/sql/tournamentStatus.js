const buildEffectiveTournamentStatusSql = (alias = 't', nowExpr = 'NOW()') => `
CASE
  WHEN ${alias}.status IN ('draft', 'cancelled', 'completed') THEN ${alias}.status
  WHEN ${alias}.ends_at IS NOT NULL AND ${alias}.ends_at <= ${nowExpr} THEN 'completed'
  WHEN ${alias}.starts_at <= ${nowExpr} THEN 'live'
  WHEN ${alias}.registration_closes_at IS NOT NULL
       AND ${alias}.registration_closes_at <= ${nowExpr} THEN 'registration_closed'
  WHEN ${alias}.registration_opens_at IS NOT NULL
       AND ${alias}.registration_opens_at <= ${nowExpr} THEN 'registration_open'
  ELSE 'upcoming'
END
`;

module.exports = { buildEffectiveTournamentStatusSql };