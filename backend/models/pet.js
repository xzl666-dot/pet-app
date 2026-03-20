const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const Pet = sequelize.define('Pet', {
  petId: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  userId: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  petName: {
    type: DataTypes.STRING(50),
    allowNull: false,
  },
  petAvatar: {
    type: DataTypes.STRING(255),
    allowNull: true,
  },
  petType: {
    type: DataTypes.STRING(50),
    allowNull: true,
    defaultValue: 'common',
  },
  nutrition: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 100,
  },
  happiness: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 100,
  },
  intimacy: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
  },
 level: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 1,
  },
  exp: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
  },
  expThreshold: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 100,
  },
  isSelected: {
    type: DataTypes.TINYINT,
    allowNull: false,
    defaultValue: 0,
  },
  versionType: {
    type: DataTypes.TINYINT,
    allowNull: false,
    defaultValue: 0,
  },
  createTime: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW,
  },
  abilityLevel: {
    type: DataTypes.STRING(10),
    allowNull: true,
  },
  initialLevel: {
    type: DataTypes.TINYINT,
    allowNull: true,
  },
  initialExp: {
    type: DataTypes.INTEGER,
    allowNull: true,
  },
  petDesc: {
    type: DataTypes.STRING(255),
    allowNull: true,
  },
  unlockAvatar: {
    type: DataTypes.STRING(500),
    allowNull: true,
  },
}, {
  tableName: 'pets',
  timestamps: false,
});

module.exports = Pet;