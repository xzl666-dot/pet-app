const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const NPCChallenge = sequelize.define('NPCChallenge', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  publisherId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    comment: '发起者ID',
  },
  opponentId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    comment: '对手ID（NPC ID）',
  },
  challengeType: {
    type: DataTypes.STRING(20),
    allowNull: false,
    comment: '挑战类型',
  },
  status: {
    type: DataTypes.STRING(20),
    allowNull: false,
    defaultValue: 'ongoing',
    comment: '状态',
  },
  startTime: {
    type: DataTypes.DATE,
    allowNull: false,
    comment: '开始时间',
  },
  endTime: {
    type: DataTypes.DATE,
    allowNull: true,
    comment: '结束时间',
  },
  winnerId: {
    type: DataTypes.INTEGER,
    allowNull: true,
    comment: '胜利者ID',
  },
  publisherScore: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
    comment: '发起者得分',
  },
  opponentScore: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
    comment: '对手得分',
  },
}, {
  tableName: 'npc_challenges',
  timestamps: false,
  indexes: [
    {
      fields: ['publisherId'],
      name: 'idx_npc_challenge_publisher_id',
    },
    {
      fields: ['opponentId'],
      name: 'idx_npc_challenge_opponent_id',
    },
    {
      fields: ['status'],
      name: 'idx_npc_challenge_status',
    },
  ],
});

module.exports = NPCChallenge;
