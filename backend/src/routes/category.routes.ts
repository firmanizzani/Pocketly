import { Router } from 'express';
import { listCategories } from '../controllers/category.controller';
import { auth } from '../middleware/auth';

const router = Router();

router.get('/categories', auth, listCategories);

export default router;
