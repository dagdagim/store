const express = require('express');
const { protect, authorize } = require('../middleware/auth');
const {
  getUsers,
  createAdmin,
  updateUserRole,
  deleteUser,
} = require('../controllers/userController');

const router = express.Router();

router.use(protect, authorize('admin'));

router.get('/', getUsers);
router.post('/admins', createAdmin);
router.put('/:id/role', updateUserRole);
router.delete('/:id', deleteUser);

module.exports = router;
