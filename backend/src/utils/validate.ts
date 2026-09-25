import { HttpError } from '../middleware/error';

export function requireFields(body: Record<string, unknown>, fields: string[]): void {
  for (const f of fields) {
    const v = body[f];
    if (v === undefined || v === null || v === '') {
      throw new HttpError(400, `Field '${f}' wajib diisi`);
    }
  }
}

export function requireInt(value: unknown, name: string): number {
  const n = Number(value);
  if (!Number.isInteger(n)) throw new HttpError(400, `Field '${name}' harus angka bulat`);
  return n;
}

export function requireStringId(value: unknown, pattern: RegExp): string {
  const s = String(value ?? '');
  if (!pattern.test(s)) throw new HttpError(400, 'Id tidak valid');
  return s;
}

export function requireMonthYear(month: unknown, year: unknown): { month: number; year: number } {
  const m = month === undefined || month === null ? new Date().getMonth() + 1 : Number(month);
  const y = year === undefined || year === null ? new Date().getFullYear() : Number(year);
  if (!(m >= 1 && m <= 12)) throw new HttpError(400, 'Bulan tidak valid');
  if (!(y >= 2000 && y <= 2100)) throw new HttpError(400, 'Tahun tidak valid');
  return { month: m, year: y };
}

const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;

export function isValidDate(d: string): boolean {
  if (!DATE_RE.test(d)) return false;
  const parsed = new Date(`${d}T00:00:00Z`);
  return !Number.isNaN(parsed.getTime());
}
