import bcrypt from 'bcryptjs';
import { eq } from 'drizzle-orm';
import type { Response } from 'express';
import { db } from '../db';
import { nextId } from '../db/id';
import { ensureDefaultCategories } from '../db/seed';
import { users, type User } from '../db/schema';
import { asyncHandler, HttpError } from '../middleware/error';
import { type AuthRequest, signToken } from '../middleware/auth';
import { requireFields } from '../utils/validate';

function userJson(user: User) {
  return { id: user.id, name: user.name, email: user.email };
}

export const register = asyncHandler(async (req, res: Response) => {
  const body = req.body as Record<string, unknown>;
  requireFields(body, ['name', 'email', 'password']);

  const name = String(body.name).trim();
  const email = String(body.email).trim().toLowerCase();
  const password = String(body.password);
  const remember = body.rememberMe !== false;

  if (name.length < 2) throw new HttpError(400, 'Nama minimal 2 karakter');
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) throw new HttpError(400, 'Format email tidak valid');
  if (password.length < 8) throw new HttpError(400, 'Kata sandi minimal 8 karakter');

  const existing = await db.select({ id: users.id }).from(users).where(eq(users.email, email));
  if (existing.length > 0) throw new HttpError(409, 'Email sudah terdaftar');

  const passwordHash = await bcrypt.hash(password, 10);
  const id = await nextId('users');
  const [user] = await db
    .insert(users)
    .values({ id, name, email, passwordHash })
    .returning();

  await ensureDefaultCategories();

  const token = signToken(user.id, remember);
  res.status(201).json({ token, user: userJson(user) });
});

export const login = asyncHandler(async (req, res: Response) => {
  const body = req.body as Record<string, unknown>;
  requireFields(body, ['email', 'password']);

  const email = String(body.email).trim().toLowerCase();
  const password = String(body.password);
  const remember = body.rememberMe === true;

  const [user] = await db.select().from(users).where(eq(users.email, email));
  if (!user) throw new HttpError(401, 'Email atau kata sandi salah');

  const ok = await bcrypt.compare(password, user.passwordHash);
  if (!ok) throw new HttpError(401, 'Email atau kata sandi salah');

  const token = signToken(user.id, remember);
  res.json({ token, user: userJson(user) });
});

export const me = asyncHandler(async (req: AuthRequest, res: Response) => {
  const [user] = await db.select().from(users).where(eq(users.id, req.userId!));
  // 401 (bukan 404) supaya client tahu sesi tidak valid → wajib login ulang.
  if (!user) throw new HttpError(401, 'Sesi tidak valid, silakan login ulang');
  res.json({ user: userJson(user) });
});

export const updateProfile = asyncHandler(async (req: AuthRequest, res: Response) => {
  const body = req.body as Record<string, unknown>;
  const updates: Partial<{ name: string; email: string }> = {};

  if (body.name !== undefined) {
    const name = String(body.name).trim();
    if (name.length < 2) throw new HttpError(400, 'Nama minimal 2 karakter');
    updates.name = name;
  }

  if (body.email !== undefined) {
    const email = String(body.email).trim().toLowerCase();
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) throw new HttpError(400, 'Format email tidak valid');
    const taken = await db
      .select({ id: users.id })
      .from(users)
      .where(eq(users.email, email));
    if (taken.length > 0 && taken[0].id !== req.userId) {
      throw new HttpError(409, 'Email sudah digunakan akun lain');
    }
    updates.email = email;
  }

  if (Object.keys(updates).length === 0) throw new HttpError(400, 'Tidak ada perubahan');

  const [user] = await db
    .update(users)
    .set(updates)
    .where(eq(users.id, req.userId!))
    .returning();

  res.json({ user: userJson(user) });
});
