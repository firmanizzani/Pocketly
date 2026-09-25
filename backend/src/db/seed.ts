import { eq, isNull, or } from 'drizzle-orm';
import { db } from '.';
import { categories, type Category } from './schema';

const DEFAULTS: { name: string; type: 'income' | 'expense'; icon: string }[] = [
  { name: 'Makan', type: 'expense', icon: 'restaurant' },
  { name: 'Transport', type: 'expense', icon: 'two_wheeler' },
  { name: 'Kuliah', type: 'expense', icon: 'school' },
  { name: 'Hiburan', type: 'expense', icon: 'sports_esports' },
  { name: 'Kos', type: 'expense', icon: 'home' },
  { name: 'Lainnya', type: 'expense', icon: 'more_horiz' },
  { name: 'Orang tua', type: 'income', icon: 'family_restroom' },
  { name: 'Gaji', type: 'income', icon: 'payments' },
  { name: 'Beasiswa', type: 'income', icon: 'school' },
  { name: 'Jualan', type: 'income', icon: 'storefront' },
  { name: 'Lainnya', type: 'income', icon: 'add_circle' },
];

export async function ensureDefaultCategories(): Promise<void> {
  const existing = await db.select({ id: categories.id }).from(categories).limit(1);
  if (existing.length > 0) {
    // Pastikan kategori "Orang tua" ada (untuk DB lama yang sudah ter-seed)
    const orangTua = await db
      .select({ id: categories.id })
      .from(categories)
      .where(eq(categories.name, 'Orang tua'))
      .limit(1);
    if (orangTua.length === 0) {
      await db
        .insert(categories)
        .values({ name: 'Orang tua', type: 'income', icon: 'family_restroom' });
    }
    return;
  }
  await db.insert(categories).values(DEFAULTS);
}

export async function listUserCategories(userId: string): Promise<Category[]> {
  const rows = await db
    .select()
    .from(categories)
    .where(or(eq(categories.userId, userId), isNull(categories.userId)))
    .orderBy(categories.type, categories.id);
  // Pemasukan: "Orang tua" selalu di urutan pertama
  return [
    ...rows.filter((c) => c.type === 'income' && c.name === 'Orang tua'),
    ...rows.filter((c) => !(c.type === 'income' && c.name === 'Orang tua')),
  ];
}
