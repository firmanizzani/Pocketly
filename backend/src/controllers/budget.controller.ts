import { asc, eq, and, sql } from 'drizzle-orm';
import type { Response } from 'express';
import { db } from '../db';
import { nextId } from '../db/id';
import { budgets, categories, transactions } from '../db/schema';
import { asyncHandler, HttpError } from '../middleware/error';
import type { AuthRequest } from '../middleware/auth';
import { requireFields, requireMonthYear } from '../utils/validate';

export const listBudgets = asyncHandler(async (req: AuthRequest, res: Response) => {
  const { month, year } = requireMonthYear(req.query.month, req.query.year);

  const rows = await db
    .select({
      id: budgets.id,
      categoryId: budgets.categoryId,
      amount: budgets.amount,
      catName: categories.name,
      catIcon: categories.icon,
    })
    .from(budgets)
    .leftJoin(categories, eq(budgets.categoryId, categories.id))
    .where(
      and(
        eq(budgets.userId, req.userId!),
        eq(budgets.month, month),
        eq(budgets.year, year),
      ),
    )
    .orderBy(asc(budgets.categoryId));

  const spentRows = await db
    .select({
      categoryId: transactions.categoryId,
      total: sql<number>`COALESCE(SUM(${transactions.amount}), 0)`,
    })
    .from(transactions)
    .where(
      and(
        eq(transactions.userId, req.userId!),
        eq(transactions.type, 'expense'),
        sql`EXTRACT(MONTH FROM ${transactions.date}::date) = ${month}`,
        sql`EXTRACT(YEAR FROM ${transactions.date}::date) = ${year}`,
      ),
    )
    .groupBy(transactions.categoryId);

  const spentByCategory = new Map<number, number>(
    spentRows.map((r) => [r.categoryId, Number(r.total)]),
  );
  const totalUsed = [...spentByCategory.values()].reduce((s, v) => s + v, 0);

  const totalRow = rows.find((r) => r.categoryId === null);
  const target = totalRow?.amount ?? 0;

  const items = rows
    .filter((r) => r.categoryId !== null)
    .map((r) => {
      const used = spentByCategory.get(r.categoryId!) ?? 0;
      return {
        id: r.id,
        categoryId: r.categoryId,
        name: r.catName,
        icon: r.catIcon,
        amount: r.amount,
        used,
        percent: r.amount > 0 ? used / r.amount : 0,
      };
    });

  res.json({
    month,
    year,
    total: {
      amount: target,
      used: totalUsed,
      remaining: Math.max(target - totalUsed, 0),
      percent: target > 0 ? totalUsed / target : 0,
    },
    categories: items,
  });
});

export const upsertBudget = asyncHandler(async (req: AuthRequest, res: Response) => {
  const body = req.body as Record<string, unknown>;
  requireFields(body, ['amount', 'month', 'year']);

  const amount = Number(body.amount);
  if (!Number.isInteger(amount) || amount < 0) {
    throw new HttpError(400, 'Nominal budget tidak valid');
  }

  const { month, year } = requireMonthYear(body.month, body.year);
  const categoryId = body.categoryId === null || body.categoryId === undefined
    ? null
    : Number(body.categoryId);

  if (categoryId !== null) {
    const [cat] = await db
      .select()
      .from(categories)
      .where(
        and(
          eq(categories.id, categoryId),
          sql`(${categories.userId} IS NULL OR ${categories.userId} = ${req.userId!})`,
        ),
      );
    if (!cat) throw new HttpError(404, 'Kategori tidak ditemukan');
  }

  const [existing] = await db
    .select()
    .from(budgets)
    .where(
      and(
        eq(budgets.userId, req.userId!),
        eq(budgets.month, month),
        eq(budgets.year, year),
        categoryId === null
          ? sql`${budgets.categoryId} IS NULL`
          : eq(budgets.categoryId, categoryId),
      ),
    );

  if (existing) {
    const [updated] = await db
      .update(budgets)
      .set({ amount })
      .where(eq(budgets.id, existing.id))
      .returning();
    res.json({ budget: updated });
    return;
  }

  const id = await nextId('budgets');
  const [created] = await db
    .insert(budgets)
    .values({ id, userId: req.userId!, categoryId, month, year, amount })
    .returning();
  res.status(201).json({ budget: created });
});
