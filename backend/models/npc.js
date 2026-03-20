const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const NPC = sequelize.define('NPC', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  name: {
    type: DataTypes.STRING(50),
    allowNull: false,
    comment: 'NPC名称',
  },
  avatar: {
    type: DataTypes.STRING(255),
    allowNull: true,
    comment: 'NPC头像',
  },
  level: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 1,
    comment: 'NPC等级',
  },
  difficulty: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 1,
    comment: '难度等级（1:简单 2:中等 3:困难）',
  },
  petType: {
    type: DataTypes.STRING(50),
    allowNull: true,
    comment: 'NPC宠物类型',
  },
  petForm: {
    type: DataTypes.STRING(50),
    allowNull: true,
    comment: 'NPC宠物形态',
  },
  petLevel: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 1,
    comment: 'NPC宠物等级',
  },
  challengeCount: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
    comment: '挑战次数',
  },
  winCount: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
    comment: '胜利次数',
  },
  rewardExp: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 10,
    comment: '胜利经验奖励',
  },
  rewardPoints: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 5,
    comment: '胜利积分奖励',
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: true,
    comment: 'NPC描述',
  },
  isAvailable: {
    type: DataTypes.TINYINT,
    allowNull: false,
    defaultValue: 1,
    comment: '是否可用（0:不可用 1:可用）',
  },
  createTime: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW,
    comment: '创建时间',
  },
}, {
  tableName: 'npcs',
  timestamps: false,
  indexes: [
    {
      fields: ['level'],
      name: 'idx_npc_level',
    },
    {
      fields: ['difficulty'],
      name: 'idx_npc_difficulty',
    },
    {
      fields: ['isAvailable'],
      name: 'idx_npc_is_available',
    },
  ],
});

module.exports = NPC;