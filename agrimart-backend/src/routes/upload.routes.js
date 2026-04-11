const express = require('express');
const router = express.Router();
const { requireAuth } = require('../middleware/auth');
const { upload, uploadToSupabase } = require('../middleware/upload');
const prisma = require('../config/database');
const { success, error } = require('../utils/apiResponse');
const logger = require('../utils/logger');

// POST /api/upload/govt-doc
// Upload a government document for supplier/dealer verification
router.post('/govt-doc', requireAuth, upload.single('document'), async (req, res, next) => {
    try {
        const user = req.user;
        if (!req.file) return error(res, 'Document file is required', 400);
        if (!['SUPPLIER', 'DEALER'].includes(user.role)) {
            return error(res, 'Only suppliers and dealers need to upload documents', 403);
        }

        const { docType } = req.body; // e.g. 'GST', 'SHOP_LICENSE', 'AADHAR', 'PAN'

        // Upload to Supabase
        const docUrl = await uploadToSupabase(req.file.buffer, req.file.originalname, 'govt-docs');

        // Update the relevant record
        if (user.role === 'SUPPLIER') {
            await prisma.supplier.update({
                where: { userId: user.id },
                data: {
                    govtDocUrl: docUrl,
                    govtDocType: docType || 'OTHER',
                    docStatus: 'PENDING',
                },
            });
        } else if (user.role === 'DEALER') {
            await prisma.dealer.update({
                where: { userId: user.id },
                data: {
                    govtDocUrl: docUrl,
                    govtDocType: docType || 'OTHER',
                    docStatus: 'PENDING',
                },
            });
        }

        logger.info(`Govt doc uploaded for ${user.role} userId=${user.id}: ${docUrl}`);
        success(res, { docUrl, docStatus: 'PENDING' }, 'Document uploaded. Pending admin approval.');
    } catch (err) {
        next(err);
    }
});

module.exports = router;
