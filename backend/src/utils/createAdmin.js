const mongoose = require('mongoose');
const dotenv = require('dotenv');
const User = require('../models/User');

dotenv.config({ path: './.env' });

async function createOrResetAdmin() {
  const email = 'admin@medichain.com';
  const password = 'Admin@12345';

  if (!process.env.MONGODB_URI) {
    throw new Error('MONGODB_URI is missing in backend/.env');
  }

  await mongoose.connect(process.env.MONGODB_URI);

  let user = await User.findOne({ email });
  if (!user) {
    user = new User({
      name: 'Admin',
      email,
      password,
      role: 'admin',
    });
  } else {
    user.name = 'Admin';
    user.role = 'admin';
    user.password = password;
  }

  await user.save();

  console.log('ADMIN_READY');
  console.log(`email=${email}`);
  console.log(`password=${password}`);

  await mongoose.disconnect();
}

createOrResetAdmin().catch(async (error) => {
  console.error('FAILED_TO_CREATE_ADMIN:', error.message);
  try {
    await mongoose.disconnect();
  } catch (_) {}
  process.exit(1);
});
