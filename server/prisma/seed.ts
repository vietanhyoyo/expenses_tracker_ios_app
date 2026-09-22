import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();
const seedUser = {
  email: 'user@gmail.com',
  password: 'User123456@',
};
const defaultCategories = [
  'Food',
  'Transportation',
  'Entertainment',
  'Utilities',
  'Shopping',
  'Health',
  'Education',
  'Other',
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

  for (const name of defaultCategories) {
    const normalizedName = name.toLocaleLowerCase('en-US');
    const existing = await prisma.category.findFirst({
      where: { userId: null, normalizedName },
    });

    if (existing) {
      await prisma.category.update({
        where: { id: existing.id },
        data: { name, isDefault: true },
      });
    } else {
      await prisma.category.create({
        data: { name, normalizedName, userId: null, isDefault: true },
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
