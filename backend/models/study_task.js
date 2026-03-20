const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const StudyTask = sequelize.define('StudyTask', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  userId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    comment: '用户ID',
  },
  name: {
    type: DataTypes.STRING(200),
    allowNull: false,
    comment: '任务名称',
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: true,
    comment: '任务描述',
  },
  subject: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
    comment: '科目（0:数学 1:英语 2:物理 3:生物 4:世界历史 5:化学）',
  },
  difficulty: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
    comment: '难度（0:简单 1:中等 2:困难）',
  },
  deadline: {
    type: DataTypes.DATE,
    allowNull: false,
    comment: '截止时间',
  },
  benefitType: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
    comment: '收益类型（0:营养值 1:快乐度 2:技能点）',
  },
  benefitValue: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 10,
    comment: '收益值',
  },
  isCompleted: {
    type: DataTypes.TINYINT,
    allowNull: false,
    defaultValue: 0,
    comment: '是否完成（0:未完成 1:已完成）',
  },
  createdAt: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW,
    comment: '创建时间',
  },
  completedAt: {
    type: DataTypes.DATE,
    allowNull: true,
    comment: '完成时间',
  },
}, {
  tableName: 'study_tasks',
  timestamps: false,
  indexes: [
    {
      fields: ['userId'],
      name: 'idx_study_task_user_id',
    },
    {
      fields: ['subject'],
      name: 'idx_study_task_subject',
    },
    {
      fields: ['difficulty'],
      name: 'idx_study_task_difficulty',
    },
    {
      fields: ['isCompleted'],
      name: 'idx_study_task_is_completed',
    },
  ],
});

module.exports = StudyTask;