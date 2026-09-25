import 'dotenv/config';
import app from './app';
import { ensureDefaultCategories } from './db/seed';

const port = Number(process.env.PORT ?? 3000);

ensureDefaultCategories()
  .catch((err) => console.error('Gagal seed kategori default:', err.message))
  .finally(() => {
    app.listen(port, () => {
      console.log(`Pocketly API berjalan di http://localhost:${port}/api`);
    });
  });
