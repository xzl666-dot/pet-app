const express = require('express');
const cors = require('cors');
const { sequelize, syncDatabase } = require('./models');
const challengeRoutes = require('./routes/challenge');
const userRoutes = require('./routes/user');
const stateRoutes = require('./routes/state');
const taskRoutes = require('./routes/task');
const incentiveRoutes = require('./routes/incentive');
const incentiveOperationsRoutes = require('./routes/incentiveOperations');
const petRoutes = require('./routes/pet');
const evaluationRoutes = require('./routes/evaluation');
const evaluationCalcRoutes = require('./routes/evaluation_calc');
const taskEvaluationRoutes = require('./routes/taskEvaluation');
const socialRoutes = require('./routes/social');
const userCenterRoutes = require('./routes/user_center');
const petAdvanceRoutes = require('./routes/petAdvance');
const studyTaskRoutes = require('./routes/study_task');
const npcChallengeRoutes = require('./routes/npc_challenge');
const itemsRoutes = require('./routes/items');
const petDailyRoutes = require('./routes/petDaily');

const app = express();
const PORT = 3000;
const path = require('path');

// 中间件
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// 静态文件服务 - Flutter Web应用
app.use(express.static(path.join(__dirname, '../build/web')));

// 路由
app.use('/api/challenge', challengeRoutes);
app.use('/api/user', userRoutes);
app.use('/api/state', stateRoutes);
app.use('/api/task', taskRoutes);
app.use('/api/taskEvaluation', taskEvaluationRoutes);
app.use('/api/incentive', incentiveRoutes);
// app.use('/api/incentive', incentiveOperationsRoutes); // 移除重复的路由挂载，避免冲突
app.use('/api/pet', petRoutes);
app.use('/api/evaluation', evaluationRoutes);
app.use('/api/evaluationCalc', evaluationCalcRoutes);
app.use('/api/social', socialRoutes);
app.use('/api/user_center', userCenterRoutes);
app.use('/api/petAdvance', petAdvanceRoutes);
app.use('/api/studyTask', studyTaskRoutes);
app.use('/api/npcChallenge', npcChallengeRoutes);
app.use('/api/items', itemsRoutes);
app.use('/api/petDaily', petDailyRoutes);

// 健康检查
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

// SPA路由支持 - 所有非API请求返回index.html
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, '../build/web/index.html'));
});

// 初始化
const init = async () => {
  try {
    // 同步数据库
    await syncDatabase();
    
    // 启动服务器
    app.listen(PORT, () => {
      console.log(`服务器运行在 http://localhost:${PORT}`);
    });
  } catch (error) {
    console.error('初始化失败:', error);
  }
};

// 启动应用
init();
