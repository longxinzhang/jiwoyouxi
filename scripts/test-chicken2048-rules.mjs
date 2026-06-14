#!/usr/bin/env node

import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import { resolve } from 'node:path';
import vm from 'node:vm';

const projectRoot = resolve(import.meta.dirname, '..');
const sourceFiles = [
  'entry/src/main/ets/games/chicken2048/Chicken2048Types.ets',
  'entry/src/main/ets/games/chicken2048/Chicken2048Rules.ets'
];

function loadChicken2048Rules() {
  const source = sourceFiles
    .map((file) => readFileSync(resolve(projectRoot, file), 'utf8'))
    .join('\n')
    .replace(/^import\s+[^;]+;\n/gm, '')
    .replace(/^export\s+/gm, '');
  const runtimeSource = stripTypeScriptTypes(source, { mode: 'transform' });
  const context = { Math: Math };
  vm.runInNewContext(`${runtimeSource}
globalThis.__chicken2048 = {
  CHICKEN_2048_SIZE,
  CHICKEN_2048_TARGET,
  moveChicken2048Tiles,
  canMoveChicken2048,
  maxChicken2048Tile,
  normalizeChicken2048Tiles
};
`, context);
  return context.__chicken2048;
}

function tile(id, value, row, col) {
  return {
    id: id,
    value: value,
    row: row,
    col: col,
    previousRow: row,
    previousCol: col,
    mergedFromIds: [],
    isNew: false,
    isMerged: false,
    scale: 1,
    opacity: 1
  };
}

function boardValues(tiles) {
  const values = new Array(16).fill(0);
  tiles.forEach((item) => {
    values[item.row * 4 + item.col] = item.value;
  });
  return values;
}

function tilesFromValues(values) {
  const result = [];
  values.forEach((value, index) => {
    if (value > 0) {
      result.push(tile(index + 1, value, Math.floor(index / 4), index % 4));
    }
  });
  return result;
}

function referenceMove(values, direction) {
  const grid = [];
  const merged = [];
  for (let row = 0; row < 4; row += 1) {
    grid[row] = [];
    merged[row] = [];
    for (let col = 0; col < 4; col += 1) {
      grid[row][col] = values[row * 4 + col];
      merged[row][col] = false;
    }
  }
  const vector = {
    up: { row: -1, col: 0 },
    right: { row: 0, col: 1 },
    down: { row: 1, col: 0 },
    left: { row: 0, col: -1 }
  }[direction];
  const rows = [0, 1, 2, 3];
  const cols = [0, 1, 2, 3];
  if (vector.row === 1) rows.reverse();
  if (vector.col === 1) cols.reverse();
  let moved = false;
  let scoreGain = 0;

  rows.forEach((row) => {
    cols.forEach((col) => {
      const value = grid[row][col];
      if (value === 0) {
        return;
      }
      let farthest = { row, col };
      let next = { row: row + vector.row, col: col + vector.col };
      while (next.row >= 0 && next.row < 4 && next.col >= 0 && next.col < 4 && grid[next.row][next.col] === 0) {
        farthest = { row: next.row, col: next.col };
        next = { row: farthest.row + vector.row, col: farthest.col + vector.col };
      }
      if (next.row >= 0 && next.row < 4 && next.col >= 0 && next.col < 4 &&
        grid[next.row][next.col] === value && !merged[next.row][next.col]) {
        grid[row][col] = 0;
        grid[next.row][next.col] = value * 2;
        merged[next.row][next.col] = true;
        moved = true;
        scoreGain += value * 2;
        return;
      }
      grid[row][col] = 0;
      grid[farthest.row][farthest.col] = value;
      if (row !== farthest.row || col !== farthest.col) {
        moved = true;
      }
    });
  });

  return {
    values: grid.flat(),
    moved,
    scoreGain
  };
}

const api = loadChicken2048Rules();

{
  const result = api.moveChicken2048Tiles([
    tile(1, 2, 0, 0),
    tile(2, 2, 0, 1)
  ], 'left');
  assert.equal(result.moved, true, '2 2 should be an effective move');
  assert.equal(result.scoreGain, 4, '2+2 should score 4');
  assert.deepEqual(boardValues(result.tiles).slice(0, 4), [4, 0, 0, 0], '2 2 left should become 4');
  assert.equal(result.finalTiles[0].isMerged, true, 'merged final tile should be marked for pulse animation');
  assert.equal(JSON.stringify(result.finalTiles[0].mergedFromIds.slice().sort()), JSON.stringify([1, 2]), 'merged final tile should retain source ids');
}

{
  const result = api.moveChicken2048Tiles([
    tile(1, 2, 0, 0),
    tile(2, 0, 0, 1),
    tile(3, 2, 0, 2)
  ].filter((item) => item.value > 0), 'left');
  assert.deepEqual(boardValues(result.tiles).slice(0, 4), [4, 0, 0, 0], '2 0 2 left should become 4');
}

{
  const result = api.moveChicken2048Tiles([
    tile(1, 2, 0, 0),
    tile(2, 2, 0, 1),
    tile(3, 2, 0, 2),
    tile(4, 2, 0, 3)
  ], 'left');
  assert.equal(result.moved, true, 'equal row should move/merge');
  assert.equal(result.scoreGain, 8, 'two 2+2 merges should score 4+4');
  assert.deepEqual(boardValues(result.tiles).slice(0, 4), [4, 4, 0, 0], '2 2 2 2 left should become 4 4');
  assert.equal(result.merges.length, 2, '2 2 2 2 should produce two merge events');
  assert.equal(result.movingTiles.length, 4, 'moving stage should retain all original tiles for slide animation');
}

{
  const result = api.moveChicken2048Tiles([
    tile(1, 2, 0, 0),
    tile(2, 2, 0, 1),
    tile(3, 4, 0, 2)
  ], 'left');
  assert.equal(result.scoreGain, 4, 'single merge should score merged value');
  assert.deepEqual(boardValues(result.tiles).slice(0, 4), [4, 4, 0, 0], 'merged tile should not merge again in same move');
}

{
  const result = api.moveChicken2048Tiles([
    tile(1, 4, 0, 0),
    tile(2, 4, 0, 1),
    tile(3, 8, 0, 2),
    tile(4, 8, 0, 3)
  ], 'right');
  assert.equal(result.scoreGain, 24, '4+4 and 8+8 should score 8+16');
  assert.deepEqual(boardValues(result.tiles).slice(0, 4), [0, 0, 8, 16], '4 4 8 8 right should become 0 0 8 16');
}

{
  const result = api.moveChicken2048Tiles([
    tile(1, 2, 0, 1),
    tile(2, 2, 1, 1),
    tile(3, 4, 3, 1)
  ], 'up');
  const values = boardValues(result.tiles);
  assert.equal(result.scoreGain, 4, 'vertical merge should score correctly');
  assert.equal(values[1], 4, 'first column target should contain merged tile');
  assert.equal(values[5], 4, 'trailing vertical tile should compact upward');
}

{
  const result = api.moveChicken2048Tiles([
    tile(1, 2, 0, 0),
    tile(2, 4, 0, 1)
  ], 'left');
  assert.equal(result.moved, false, 'already compact non-equal row should not move');
  assert.equal(result.scoreGain, 0, 'invalid move should not score');
}

{
  const fullNoMoves = [
    2, 4, 2, 4,
    4, 2, 4, 2,
    2, 4, 2, 4,
    4, 2, 4, 2
  ].map((value, index) => tile(index + 1, value, Math.floor(index / 4), index % 4));
  assert.equal(api.canMoveChicken2048(fullNoMoves), false, 'full checkerboard should be terminal');

  const fullWithMove = fullNoMoves.slice();
  fullWithMove[15] = tile(16, 4, 3, 3);
  assert.equal(api.canMoveChicken2048(fullWithMove), true, 'full board with adjacent equal tiles should be movable');
}

{
  const directions = ['up', 'right', 'down', 'left'];
  const cases = [
    [2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [2, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [2, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [2, 2, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [4, 4, 8, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [2, 4, 8, 16, 4, 2, 4, 2, 2, 4, 2, 4, 4, 2, 4, 2],
    [0, 2, 0, 2, 4, 0, 4, 0, 0, 8, 8, 0, 16, 0, 0, 16]
  ];
  let seed = 2048;
  for (let i = 0; i < 120; i += 1) {
    const values = [];
    for (let j = 0; j < 16; j += 1) {
      seed = (seed * 1103515245 + 12345) % 2147483648;
      const bucket = seed % 5;
      values.push(bucket === 0 ? 0 : Math.pow(2, bucket));
    }
    cases.push(values);
  }

  cases.forEach((values, caseIndex) => {
    directions.forEach((direction) => {
      const expected = referenceMove(values, direction);
      const actual = api.moveChicken2048Tiles(tilesFromValues(values), direction);
      assert.deepEqual(boardValues(actual.tiles), expected.values, `case ${caseIndex} ${direction} board should match reference`);
      assert.equal(actual.moved, expected.moved, `case ${caseIndex} ${direction} moved should match reference`);
      assert.equal(actual.scoreGain, expected.scoreGain, `case ${caseIndex} ${direction} score should match reference`);
    });
  });
}

console.log('Chicken 2048 rules tests passed');
