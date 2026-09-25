import cors from 'cors';
import express from 'express';
import { errorHandler, notFound } from './middleware/error';
import authRoutes from './routes/auth.routes';
import budgetRoutes from './routes/budget.routes';
import categoryRoutes from './routes/category.routes';
import statsRoutes from './routes/stats.routes';
import transactionRoutes from './routes/transaction.routes';

const app = express();

app.use(cors());
app.use(express.json());

app.get('/api/health', (_req, res) => {
  res.json({ ok: true, name: 'Pocketly API' });
});

app.use('/api/auth', authRoutes);
app.use('/api', transactionRoutes);
app.use('/api', categoryRoutes);
app.use('/api', budgetRoutes);
app.use('/api', statsRoutes);

app.use(notFound);
app.use(errorHandler);

export default app;
