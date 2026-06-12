export interface FruitDef {
  name: string;
  radius: number;
  color: string;
  image: string;
  previewImage: string;
}

export interface FruitBody {
  id: number;
  level: number;
  x: number;
  y: number;
  vx: number;
  vy: number;
  visualAngle: number;
  visualSpin: number;
  bornAt: number;
  releasedAt: number;
  mergeLockedUntil: number;
}

export interface SuikaBounds {
  left: number;
  right: number;
  bottom: number;
}

export interface OverflowState {
  isOverflowing: boolean;
  overflowSince: number;
  shouldFinish: boolean;
}

export interface MergeOutcome {
  canMerge: boolean;
  nextLevel: number;
  scoreDelta: number;
  isFinalMerge: boolean;
}

export interface CollisionStepResult {
  fruits: FruitBody[];
  nextId: number;
  scoreDelta: number;
  didMerge: boolean;
  isFinalMerge: boolean;
  mergeLevel: number;
  mergeX: number;
  mergeY: number;
}

export const FRUITS: FruitDef[] = [
  {
    name: '小葡萄',
    radius: 13,
    color: '#8b5cf6',
    image: 'games/suika/fruits/fruit_00_grape.png',
    previewImage: 'games/suika/fruits/preview/fruit_00_grape_preview.png'
  },
  {
    name: '蓝莓',
    radius: 17,
    color: '#3b82f6',
    image: 'games/suika/fruits/fruit_01_blueberry.png',
    previewImage: 'games/suika/fruits/preview/fruit_01_blueberry_preview.png'
  },
  {
    name: '橘子',
    radius: 21,
    color: '#f97316',
    image: 'games/suika/fruits/fruit_02_orange.png',
    previewImage: 'games/suika/fruits/preview/fruit_02_orange_preview.png'
  },
  {
    name: '苹果',
    radius: 26,
    color: '#ef4444',
    image: 'games/suika/fruits/fruit_03_apple.png',
    previewImage: 'games/suika/fruits/preview/fruit_03_apple_preview.png'
  },
  {
    name: '桃子',
    radius: 31,
    color: '#fb7185',
    image: 'games/suika/fruits/fruit_04_peach.png',
    previewImage: 'games/suika/fruits/preview/fruit_04_peach_preview.png'
  },
  {
    name: '哈密瓜',
    radius: 37,
    color: '#a3e635',
    image: 'games/suika/fruits/fruit_05_melon.png',
    previewImage: 'games/suika/fruits/preview/fruit_05_melon_preview.png'
  },
  {
    name: '小西瓜',
    radius: 43,
    color: '#22c55e',
    image: 'games/suika/fruits/fruit_06_small_watermelon.png',
    previewImage: 'games/suika/fruits/preview/fruit_06_small_watermelon_preview.png'
  },
  {
    name: '西瓜',
    radius: 50,
    color: '#16a34a',
    image: 'games/suika/fruits/fruit_07_watermelon.png',
    previewImage: 'games/suika/fruits/preview/fruit_07_watermelon_preview.png'
  },
  {
    name: '大西瓜',
    radius: 58,
    color: '#15803d',
    image: 'games/suika/fruits/fruit_08_big_watermelon.png',
    previewImage: 'games/suika/fruits/preview/fruit_08_big_watermelon_preview.png'
  },
  {
    name: '鸡冠西瓜',
    radius: 67,
    color: '#0f9f5f',
    image: 'games/suika/fruits/fruit_09_rooster_watermelon.png',
    previewImage: 'games/suika/fruits/preview/fruit_09_rooster_watermelon_preview.png'
  },
  {
    name: '巨型鸡窝西瓜',
    radius: 77,
    color: '#047857',
    image: 'games/suika/fruits/fruit_10_giant_chicken_watermelon.png',
    previewImage: 'games/suika/fruits/preview/fruit_10_giant_chicken_watermelon_preview.png'
  }
];
