import { and, desc, eq, sql } from 'drizzle-orm';
import type { Response } from 'express';
import { db } from '../db';
import { budgets, categories, transactions } from '../db/schema';
import { asyncHandler, HttpError } from '../middleware/error';
import type { AuthRequest } from '../middleware/auth';

const PALETTE = [
  { color: '#10B981', iconBg: 'rgba(16,185,129,0.12)' },
  { color: '#0F172A', iconBg: 'rgba(15,23,42,0.10)' },
  { color: '#F59E0B', iconBg: 'rgba(245,158,11,0.12)' },
  { color: '#8B5CF6', iconBg: 'rgba(139,92,246,0.12)' },
  { color: '#F43F5E', iconBg: 'rgba(244,63,94,0.12)' },
  { color: '#0EA5E9', iconBg: 'rgba(14,165,233,0.12)' },
  { color: '#64748B', iconBg: 'rgba(100,116,139,0.12)' },
];

function rangeFor(period: string): { start: Date; end: Date } {
  const now = new Date();
  const startOfDay = (d: Date) =>
    new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()));

  if (period === 'week') {
    const start = startOfDay(now);
    start.setUTCDate(start.getUTCDate() - 6);
    return { start, end: startOfDay(now) };
  }
  if (period === 'year') {
    return {
      start: new Date(Date.UTC(now.getUTCFullYear(), 0, 1)),
      end: new Date(Date.UTC(now.getUTCFullYear(), 11, 31)),
    };
  }
  if (period === 'month') {
    return {
      start: new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1)),
      end: new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 0)),
    };
  }
  throw new HttpError(400, 'Period harus week, month, atau year');
}

export const getStats = asyncHandler(async (req: AuthRequest, res: Response) => {
  const period = String(req.query.period ?? 'month');
  const { start, end } = rangeFor(period);
  const iso = (d: Date) => d.toISOString().slice(0, 10);

  const userId = req.userId!;

  const [totals] = await db
    .select({
      income: sql<number>`COALESCE(SUM(CASE WHEN ${transactions.type} = 'income' THEN ${transactions.amount} ELSE 0 END), 0)`,
      expense: sql<number>`COALESCE(SUM(CASE WHEN ${transactions.type} = 'expense' THEN ${transactions.amount} ELSE 0 END), 0)`,
    })
    .from(transactions)
    .where(eq(transactions.userId, userId));

  const [rangeTotals] = await db
    .select({
      income: sql<number>`COALESCE(SUM(CASE WHEN ${transactions.type} = 'income' THEN ${transactions.amount} ELSE 0 END), 0)`,
      expense: sql<number>`COALESCE(SUM(CASE WHEN ${transactions.type} = 'expense' THEN ${transactions.amount} ELSE 0 END), 0)`,
    })
    .from(transactions)
    .where(
      and(
        eq(transactions.userId, userId),
        sql`${transactions.date}::date >= ${iso(start)}::date`,
        sql`${transactions.date}::date <= ${iso(end)}::date`,
      ),
    );

  const byCatRows = await db
    .select({
      categoryId: transactions.categoryId,
      name: categories.name,
      icon: categories.icon,
      amount: sql<number>`COALESCE(SUM(${transactions.amount}), 0)`,
    })
    .from(transactions)
    .innerJoin(categories, eq(transactions.categoryId, categories.id))
    .where(
      and(
        eq(transactions.userId, userId),
        eq(transactions.type, 'expense'),
        sql`${transactions.date}::date >= ${iso(start)}::date`,
        sql`${transactions.date}::date <= ${iso(end)}::date`,
      ),
    )
    .groupBy(transactions.categoryId, categories.name, categories.icon)
    .orderBy(desc(sql`SUM(${transactions.amount})`));

  const rangeExpense = Number(rangeTotals.expense);
  const byCategory = byCatRows.map((r, i) => ({
    categoryId: r.categoryId,
    name: r.name,
    icon: r.icon,
    amount: Number(r.amount),
    percent: rangeExpense > 0 ? Number(r.amount) / rangeExpense : 0,
    color: PALETTE[i % PALETTE.length].color,
    iconBg: PALETTE[i % PALETTE.length].iconBg,
  }));

  const monthRows = await db
    .select({
      y: sql<number>`EXTRACT(YEAR FROM ${transactions.date}::date)::int`,
      m: sql<number>`EXTRACT(MONTH FROM ${transactions.date}::date)::int`,
      income: sql<number>`COALESCE(SUM(CASE WHEN ${transactions.type} = 'income' THEN ${transactions.amount} ELSE 0 END), 0)`,
      expense: sql<number>`COALESCE(SUM(CASE WHEN ${transactions.type} = 'expense' THEN ${transactions.amount} ELSE 0 END), 0)`,
    })
    .from(transactions)
    .where(eq(transactions.userId, userId))
    .groupBy(sql`EXTRACT(YEAR FROM ${transactions.date}::date)`, sql`EXTRACT(MONTH FROM ${transactions.date}::date)`)
    .orderBy(desc(sql`EXTRACT(YEAR FROM ${transactions.date}::date)`), desc(sql`EXTRACT(MONTH FROM ${transactions.date}::date)`))
    .limit(4);

  const LABELS = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
  const monthly = monthRows
    .map((r) => ({
      label: LABELS[Number(r.m) - 1],
      income: Number(r.income),
      expense: Number(r.expense),
    }))
    .reverse();

  const avgSavings =
    monthly.length > 0
      ? Math.round(monthly.reduce((s, m) => s + (m.income - m.expense), 0) / monthly.length)
      : 0;

  const now = new Date();
  const curMonth = now.getMonth() + 1;
  const curYear = now.getFullYear();

  const [budgetRow] = await db
    .select({ amount: budgets.amount })
    .from(budgets)
    .where(
      and(
        eq(budgets.userId, userId),
        eq(budgets.month, curMonth),
        eq(budgets.year, curYear),
        sql`${budgets.categoryId} IS NULL`,
      ),
    );

  const budgetTarget = budgetRow?.amount ?? 0;
  const [monthExpenseRow] = await db
    .select({
      expense: sql<number>`COALESCE(SUM(CASE WHEN ${transactions.type} = 'expense' THEN ${transactions.amount} ELSE 0 END), 0)`,
    })
    .from(transactions)
    .where(
      and(
        eq(transactions.userId, userId),
        sql`EXTRACT(MONTH FROM ${transactions.date}::date) = ${curMonth}`,
        sql`EXTRACT(YEAR FROM ${transactions.date}::date) = ${curYear}`,
      ),
    );
  const budgetUsed = Number(monthExpenseRow.expense);
  const budgetPercent = budgetTarget > 0 ? budgetUsed / budgetTarget : 0;

  const [prevMonthExpense] = await db
    .select({
      expense: sql<number>`COALESCE(SUM(CASE WHEN ${transactions.type} = 'expense' THEN ${transactions.amount} ELSE 0 END), 0)`,
    })
    .from(transactions)
    .where(
      and(
        eq(transactions.userId, userId),
        sql`EXTRACT(MONTH FROM ${transactions.date}::date) = ${curMonth === 1 ? 12 : curMonth - 1}`,
        sql`EXTRACT(YEAR FROM ${transactions.date}::date) = ${curMonth === 1 ? curYear - 1 : curYear}`,
      ),
    );

  res.json({
    balance: Number(totals.income) - Number(totals.expense),
    income: Number(rangeTotals.income),
    expense: rangeExpense,
    byCategory,
    monthly,
    avgSavings,
    savingsRate:
      Number(rangeTotals.income) > 0
        ? (Number(rangeTotals.income) - rangeExpense) / Number(rangeTotals.income)
        : 0,
    budget: {
      target: budgetTarget,
      used: budgetUsed,
      remaining: Math.max(budgetTarget - budgetUsed, 0),
      percent: budgetPercent,
    },
    insight: buildInsight(byCategory, budgetPercent, rangeExpense, Number(prevMonthExpense.expense)),
  });
});

function buildInsight(
  byCategory: { name: string; amount: number; percent: number }[],
  budgetPercent: number,
  expense: number,
  prevExpense: number,
): string {
  if (expense === 0 && prevExpense === 0) {
    return 'Belum ada pengeluaran pada periode ini. Mulai catat transaksi agar insight muncul.';
  }
  if (budgetPercent >= 0.8) {
    return `Hati-hati! Budget bulan ini sudah terpakai ${Math.round(budgetPercent * 100)}%. Kurangi pengeluaran non-esensial ya.`;
  }
  if (byCategory.length === 0) {
    return 'Belum ada pengeluaran pada periode ini.';
  }
  const top = byCategory[0];
  if (prevExpense > 0) {
    const delta = Math.round(((prevExpense - expense) / prevExpense) * 100);
    if (delta > 0) {
      return `Pengeluaranmu ${delta}% lebih hemat dari bulan lalu! Kategori terbesar: ${top.name} (${Math.round(top.percent * 100)}% dari total).`;
    }
    if (delta < 0) {
      return `Pengeluaranmu naik ${Math.abs(delta)}% dari bulan lalu. Perhatikan kategori ${top.name} yang paling besar.`;
    }
  }
  return `Kategori pengeluaran terbesarmu: ${top.name} (${Math.round(top.percent * 100)}% dari total). Tetap jaga batas budget bulananmu.`;
}
