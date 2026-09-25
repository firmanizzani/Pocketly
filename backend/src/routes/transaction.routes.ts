import { Router } from 'express';
import {
  createTransaction,
  deleteTransaction,
  listTransactions,
  summary,
  updateTransaction,
} from '../controllers/transaction.controller';
import { auth } from '../middleware/auth';

const router = Router();

router.use(auth);
router.get('/transactions', listTransactions);
router.post('/transactions', createTransaction);
router.put('/transactions/:id', updateTransaction);
router.delete('/transactions/:id', deleteTransaction);
router.get('/summary', summary);

export default router;
