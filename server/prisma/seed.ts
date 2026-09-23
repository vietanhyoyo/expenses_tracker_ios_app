import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();
const seedUser = {
  email: 'user@gmail.com',
  password: 'user123456@',
};
const defaultCategories = [
  { name: 'Ăn uống', type: 'expense' as const },
  { name: 'Di chuyển', type: 'expense' as const },
  { name: 'Giải trí', type: 'expense' as const },
  { name: 'Tiện ích', type: 'expense' as const },
  { name: 'Mua sắm', type: 'expense' as const },
  { name: 'Sức khỏe', type: 'expense' as const },
  { name: 'Giáo dục', type: 'expense' as const },
  { name: 'Khác', type: 'expense' as const },
  { name: 'Lương', type: 'income' as const },
  { name: 'Thưởng', type: 'income' as const },
  { name: 'Đầu tư', type: 'income' as const },
  { name: 'Thu nhập khác', type: 'income' as const },
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
        data: { name: category.name, type: category.type, isDefault: true },
      });
    } else {
      await prisma.category.create({
        data: {
          name: category.name,
          normalizedName,
          type: category.type,
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
