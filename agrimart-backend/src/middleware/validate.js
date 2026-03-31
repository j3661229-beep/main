const { ZodError } = require('zod');
const { error } = require('../utils/apiResponse');

/**
 * Middleware to validate request payload against a Zod schema.
 * @param {import('zod').ZodSchema} schema
 */
const validate = (schema) => (req, res, next) => {
    try {
        schema.parse({
            body: req.body,
            query: req.query,
            params: req.params,
        });
        next();
    } catch (err) {
        if (err instanceof ZodError) {
            const formattedErrors = err.errors.map(e => ({
                path: e.path.join('.'),
                message: e.message
            }));
            return error(res, 'Validation failed', 400, { errors: formattedErrors });
        }
        next(err);
    }
};

module.exports = { validate };
