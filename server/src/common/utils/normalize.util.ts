export const normalizeEmail = (email: string): string =>
  email.trim().toLocaleLowerCase('en-US');

export const normalizeCategoryName = (name: string): string =>
  name.trim().replace(/\s+/g, ' ').toLocaleLowerCase('en-US');

export const cleanText = (value: string): string => value.trim();
