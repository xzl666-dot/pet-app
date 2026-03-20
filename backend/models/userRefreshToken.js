const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const UserRefreshToken = sequelize.define('UserRefreshToken', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  userId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'users',
      key: 'id',
    },
  },
  refreshToken: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true,
  },
  deviceId: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  deviceName: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  expireTime: {
    type: DataTypes.DATE,
    allowNull: false,
  },
  createTime: {
    type: DataTypes.DATE,
    allowNull: false,
  },
  updateTime: {
    type: DataTypes.DATE,
    allowNull: false,
  },
}, {
  tableName: 'user_refresh_token',
  timestamps: false,
  indexes: [
    {
      name: 'idx_urt_userId',
      fields: ['userId'],
    },
    {
      name: 'idx_urt_refreshToken',
      fields: ['refreshToken'],
    },
    {
      name: 'idx_urt_deviceId',
      fields: ['deviceId'],
    },
    {
      name: 'idx_urt_expireTime',
      fields: ['expireTime'],
    },
  ],
});

module.exports = UserRefreshToken;
