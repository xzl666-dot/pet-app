const { sequelize } = require('../config/database');

// Redis键前缀
const REDIS_BLACKLIST_PREFIX = 'refresh_token_blacklist:';

// Redis客户端（初始化为null，不强制依赖）
let redisClient = null;

// 添加refreshToken到黑名单
const addRefreshTokenToBlacklist = async (refreshToken, expireSeconds = 7 * 24 * 60 * 60) => {
  try {
    // 直接使用SQLite存储
    await sequelize.query(`
      CREATE TABLE IF NOT EXISTS refresh_token_blacklist (
        token TEXT PRIMARY KEY,
        expire_time DATETIME NOT NULL
      )
    `);
    const expireTime = new Date(Date.now() + expireSeconds * 1000);
    await sequelize.query(
      'INSERT OR REPLACE INTO refresh_token_blacklist (token, expire_time) VALUES (?, ?)',
      { replacements: [refreshToken, expireTime] }
    );
    return true;
  } catch (error) {
    console.error('添加refreshToken到黑名单失败:', error);
    return false;
  }
};

// 检查refreshToken是否在黑名单中
const isRefreshTokenInBlacklist = async (refreshToken) => {
  try {
    // 直接使用SQLite检查
    await sequelize.query(`
      CREATE TABLE IF NOT EXISTS refresh_token_blacklist (
        token TEXT PRIMARY KEY,
        expire_time DATETIME NOT NULL
      )
    `);
    const now = new Date();
    const [rows] = await sequelize.query(
      'SELECT * FROM refresh_token_blacklist WHERE token = ? AND expire_time > ?',
      { replacements: [refreshToken, now] }
    );
    return rows.length > 0;
  } catch (error) {
    console.error('检查refreshToken黑名单失败:', error);
    return false;
  }
};

// 清理过期的黑名单记录
const cleanupBlacklist = async () => {
  try {
    if (!redisClient) {
      const now = new Date();
      await sequelize.query(
        'DELETE FROM refresh_token_blacklist WHERE expire_time <= ?',
        { replacements: [now] }
      );
    }
  } catch (error) {
    console.error('清理黑名单失败:', error);
  }
};

module.exports = {
  addRefreshTokenToBlacklist,
  isRefreshTokenInBlacklist,
  cleanupBlacklist,
};
