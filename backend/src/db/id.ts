import { sql } from 'drizzle-orm';
import { db } from '.';

const PREFIXES = {
  users: 'user',
  transactions: 'transaction',
  budgets: 'budget',
} as const;

export type IdTable = keyof typeof PREFIXES;

export function formatId(prefix: string, n: number): string {
  return `${prefix}${String(n).padStart(3, '0')}`;
}

export function parseIdSeq(id: string): number {
  const m = id.match(/(\d+)$/);
  return m ? Number(m[1]) : 0;
}

/** ID baru = max suffix yang sudah ada + 1, format: user001, transaction001, dst. */
export async function nextId(table: IdTable): Promise<string> {
  const prefix = PREFIXES[table];
  return db.transaction(async (tx) => {
    await tx.execute(
      sql`SELECT pg_advisory_xact_lock(hashtext(${`${table}:next_id`}))`,
    );
    const rows = await tx.execute<{ next: string | number }>(
      sql`SELECT COALESCE(MAX(SUBSTRING(id FROM '[0-9]+$')::int), 0) + 1 AS next
          FROM ${sql.identifier(table)}`,
    );
    const n = Number(rows[0]?.next ?? 1);
    return formatId(prefix, n);
  });
}
