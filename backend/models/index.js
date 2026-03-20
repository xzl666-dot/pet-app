const { sequelize } = require('../config/database');
const User = require('./user');
const Task = require('./task');
const Challenge = require('./challenge');
const ChallengeRecord = require('./challengeRecord');
const UserState = require('./userState');
const UserRefreshToken = require('./userRefreshToken');
const Incentive = require('./incentive')(sequelize);
const Pet = require('./pet');
const EvaluationLevel = require('./evaluationLevel');
const EvaluationCalc = require('./evaluationCalc');
const Social = require('./social');
const UserCenter = require('./userCenter');
const PetAdvance = require('./petAdvance');
const PetAlbum = require('./petAlbum');
const AbilityTest = require('./ability_test');
const StudyTask = require('./study_task');
const NPC = require('./npc');
const NPCChallenge = require('./npc_challenge');
const FriendRequest = require('./friendRequest');
const CheckIn = require('./checkIn');
const Achievement = require('./achievement');

// 定义模型关系
User.hasMany(Challenge, { foreignKey: 'publisherId' });
User.hasMany(Challenge, { foreignKey: 'opponentId' });
User.hasMany(Challenge, { foreignKey: 'winnerId' });
User.hasMany(ChallengeRecord, { foreignKey: 'userId' });
User.hasMany(UserState, { foreignKey: 'userId' });
User.hasMany(UserRefreshToken, { foreignKey: 'userId' });
User.hasMany(Incentive, { foreignKey: 'userId' });
User.hasMany(Pet, { foreignKey: 'userId' });
User.hasMany(EvaluationLevel, { foreignKey: 'userId' });
User.hasMany(EvaluationCalc, { foreignKey: 'userId' });
User.hasMany(Social, { foreignKey: 'userId' });
User.hasMany(UserCenter, { foreignKey: 'userId' });
User.hasMany(PetAdvance, { foreignKey: 'userId' });
User.hasMany(PetAlbum, { foreignKey: 'userId' });
User.hasMany(AbilityTest, { foreignKey: 'userId' });
User.hasMany(StudyTask, { foreignKey: 'userId' });
User.hasMany(NPCChallenge, { foreignKey: 'publisherId' });
User.hasMany(FriendRequest, { foreignKey: 'senderId', as: 'SentFriendRequests' });
User.hasMany(FriendRequest, { foreignKey: 'targetId', as: 'ReceivedFriendRequests' });
User.hasMany(CheckIn, { foreignKey: 'userId' });
User.hasMany(Achievement, { foreignKey: 'userId' });

Pet.hasMany(EvaluationLevel, { foreignKey: 'petId' });
Pet.hasMany(EvaluationCalc, { foreignKey: 'petId' });
Pet.hasMany(Social, { foreignKey: 'petId' });
Pet.hasMany(PetAdvance, { foreignKey: 'petId' });
Pet.hasMany(PetAlbum, { foreignKey: 'petId' });

Task.hasMany(Challenge, { foreignKey: 'taskId' });

Challenge.hasMany(ChallengeRecord, { foreignKey: 'challengeId' });

// 同步数据库
const syncDatabase = async () => {
  try {
    await sequelize.sync({ force: false });
    console.log('数据库同步成功');
  } catch (error) {
    console.error('数据库同步失败:', error);
  }
};

module.exports = {
  sequelize,
  User,
  Task,
  Challenge,
  ChallengeRecord,
  UserState,
  UserRefreshToken,
  Incentive,
  Pet,
  EvaluationLevel,
  EvaluationCalc,
  Social,
  UserCenter,
  PetAdvance,
  PetAlbum,
  AbilityTest,
  StudyTask,
  NPC,
  NPCChallenge,
  FriendRequest,
  CheckIn,
  Achievement,
  syncDatabase,
};
