const { Client } = require('pg');

const client = new Client({
  connectionString: 'postgresql://postgres.xufgkrkdlbvvnpknpcgh:Jayesh%20jay%402006@aws-0-ap-northeast-1.pooler.supabase.com:5432/postgres',
});

client.connect()
  .then(() => {
    console.log('Connected directly via pg!');
    return client.end();
  })
  .catch(err => console.error('Connection error', err.stack));
