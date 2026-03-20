const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const ChallengeRecord = sequelize.define('ChallengeRecord', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  challengeId: {
    type: DataTypes.STRING,
    allowNull: false,
    references: {
      model: 'challenge',
      key: 'challengeId',
    },
  },
  userId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'users',
      key: 'userId',
    },
  },
  finishStatus: {
    type: DataTypes.TINYINT,
    allowNull: false,
  },
  finishTime: {
    type: DataTypes.INTEGER,
    allowNull: true,
  },
  taskScore: {
    type: DataTypes.TINYINT,
    allowNull: true,
  },
  comprehensiveScore: {
    type: DataTypes.FLOAT,
    allowNull: true,
  },
  petExpReward: {
    type: DataTypes.INTEGER,
    allowNull: true,
  },
  challengeScoreChange: {
    type: DataTypes.INTEGER,
    allowNull: true,
  },
  syncTime: {
    type: DataTypes.DATE,
    allowNull: false,
  },
}, {
  tableName: 'challenge_record',
  timestamps: false,
  indexes: [
    {
      name: 'idx_challengeRecord_challengeId',
      fields: ['challengeId'],
    },
    {
      name: 'idx_challengeRecord_userId',
      fields: ['userId'],
    },
  ],
});

module.exports = ChallengeRecord;
