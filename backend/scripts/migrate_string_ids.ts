import 'dotenv/config';
import postgres from 'postgres';

const url = process.env.DATABASE_URL;
if (!url) {
  console.error('DATABASE_URL belum diset.');
  process.exit(1);
}

const sql = postgres(url, { max: 1, onnotice: () => {} });

async function main() {
  console.log('Mulai migrasi ID → format singular+001 ...');

  await sql.begin(async (tx) => {
    // 1) Drop FK yang menunjuk users.id
    const fks = await tx<{ table_name: string; constraint_name: string }[]>`
      SELECT tc.table_name, tc.constraint_name
      FROM information_schema.table_constraints tc
      JOIN information_schema.key_column_usage kcu
        ON tc.constraint_name = kcu.constraint_name
      JOIN information_schema.constraint_column_usage ccu
        ON tc.constraint_name = ccu.constraint_name
      WHERE tc.constraint_type = 'FOREIGN KEY'
        AND ccu.table_name = 'users'
        AND tc.table_name IN ('categories', 'transactions', 'budgets')
    `;
    for (const fk of fks) {
      console.log(`  Drop FK ${fk.constraint_name} on ${fk.table_name}`);
      await tx.unsafe(`ALTER TABLE ${fk.table_name} DROP CONSTRAINT "${fk.constraint_name}"`);
    }

    // 2) users.id: serial → user001
    console.log('  Convert users.id');
    await tx.unsafe(`
      ALTER TABLE users
        ALTER COLUMN id DROP DEFAULT,
        ALTER COLUMN id TYPE varchar(32)
        USING ('user' || lpad(id::text, 3, '0'))
    `);
    await tx.unsafe(`DROP SEQUENCE IF EXISTS users_id_seq CASCADE`);

    // 3) categories.user_id → varchar (kolom lain tetap)
    console.log('  Convert categories.user_id');
    await tx.unsafe(`
      ALTER TABLE categories
        ALTER COLUMN user_id TYPE varchar(32)
        USING (CASE WHEN user_id IS NULL THEN NULL ELSE 'user' || lpad(user_id::text, 3, '0') END)
    `);

    // 4) transactions
    console.log('  Convert transactions.id & user_id');
    await tx.unsafe(`
      ALTER TABLE transactions
        ALTER COLUMN id DROP DEFAULT,
        ALTER COLUMN id TYPE varchar(32)
        USING ('transaction' || lpad(id::text, 3, '0'))
    `);
    await tx.unsafe(`
      ALTER TABLE transactions
        ALTER COLUMN user_id TYPE varchar(32)
        USING ('user' || lpad(user_id::text, 3, '0'))
    `);
    await tx.unsafe(`DROP SEQUENCE IF EXISTS transactions_id_seq CASCADE`);

    // 5) budgets
    console.log('  Convert budgets.id & user_id');
    await tx.unsafe(`
      ALTER TABLE budgets
        ALTER COLUMN id DROP DEFAULT,
        ALTER COLUMN id TYPE varchar(32)
        USING ('budget' || lpad(id::text, 3, '0'))
    `);
    await tx.unsafe(`
      ALTER TABLE budgets
        ALTER COLUMN user_id TYPE varchar(32)
        USING ('user' || lpad(user_id::text, 3, '0'))
    `);
    await tx.unsafe(`DROP SEQUENCE IF EXISTS budgets_id_seq CASCADE`);

    // 6) Drop orphans agar FK bisa dipasang lagi (opsional aman)
    await tx.unsafe(`DELETE FROM transactions WHERE user_id NOT IN (SELECT id FROM users)`);
    await tx.unsafe(`DELETE FROM budgets WHERE user_id NOT IN (SELECT id FROM users)`);
    await tx.unsafe(`DELETE FROM categories WHERE user_id IS NOT NULL AND user_id NOT IN (SELECT id FROM users)`);

    // 7) Re-create FK
    console.log('  Re-create FK');
    await tx.unsafe(`
      ALTER TABLE categories
        ADD CONSTRAINT categories_user_id_fkey
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    `);
    await tx.unsafe(`
      ALTER TABLE transactions
        ADD CONSTRAINT transactions_user_id_fkey
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    `);
    await tx.unsafe(`
      ALTER TABLE budgets
        ADD CONSTRAINT budgets_user_id_fkey
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    `);
  });

  const [users] = await sql`SELECT COUNT(*)::int AS n FROM users`;
  const [txs] = await sql`SELECT COUNT(*)::int AS n FROM transactions`;
  const [bgs] = await sql`SELECT COUNT(*)::int AS n FROM budgets`;
  const sampleU = await sql`SELECT id FROM users ORDER BY id LIMIT 5`;
  const sampleT = await sql`SELECT id FROM transactions ORDER BY id LIMIT 5`;
  const sampleB = await sql`SELECT id FROM budgets ORDER BY id LIMIT 5`;

  console.log('Selesai!');
  console.log(`  users: ${users.n} | contoh:`, sampleU.map((r) => r.id));
  console.log(`  transactions: ${txs.n} | contoh:`, sampleT.map((r) => r.id));
  console.log(`  budgets: ${bgs.n} | contoh:`, sampleB.map((r) => r.id));

  await sql.end();
}

main().catch((err) => {
  console.error('Migrasi GAGAL:', err);
  process.exit(1);
});
