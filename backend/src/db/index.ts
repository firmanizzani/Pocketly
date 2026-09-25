import 'dotenv/config';
import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';
import * as schema from './schema';

const url = process.env.DATABASE_URL;
if (!url) {
  console.error('DATABASE_URL belum diset. Salin .env.example ke .env lalu isi NeonDB URL.');
  process.exit(1);
}

const client = postgres(url, { max: 1 });

export const db = drizzle(client, { schema });
