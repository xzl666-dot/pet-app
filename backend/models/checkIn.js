const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const CheckIn = sequelize.define('CheckIn', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  userId: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  checkInDate: {
    type: DataTypes.DATEONLY,
    allowNull: false,
  },
  continuousDays: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 1,
  },
  rewardPoints: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 10,
  },
}, {
  tableName: 'check_ins',
  timestamps: true,
});

module.exports = CheckIn;
