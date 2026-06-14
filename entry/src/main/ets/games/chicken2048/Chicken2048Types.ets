export const CHICKEN_2048_SIZE: number = 4;
export const CHICKEN_2048_TARGET: number = 2048;

export type Chicken2048Direction = 'up' | 'down' | 'left' | 'right';

export interface Chicken2048Tile {
  id: number;
  value: number;
  row: number;
  col: number;
  previousRow: number;
  previousCol: number;
  mergedFromIds: number[];
  isNew: boolean;
  isMerged: boolean;
  scale: number;
  opacity: number;
}

export interface Chicken2048MergeEvent {
  row: number;
  col: number;
  value: number;
  sourceIds: number[];
}

export interface Chicken2048MoveResult {
  moved: boolean;
  movingTiles: Chicken2048Tile[];
  finalTiles: Chicken2048Tile[];
  tiles: Chicken2048Tile[];
  scoreGain: number;
  maxTile: number;
  merges: Chicken2048MergeEvent[];
}
