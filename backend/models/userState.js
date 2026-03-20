const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const UserState = sequelize.define('UserState', {
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
      key: 'userId',
    },
  },
  stateCode: {
    type: DataTypes.TINYINT,
    allowNull: false,
  },
  stateName: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  coreFeature: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  isManual: {
    type: DataTypes.TINYINT,
    allowNull: false,
    defaultValue: 0,
  },
  recognizeTime: {
    type: DataTypes.DATE,
    allowNull: false,
  },
  expireTime: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  adaptStrategy: {
    type: DataTypes.STRING,
    allowNull: false,
  },
}, {
  tableName: 'user_state',
  timestamps: false,
  indexes: [
    {
      name: 'idx_userState_userId',
      fields: ['userId'],
    },
    {
      name: 'idx_userState_recognizeTime',
      fields: ['recognizeTime'],
    },
  ],
});

module.exports = UserState;
