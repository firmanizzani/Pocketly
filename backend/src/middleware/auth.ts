import type { NextFunction, Request, Response } from 'express';
import jwt from 'jsonwebtoken';

export const JWT_SECRET = process.env.JWT_SECRET || 'pocketly-dev-secret';

export interface AuthRequest extends Request {
  userId?: string;
}

/** Token lama memakai sub numerik (mis. 1) → konversi ke user001. */
export function normalizeUserId(sub: string | number): string {
  const s = String(sub);
  if (/^\d+$/.test(s)) return `user${s.padStart(3, '0')}`;
  return s;
}

export function signToken(userId: string, remember: boolean): string {
  return jwt.sign({ sub: userId }, JWT_SECRET, {
    expiresIn: remember ? '30d' : '1d',
  });
}

export function auth(req: AuthRequest, res: Response, next: NextFunction): void {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Token tidak ditemukan' });
    return;
  }
  try {
    const payload = jwt.verify(header.slice(7), JWT_SECRET) as unknown as {
      sub: string | number;
    };
    req.userId = normalizeUserId(payload.sub);
    next();
  } catch {
    res.status(401).json({ error: 'Token tidak valid atau kedaluwarsa' });
  }
}
