#!/usr/bin/env node

// 石头剪刀布大作战绝地求生规则回归测试。
// 覆盖分裂、复活印记、复活生成、每阵营次数限制和快照隔离。

import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import { resolve } from 'node:path';
import vm from 'node:vm';

const projectRoot = resolve(import.meta.dirname, '..');
const sourceFiles = [
  'entry/src/main/ets/games/rpsBattle/RpsBattleTypes.ets',
  'entry/src/main/ets/games/rpsBattle/RpsBattleModeConfig.ets',
  'entry/src/main/ets/games/rpsBattle/RpsBattleRules.ets',
  'entry/src/main/ets/games/rpsBattle/RpsBattleBlackHoleSystem.ets',
  'entry/src/main/ets/games/rpsBattle/RpsBattleZoneSystem.ets',
  'entry/src/main/ets/games/rpsBattle/RpsBattleLastStandSystem.ets',
  'entry/src/main/ets/games/rpsBattle/RpsBattlePowerUpSystem.ets',
  'entry/src/main/ets/games/rpsBattle/RpsBattleShrinkSystem.ets',
  'entry/src/main/ets/games/rpsBattle/RpsBattleTraitorSystem.ets',
  'entry/src/main/ets/games/rpsBattle/RpsBattleSnapSystem.ets',
  'entry/src/main/ets/games/rpsBattle/RpsBattleObstacleSystem.ets',
  'entry/src/main/ets/games/rpsBattle/RpsBattleBountySystem.ets',
  'entry/src/main/ets/games/rpsBattle/RpsBattleGodHandSystem.ets',
  'entry/src/main/ets/games/rpsBattle/RpsBattleTenAgainstOneSystem.ets',
  'entry/src/main/ets/games/rpsBattle/RpsBattleEngine.ets'
];

function loadRpsBattleLastStandSystem() {
  const source = sourceFiles
    .map((file) => readFileSync(resolve(projectRoot, file), 'utf8'))
    .join('\n')
    .replace(/^import\s+[\s\S]*?;\n/gm, '')
    .replace(/^export\s+/gm, '');
  const runtimeSource = stripTypeScriptTypes(source, { mode: 'transform' });
  const context = { Math: Math, Number: Number };
  vm.runInNewContext(`${runtimeSource}
globalThis.__rpsBattleLastStand = {
  RPS_BATTLE_LAST_STAND_SPLIT_INTERVAL_SEC,
  RPS_BATTLE_LAST_STAND_SPLIT_CHANCE,
  RPS_BATTLE_LAST_STAND_REVIVE_TRIGGER_COUNT,
  RPS_BATTLE_LAST_STAND_REVIVE_CHANCE,
  RPS_BATTLE_LAST_STAND_REVIVE_DELAY_SEC,
  RPS_BATTLE_LAST_STAND_REINFORCEMENT_COOLDOWN_SEC,
  RpsBattleLastStandSystem,
  RpsBattleEngine
};
`, context);
  return context.__rpsBattleLastStand;
}

const L = loadRpsBattleLastStandSystem();
let passed = 0;
let failed = 0;

function test(name, fn) {
  try {
    fn();
    passed += 1;
    console.log(`  ✓ ${name}`);
  } catch (error) {
    failed += 1;
    console.log(`  ✗ ${name}`);
    console.log(`      ${error.message}`);
  }
}

function queuedRandom(values) {
  let index = 0;
  return () => {
    const value = values[Math.min(index, values.length - 1)];
    index += 1;
    return value;
  };
}

function entity(id, faction, x, y) {
  return {
    id,
    faction,
    x,
    y,
    vx: 0,
    vy: 0,
    radius: 14,
    shield: 0,
    speedBoostUntilSec: 0,
    convertedAt: 0
  };
}

function counts(rock, scissors, paper) {
  return { rock, scissors, paper };
}

function plain(value) {
  return JSON.parse(JSON.stringify(value));
}

console.log('\n石头剪刀布大作战绝地求生规则测试\n');

test('重置后没有复活印记和脉冲', () => {
  const system = new L.RpsBattleLastStandSystem();
  system.reset([entity(1, 'rock', 120, 130)], counts(1, 0, 0), 400, 300);
  assert.equal(system.snapshot(), null);
  assert.equal(system.hasPendingReviveMarks(), false);
});

test('只剩一个单位时按时间判定触发分裂', () => {
  const system = new L.RpsBattleLastStandSystem();
  const source = entity(1, 'rock', 120, 130);
  system.reset([source], counts(1, 0, 0), 400, 300);
  const requests = system.update([source], counts(1, 0, 0), 1, 400, 300, queuedRandom([0.1, 0.5, 0.5]));
  const snapshot = system.snapshot();
  assert.equal(requests.length, 1);
  assert.equal(requests[0].faction, 'rock');
  assert.equal(requests[0].eventKind, 'split');
  assert.equal(requests[0].x, 120);
  assert.equal(requests[0].y, 130);
  assert.equal(snapshot.splitCount, 1);
  assert.equal(snapshot.pulses.length, 1);
  assert.equal(system.lastFrameEventCount(), 1);
});

test('分裂失败后需要等待下一次检查时间', () => {
  const system = new L.RpsBattleLastStandSystem();
  const source = entity(1, 'scissors', 200, 140);
  system.reset([source], counts(0, 1, 0), 400, 300);
  assert.equal(system.update([source], counts(0, 1, 0), 1, 400, 300, queuedRandom([0.9])).length, 0);
  assert.equal(system.update([source], counts(0, 1, 0), 1.5, 400, 300, queuedRandom([0.1, 0.5, 0.5])).length, 0);
  assert.equal(system.update([source], counts(0, 1, 0), 2, 400, 300, queuedRandom([0.1, 0.5, 0.5])).length, 1);
});

test('每个阵营最多成功分裂一次', () => {
  const system = new L.RpsBattleLastStandSystem();
  const source = entity(1, 'paper', 180, 150);
  system.reset([source], counts(0, 0, 1), 400, 300);
  assert.equal(system.update([source], counts(0, 0, 1), 1, 400, 300, queuedRandom([0.1, 0.5, 0.5])).length, 1);
  system.completeFrame([source], counts(0, 0, 1));
  assert.equal(system.update([source], counts(0, 0, 1), 3, 400, 300, queuedRandom([0.1, 0.5, 0.5])).length, 0);
});

test('剩余三个单位以内时概率留下复活印记', () => {
  const system = new L.RpsBattleLastStandSystem();
  const previous = [
    entity(1, 'rock', 220, 160),
    entity(2, 'rock', 224, 164),
    entity(3, 'rock', 228, 168),
    entity(4, 'rock', 232, 172)
  ];
  const current = [
    entity(1, 'rock', 220, 160),
    entity(2, 'rock', 224, 164),
    entity(3, 'rock', 228, 168)
  ];
  system.reset(previous, counts(4, 0, 0), 400, 300);
  const requests = system.update(current, counts(L.RPS_BATTLE_LAST_STAND_REVIVE_TRIGGER_COUNT, 0, 0), 1, 400,
    300, queuedRandom([0.1]));
  const snapshot = system.snapshot();
  assert.equal(requests.length, 0);
  assert.equal(system.hasPendingReviveMarks(), true);
  assert.equal(snapshot.reviveMarks.length, 1);
  assert.equal(snapshot.pulses.length, 1);
  assert.equal(snapshot.pulses[0].kind, 'reviveMark');
  assert.deepEqual(plain(snapshot.reviveMarks[0]), {
    faction: 'rock',
    x: 228,
    y: 168,
    createdAtSec: 1,
    dueAtSec: 1 + L.RPS_BATTLE_LAST_STAND_REVIVE_DELAY_SEC
  });
  assert.equal(system.lastFrameEventCount(), 1);
});

test('复活印记到期后生成复活请求', () => {
  const system = new L.RpsBattleLastStandSystem();
  system.reset([entity(1, 'scissors', 230, 170)], counts(0, 1, 0), 400, 300);
  system.update([], counts(0, 0, 0), 1, 400, 300, queuedRandom([0.1]));
  system.completeFrame([], counts(0, 0, 0));
  const requests = system.update([], counts(0, 0, 0), 1 + L.RPS_BATTLE_LAST_STAND_REVIVE_DELAY_SEC, 400, 300,
    queuedRandom([0.1]));
  const snapshot = system.snapshot();
  assert.equal(requests.length, 1);
  assert.equal(requests[0].faction, 'scissors');
  assert.equal(requests[0].eventKind, 'revive');
  assert.equal(requests[0].x, 230);
  assert.equal(requests[0].y, 170);
  assert.equal(system.hasPendingReviveMarks(), false);
  assert.equal(system.lastFrameReviveCount(), 1);
  assert.equal(snapshot.reviveCount, 1);
});

test('同阵营已有复活印记时不会重复创建', () => {
  const system = new L.RpsBattleLastStandSystem();
  system.reset([entity(1, 'paper', 240, 180)], counts(0, 0, 1), 400, 300);
  system.update([], counts(0, 0, 0), 1, 400, 300, queuedRandom([0.1]));
  system.completeFrame([], counts(0, 0, 0));
  system.completeFrame([entity(2, 'paper', 260, 190)], counts(0, 0, 1));
  const requests = system.update([], counts(0, 0, 0), 2, 400, 300, queuedRandom([0.1]));
  assert.equal(requests.length, 0);
  assert.equal(system.snapshot().reviveMarks.length, 1);
});

test('团灭阵营在冷却后可以再次等待援军', () => {
  const system = new L.RpsBattleLastStandSystem();
  system.reset([entity(1, 'rock', 220, 160)], counts(1, 0, 0), 400, 300);
  system.update([], counts(0, 0, 0), 1, 400, 300, queuedRandom([0.1]));
  system.completeFrame([], counts(0, 0, 0));
  const firstRevive = system.update([], counts(0, 0, 0), 1 + L.RPS_BATTLE_LAST_STAND_REVIVE_DELAY_SEC, 400, 300,
    queuedRandom([0.1]));
  system.completeFrame([], counts(0, 0, 0));
  const blocked = system.update([], counts(0, 0, 0), 1 + L.RPS_BATTLE_LAST_STAND_REVIVE_DELAY_SEC + 1, 400, 300,
    queuedRandom([0.1]));
  const blockedSnapshot = system.snapshot();
  system.completeFrame([], counts(0, 0, 0));
  const ready = system.update([], counts(0, 0, 0),
    1 + L.RPS_BATTLE_LAST_STAND_REVIVE_DELAY_SEC + L.RPS_BATTLE_LAST_STAND_REINFORCEMENT_COOLDOWN_SEC,
    400, 300, queuedRandom([0.1]));
  const readySnapshot = system.snapshot();

  assert.equal(firstRevive.length, 1);
  assert.equal(blocked.length, 0);
  assert.equal(blockedSnapshot.reviveMarks.length, 0);
  assert.equal(ready.length, 0);
  assert.equal(readySnapshot.reviveMarks.length, 1);
  assert.equal(readySnapshot.reviveMarks[0].faction, 'rock');
});

test('快照不反向修改系统状态', () => {
  const system = new L.RpsBattleLastStandSystem();
  system.reset([entity(1, 'rock', 220, 160)], counts(1, 0, 0), 400, 300);
  system.update([], counts(0, 0, 0), 1, 400, 300, queuedRandom([0.1]));
  const snapshot = system.snapshot();
  snapshot.reviveMarks[0].x = 1;
  snapshot.reviveMarks.length = 0;
  const next = system.snapshot();
  assert.equal(next.reviveMarks.length, 1);
  assert.equal(next.reviveMarks[0].x, 220);
});

test('存在复活印记时引擎不会立即按清场结算', () => {
  const options = {
    modeKey: 'zones',
    mechanics: {
      blackHole: false,
      lastStand: true
    },
    enhancements: {
      comebackRule: 'none',
      godHandEnabled: false
    },
    supportFaction: 'rock',
    initialCounts: counts(1, 0, 0),
    durationSec: 60
  };
  const engine = new L.RpsBattleEngine(400, 300, options, queuedRandom([0.5, 0.5, 0.5, 0.5, 0.1]));
  engine.removeEntity(engine.entitiesForRender()[0]);
  const result = engine.update(0.016, 1);
  const snapshot = engine.lastStandSnapshot();
  assert.equal(result.finishReason, 'none');
  assert.equal(snapshot.reviveMarks.length, 1);
  assert.equal(engine.entityCount(), 0);
});

console.log(`\n通过 ${passed} 项，失败 ${failed} 项\n`);

if (failed > 0) {
  process.exit(1);
}
