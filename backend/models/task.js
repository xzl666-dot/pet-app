const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const Task = sequelize.define('Task', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  userId: {
    type: DataTypes.INTEGER,
    allowNull: true,
  },
  name: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  difficulty: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  deadline: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  benefit_type: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  benefit_value: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  is_completed: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
  },
  created_at: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  completed_at: {
    type: DataTypes.INTEGER,
    allowNull: true,
  },
  stateCode: {
    type: DataTypes.TINYINT,
    allowNull: true,
    defaultValue: 0,
  },
  is_test_task: {
    type: DataTypes.TINYINT,
    allowNull: false,
    defaultValue: 0,
  },
  test_task_grade: {
    type: DataTypes.TINYINT,
    allowNull: true,
  },
  test_day: {
    type: DataTypes.TINYINT,
    allowNull: true,
  },
  finish_efficiency: {
    type: DataTypes.INTEGER,
    allowNull: true,
  },
  finish_score: {
    type: DataTypes.INTEGER,
    allowNull: true,
  },
  task_type: {
    type: DataTypes.TINYINT,
    allowNull: false,
    defaultValue: 0, // 0: 每日, 1: 每周, 2: 每月
  },
  is_custom: {
    type: DataTypes.TINYINT,
    allowNull: false,
    defaultValue: 0,
  },
  category: {
    type: DataTypes.STRING(50),
    allowNull: true,
  },
}, {
  tableName: 'tasks',
  timestamps: false,
});

module.exports = Task;
