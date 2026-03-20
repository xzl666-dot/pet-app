const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const Incentive = sequelize.define('Incentive', {
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
    petId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      comment: '宠物ID',
    },
    abilityLevel: {
      type: DataTypes.STRING(10),
      allowNull: false,
      defaultValue: 'D',
      comment: '评估等级（S/A/B/C/D）',
    },
    integral: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0,
      comment: '当前积分',
    },
    integralGet: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0,
      comment: '累计获取积分',
    },
    integralConsume: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0,
      comment: '累计消耗积分',
    },
    integralExpire: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0,
      comment: '过期积分',
    },
    chestUnlock: {
      type: DataTypes.STRING(50),
      allowNull: false,
      defaultValue: '',
      comment: '已解锁宝箱等级（JSON格式）',
    },
    chestOpenNum: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0,
      comment: '已开启宝箱数量',
    },
    achievementUnlock: {
      type: DataTypes.TEXT,
      allowNull: false,
      defaultValue: '',
      comment: '已解锁成就列表（JSON格式）',
    },
    signInDays: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0,
      comment: '连续签到天数',
    },
    welfareGet: {
      type: DataTypes.TEXT,
      allowNull: false,
      defaultValue: '',
      comment: '已领取福利记录（JSON格式）',
    },
    incentivePrefer: {
      type: DataTypes.TEXT,
      allowNull: false,
      defaultValue: '',
      comment: '激励偏好设置（JSON格式）',
    },
    inventory: {
      type: DataTypes.TEXT,
      allowNull: false,
      defaultValue: '{}',
      comment: '物品栏（JSON格式）',
    },
    createTime: {
      type: DataTypes.DATE,
      allowNull: false,
      defaultValue: DataTypes.NOW,
      comment: '创建时间',
    },
    updateTime: {
      type: DataTypes.DATE,
      allowNull: false,
      defaultValue: DataTypes.NOW,
      comment: '更新时间',
    },
  }, {
    tableName: 'incentive',
    timestamps: true,
    createdAt: 'createTime',
    updatedAt: 'updateTime',
    indexes: [
      {
        fields: ['userId'],
        name: 'idx_incentive_user_id',
      },
      {
        fields: ['petId'],
        name: 'idx_incentive_pet_id',
      },
    ],
  });

  return Incentive;
};
