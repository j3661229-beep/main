require('dotenv').config();
const { PrismaClient } = require('../src/generated/prisma');

async function main() {
  const checks = [];
  const dbRef = (process.env.DATABASE_URL || '').match(/postgres\.([^:]+)/)?.[1];
  const apiRef = (process.env.SUPABASE_URL || '').replace('https://', '').split('.')[0];
  checks.push({ name: 'Supabase DB/API same project', ok: dbRef === apiRef, detail: `${dbRef} vs ${apiRef}` });

  const direct = process.env.DIRECT_URL || '';
  checks.push({ name: 'DIRECT_URL no pgbouncer flag', ok: !direct.includes('pgbouncer=true'), detail: direct.includes('pgbouncer') ? 'has pgbouncer=true — remove it' : 'ok' });

  checks.push({ name: 'GOOGLE_CLOUD_PROJECT', ok: !!process.env.GOOGLE_CLOUD_PROJECT });
  checks.push({ name: 'GOOGLE_CLOUD_LOCATION', ok: !!process.env.GOOGLE_CLOUD_LOCATION });
  checks.push({ name: 'JWT_SECRET', ok: !!(process.env.JWT_SECRET && process.env.JWT_SECRET.length > 32) });
  checks.push({ name: 'GROQ_API_KEY', ok: !!process.env.GROQ_API_KEY });
  checks.push({ name: 'OPENWEATHER_API_KEY', ok: !!process.env.OPENWEATHER_API_KEY });
  checks.push({ name: 'RAZORPAY (optional)', ok: !process.env.RAZORPAY_KEY_ID?.includes('YOUR_'), detail: 'placeholder if false' });

  try {
    const p = new PrismaClient();
    const count = await p.user.count();
    checks.push({ name: 'Database connect', ok: true, detail: `users: ${count}` });
    await p.$disconnect();
  } catch (e) {
    checks.push({ name: 'Database connect', ok: false, detail: e.message.split('\n')[0] });
  }

  for (const c of checks) {
    console.log(`${c.ok ? 'OK' : 'FAIL'}  ${c.name}${c.detail ? ' — ' + c.detail : ''}`);
  }
}

main();
