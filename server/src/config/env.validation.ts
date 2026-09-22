const requiredVariables = [
  'DATABASE_URL',
  'JWT_ACCESS_SECRET',
  'JWT_REFRESH_SECRET',
] as const;

export function validateEnvironment(
  config: Record<string, unknown>,
): Record<string, unknown> {
  for (const key of requiredVariables) {
    if (typeof config[key] !== 'string' || config[key].length < 1) {
      throw new Error(`Environment variable ${key} is required`);
    }
  }
  const saltRounds = Number(config.BCRYPT_SALT_ROUNDS ?? 12);
  if (!Number.isInteger(saltRounds) || saltRounds < 4 || saltRounds > 15) {
    throw new Error('BCRYPT_SALT_ROUNDS must be an integer between 4 and 15');
  }
  return config;
}
