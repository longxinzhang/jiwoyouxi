import { CoopModalTransition } from '../../components/CoopModalTransition';
import { CoopTheme } from '../../design/CoopTheme';
import { Chicken2048ExitConfirmOverlay } from './Chicken2048ExitConfirmOverlay';
import { Chicken2048ResultOverlay } from './Chicken2048ResultOverlay';
import {
  addRandomChicken2048Tile,
  canMoveChicken2048,
  createInitialChicken2048Tiles,
  maxChicken2048Tile,
  moveChicken2048Tiles,
  normalizeChicken2048Tiles
} from './Chicken2048Rules';
import {
  CHICKEN_2048_SIZE,
  CHICKEN_2048_TARGET,
  Chicken2048Direction,
  Chicken2048MergeEvent,
  Chicken2048Tile
} from './Chicken2048Types';

interface Chicken2048Point {
  x: number;
  y: number;
}

interface Chicken2048MergePulse {
  id: number;
  row: number;
  col: number;
  value: number;
  variant: number;
}

interface Chicken2048SpawnPulse {
  id: number;
  row: number;
  col: number;
  value: number;
}

interface Chicken2048BurstDot {
  index: number;
  xRatio: number;
  yRatio: number;
  sizeRatio: number;
  delay: number;
}

const SWIPE_THRESHOLD: number = 14;
const MERGE_PULSE_START_DELAY: number = 20;
const MERGE_PULSE_UP_DURATION: number = 100;
const MERGE_PULSE_DOWN_DURATION: number = 120;
const MERGE_PULSE_CLEAR_DELAY: number = MERGE_PULSE_START_DELAY + MERGE_PULSE_UP_DURATION + MERGE_PULSE_DOWN_DURATION + 40;
const MERGE_PULSE_SCALE: number = 1.28;
const SPAWN_PULSE_CLEAR_DELAY: number = 190;
const SPAWN_PULSE_UP_DURATION: number = 80;
const SPAWN_PULSE_DOWN_DURATION: number = 100;
const SPAWN_PULSE_SCALE: number = 1.12;
const DEV_TOOLS_TAP_THRESHOLD: number = 5;
const DEV_TOOLS_TAP_WINDOW_MS: number = 1400;
const CHICKEN_2048_BACKGROUND_IMAGE: string = 'games/chicken2048/bg.png';
const MERGE_BURST_DOTS: Chicken2048BurstDot[] = [
  { index: 0, xRatio: 0.27, yRatio: 0.16, sizeRatio: 0.095, delay: 0 },
  { index: 1, xRatio: 0.74, yRatio: 0.16, sizeRatio: 0.088, delay: 12 },
  { index: 2, xRatio: 0.20, yRatio: 0.50, sizeRatio: 0.075, delay: 22 },
  { index: 3, xRatio: 0.83, yRatio: 0.50, sizeRatio: 0.072, delay: 18 },
  { index: 4, xRatio: 0.63, yRatio: 0.72, sizeRatio: 0.115, delay: 30 },
  { index: 5, xRatio: 0.34, yRatio: 0.84, sizeRatio: 0.092, delay: 36 }
];
const MERGE_BURST_PALETTES: string[][] = [
  ['#F8B74E', '#F7B24A', '#F5B94B', '#F7B64D', '#FDBA50', '#F3A75C'],
  ['#FFD56B', '#F8A75E', '#FFE18A', '#F7B24A', '#FFCA66', '#F2A15C'],
  ['#FFC0D7', '#FFE28A', '#F6A96F', '#B8ECD9', '#F8B74E', '#FFF0A7'],
  ['#F6A96F', '#FAD36B', '#B9E0F6', '#FFB870', '#F7B3A6', '#FFE28A']
];

@Component
struct Chicken2048MergePulseTile {
  @Prop value: number = 2;
  @Prop variant: number = 0;
  @Prop tileSizeValue: number = 64;
  @Prop radius: number = 14;
  @Prop fontSize: number = 28;
  @Prop tileBackground: string = '#FFF4DA';
  @Prop textColor: string = '#70432B';
  private startTimer: number = -1;
  private downTimer: number = -1;
  @State private pulseScale: number = 1;
  @State private burstActive: boolean = false;

  aboutToAppear(): void {
    this.pulseScale = 1;
    this.burstActive = false;
    this.startTimer = setTimeout(() => {
      this.startTimer = -1;
      this.getUIContext().animateTo({
        duration: MERGE_PULSE_UP_DURATION,
        curve: Curve.EaseOut
      }, () => {
        this.pulseScale = MERGE_PULSE_SCALE;
        this.burstActive = true;
      });
      this.downTimer = setTimeout(() => {
        this.downTimer = -1;
        this.getUIContext().animateTo({
          duration: MERGE_PULSE_DOWN_DURATION,
          curve: Curve.Friction
        }, () => {
          this.pulseScale = 1;
        });
      }, MERGE_PULSE_UP_DURATION);
    }, MERGE_PULSE_START_DELAY);
  }

  aboutToDisappear(): void {
    if (this.startTimer !== -1) {
      clearTimeout(this.startTimer);
      this.startTimer = -1;
    }
    if (this.downTimer !== -1) {
      clearTimeout(this.downTimer);
      this.downTimer = -1;
    }
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Text(`${this.value}`)
        .width(this.tileTextWidth())
        .height(this.tileSizeValue)
        .fontSize(this.fontSize)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textColor)
        .textAlign(TextAlign.Center)
        .maxLines(1)

      ForEach(MERGE_BURST_DOTS, (dot: Chicken2048BurstDot) => {
        Row()
          .width(this.dotSize(dot))
          .height(this.dotSize(dot))
          .borderRadius(this.dotSize(dot) / 2)
          .backgroundColor(this.dotColor(dot))
          .opacity(this.burstActive ? 0.96 : 0)
          .scale({ x: this.burstActive ? 1 : 0.4, y: this.burstActive ? 1 : 0.4 })
          .position({
            x: this.burstActive ? this.dotEndX(dot) : this.dotCenterX(dot),
            y: this.burstActive ? this.dotEndY(dot) : this.dotCenterY(dot)
          })
          .animation({
            duration: MERGE_PULSE_UP_DURATION + 40,
            curve: Curve.EaseOut,
            delay: dot.delay
          })
      }, (dot: Chicken2048BurstDot) => `${dot.index}`)
    }
    .width(this.tileSizeValue)
    .height(this.tileSizeValue)
    .borderRadius(this.radius)
    .backgroundColor(this.tileBackground)
    .border({ width: 3, color: '#70432B' })
    .shadow({
      radius: 12,
      color: 'rgba(65,35,20,0.20)',
      offsetX: 0,
      offsetY: 6
    })
    .scale({ x: this.pulseScale, y: this.pulseScale })
    .hitTestBehavior(HitTestMode.None)
  }

  private dotSize(dot: Chicken2048BurstDot): number {
    return Math.max(5, Math.round(this.tileSizeValue * dot.sizeRatio));
  }

  private tileTextWidth(): number {
    return Math.round(this.tileSizeValue * 0.84);
  }

  private dotCenterX(dot: Chicken2048BurstDot): number {
    return this.tileSizeValue * 0.5 - this.dotSize(dot) * 0.5;
  }

  private dotCenterY(dot: Chicken2048BurstDot): number {
    return this.tileSizeValue * 0.5 - this.dotSize(dot) * 0.5;
  }

  private dotEndX(dot: Chicken2048BurstDot): number {
    return this.tileSizeValue * dot.xRatio - this.dotSize(dot) * 0.5;
  }

  private dotEndY(dot: Chicken2048BurstDot): number {
    return this.tileSizeValue * dot.yRatio - this.dotSize(dot) * 0.5;
  }

  private dotColor(dot: Chicken2048BurstDot): string {
    const palette = MERGE_BURST_PALETTES[this.variant % MERGE_BURST_PALETTES.length];
    return palette[dot.index % palette.length];
  }
}

@Component
struct Chicken2048SpawnPulseTile {
  @Prop value: number = 2;
  @Prop tileSizeValue: number = 64;
  @Prop radius: number = 14;
  @Prop fontSize: number = 28;
  @Prop tileBackground: string = '#FFF4DA';
  @Prop textColor: string = '#70432B';
  private downTimer: number = -1;
  @State private pulseScale: number = 1;

  aboutToAppear(): void {
    this.pulseScale = 1;
    this.getUIContext().animateTo({
      duration: SPAWN_PULSE_UP_DURATION,
      curve: Curve.EaseOut
    }, () => {
      this.pulseScale = SPAWN_PULSE_SCALE;
    });
    this.downTimer = setTimeout(() => {
      this.downTimer = -1;
      this.getUIContext().animateTo({
        duration: SPAWN_PULSE_DOWN_DURATION,
        curve: Curve.Friction
      }, () => {
        this.pulseScale = 1;
      });
    }, SPAWN_PULSE_UP_DURATION);
  }

  aboutToDisappear(): void {
    if (this.downTimer !== -1) {
      clearTimeout(this.downTimer);
      this.downTimer = -1;
    }
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Text(`${this.value}`)
        .width(this.tileTextWidth())
        .height(this.tileSizeValue)
        .fontSize(this.fontSize)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textColor)
        .textAlign(TextAlign.Center)
        .maxLines(1)
    }
    .width(this.tileSizeValue)
    .height(this.tileSizeValue)
    .borderRadius(this.radius)
    .backgroundColor(this.tileBackground)
    .border({ width: 3, color: '#70432B' })
    .shadow({
      radius: 9,
      color: 'rgba(65,35,20,0.16)',
      offsetX: 0,
      offsetY: 5
    })
    .scale({ x: this.pulseScale, y: this.pulseScale })
    .hitTestBehavior(HitTestMode.None)
  }

  private tileTextWidth(): number {
    return Math.round(this.tileSizeValue * 0.84);
  }
}

@Component
export struct Chicken2048Page {
  @Prop bestScore: number = 0;
  exitToHub: () => void = () => {};
  recordScore: (score: number) => void = () => {};
  private nextTileId: number = 1;
  private scoreReported: boolean = false;
  private touchStartX: number = 0;
  private touchStartY: number = 0;
  private nextMergePulseId: number = 1;
  private mergePulseClearTimer: number = -1;
  private nextSpawnPulseId: number = 1;
  private spawnPulseClearTimer: number = -1;
  private pausedBeforeExitConfirm: boolean = false;
  private devTapCount: number = 0;
  private devLastTapAt: number = 0;
  @State inputLocked: boolean = false;
  @State pageWidth: number = 390;
  @State pageHeight: number = 760;
  @State boardTiles: Chicken2048Tile[] = [];
  @State displayTiles: Chicken2048Tile[] = [];
  @State mergePulses: Chicken2048MergePulse[] = [];
  @State spawnPulses: Chicken2048SpawnPulse[] = [];
  @State score: number = 0;
  @State maxTile: number = 0;
  @State won: boolean = false;
  @State paused: boolean = false;
  @State gameOver: boolean = false;
  @State showWinOverlay: boolean = false;
  @State showExitConfirmOverlay: boolean = false;
  @State movesMade: number = 0;
  @State devToolsVisible: boolean = false;

  aboutToAppear(): void {
    this.restart();
  }

  aboutToDisappear(): void {
    this.clearMergePulseTimers();
    this.clearSpawnPulseTimer();
    this.inputLocked = false;
  }

  build() {
    Stack() {
      Image($rawfile(CHICKEN_2048_BACKGROUND_IMAGE))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Fill)
        .zIndex(0)

      this.TopBar()
      this.ScoreRow()
      this.BoardArea()
      this.HintLine()
      this.ControlPad()

      if (this.paused && !this.gameOver && !this.showWinOverlay && !this.showExitConfirmOverlay) {
        this.PauseOverlay()
      }
      if (this.showWinOverlay) {
        Chicken2048ResultOverlay({
          success: true,
          pageWidth: this.pageWidth,
          pageHeight: this.pageHeight,
          currentScore: this.score,
          maxTileValue: Math.max(this.maxTile, maxChicken2048Tile(this.boardTiles)),
          continueGame: () => {
            this.showWinOverlay = false;
          },
          restartGame: () => {
            this.restart();
          },
          exitToHub: () => {
            this.leaveToHub();
          }
        })
        .zIndex(30)
      }
      if (this.gameOver) {
        Chicken2048ResultOverlay({
          success: false,
          pageWidth: this.pageWidth,
          pageHeight: this.pageHeight,
          currentScore: this.score,
          maxTileValue: Math.max(this.maxTile, maxChicken2048Tile(this.boardTiles)),
          continueGame: () => {},
          restartGame: () => {
            this.restart();
          },
          exitToHub: () => {
            this.leaveToHub();
          }
        })
        .zIndex(30)
      }
      if (this.showExitConfirmOverlay) {
        Chicken2048ExitConfirmOverlay({
          pageWidth: this.pageWidth,
          pageHeight: this.pageHeight,
          currentScore: this.score,
          maxTileValue: Math.max(this.maxTile, maxChicken2048Tile(this.boardTiles)),
          cancelExit: () => {
            this.cancelExitConfirm();
          },
          confirmExit: () => {
            this.confirmExitToHub();
          }
        })
        .zIndex(30)
      }
      if (this.devToolsVisible) {
        this.DevToolsPanel()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#fff3dd')
    .onAreaChange((oldArea, newArea) => {
      const width = Number.parseFloat(`${newArea.width}`);
      const height = Number.parseFloat(`${newArea.height}`);
      if (!Number.isNaN(width) && !Number.isNaN(height)) {
        this.pageWidth = Math.max(280, width);
        this.pageHeight = Math.max(420, height);
      }
    })
  }

  @Builder
  TopBar() {
    Row({ space: 8 }) {
      Button('大厅')
        .width(62)
        .height(34)
        .borderRadius(17)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .backgroundColor('rgba(255,247,230,0.86)')
        .fontColor(CoopTheme.ink)
        .border({ width: 1, color: '#F2D8AD' })
        .onClick(() => {
          this.requestExitToHub();
        })
      Column() {
        Text('鸡窝 2048')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(CoopTheme.ink)
          .textAlign(TextAlign.Center)
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .layoutWeight(1)
      .onClick(() => {
        this.handleDevTitleTap();
      })
      Button(this.paused ? '继续' : '暂停')
        .width(62)
        .height(34)
        .borderRadius(17)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .backgroundColor('rgba(72,42,26,0.88)')
        .fontColor('#ffffff')
        .onClick(() => {
          if (this.gameOver || this.showWinOverlay) {
            return;
          }
          if (this.showExitConfirmOverlay) {
            return;
          }
          this.paused = !this.paused;
        })
    }
    .position({ x: 0, y: 0 })
    .width('100%')
    .height(this.topBarHeight())
    .padding({ left: 6, right: 14, top: this.topBarPaddingTop() })
    .zIndex(5)
  }

  @Builder
  ScoreRow() {
    Row({ space: this.scoreCardGap() }) {
      this.StatCard('本局得分', 'score')
      this.StatCard('最高分', 'best')
      this.StatCard('最大数字', 'max')
    }
    .position({ x: this.scoreRowLeft(), y: this.scoreRowTop() })
    .width(this.scoreRowWidth())
    .height(this.scoreCardHeight())
    .zIndex(2)
  }

  @Builder
  StatCard(label: string, kind: string) {
    Column({ space: 3 }) {
      Text(label)
        .fontSize(this.scoreLabelFontSize())
        .fontColor('#8b6645')
        .textAlign(TextAlign.Center)
      if (kind === 'score') {
        Text(`${this.score}`)
          .fontSize(this.scoreValueFontSize())
          .fontWeight(FontWeight.Bold)
          .fontColor('#5f3a22')
          .maxLines(1)
          .textAlign(TextAlign.Center)
      } else if (kind === 'best') {
        Text(`${Math.max(this.bestScore, this.score)}`)
          .fontSize(this.scoreValueFontSize())
          .fontWeight(FontWeight.Bold)
          .fontColor('#5f3a22')
          .maxLines(1)
          .textAlign(TextAlign.Center)
      } else {
        Text(`${Math.max(this.maxTile, maxChicken2048Tile(this.boardTiles))}`)
          .fontSize(this.scoreValueFontSize())
          .fontWeight(FontWeight.Bold)
          .fontColor('#5f3a22')
          .maxLines(1)
          .textAlign(TextAlign.Center)
      }
    }
    .layoutWeight(1)
    .height(this.scoreCardHeight())
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  BoardArea() {
    Row() {
      Stack({ alignContent: Alignment.TopStart }) {
        ForEach(this.slotIndexes(), (index: number) => {
          Row()
            .width(this.tileSize())
            .height(this.tileSize())
            .borderRadius(this.tileRadius())
            .backgroundColor('rgba(246,215,152,0.62)')
            .border({ width: 1, color: 'rgba(111,67,43,0.12)' })
            .position({ x: this.slotX(index), y: this.slotY(index) })
        }, (index: number) => `slot-${index}`)

        ForEach(this.displayTiles, (tile: Chicken2048Tile) => {
          this.TileView(tile)
        }, (tile: Chicken2048Tile) => this.tileRenderKey(tile))

        ForEach(this.spawnPulses, (pulse: Chicken2048SpawnPulse) => {
          this.SpawnPulseView(pulse)
        }, (pulse: Chicken2048SpawnPulse) => `${pulse.id}`)

        ForEach(this.mergePulses, (pulse: Chicken2048MergePulse) => {
          this.MergePulseView(pulse)
        }, (pulse: Chicken2048MergePulse) => `${pulse.id}`)
      }
      .width(this.boardSize())
      .height(this.boardSize())
      .borderRadius(30)
      .backgroundColor('#C58A58')
      .border({ width: 5, color: '#7B4A2F' })
      .shadow({
        radius: 20,
        color: 'rgba(71,39,23,0.20)',
        offsetX: 0,
        offsetY: 10
      })
      .clip(true)
      .onTouch((event: TouchEvent) => {
        this.handleBoardTouch(event);
      })
    }
    .position({ x: 0, y: this.boardTop() })
    .width('100%')
    .height(this.boardSize())
    .justifyContent(FlexAlign.Center)
    .padding({ left: 14, right: 14 })
    .zIndex(2)
  }

  @Builder
  TileView(tile: Chicken2048Tile) {
    Stack({ alignContent: Alignment.Center }) {
      Text(`${tile.value}`)
        .width(this.tileTextWidth())
        .height(this.tileSize())
        .fontSize(this.tileFontSize(tile.value))
        .fontWeight(FontWeight.Bold)
        .fontColor(this.tileTextColor(tile.value))
        .textAlign(TextAlign.Center)
        .maxLines(1)
    }
    .width(this.tileSize())
    .height(this.tileSize())
    .borderRadius(this.tileRadius())
    .backgroundColor(this.tileColor(tile.value))
    .border({ width: 3, color: '#70432B' })
    .shadow({
      radius: 8,
      color: 'rgba(65,35,20,0.16)',
      offsetX: 0,
      offsetY: 5
    })
    .opacity(tile.opacity)
    .scale({ x: tile.scale, y: tile.scale })
    .position({ x: this.tileX(tile), y: this.tileY(tile) })
  }

  @Builder
  MergePulseView(pulse: Chicken2048MergePulse) {
    Chicken2048MergePulseTile({
      value: pulse.value,
      variant: pulse.variant,
      tileSizeValue: this.tileSize(),
      radius: this.tileRadius(),
      fontSize: this.tileFontSize(pulse.value),
      tileBackground: this.tileColor(pulse.value),
      textColor: this.tileTextColor(pulse.value)
    })
    .position({ x: this.tileXByCell(pulse.col), y: this.tileYByCell(pulse.row) })
    .hitTestBehavior(HitTestMode.None)
  }

  @Builder
  SpawnPulseView(pulse: Chicken2048SpawnPulse) {
    Chicken2048SpawnPulseTile({
      value: pulse.value,
      tileSizeValue: this.tileSize(),
      radius: this.tileRadius(),
      fontSize: this.tileFontSize(pulse.value),
      tileBackground: this.tileColor(pulse.value),
      textColor: this.tileTextColor(pulse.value)
    })
    .position({ x: this.tileXByCell(pulse.col), y: this.tileYByCell(pulse.row) })
    .hitTestBehavior(HitTestMode.None)
  }

  @Builder
  HintLine() {
    Text(this.statusText())
      .width('100%')
      .padding({ left: 18, right: 18 })
      .fontSize(13)
      .fontColor(CoopTheme.brandDark)
      .textAlign(TextAlign.Center)
      .maxLines(2)
      .position({ x: 0, y: this.hintTop() })
      .zIndex(2)
  }

  @Builder
  ControlPad() {
    Column({ space: 7 }) {
      this.DirectionKey('↑', 'up')
      Row({ space: 11 }) {
        this.DirectionKey('←', 'left')
        this.DirectionKey('↓', 'down')
        this.DirectionKey('→', 'right')
      }
      .justifyContent(FlexAlign.Center)
    }
    .position({ x: 0, y: this.controlPadTop() })
    .width('100%')
    .height(this.controlPadHeight())
    .alignItems(HorizontalAlign.Center)
    .padding({ left: 18, right: 18, top: 2, bottom: 2 })
    .zIndex(2)
  }

  @Builder
  DevToolsPanel() {
    Row({ space: 7 }) {
      this.DevToolButton('触发2048', () => {
        this.triggerDevSuccess();
      })
      this.DevToolButton('触发失败', () => {
        this.triggerDevFailure();
      })
      this.DevToolButton('隐藏', () => {
        this.devToolsVisible = false;
      })
    }
    .position({ x: Math.max(10, this.pageWidth - this.devPanelWidth() - 10), y: this.devPanelY() })
    .width(this.devPanelWidth())
    .height(36)
    .padding({ left: 8, right: 8 })
    .borderRadius(18)
    .backgroundColor('rgba(61,38,24,0.78)')
    .border({ width: 1, color: 'rgba(255,244,214,0.34)' })
    .shadow({
      radius: 10,
      color: 'rgba(45,25,14,0.22)',
      offsetX: 0,
      offsetY: 5
    })
    .zIndex(12)
  }

  @Builder
  DevToolButton(label: string, action: () => void) {
    Text(label)
      .height(26)
      .padding({ left: 7, right: 7 })
      .borderRadius(13)
      .fontSize(11)
      .fontWeight(FontWeight.Bold)
      .fontColor('#fff7df')
      .textAlign(TextAlign.Center)
      .backgroundColor('rgba(255,246,227,0.18)')
      .border({ width: 1, color: 'rgba(255,246,227,0.16)' })
      .onClick(() => {
        action();
      })
  }

  @Builder
  DirectionKey(label: string, direction: Chicken2048Direction) {
    Stack({ alignContent: Alignment.Center }) {
      Text(label)
        .width(this.controlButtonSize())
        .height(this.controlButtonSize())
        .fontSize(this.controlButtonFontSize())
        .fontWeight(FontWeight.Bold)
        .fontColor(this.inputDisabled() ? 'rgba(47,29,20,0.42)' : CoopTheme.ink)
        .textAlign(TextAlign.Center)
    }
    .width(this.controlButtonSize())
    .height(this.controlButtonSize())
    .borderRadius(this.controlButtonSize() / 2)
    .backgroundColor(this.inputDisabled() ? '#F2D9B4' : '#FFF6E3')
    .border({ width: 1, color: '#E7C58D' })
    .shadow({
      radius: 8,
      color: 'rgba(75,42,22,0.10)',
      offsetX: 0,
      offsetY: 4
    })
    .onClick(() => {
      this.tryMove(direction);
    })
  }

  @Builder
  PauseOverlay() {
    CoopModalTransition({
      maskColor: 'rgba(39,24,15,0.52)',
      panelScaleFrom: 0.96,
      panelOffsetVp: 8
    }) {
      Column({ space: 12 }) {
        Text('2048 暂停')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor(CoopTheme.ink)
        Button('继续')
          .width(168)
          .height(44)
          .borderRadius(22)
          .backgroundColor(CoopTheme.ink)
          .fontColor('#ffffff')
          .onClick(() => {
            this.paused = false;
          })
        Button('再来一局')
          .width(168)
          .height(42)
          .borderRadius(21)
          .backgroundColor('#FFF6E3')
          .fontColor(CoopTheme.ink)
          .border({ width: 1, color: '#E7C58D' })
          .onClick(() => {
            this.restart();
          })
      }
      .width(248)
      .padding({ left: 22, right: 22, top: 24, bottom: 24 })
      .borderRadius(26)
      .backgroundColor('rgba(255,250,238,0.94)')
      .border({ width: 1, color: 'rgba(255,255,255,0.84)' })
      .shadow(CoopTheme.shadow)
      .alignItems(HorizontalAlign.Center)
    }
  }

  private restart(): void {
    this.clearMergePulseTimers();
    this.clearSpawnPulseTimer();
    this.nextTileId = 1;
    this.nextMergePulseId = 1;
    this.nextSpawnPulseId = 1;
    this.inputLocked = false;
    this.mergePulses = [];
    this.spawnPulses = [];
    this.scoreReported = false;
    this.score = 0;
    this.maxTile = 0;
    this.movesMade = 0;
    this.won = false;
    this.paused = false;
    this.gameOver = false;
    this.showWinOverlay = false;
    this.showExitConfirmOverlay = false;
    this.devToolsVisible = false;
    this.pausedBeforeExitConfirm = false;
    const initialTiles = createInitialChicken2048Tiles(this.nextTileId);
    this.boardTiles = normalizeChicken2048Tiles(initialTiles);
    this.displayTiles = normalizeChicken2048Tiles(initialTiles);
    this.nextTileId += initialTiles.length;
    this.maxTile = maxChicken2048Tile(initialTiles);
  }

  private tryMove(direction: Chicken2048Direction): void {
    if (this.inputDisabled()) {
      return;
    }
    const result = moveChicken2048Tiles(this.boardTiles, direction);
    if (!result.moved) {
      if (!canMoveChicken2048(this.boardTiles)) {
        this.finishGame();
      }
      return;
    }

    this.clearMergePulseTimers();
    this.clearSpawnPulseTimer();
    this.inputLocked = true;
    this.movesMade += 1;
    const nextScore = this.score + result.scoreGain;
    this.score = nextScore;
    this.maxTile = Math.max(this.maxTile, result.maxTile);
    const reachedTarget = !this.won && result.maxTile >= CHICKEN_2048_TARGET;

    const settledTiles = normalizeChicken2048Tiles(result.finalTiles);
    const nextTileId = this.nextTileId;
    const nextTiles = addRandomChicken2048Tile(settledTiles, nextTileId);
    if (nextTiles.length > settledTiles.length) {
      this.nextTileId += 1;
    }
    this.boardTiles = normalizeChicken2048Tiles(nextTiles);
    this.displayTiles = normalizeChicken2048Tiles(nextTiles);
    this.inputLocked = false;
    this.playSpawnPulse(nextTiles, nextTileId);
    this.playMergePulse(result.merges);

    if (reachedTarget) {
      this.won = true;
      this.showWinOverlay = true;
      return;
    }
    if (!canMoveChicken2048(this.boardTiles)) {
      this.finishGame();
    }
  }

  private finishGame(): void {
    if (this.gameOver) {
      return;
    }
    this.gameOver = true;
    this.showWinOverlay = false;
    this.safeRecordScore();
  }

  private safeRecordScore(): void {
    if (this.scoreReported) {
      return;
    }
    this.scoreReported = true;
    this.recordScore(this.score);
  }

  private leaveToHub(): void {
    if (this.hasGameStarted()) {
      this.safeRecordScore();
    }
    this.exitToHub();
  }

  private requestExitToHub(): void {
    if (this.gameOver || !this.hasGameStarted()) {
      this.leaveToHub();
      return;
    }
    if (this.showExitConfirmOverlay) {
      return;
    }
    this.pausedBeforeExitConfirm = this.paused;
    this.paused = true;
    this.showExitConfirmOverlay = true;
  }

  private cancelExitConfirm(): void {
    this.showExitConfirmOverlay = false;
    this.paused = this.pausedBeforeExitConfirm;
    this.pausedBeforeExitConfirm = false;
  }

  private confirmExitToHub(): void {
    this.showExitConfirmOverlay = false;
    this.leaveToHub();
  }

  private handleDevTitleTap(): void {
    const now = Date.now();
    if (now - this.devLastTapAt > DEV_TOOLS_TAP_WINDOW_MS) {
      this.devTapCount = 0;
    }
    this.devLastTapAt = now;
    this.devTapCount += 1;
    if (this.devTapCount < DEV_TOOLS_TAP_THRESHOLD) {
      return;
    }
    this.devTapCount = 0;
    this.devToolsVisible = !this.devToolsVisible;
  }

  private triggerDevSuccess(): void {
    const values: number[] = [
      2048, 512, 128, 32,
      256, 64, 16, 4,
      128, 32, 8, 2,
      64, 16, 4, 2
    ];
    this.applyDevBoard(values, 2048);
    this.won = true;
    this.gameOver = false;
    this.showExitConfirmOverlay = false;
    this.showWinOverlay = true;
    this.paused = false;
  }

  private triggerDevFailure(): void {
    const values: number[] = [
      2, 4, 2, 4,
      4, 2, 4, 2,
      2, 4, 2, 4,
      4, 2, 4, 2
    ];
    this.applyDevBoard(values, 512);
    this.won = false;
    this.showWinOverlay = false;
    this.showExitConfirmOverlay = false;
    this.paused = false;
    this.gameOver = true;
  }

  private applyDevBoard(values: number[], score: number): void {
    this.clearMergePulseTimers();
    this.clearSpawnPulseTimer();
    this.inputLocked = false;
    this.mergePulses = [];
    this.spawnPulses = [];
    this.scoreReported = false;
    this.score = score;
    this.movesMade = 1;
    const tiles = this.devTilesFromValues(values);
    this.boardTiles = normalizeChicken2048Tiles(tiles);
    this.displayTiles = normalizeChicken2048Tiles(tiles);
    this.maxTile = maxChicken2048Tile(tiles);
    this.nextTileId = tiles.length + 1;
  }

  private devTilesFromValues(values: number[]): Chicken2048Tile[] {
    const tiles: Chicken2048Tile[] = [];
    values.forEach((value: number, index: number) => {
      if (value <= 0) {
        return;
      }
      const row = Math.floor(index / CHICKEN_2048_SIZE);
      const col = index % CHICKEN_2048_SIZE;
      tiles.push({
        id: tiles.length + 1,
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
      });
    });
    return tiles;
  }

  private handleBoardTouch(event: TouchEvent): void {
    const point = this.touchPoint(event);
    if (event.type === TouchType.Down) {
      this.touchStartX = point.x;
      this.touchStartY = point.y;
      return;
    }
    if (event.type === TouchType.Up) {
      const dx = point.x - this.touchStartX;
      const dy = point.y - this.touchStartY;
      this.handleSwipe(dx, dy);
      return;
    }
    if (event.type === TouchType.Cancel) {
      this.touchStartX = 0;
      this.touchStartY = 0;
    }
  }

  private handleSwipe(dx: number, dy: number): void {
    if (Math.max(Math.abs(dx), Math.abs(dy)) < SWIPE_THRESHOLD) {
      return;
    }
    if (Math.abs(dx) > Math.abs(dy)) {
      this.tryMove(dx > 0 ? 'right' : 'left');
      return;
    }
    this.tryMove(dy > 0 ? 'down' : 'up');
  }

  private touchPoint(event: TouchEvent): Chicken2048Point {
    if (event.touches !== undefined && event.touches.length > 0) {
      return { x: event.touches[0].x, y: event.touches[0].y };
    }
    if (event.changedTouches !== undefined && event.changedTouches.length > 0) {
      return { x: event.changedTouches[0].x, y: event.changedTouches[0].y };
    }
    return { x: 0, y: 0 };
  }

  private playMergePulse(merges: Chicken2048MergeEvent[]): void {
    this.clearMergePulseTimers();
    if (merges.length === 0) {
      this.mergePulses = [];
      return;
    }

    const pulses: Chicken2048MergePulse[] = [];
    merges.forEach((merge: Chicken2048MergeEvent) => {
      pulses.push({
        id: this.nextMergePulseId,
        row: merge.row,
        col: merge.col,
        value: merge.value,
        variant: this.nextMergePulseId % MERGE_BURST_PALETTES.length
      });
      this.nextMergePulseId += 1;
    });
    this.mergePulses = pulses;
    this.mergePulseClearTimer = setTimeout(() => {
      this.mergePulseClearTimer = -1;
      this.mergePulses = [];
    }, MERGE_PULSE_CLEAR_DELAY);
  }

  private clearMergePulseTimers(): void {
    if (this.mergePulseClearTimer !== -1) {
      clearTimeout(this.mergePulseClearTimer);
      this.mergePulseClearTimer = -1;
    }
  }

  private playSpawnPulse(tiles: Chicken2048Tile[], tileId: number): void {
    this.clearSpawnPulseTimer();
    const tile = tiles.find((item: Chicken2048Tile) => item.id === tileId);
    if (tile === undefined) {
      this.spawnPulses = [];
      return;
    }
    this.spawnPulses = [{
      id: this.nextSpawnPulseId,
      row: tile.row,
      col: tile.col,
      value: tile.value
    }];
    this.nextSpawnPulseId += 1;
    this.spawnPulseClearTimer = setTimeout(() => {
      this.spawnPulseClearTimer = -1;
      this.spawnPulses = [];
    }, SPAWN_PULSE_CLEAR_DELAY);
  }

  private clearSpawnPulseTimer(): void {
    if (this.spawnPulseClearTimer !== -1) {
      clearTimeout(this.spawnPulseClearTimer);
      this.spawnPulseClearTimer = -1;
    }
  }

  private inputDisabled(): boolean {
    return this.inputLocked || this.paused || this.gameOver || this.showWinOverlay || this.showExitConfirmOverlay;
  }

  private hasGameStarted(): boolean {
    return this.movesMade > 0 || this.score > 0;
  }

  private statusText(): string {
    if (this.gameOver) {
      return '没有可移动方块了';
    }
    if (this.showWinOverlay) {
      return '2048 已达成';
    }
    if (this.paused) {
      return '鸡窝暂停整理中';
    }
    return '滑动棋盘，或点方向键合成数字块';
  }

  private boardSize(): number {
    const heightLimit = this.pageHeight * (this.pageHeight < 700 ? 0.34 : 0.37);
    const widthLimit = this.pageWidth - (this.pageWidth < 340 ? 46 : 58);
    return Math.floor(Math.max(220, Math.min(widthLimit, heightLimit, 430)));
  }

  private topBarHeight(): number {
    return this.pageHeight < 700 ? 68 : 78;
  }

  private topBarPaddingTop(): number {
    return this.pageHeight < 700 ? 26 : 34;
  }

  private scoreRowTop(): number {
    return Math.round(this.pageHeight * 0.246);
  }

  private scoreRowLeft(): number {
    return Math.round(this.pageWidth * 0.069);
  }

  private scoreRowWidth(): number {
    return Math.round(this.pageWidth * 0.862);
  }

  private scoreCardHeight(): number {
    return Math.round(Math.max(46, Math.min(68, this.pageHeight * 0.069)));
  }

  private scoreCardGap(): number {
    return Math.round(this.pageWidth * 0.023);
  }

  private scoreLabelFontSize(): number {
    return this.pageHeight < 700 ? 9 : 11;
  }

  private scoreValueFontSize(): number {
    return this.pageHeight < 700 ? 17 : 20;
  }

  private boardTop(): number {
    return Math.round(this.pageHeight * (this.pageHeight < 700 ? 0.345 : 0.355));
  }

  private hintTop(): number {
    return Math.round(this.boardTop() + this.boardSize() + 8);
  }

  private controlPadTop(): number {
    const preferred = this.boardTop() + this.boardSize() + (this.pageHeight < 700 ? 28 : 34);
    const bottomLimit = this.pageHeight - this.controlPadHeight() - (this.pageHeight < 700 ? 18 : 36);
    return Math.round(Math.max(this.hintTop() + 22, Math.min(preferred, bottomLimit)));
  }

  private devPanelWidth(): number {
    return this.pageWidth < 360 ? 236 : 258;
  }

  private devPanelY(): number {
    return this.pageHeight < 700 ? 96 : 104;
  }

  private boardPadding(): number {
    return Math.max(11, Math.floor(this.boardSize() * 0.044));
  }

  private boardGap(): number {
    return Math.max(7, Math.floor(this.boardSize() * 0.03));
  }

  private tileSize(): number {
    return Math.floor((this.boardSize() - this.boardPadding() * 2 - this.boardGap() * (CHICKEN_2048_SIZE - 1)) / CHICKEN_2048_SIZE);
  }

  private tilePitch(): number {
    return this.tileSize() + this.boardGap();
  }

  private tileRadius(): number {
    return Math.max(14, Math.floor(this.tileSize() * 0.20));
  }

  private tileX(tile: Chicken2048Tile): number {
    return this.boardPadding() + tile.col * this.tilePitch();
  }

  private tileY(tile: Chicken2048Tile): number {
    return this.boardPadding() + tile.row * this.tilePitch();
  }

  private tileXByCell(col: number): number {
    return this.boardPadding() + col * this.tilePitch();
  }

  private tileYByCell(row: number): number {
    return this.boardPadding() + row * this.tilePitch();
  }

  private tileRenderKey(tile: Chicken2048Tile): string {
    return `${tile.id}-${tile.value}-${tile.row}-${tile.col}`;
  }

  private slotX(index: number): number {
    return this.boardPadding() + (index % CHICKEN_2048_SIZE) * this.tilePitch();
  }

  private slotY(index: number): number {
    return this.boardPadding() + Math.floor(index / CHICKEN_2048_SIZE) * this.tilePitch();
  }

  private slotIndexes(): number[] {
    const result: number[] = [];
    for (let i = 0; i < CHICKEN_2048_SIZE * CHICKEN_2048_SIZE; i += 1) {
      result.push(i);
    }
    return result;
  }

  private controlPadHeight(): number {
    return this.controlButtonSize() * 2 + 11;
  }

  private controlButtonSize(): number {
    return this.pageHeight < 700 ? 46 : 52;
  }

  private controlButtonFontSize(): number {
    return this.pageHeight < 700 ? 23 : 27;
  }

  private tileFontSize(value: number): number {
    const digits = `${Math.max(0, Math.floor(value))}`.length;
    const tileSize = this.tileSize();
    let preferred = Math.floor(tileSize * 0.42);
    if (digits === 2) {
      preferred = Math.floor(tileSize * 0.38);
    } else if (digits === 3) {
      preferred = Math.floor(tileSize * 0.32);
    } else if (digits === 4) {
      preferred = Math.floor(tileSize * 0.26);
    } else if (digits >= 5) {
      preferred = Math.floor(tileSize * 0.21);
    }
    const widthLimit = Math.floor((this.tileTextWidth() / Math.max(1, digits)) * 1.42);
    const heightLimit = Math.floor(tileSize * 0.44);
    return Math.max(14, Math.min(preferred, widthLimit, heightLimit));
  }

  private tileTextWidth(): number {
    return Math.round(this.tileSize() * 0.84);
  }

  private tileColor(value: number): string {
    if (value === 2) return '#FFF4DA';
    if (value === 4) return '#FFE28A';
    if (value === 8) return '#FFC0D7';
    if (value === 16) return '#B8ECD9';
    if (value === 32) return '#FFB870';
    if (value === 64) return '#D9C69D';
    if (value === 128) return '#B9E0F6';
    if (value === 256) return '#F69AA0';
    if (value === 512) return '#98DF9F';
    if (value === 1024) return '#F7CF86';
    if (value === 2048) return '#FFF0A7';
    return '#E9D8FF';
  }

  private tileTextColor(value: number): string {
    return value >= 8 ? '#6F432B' : '#70432B';
  }
}
