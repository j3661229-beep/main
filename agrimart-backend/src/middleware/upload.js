const multer = require('multer');
const supabase = require('../config/supabase');
const { error } = require('../utils/apiResponse');

const storage = multer.memoryStorage();

const upload = multer({
    storage,
    limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
    fileFilter: (req, file, cb) => {
        const allowed = ['image/jpeg', 'image/png', 'image/webp', 'image/jpg'];
        if (allowed.includes(file.mimetype)) return cb(null, true);
        cb(new Error('Only JPEG, PNG and WebP images are allowed'));
    },
});

/**
 * Upload a buffer to Supabase Storage
 * Returns public URL
 */
const uploadToSupabase = async (buffer, originalName, folder = 'products') => {
    const ext = originalName.split('.').pop() || 'jpg';
    const filename = `${folder}/${Date.now()}-${Math.random().toString(36).slice(2)}.${ext}`;
    const bucket = process.env.SUPABASE_STORAGE_BUCKET || 'agrimart-images';

    const { data, error: uploadError } = await supabase.storage
        .from(bucket)
        .upload(filename, buffer, { contentType: 'image/jpeg', upsert: false });

    if (uploadError) throw new Error(`Upload failed: ${uploadError.message}`);

    const { data: urlData } = supabase.storage.from(bucket).getPublicUrl(filename);
    return urlData.publicUrl;
};

module.exports = { upload, uploadToSupabase };
