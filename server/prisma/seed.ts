import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();
const seedUser = {
  email: 'user@gmail.com',
  password: 'User123456@',
};
const defaultCategories = [
  { name: 'Ăn uống', type: 'expense' as const, colorHex: '#FF5D73' },
  { name: 'Di chuyển', type: 'expense' as const, colorHex: '#3B82F6' },
  { name: 'Giải trí', type: 'expense' as const, colorHex: '#EC4899' },
  { name: 'Tiện ích', type: 'expense' as const, colorHex: '#F59E0B' },
  { name: 'Mua sắm', type: 'expense' as const, colorHex: '#A855F7' },
  { name: 'Sức khỏe', type: 'expense' as const, colorHex: '#EF4444' },
  { name: 'Giáo dục', type: 'expense' as const, colorHex: '#14B8A6' },
  { name: 'Khác', type: 'expense' as const, colorHex: '#64748B' },
  { name: 'Lương', type: 'income' as const, colorHex: '#10B981' },
  { name: 'Thưởng', type: 'income' as const, colorHex: '#F59E0B' },
  { name: 'Đầu tư', type: 'income' as const, colorHex: '#0EA5E9' },
  { name: 'Thu nhập khác', type: 'income' as const, colorHex: '#8B5CF6' },
];

async function main(): Promise<void> {
  const saltRounds = Number(process.env.BCRYPT_SALT_ROUNDS ?? 12);
  const passwordHash = await bcrypt.hash(seedUser.password, saltRounds);

  await prisma.user.upsert({
    where: { email: seedUser.email },
    update: { passwordHash },
    create: {
      email: seedUser.email,
      passwordHash,
    },
  });

  for (const category of defaultCategories) {
    const normalizedName = category.name.toLocaleLowerCase('en-US');
    const existing = await prisma.category.findFirst({
      where: { userId: null, normalizedName, type: category.type },
    });

    if (existing) {
      await prisma.category.update({
        where: { id: existing.id },
        data: {
          name: category.name,
          type: category.type,
          colorHex: category.colorHex,
          isDefault: true,
        },
      });
    } else {
      await prisma.category.create({
        data: {
          name: category.name,
          normalizedName,
          type: category.type,
          colorHex: category.colorHex,
          userId: null,
          isDefault: true,
        },
      });
    }
  }
}

main()
  .then(() => prisma.$disconnect())
  .catch(async (error: unknown) => {
    console.error('Failed to seed database', error);
    await prisma.$disconnect();
    process.exit(1);
  });
