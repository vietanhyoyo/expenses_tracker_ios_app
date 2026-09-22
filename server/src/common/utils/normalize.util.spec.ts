import {
  cleanText,
  normalizeCategoryName,
  normalizeEmail,
} from './normalize.util';

describe('normalization utilities', () => {
  it('normalizes email casing and surrounding whitespace', () => {
    expect(normalizeEmail('  User@Example.COM ')).toBe('user@example.com');
  });

  it('normalizes category whitespace and casing', () => {
    expect(normalizeCategoryName('  Health   Care ')).toBe('health care');
  });

  it('trims public text fields', () => {
    expect(cleanText('  lunch  ')).toBe('lunch');
  });
});
