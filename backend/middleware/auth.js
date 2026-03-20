const { verifyAccessToken } = require('../utils/jwt');

// 认证中间件
const authMiddleware = (req, res, next) => {
  const token = req.headers.token;
  if (!token) {
    return res.json({ code: 401, data: {}, msg: '请先登录' });
  }

  try {
    const result = verifyAccessToken(token);
    if (!result.valid) {
      if (result.msg === 'accessToken已过期') {
        return res.json({ code: 403, data: {}, msg: 'accessToken已过期，请刷新' });
      }
      return res.json({ code: 401, data: {}, msg: result.msg });
    }

    // 将用户ID存入请求对象
    req.userId = result.userId;
    next();
  } catch (err) {
    return res.json({ code: 401, data: {}, msg: '令牌无效，请重新登录' });
  }
};

module.exports = authMiddleware;
