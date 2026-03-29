const { createClient } = require('@supabase/supabase-js');

let supabase;

if (process.env.SUPABASE_URL && process.env.SUPABASE_SERVICE_KEY) {
    supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_KEY, {
        auth: { persistSession: false },
    });
} else {
    supabase = {
        storage: {
            from: () => ({
                upload: async (path, file) => ({ data: { path }, error: null }),
                getPublicUrl: (path) => ({ data: { publicUrl: `https://placeholder.supabase.co/storage/v1/object/public/${path}` } }),
                remove: async () => ({ data: {}, error: null }),
            }),
        },
        from: () => ({
            select: () => ({ data: [], error: null }),
        }),
    };
}

module.exports = supabase;
