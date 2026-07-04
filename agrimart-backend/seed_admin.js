const { PrismaClient } = require('./src/generated/prisma'); 
const prisma = new PrismaClient(); 

async function main() { 
  await prisma.user.upsert({ 
    where: { phone: '9999999999' }, 
    update: { role: 'ADMIN' }, 
    create: { 
      name: 'Super Admin', 
      phone: '9999999999', 
      role: 'ADMIN', 
      isVerified: true 
    } 
  }); 
  console.log('Admin user created/updated with phone: 9999999999'); 
} 

main().catch(console.error).finally(() => prisma.$disconnect());
