const jwt = require('jsonwebtoken');
const moment = require('moment');

// 令牌有效期（秒）
const ACCESS_TOKEN_EXPIRE = 2 * 60 * 60; // 2小时
const REFRESH_TOKEN_EXPIRE = 7 * 24 * 60 * 60; // 7天

// JWT密钥
const JWT_SECRET = 'pet_app_jwt_secret_key';

// 生成双令牌
const generateDoubleToken = (userId, deviceId) => {
  // 生成accessToken
  const accessToken = jwt.sign(
    { userId, type: 'access' },
    JWT_SECRET,
    { expiresIn: ACCESS_TOKEN_EXPIRE }
  );

  // 生成refreshToken
  const refreshToken = jwt.sign(
    { userId, deviceId, type: 'refresh' },
    JWT_SECRET,
    { expiresIn: REFRESH_TOKEN_EXPIRE }
  );

  // 计算过期时间
  const accessExpire = moment().add(ACCESS_TOKEN_EXPIRE, 'seconds').toDate();
  const refreshExpire = moment().add(REFRESH_TOKEN_EXPIRE, 'seconds').toDate();

  return {
    accessToken,
    refreshToken,
    accessExpire,
    refreshExpire,
  };
};

// 校验accessToken
const verifyAccessToken = (token) => {
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    if (decoded.type !== 'access') {
      return { valid: false, msg: '令牌类型错误' };
    }
    return { valid: true, userId: decoded.userId };
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return { valid: false, msg: 'accessToken已过期' };
    }
    return { valid: false, msg: '令牌无效' };
  }
};

// 校验refreshToken
const verifyRefreshToken = (token, deviceId) => {
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    if (decoded.type !== 'refresh') {
      return { valid: false, msg: '令牌类型错误' };
    }
    if (decoded.deviceId !== deviceId) {
      return { valid: false, msg: '设备不匹配' };
    }
    return { valid: true, userId: decoded.userId, deviceId: decoded.deviceId };
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return { valid: false, msg: 'refreshToken已过期' };
    }
    return { valid: false, msg: '令牌无效' };
  }
};

module.exports = {
  generateDoubleToken,
  verifyAccessToken,
  verifyRefreshToken,
  ACCESS_TOKEN_EXPIRE,
  REFRESH_TOKEN_EXPIRE,
  JWT_SECRET,
};
