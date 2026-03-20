const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const EvaluationLevel = sequelize.define('EvaluationLevel', {
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
  currentLevel: {
    type: DataTypes.STRING(10),
    allowNull: false,
    defaultValue: 'D',
  },
  currentScore: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
  },
  levelExpireTime: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  levelHistory: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  upgradeConditions: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  downgradeConditions: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  createTime: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW,
  },
  updateTime: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW,
  },
}, {
  tableName: 'evaluation_levels',
  timestamps: false,
  indexes: [
    {
      fields: ['userId'],
      name: 'idx_evaluation_user_id',
    },
    {
      fields: ['petId'],
      name: 'idx_evaluation_pet_id',
    },
  ],
});

module.exports = EvaluationLevel;