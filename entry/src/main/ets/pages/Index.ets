import { common } from '@kit.AbilityKit';
import { CoopStorage } from '../app/CoopStorage';
import { CoopMotion } from '../design/CoopMotion';
import { APPEARANCE_DARK, APPEARANCE_LIGHT, CoopAppSnapshot, emptySnapshot, GameRecord } from '../shell/GameModule';
import { GameEntryBadge } from '../shell/GameEntryBadge';
import { GameSceneTransition } from '../shell/GameSceneTransition';
import { HubPage } from './HubPage';
import { RpsPage } from '../games/rps/RpsPage';
import { FreecellPage } from '../games/freecell/FreecellPage';
import { MinesweeperPage } from '../games/minesweeper/MinesweeperPage';
import { Chicken2048Page } from '../games/chicken2048/Chicken2048Page';
import { TetrisPage } from '../games/tetris/TetrisPage';
import { SuikaPage } from '../games/suika/SuikaPage';
import { EggSlingPage } from '../games/eggSling/EggSlingPage';

@Entry
@Component
struct Index {
  private appContext: common.Context | undefined = undefined;
  private entryBadgeInTimer: number = -1;
  private entryBadgeOutTimer: number = -1;
  private entryBadgeUnmountTimer: number = -1;
  @State snapshot: CoopAppSnapshot = emptySnapshot();
  @State activeGame: string = 'hub';
  @State tetrisSession: number = 0;
  @State sceneDirection: string = 'push';
  @State sceneTransitioning: boolean = false;
  @State entryBadgeGameId: string = 'rps';
  @State entryBadgeMounted: boolean = false;
  @State entryBadgeVisible: boolean = false;
  @State minesweeperExitRequestId: number = 0;

  aboutToAppear(): void {
    const context = this.getUIContext().getHostContext();
    if (context !== undefined) {
      this.appContext = context as common.Context;
      CoopStorage.load(this.appContext).then((snapshot: CoopAppSnapshot) => {
        this.snapshot = snapshot;
      });
    }
  }

  onBackPress(): boolean {
    if (this.activeGame === 'minesweeper') {
      this.requestMinesweeperExit();
      return true;
    }
    if (this.activeGame !== 'hub') {
      this.closeGameAnimated();
      return true;
    }
    return false;
  }

  aboutToDisappear(): void {
    this.clearEntryBadgeTimers();
  }

  build() {
    Stack() {
      if (this.activeGame === 'hub') {
        GameSceneTransition({ role: 'hub', sceneDirection: this.sceneDirection }) {
          HubPage({
            snapshot: this.snapshot,
            openGame: (gameId: string) => {
              this.openGame(gameId);
            },
            toggleFavorite: (gameId: string) => {
              this.toggleFavorite(gameId);
            },
            updateSound: (enabled: boolean) => {
              this.updateSound(enabled);
            },
            updateHaptic: (enabled: boolean) => {
              this.updateHaptic(enabled);
            },
            updateAppearanceMode: (appearanceMode: string) => {
              this.updateAppearanceMode(appearanceMode);
            }
          })
        }
      } else if (this.activeGame === 'rps') {
        GameSceneTransition({ role: 'game', sceneDirection: this.sceneDirection }) {
          RpsPage({
            exitToHub: () => {
              this.closeGameAnimated();
            },
            recordScore: (score: number) => {
              this.recordGameResult('rps', score);
            }
          })
        }
      } else if (this.activeGame === 'freecell') {
        GameSceneTransition({ role: 'game', sceneDirection: this.sceneDirection }) {
          FreecellPage({
            bestScore: this.recordFor('freecell').highScore,
            exitToHub: () => {
              this.closeGameAnimated();
            },
            recordScore: (score: number) => {
              this.recordGameResult('freecell', score);
            }
          })
        }
      } else if (this.activeGame === 'minesweeper') {
        GameSceneTransition({ role: 'game', sceneDirection: this.sceneDirection }) {
          MinesweeperPage({
            bestScore: this.recordFor('minesweeper').highScore,
            externalExitRequestId: this.minesweeperExitRequestId,
            exitToHub: () => {
              this.closeGameAnimated();
            },
            recordScore: (score: number) => {
              this.recordGameResult('minesweeper', score);
            }
          })
        }
      } else if (this.activeGame === 'chicken2048') {
        GameSceneTransition({ role: 'game', sceneDirection: this.sceneDirection }) {
          Chicken2048Page({
            bestScore: this.recordFor('chicken2048').highScore,
            exitToHub: () => {
              this.closeGameAnimated();
            },
            recordScore: (score: number) => {
              this.recordGameResult('chicken2048', score);
            }
          })
        }
      } else if (this.activeGame === 'tetris') {
        GameSceneTransition({ role: 'game', sceneDirection: this.sceneDirection }) {
          TetrisPage({
            bestScore: this.recordFor('tetris').highScore,
            session: this.tetrisSession,
            exitToHub: () => {
              this.closeGameAnimated();
            },
            recordScore: (score: number) => {
              this.recordGameResult('tetris', score);
            }
          })
        }
      } else if (this.activeGame === 'suika') {
        GameSceneTransition({ role: 'game', sceneDirection: this.sceneDirection }) {
          SuikaPage({
            bestScore: this.recordFor('suika').highScore,
            exitToHub: () => {
              this.closeGameAnimated();
            },
            recordScore: (score: number) => {
              this.recordGameResult('suika', score);
            }
          })
        }
      } else if (this.activeGame === 'eggSling') {
        GameSceneTransition({ role: 'game', sceneDirection: this.sceneDirection }) {
          EggSlingPage({
            bestScore: this.recordFor('eggSling').highScore,
            exitToHub: () => {
              this.closeGameAnimated();
            },
            recordScore: (score: number) => {
              this.recordGameResult('eggSling', score);
            }
          })
        }
      }

      if (this.entryBadgeMounted) {
        GameEntryBadge({
          gameId: this.entryBadgeGameId,
          badgeVisible: this.entryBadgeVisible
        })
      }
    }
    .width('100%')
    .height('100%')
  }

  private openGame(gameId: string): void {
    if (this.sceneTransitioning || this.activeGame === gameId) {
      return;
    }
    if (gameId === 'tetris') {
      this.tetrisSession += 1;
    }
    this.sceneDirection = 'push';
    this.sceneTransitioning = true;
    this.saveSnapshot(this.withRecent(this.snapshot, gameId));
    this.showEntryBadge(gameId);
    this.getUIContext().animateTo({
      duration: CoopMotion.scenePushDuration,
      curve: Curve.Friction,
      onFinish: () => {
        this.sceneTransitioning = false;
      }
    }, () => {
      this.activeGame = gameId;
    });
  }

  private closeGameAnimated(): void {
    if (this.sceneTransitioning || this.activeGame === 'hub') {
      return;
    }
    this.sceneDirection = 'pop';
    this.sceneTransitioning = true;
    this.hideEntryBadge();
    this.getUIContext().animateTo({
      duration: CoopMotion.scenePopDuration,
      curve: Curve.Friction,
      onFinish: () => {
        this.sceneTransitioning = false;
      }
    }, () => {
      this.activeGame = 'hub';
    });
  }

  private requestMinesweeperExit(): void {
    if (this.sceneTransitioning) {
      return;
    }
    this.minesweeperExitRequestId += 1;
  }

  private toggleFavorite(gameId: string): void {
    const favorites = this.snapshot.favorites.slice();
    const index = favorites.indexOf(gameId);
    if (index >= 0) {
      favorites.splice(index, 1);
    } else {
      favorites.unshift(gameId);
    }
    this.saveSnapshot({
      records: this.snapshot.records.slice(),
      favorites: favorites.slice(0, 12),
      recent: this.snapshot.recent.slice(),
      soundEnabled: this.snapshot.soundEnabled,
      hapticEnabled: this.snapshot.hapticEnabled,
      appearanceMode: this.snapshot.appearanceMode
    });
  }

  private updateSound(enabled: boolean): void {
    this.saveSnapshot({
      records: this.snapshot.records.slice(),
      favorites: this.snapshot.favorites.slice(),
      recent: this.snapshot.recent.slice(),
      soundEnabled: enabled,
      hapticEnabled: this.snapshot.hapticEnabled,
      appearanceMode: this.snapshot.appearanceMode
    });
  }

  private updateHaptic(enabled: boolean): void {
    this.saveSnapshot({
      records: this.snapshot.records.slice(),
      favorites: this.snapshot.favorites.slice(),
      recent: this.snapshot.recent.slice(),
      soundEnabled: this.snapshot.soundEnabled,
      hapticEnabled: enabled,
      appearanceMode: this.snapshot.appearanceMode
    });
  }

  private updateAppearanceMode(appearanceMode: string): void {
    this.saveSnapshot({
      records: this.snapshot.records.slice(),
      favorites: this.snapshot.favorites.slice(),
      recent: this.snapshot.recent.slice(),
      soundEnabled: this.snapshot.soundEnabled,
      hapticEnabled: this.snapshot.hapticEnabled,
      appearanceMode: appearanceMode === APPEARANCE_DARK ? APPEARANCE_DARK : APPEARANCE_LIGHT
    });
  }

  private recordGameResult(gameId: string, score: number): void {
    const records = this.snapshot.records.slice();
    const index = records.findIndex((item: GameRecord) => item.gameId === gameId);
    const now = Date.now();
    if (index >= 0) {
      const current = records[index];
      records[index] = {
        gameId: gameId,
        highScore: Math.max(current.highScore, Math.max(0, Math.floor(score))),
        playCount: current.playCount + 1,
        lastPlayedAt: now
      };
    } else {
      records.push({
        gameId: gameId,
        highScore: Math.max(0, Math.floor(score)),
        playCount: 1,
        lastPlayedAt: now
      });
    }
    this.saveSnapshot(this.withRecent({
      records: records,
      favorites: this.snapshot.favorites.slice(),
      recent: this.snapshot.recent.slice(),
      soundEnabled: this.snapshot.soundEnabled,
      hapticEnabled: this.snapshot.hapticEnabled,
      appearanceMode: this.snapshot.appearanceMode
    }, gameId));
  }

  private withRecent(snapshot: CoopAppSnapshot, gameId: string): CoopAppSnapshot {
    const recent = snapshot.recent.filter((item: string) => item !== gameId);
    recent.unshift(gameId);
    return {
      records: snapshot.records.slice(),
      favorites: snapshot.favorites.slice(),
      recent: recent.slice(0, 6),
      soundEnabled: snapshot.soundEnabled,
      hapticEnabled: snapshot.hapticEnabled,
      appearanceMode: snapshot.appearanceMode
    };
  }

  private recordFor(gameId: string): GameRecord {
    const found = this.snapshot.records.find((item: GameRecord) => item.gameId === gameId);
    if (found !== undefined) {
      return found;
    }
    return { gameId: gameId, highScore: 0, playCount: 0, lastPlayedAt: 0 };
  }

  private showEntryBadge(gameId: string): void {
    this.clearEntryBadgeTimers();
    this.entryBadgeGameId = gameId;
    this.entryBadgeVisible = false;
    this.entryBadgeMounted = true;
    this.entryBadgeInTimer = setTimeout(() => {
      this.getUIContext().animateTo({
        duration: CoopMotion.entryBadgeDuration,
        curve: Curve.EaseOut
      }, () => {
        this.entryBadgeVisible = true;
      });
    }, 20);
    this.entryBadgeOutTimer = setTimeout(() => {
      this.hideEntryBadge();
    }, CoopMotion.entryBadgeHoldDuration);
  }

  private hideEntryBadge(): void {
    if (!this.entryBadgeMounted) {
      return;
    }
    this.clearEntryBadgeTimers();
    this.getUIContext().animateTo({
      duration: CoopMotion.entryBadgeDuration,
      curve: Curve.EaseOut
    }, () => {
      this.entryBadgeVisible = false;
    });
    this.entryBadgeUnmountTimer = setTimeout(() => {
      this.entryBadgeMounted = false;
    }, CoopMotion.entryBadgeDuration);
  }

  private clearEntryBadgeTimers(): void {
    if (this.entryBadgeInTimer !== -1) {
      clearTimeout(this.entryBadgeInTimer);
      this.entryBadgeInTimer = -1;
    }
    if (this.entryBadgeOutTimer !== -1) {
      clearTimeout(this.entryBadgeOutTimer);
      this.entryBadgeOutTimer = -1;
    }
    if (this.entryBadgeUnmountTimer !== -1) {
      clearTimeout(this.entryBadgeUnmountTimer);
      this.entryBadgeUnmountTimer = -1;
    }
  }

  private saveSnapshot(snapshot: CoopAppSnapshot): void {
    this.snapshot = snapshot;
    if (this.appContext !== undefined) {
      CoopStorage.save(this.appContext, snapshot);
    }
  }
}
