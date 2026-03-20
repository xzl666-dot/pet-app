const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const PetAdvance = sequelize.define('PetAdvance', {
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
  currentStage: {
    type: DataTypes.STRING(50),
    allowNull: false,
    defaultValue: '幼年期',
  },
  stageExp: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
  },
  stageExpMax: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 100,
  },
  skillPoint: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
  },
  skillList: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  stageRecord: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  evolveCondition: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  evolveTime: {
    type: DataTypes.DATE,
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
  tableName: 'pet_advance',
  timestamps: false,
});

module.exports = PetAdvance;