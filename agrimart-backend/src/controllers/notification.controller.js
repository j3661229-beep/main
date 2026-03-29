const notifService = require('../services/notification.service');
const { success, created, paginated } = require('../utils/apiResponse');
const { getPagination } = require('../utils/helpers');

const getNotifications = async (req, res, next) => {
    try {
        const pag = getPagination(req.query);
        const { notifications, total, unread } = await notifService.getNotifications(req.user.id, pag);
        res.json({ success: true, data: notifications, unread, pagination: { page: pag.page, limit: pag.limit, total } });
    } catch (e) { next(e); }
};
const markRead = async (req, res, next) => {
    try { success(res, await notifService.markRead(req.user.id, req.params.id), 'Marked as read'); } catch (e) { next(e); }
};
const markAllRead = async (req, res, next) => {
    try { success(res, await notifService.markAllRead(req.user.id), 'All marked as read'); } catch (e) { next(e); }
};
const deleteNotification = async (req, res, next) => {
    try { success(res, await notifService.deleteNotification(req.user.id, req.params.id), 'Notification deleted'); } catch (e) { next(e); }
};
const saveFCMToken = async (req, res, next) => {
    try { success(res, await notifService.saveFCMToken(req.user.id, req.body), 'FCM token saved'); } catch (e) { next(e); }
};

module.exports = { getNotifications, markRead, markAllRead, deleteNotification, saveFCMToken };
