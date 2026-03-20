const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const UserCenter = sequelize.define('UserCenter', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  userId: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  petId: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  avatar: {
    type: DataTypes.STRING(255),
    allowNull: true,
  },
  nickname: {
    type: DataTypes.STRING(50),
    allowNull: true,
  },
  commonEntry: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  toDoList: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  interactSet: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  privacySet: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  remindSet: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  dataSet: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  updateTime: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW,
  },
  syncStatus: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
  },
}, {
  tableName: 'user_center',
  timestamps: false,
});

module.exports = UserCenter;