const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const Challenge = sequelize.define('Challenge', {
  challengeId: {
    type: DataTypes.STRING,
    primaryKey: true,
    allowNull: false,
  },
  publisherId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'users',
      key: 'userId',
    },
  },
  opponentId: {
    type: DataTypes.INTEGER,
    allowNull: true,
    references: {
      model: 'users',
      key: 'userId',
    },
  },
  taskId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'tasks',
      key: 'id',
    },
  },
  challengeName: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  status: {
    type: DataTypes.TINYINT,
    allowNull: false,
    defaultValue: 0,
  },
  createTime: {
    type: DataTypes.DATE,
    allowNull: false,
  },
  matchTime: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  settleTime: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  winnerId: {
    type: DataTypes.INTEGER,
    allowNull: true,
    references: {
      model: 'users',
      key: 'userId',
    },
  },
}, {
  tableName: 'challenge',
  timestamps: false,
  indexes: [
    {
      name: 'idx_challenge_publisherId',
      fields: ['publisherId'],
    },
    {
      name: 'idx_challenge_opponentId',
      fields: ['opponentId'],
    },
    {
      name: 'idx_challenge_taskId',
      fields: ['taskId'],
    },
    {
      name: 'idx_challenge_status',
      fields: ['status'],
    },
  ],
});

module.exports = Challenge;
