import { relations } from 'drizzle-orm';
import {
  date,
  integer,
  pgEnum,
  pgTable,
  serial,
  text,
  timestamp,
  varchar,
} from 'drizzle-orm/pg-core';

export const txTypeEnum = pgEnum('tx_type', ['income', 'expense']);
export const categoryTypeEnum = pgEnum('category_type', ['income', 'expense']);

export const users = pgTable('users', {
  id: varchar('id', { length: 32 }).primaryKey(),
  name: varchar('name', { length: 100 }).notNull(),
  email: varchar('email', { length: 255 }).notNull().unique(),
  passwordHash: text('password_hash').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
});

export const categories = pgTable('categories', {
  id: serial('id').primaryKey(),
  name: varchar('name', { length: 60 }).notNull(),
  type: categoryTypeEnum('type').notNull(),
  icon: varchar('icon', { length: 40 }).notNull(),
  userId: varchar('user_id', { length: 32 }).references(() => users.id, {
    onDelete: 'cascade',
  }),
});

export const transactions = pgTable('transactions', {
  id: varchar('id', { length: 32 }).primaryKey(),
  userId: varchar('user_id', { length: 32 })
    .notNull()
    .references(() => users.id, { onDelete: 'cascade' }),
  categoryId: integer('category_id')
    .notNull()
    .references(() => categories.id, { onDelete: 'restrict' }),
  type: txTypeEnum('type').notNull(),
  amount: integer('amount').notNull(),
  source: varchar('source', { length: 40 }).notNull().default('Tunai'),
  note: text('note'),
  date: date('date').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
});

export const budgets = pgTable('budgets', {
  id: varchar('id', { length: 32 }).primaryKey(),
  userId: varchar('user_id', { length: 32 })
    .notNull()
    .references(() => users.id, { onDelete: 'cascade' }),
  categoryId: integer('category_id').references(() => categories.id, {
    onDelete: 'cascade',
  }),
  month: integer('month').notNull(),
  year: integer('year').notNull(),
  amount: integer('amount').notNull(),
});

export const usersRelations = relations(users, ({ many }) => ({
  transactions: many(transactions),
  budgets: many(budgets),
}));

export const categoriesRelations = relations(categories, ({ many }) => ({
  transactions: many(transactions),
}));

export const transactionsRelations = relations(transactions, ({ one }) => ({
  user: one(users, { fields: [transactions.userId], references: [users.id] }),
  category: one(categories, {
    fields: [transactions.categoryId],
    references: [categories.id],
  }),
}));

export const budgetsRelations = relations(budgets, ({ one }) => ({
  user: one(users, { fields: [budgets.userId], references: [users.id] }),
  category: one(categories, { fields: [budgets.categoryId], references: [categories.id] }),
}));

export type User = typeof users.$inferSelect;
export type Category = typeof categories.$inferSelect;
export type Transaction = typeof transactions.$inferSelect;
export type Budget = typeof budgets.$inferSelect;
