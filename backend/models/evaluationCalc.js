const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const EvaluationCalc = sequelize.define('EvaluationCalc', {
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
  accuracy: {
    type: DataTypes.FLOAT,
    allowNull: false,
    defaultValue: 0,
  },
  completionEfficiency: {
    type: DataTypes.FLOAT,
    allowNull: false,
    defaultValue: 0,
  },
  qualityScore: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
  },
  totalScore: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
  },
  taskCompletionCount: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
  },
  highQualityCount: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
  },
  evaluationDate: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW,
  },
  isAbnormal: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: false,
  },
  abnormalReason: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
}, {
  tableName: 'evaluation_calc',
  timestamps: false,
});

module.exports = EvaluationCalc;