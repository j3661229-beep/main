/**
 * Standard API response helpers
 */
const success = (res, data = {}, message = 'Success', statusCode = 200) => {
    return res.status(statusCode).json({ success: true, message, data });
};

const created = (res, data = {}, message = 'Created successfully') => {
    return res.status(201).json({ success: true, message, data });
};

const error = (res, message = 'An error occurred', statusCode = 400, errors = null) => {
    const body = { success: false, message };
    if (errors) body.errors = errors;
    return res.status(statusCode).json(body);
};

const paginated = (res, data, page, limit, total) => {
    return res.status(200).json({
        success: true,
        data,
        pagination: {
            page: Number(page),
            limit: Number(limit),
            total,
            totalPages: Math.ceil(total / limit),
            hasNext: page * limit < total,
            hasPrev: page > 1,
        },
    });
};

module.exports = { success, created, error, paginated };
