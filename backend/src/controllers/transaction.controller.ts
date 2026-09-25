import { desc, eq, and, sql } from 'drizzle-orm';
import type { Response } from 'express';
import { db } from '../db';
import { nextId } from '../db/id';
import { budgets, categories, transactions } from '../db/schema';
import { asyncHandler, HttpError } from '../middleware/error';
import type { AuthRequest } from '../middleware/auth';
import { isValidDate, requireFields, requireMonthYear, requireStringId } from '../utils/validate';

const TX_ID_RE = /^transaction\d{3,}$/;

function txJson(row: {
  id: string;
  type: string;
  amount: number;
  source: string;
  note: string | null;
  date: string;
  created_at: Date;
  categoryId: number;
  catName: string;
  catIcon: string;
}) {
  return {
    id: row.id,
    categoryId: row.categoryId,
    categoryName: row.catName,
    categoryIcon: row.catIcon,
    type: row.type,
    amount: row.amount,
    source: row.source,
    note: row.note,
    date: row.date,
    createdAt: row.created_at,
  };
}

const joined = {
  id: transactions.id,
  categoryId: transactions.categoryId,
  type: transactions.type,
  amount: transactions.amount,
  source: transactions.source,
  note: transactions.note,
  date: transactions.date,
  created_at: transactions.createdAt,
  catName: categories.name,
  catIcon: categories.icon,
};

const txIdOrder = desc(sql`SUBSTRING(${transactions.id} FROM '[0-9]+$')::int`);

export const listTransactions = asyncHandler(async (req: AuthRequest, res: Response) => {
  const recent = Number(req.query.recent);
  const conditions = [eq(transactions.userId, req.userId!)];

  if (Number.isInteger(recent) && recent > 0) {
    const rows = await db
      .select(joined)
      .from(transactions)
      .innerJoin(categories, eq(transactions.categoryId, categories.id))
      .where(and(...conditions))
      .orderBy(desc(transactions.date), txIdOrder)
      .limit(recent);
    res.json({ transactions: rows.map(txJson) });
    return;
  }

  const { month, year } = requireMonthYear(req.query.month, req.query.year);
  const categoryId = req.query.categoryId ? Number(req.query.categoryId) : null;
  const type = req.query.type ? String(req.query.type) : null;

  conditions.push(
    sql`EXTRACT(MONTH FROM ${transactions.date}::date) = ${month}`,
    sql`EXTRACT(YEAR FROM ${transactions.date}::date) = ${year}`,
  );
  if (categoryId) conditions.push(eq(transactions.categoryId, categoryId));
  if (type === 'income' || type === 'expense') conditions.push(eq(transactions.type, type));

  const rows = await db
    .select(joined)
    .from(transactions)
    .innerJoin(categories, eq(transactions.categoryId, categories.id))
    .where(and(...conditions))
    .orderBy(desc(transactions.date), txIdOrder);

  res.json({ transactions: rows.map(txJson) });
});

async function assertOwnCategory(userId: string, categoryId: number) {
  const [cat] = await db
    .select()
    .from(categories)
    .where(
      and(
        eq(categories.id, categoryId),
        sql`(${categories.userId} IS NULL OR ${categories.userId} = ${userId})`,
      ),
    );
  if (!cat) throw new HttpError(404, 'Kategori tidak ditemukan');
  return cat;
}

export const createTransaction = asyncHandler(async (req: AuthRequest, res: Response) => {
  const body = req.body as Record<string, unknown>;
  requireFields(body, ['type', 'amount', 'categoryId', 'date']);

  const type = String(body.type);
  if (type !== 'income' && type !== 'expense') throw new HttpError(400, 'Tipe tidak valid');

  const amount = Number(body.amount);
  if (!Number.isInteger(amount) || amount <= 0) throw new HttpError(400, 'Nominal harus lebih dari 0');

  const categoryId = Number(body.categoryId);
  const cat = await assertOwnCategory(req.userId!, categoryId);
  if (cat.type !== type) throw new HttpError(400, 'Kategori tidak sesuai tipe transaksi');

  const date = String(body.date);
  if (!isValidDate(date)) throw new HttpError(400, 'Format tanggal harus YYYY-MM-DD');

  const source = body.source ? String(body.source) : 'Tunai';
  if (!['Tunai', 'Bank', 'E-wallet'].includes(source)) {
    throw new HttpError(400, 'Sumber dana tidak valid');
  }
  const note = body.note ? String(body.note).trim().slice(0, 300) : null;

  const id = await nextId('transactions');
  const [row] = await db
    .insert(transactions)
    .values({ id, userId: req.userId!, categoryId, type, amount, source, note, date })
    .returning();

  res.status(201).json({
    transaction: txJson({
      ...row,
      catName: cat.name,
      catIcon: cat.icon,
      created_at: row.createdAt,
    }),
  });
});

async function getOwnTransaction(userId: string, id: string) {
  const [row] = await db
    .select({ id: transactions.id, userId: transactions.userId })
    .from(transactions)
    .where(eq(transactions.id, id));
  if (!row || row.userId !== userId) throw new HttpError(404, 'Transaksi tidak ditemukan');
  return row;
}

export const updateTransaction = asyncHandler(async (req: AuthRequest, res: Response) => {
  const id = requireStringId(req.params.id, TX_ID_RE);
  await getOwnTransaction(req.userId!, id);

  const body = req.body as Record<string, unknown>;
  const updates: Record<string, unknown> = {};

  if (body.type !== undefined) {
    if (body.type !== 'income' && body.type !== 'expense') throw new HttpError(400, 'Tipe tidak valid');
    updates.type = body.type;
  }
  if (body.amount !== undefined) {
    const amount = Number(body.amount);
    if (!Number.isInteger(amount) || amount <= 0) throw new HttpError(400, 'Nominal harus lebih dari 0');
    updates.amount = amount;
  }
  if (body.date !== undefined) {
    const date = String(body.date);
    if (!isValidDate(date)) throw new HttpError(400, 'Format tanggal harus YYYY-MM-DD');
    updates.date = date;
  }
  if (body.source !== undefined) {
    const source = String(body.source);
    if (!['Tunai', 'Bank', 'E-wallet'].includes(source)) throw new HttpError(400, 'Sumber dana tidak valid');
    updates.source = source;
  }
  if (body.note !== undefined) updates.note = body.note ? String(body.note).trim().slice(0, 300) : null;

  if (body.categoryId !== undefined) {
    const categoryId = Number(body.categoryId);
    const cat = await assertOwnCategory(req.userId!, categoryId);
    const type = String(updates.type ?? body.type ?? 'expense');
    if (cat.type !== type) throw new HttpError(400, 'Kategori tidak sesuai tipe transaksi');
    updates.categoryId = categoryId;
  }

  if (Object.keys(updates).length === 0) throw new HttpError(400, 'Tidak ada perubahan');

  const [row] = await db
    .update(transactions)
    .set(updates)
    .where(eq(transactions.id, id))
    .returning();

  const [cat] = await db
    .select({ name: categories.name, icon: categories.icon })
    .from(categories)
    .where(eq(categories.id, row.categoryId));

  res.json({
    transaction: txJson({
      ...row,
      catName: cat.name,
      catIcon: cat.icon,
      created_at: row.createdAt,
    }),
  });
});

export const deleteTransaction = asyncHandler(async (req: AuthRequest, res: Response) => {
  const id = requireStringId(req.params.id, TX_ID_RE);
  await getOwnTransaction(req.userId!, id);
  await db.delete(transactions).where(eq(transactions.id, id));
  res.json({ ok: true });
});

export const summary = asyncHandler(async (req: AuthRequest, res: Response) => {
  const { month, year } = requireMonthYear(req.query.month, req.query.year);

  const [balanceRow] = await db
    .select({
      income: sql<number>`COALESCE(SUM(CASE WHEN ${transactions.type} = 'income' THEN ${transactions.amount} ELSE 0 END), 0)`,
      expense: sql<number>`COALESCE(SUM(CASE WHEN ${transactions.type} = 'expense' THEN ${transactions.amount} ELSE 0 END), 0)`,
    })
    .from(transactions)
    .where(eq(transactions.userId, req.userId!));

  const [monthRow] = await db
    .select({
      income: sql<number>`COALESCE(SUM(CASE WHEN ${transactions.type} = 'income' THEN ${transactions.amount} ELSE 0 END), 0)`,
      expense: sql<number>`COALESCE(SUM(CASE WHEN ${transactions.type} = 'expense' THEN ${transactions.amount} ELSE 0 END), 0)`,
    })
    .from(transactions)
    .where(
      and(
        eq(transactions.userId, req.userId!),
        sql`EXTRACT(MONTH FROM ${transactions.date}::date) = ${month}`,
        sql`EXTRACT(YEAR FROM ${transactions.date}::date) = ${year}`,
      ),
    );

  const [budget] = await db
    .select()
    .from(budgets)
    .where(
      and(
        eq(budgets.userId, req.userId!),
        eq(budgets.month, month),
        eq(budgets.year, year),
        sql`${budgets.categoryId} IS NULL`,
      ),
    );

  const target = Number(budget?.amount ?? 0);
  const used = Number(monthRow.expense);
  const remaining = Math.max(target - used, 0);
  const percent = target > 0 ? used / target : 0;

  res.json({
    balance: Number(balanceRow.income) - Number(balanceRow.expense),
    monthIncome: Number(monthRow.income),
    monthExpense: Number(monthRow.expense),
    budget: { target, used, remaining, percent },
  });
});
