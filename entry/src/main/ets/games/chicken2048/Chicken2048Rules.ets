import {
  CHICKEN_2048_SIZE,
  Chicken2048Direction,
  Chicken2048MergeEvent,
  Chicken2048MoveResult,
  Chicken2048Tile
} from './Chicken2048Types';

interface CellPosition {
  row: number;
  col: number;
}

interface MoveVector {
  row: number;
  col: number;
}

interface Traversals {
  rows: number[];
  cols: number[];
}

interface FarthestResult {
  farthest: CellPosition;
  next: CellPosition;
}

export function createInitialChicken2048Tiles(nextId: number): Chicken2048Tile[] {
  let tiles: Chicken2048Tile[] = [];
  tiles = addRandomChicken2048Tile(tiles, nextId);
  tiles = addRandomChicken2048Tile(tiles, nextId + 1);
  return tiles;
}

export function addRandomChicken2048Tile(tiles: Chicken2048Tile[], id: number): Chicken2048Tile[] {
  const empty = emptyPositions(tiles);
  if (empty.length === 0) {
    return cloneTiles(tiles);
  }
  const slot = empty[Math.floor(Math.random() * empty.length)];
  const next = cloneTiles(tiles);
  next.push(makeTile(id, Math.random() < 0.9 ? 2 : 4, slot.row, slot.col, slot.row, slot.col, true, false, [], 0.72, 0.42));
  return next;
}

export function moveChicken2048Tiles(tiles: Chicken2048Tile[], direction: Chicken2048Direction): Chicken2048MoveResult {
  const grid = buildGrid(tiles);
  const movingTiles: Chicken2048Tile[] = [];
  const merges: Chicken2048MergeEvent[] = [];
  const vector = vectorForDirection(direction);
  const traversals = buildTraversals(vector);
  let moved = false;
  let scoreGain = 0;
  let maxTile = maxChicken2048Tile(tiles);

  traversals.rows.forEach((row: number) => {
    traversals.cols.forEach((col: number) => {
      const current = cellContent(grid, row, col);
      if (current === undefined) {
        return;
      }

      const positions = findFarthestPosition(grid, { row: row, col: col }, vector);
      const next = cellContent(grid, positions.next.row, positions.next.col);
      if (next !== undefined && next.value === current.value && !next.isMerged) {
        const value = current.value * 2;
        const merged = makeTile(
          next.id,
          value,
          positions.next.row,
          positions.next.col,
          positions.next.row,
          positions.next.col,
          false,
          true,
          [current.id, next.id],
          1,
          1
        );
        grid[row][col] = undefined;
        grid[positions.next.row][positions.next.col] = merged;
        upsertMotionTile(movingTiles, makeTile(
          current.id,
          current.value,
          positions.next.row,
          positions.next.col,
          current.row,
          current.col,
          false,
          false,
          [],
          1,
          1
        ));
        upsertMotionTile(movingTiles, makeTile(
          next.id,
          next.value,
          positions.next.row,
          positions.next.col,
          next.row,
          next.col,
          false,
          false,
          [],
          0.92,
          0.18
        ));
        moved = true;
        scoreGain += value;
        maxTile = Math.max(maxTile, value);
        merges.push({
          row: positions.next.row,
          col: positions.next.col,
          value: value,
          sourceIds: [current.id, next.id]
        });
      } else {
        grid[row][col] = undefined;
        const movedTile = makeTile(
          current.id,
          current.value,
          positions.farthest.row,
          positions.farthest.col,
          current.row,
          current.col,
          false,
          false,
          [],
          1,
          1
        );
        grid[positions.farthest.row][positions.farthest.col] = movedTile;
        upsertMotionTile(movingTiles, movedTile);
        if (!positionsEqual({ row: row, col: col }, positions.farthest)) {
          moved = true;
        }
      }
    });
  });

  const finalTiles = tilesFromGrid(grid);
  return {
    moved: moved,
    movingTiles: movingTiles,
    finalTiles: finalTiles,
    tiles: finalTiles,
    scoreGain: scoreGain,
    maxTile: maxTile,
    merges: merges
  };
}

export function canMoveChicken2048(tiles: Chicken2048Tile[]): boolean {
  if (emptyPositions(tiles).length > 0) {
    return true;
  }
  for (let row = 0; row < CHICKEN_2048_SIZE; row += 1) {
    for (let col = 0; col < CHICKEN_2048_SIZE; col += 1) {
      const tile = tileAt(tiles, row, col);
      if (tile === undefined) {
        return true;
      }
      const right = col + 1 < CHICKEN_2048_SIZE ? tileAt(tiles, row, col + 1) : undefined;
      const down = row + 1 < CHICKEN_2048_SIZE ? tileAt(tiles, row + 1, col) : undefined;
      if ((right !== undefined && right.value === tile.value) || (down !== undefined && down.value === tile.value)) {
        return true;
      }
    }
  }
  return false;
}

export function maxChicken2048Tile(tiles: Chicken2048Tile[]): number {
  let maxTile = 0;
  tiles.forEach((tile: Chicken2048Tile) => {
    maxTile = Math.max(maxTile, tile.value);
  });
  return maxTile;
}

export function cloneChicken2048Tile(tile: Chicken2048Tile): Chicken2048Tile {
  return makeTile(
    tile.id,
    tile.value,
    tile.row,
    tile.col,
    tile.previousRow,
    tile.previousCol,
    tile.isNew,
    tile.isMerged,
    tile.mergedFromIds.slice(),
    tile.scale,
    tile.opacity
  );
}

export function normalizeChicken2048Tiles(tiles: Chicken2048Tile[]): Chicken2048Tile[] {
  const next: Chicken2048Tile[] = [];
  tiles.forEach((tile: Chicken2048Tile) => {
    next.push(makeTile(tile.id, tile.value, tile.row, tile.col, tile.row, tile.col, false, false, [], 1, 1));
  });
  return next;
}

function buildGrid(tiles: Chicken2048Tile[]): Array<Array<Chicken2048Tile | undefined>> {
  const grid: Array<Array<Chicken2048Tile | undefined>> = [];
  for (let row = 0; row < CHICKEN_2048_SIZE; row += 1) {
    const line: Array<Chicken2048Tile | undefined> = [];
    for (let col = 0; col < CHICKEN_2048_SIZE; col += 1) {
      line.push(undefined);
    }
    grid.push(line);
  }
  tiles.forEach((tile: Chicken2048Tile) => {
    grid[tile.row][tile.col] = makeTile(tile.id, tile.value, tile.row, tile.col, tile.row, tile.col, false, false, [], 1, 1);
  });
  return grid;
}

function tilesFromGrid(grid: Array<Array<Chicken2048Tile | undefined>>): Chicken2048Tile[] {
  const result: Chicken2048Tile[] = [];
  for (let row = 0; row < CHICKEN_2048_SIZE; row += 1) {
    for (let col = 0; col < CHICKEN_2048_SIZE; col += 1) {
      const tile = grid[row][col];
      if (tile !== undefined) {
        result.push(tile);
      }
    }
  }
  return result;
}

function vectorForDirection(direction: Chicken2048Direction): MoveVector {
  if (direction === 'up') {
    return { row: -1, col: 0 };
  }
  if (direction === 'right') {
    return { row: 0, col: 1 };
  }
  if (direction === 'down') {
    return { row: 1, col: 0 };
  }
  return { row: 0, col: -1 };
}

function buildTraversals(vector: MoveVector): Traversals {
  const rows: number[] = [];
  const cols: number[] = [];
  for (let index = 0; index < CHICKEN_2048_SIZE; index += 1) {
    rows.push(index);
    cols.push(index);
  }
  if (vector.row === 1) {
    rows.reverse();
  }
  if (vector.col === 1) {
    cols.reverse();
  }
  return { rows: rows, cols: cols };
}

function findFarthestPosition(
  grid: Array<Array<Chicken2048Tile | undefined>>,
  cell: CellPosition,
  vector: MoveVector
): FarthestResult {
  let previous: CellPosition = { row: cell.row, col: cell.col };
  let current: CellPosition = { row: cell.row + vector.row, col: cell.col + vector.col };
  while (withinBounds(current) && cellContent(grid, current.row, current.col) === undefined) {
    previous = { row: current.row, col: current.col };
    current = { row: previous.row + vector.row, col: previous.col + vector.col };
  }
  return {
    farthest: previous,
    next: current
  };
}

function cellContent(
  grid: Array<Array<Chicken2048Tile | undefined>>,
  row: number,
  col: number
): Chicken2048Tile | undefined {
  if (!withinBounds({ row: row, col: col })) {
    return undefined;
  }
  return grid[row][col];
}

function withinBounds(position: CellPosition): boolean {
  return position.row >= 0 && position.row < CHICKEN_2048_SIZE &&
    position.col >= 0 && position.col < CHICKEN_2048_SIZE;
}

function positionsEqual(first: CellPosition, second: CellPosition): boolean {
  return first.row === second.row && first.col === second.col;
}

function upsertMotionTile(tiles: Chicken2048Tile[], tile: Chicken2048Tile): void {
  const index = tiles.findIndex((item: Chicken2048Tile) => item.id === tile.id);
  if (index >= 0) {
    tiles[index] = tile;
    return;
  }
  tiles.push(tile);
}

function makeTile(
  id: number,
  value: number,
  row: number,
  col: number,
  previousRow: number,
  previousCol: number,
  isNew: boolean,
  isMerged: boolean,
  mergedFromIds: number[],
  scale: number,
  opacity: number
): Chicken2048Tile {
  return {
    id: id,
    value: value,
    row: row,
    col: col,
    previousRow: previousRow,
    previousCol: previousCol,
    mergedFromIds: mergedFromIds.slice(),
    isNew: isNew,
    isMerged: isMerged,
    scale: scale,
    opacity: opacity
  };
}

function cloneTiles(tiles: Chicken2048Tile[]): Chicken2048Tile[] {
  const next: Chicken2048Tile[] = [];
  tiles.forEach((tile: Chicken2048Tile) => {
    next.push(cloneChicken2048Tile(tile));
  });
  return next;
}

function emptyPositions(tiles: Chicken2048Tile[]): CellPosition[] {
  const result: CellPosition[] = [];
  for (let row = 0; row < CHICKEN_2048_SIZE; row += 1) {
    for (let col = 0; col < CHICKEN_2048_SIZE; col += 1) {
      if (tileAt(tiles, row, col) === undefined) {
        result.push({ row: row, col: col });
      }
    }
  }
  return result;
}

function tileAt(tiles: Chicken2048Tile[], row: number, col: number): Chicken2048Tile | undefined {
  return tiles.find((tile: Chicken2048Tile) => tile.row === row && tile.col === col);
}
