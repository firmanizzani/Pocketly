import { Router } from 'express';
import { login, me, register, updateProfile } from '../controllers/auth.controller';
import { auth } from '../middleware/auth';

const router = Router();

router.post('/register', register);
router.post('/login', login);
router.get('/me', auth, me);
router.put('/me', auth, updateProfile);

export default router;
