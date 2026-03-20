const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const PetAlbum = sequelize.define('PetAlbum', {
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
  albumName: {
    type: DataTypes.STRING(100),
    allowNull: false,
    defaultValue: '默认图鉴',
  },
  petList: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  collectCount: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
  },
  totalCount: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 10,
  },
  unlockProgress: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  rareUnlock: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  albumShare: {
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
  tableName: 'pet_album',
  timestamps: false,
});

module.exports = PetAlbum;