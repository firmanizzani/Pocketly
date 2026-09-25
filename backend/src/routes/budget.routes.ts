import { Router } from 'express';
import { listBudgets, upsertBudget } from '../controllers/budget.controller';
import { auth } from '../middleware/auth';

const router = Router();

router.use(auth);
router.get('/budgets', listBudgets);
router.post('/budgets', upsertBudget);

export default router;
