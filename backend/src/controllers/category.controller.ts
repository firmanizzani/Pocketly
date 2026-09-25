import type { Response } from 'express';
import { listUserCategories } from '../db/seed';
import { asyncHandler } from '../middleware/error';
import type { AuthRequest } from '../middleware/auth';

export const listCategories = asyncHandler(async (req: AuthRequest, res: Response) => {
  const rows = await listUserCategories(req.userId!);
  res.json({
    categories: rows.map((c) => ({
      id: c.id,
      name: c.name,
      type: c.type,
      icon: c.icon,
    })),
  });
});
