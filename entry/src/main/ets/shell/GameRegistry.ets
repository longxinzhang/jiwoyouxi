import { GameModule } from './GameModule';

export const GAME_MODULES: GameModule[] = [
  {
    id: 'rps',
    title: '石头剪刀布大作战',
    subtitle: '三方自动追捕，机制全开也能离线玩',
    icon: '✊',
    tags: ['观战', '策略', '乱斗'],
    accent: '#2c8f7f',
    highScoreLabel: '最高存活数'
  },
  {
    id: 'freecell',
    title: '空当接龙',
    subtitle: '经典纸牌策略，红黑交替递减，四花色归位',
    icon: '♣',
    tags: ['纸牌', '策略', '竖屏'],
    accent: '#b46b2a',
    highScoreLabel: '最高分'
  },
  {
    id: 'minesweeper',
    title: '扫雷',
    subtitle: '经典雷区推理，首点安全，支持插旗模式',
    icon: '✹',
    tags: ['推理', '棋盘', '休闲'],
    accent: '#4e6edb',
    highScoreLabel: '最高得分'
  },
  {
    id: 'chicken2048',
    title: '鸡窝 2048',
    subtitle: '滑动数字块合成升级，冲到 2048',
    icon: '2',
    tags: ['合成', '棋盘', '轻松'],
    accent: '#f4a62a',
    highScoreLabel: '最高分'
  },
  {
    id: 'tetris',
    title: '俄罗斯方块',
    subtitle: '10×20 网格、7 种方块、消行升级',
    icon: '▣',
    tags: ['下落', '消除', '长局'],
    accent: '#8b5cf6',
    highScoreLabel: '最高分'
  },
  {
    id: 'suika',
    title: '鸡窝水果摊',
    subtitle: '圆滚滚玩具水果落进木箱，相同碰撞合成',
    icon: '◉',
    tags: ['物理', '合成', '软弹'],
    accent: '#16a34a',
    highScoreLabel: '最高瓜分'
  },
  {
    id: 'eggSling',
    title: '弹射鸡蛋',
    subtitle: '拉弹弓发射鸡蛋，击中目标过关',
    icon: '◎',
    tags: ['物理', '关卡', '弹射'],
    accent: '#ef6f57',
    highScoreLabel: '最高分'
  }
];

export function moduleById(id: string): GameModule {
  const found = GAME_MODULES.find((item: GameModule) => item.id === id);
  return found === undefined ? GAME_MODULES[0] : found;
}
