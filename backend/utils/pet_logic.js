const moment = require('moment');

/**
 * 宠物逻辑工具类
 */
const PetLogic = {
  /**
   * 计算经验获取倍率（基于营养、快乐、亲密）
   * 公式：(营养 + 快乐 + 亲密) / 300 + 0.5
   */
  calculateExpMultiplier(pet) {
    const nutrition = pet.nutrition || 0;
    const happiness = pet.happiness || 0;
    const intimacy = Math.min(pet.intimacy || 0, 100); // 亲密值参与计算上限设为100
    return (nutrition + happiness + intimacy) / 300 + 0.5;
  },

  /**
   * 处理宠物经验增加、升级与进化
   * @param {Object} pet 宠物模型实例
   * @param {number} amount 基础经验值
   * @param {number} extraRate 额外倍率（如任务质量、用户状态加成）
   */
  async addExp(pet, amount, extraRate = 1.0) {
    const multiplier = this.calculateExpMultiplier(pet);
    const gainedExp = Math.round(amount * multiplier * extraRate);
    
    let currentExp = (pet.exp || 0) + gainedExp;
    let currentLevel = pet.level || 1;
    let currentThreshold = pet.expThreshold || 100;
    let isUpgrade = false;

    // 自动升级逻辑
    while (currentExp >= currentThreshold && currentLevel < 100) {
      currentExp -= currentThreshold;
      currentLevel++;
      // 经验阈值公式：100 + 等级 * 50
      currentThreshold = 100 + currentLevel * 50;
      isUpgrade = true;
    }

    const updateData = {
      exp: currentExp,
      level: currentLevel,
      expThreshold: currentThreshold
    };

    // 进化逻辑 (30, 50, 70级)
    const type = pet.petType || 'chick';
    let stage = 'baby';
    let stageName = '幼年期';
    if (currentLevel >= 70) {
      stage = 'advanced';
      stageName = '完全体';
    } else if (currentLevel >= 50) {
      stage = 'adult';
      stageName = '成年期';
    } else if (currentLevel >= 30) {
      stage = 'adolescent';
      stageName = '成长期';
    }

    // 检查是否需要更新头像（进化点或初始缺失）
    if (isUpgrade && [30, 50, 70].includes(currentLevel)) {
      updateData.petAvatar = `${type}_${stage}.png`;
      
      // 同步更新 PetAdvance 表
      try {
        const { PetAdvance } = require('../models');
        await PetAdvance.upsert({
          userId: pet.userId,
          petId: pet.petId,
          currentStage: stageName,
          updateTime: new Date()
        });
      } catch (e) {
        console.error('更新进化阶段失败:', e.message);
      }
    } else if (!pet.petAvatar) {
      updateData.petAvatar = `${type}_${stage}.png`;
    }

    await pet.update(updateData);
    return { gainedExp, isUpgrade, newLevel: currentLevel };
  }
};

module.exports = PetLogic;
