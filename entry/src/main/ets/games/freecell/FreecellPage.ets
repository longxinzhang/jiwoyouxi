import { common } from '@kit.AbilityKit';
import { NativeAudioService } from '../../services/AudioService';
import { FreecellBoard } from './FreecellBoard';
import { FreecellDecor } from './FreecellDecor';
import { computeFreecellLayout } from './FreecellLayout';
import { FreecellResultOverlay } from './FreecellResultOverlay';
import { FreecellTheme } from './FreecellTheme';
import { FreecellToolbar } from './FreecellToolbar';
import {
  FreecellLayout,
  FreecellLocation,
  FreecellMove,
  FreecellSnapshot,
  FreecellState
} from './FreecellTypes';
import {
  applyMove,
  cloneLocation,
  cloneMove,
  cloneState,
  collectHints,
  createSolvableGame,
  findAutoCompleteMove,
  findSafeFoundationMove,
  findSmartMove,
  gameStateKey,
  getMovableCards,
  hintKey,
  isWon,
  locationMatches,
  randomSeed
} from './FreecellRules';

const DOUBLE_TAP_MS: number = 360;

@Component
export struct FreecellPage {
  @Prop bestScore: number = 0;
  exitToHub: () => void = () => {};
  recordScore: (score: number) => void = () => {};
  private timer: number = -1;
  private toastTimer: number = -1;
  private autoTimer: number = -1;
  private autoVisited: string[] = [];
  private lastTapCardId: string = '';
  private lastTapAt: number = 0;
  private settled: boolean = false;
  private audioService: NativeAudioService = new NativeAudioService();
  @State pageWidth: number = 390;
  @State pageHeight: number = 760;
  @State gameState: FreecellState = createSolvableGame(randomSeed());
  @State history: FreecellSnapshot[] = [];
  @State recentMoves: FreecellMove[] = [];
  @State selectedLocation: FreecellLocation | null = null;
  @State hintMarks: FreecellLocation[] = [];
  @State lastHintKey: string = '';
  @State moves: number = 0;
  @State score: number = 0;
  @State elapsed: number = 0;
  @State started: boolean = false;
  @State autoRunning: boolean = false;
  @State toastText: string = '';
  @State toastVisible: boolean = false;
  @State won: boolean = false;
  @State showResultOverlay: boolean = false;

  aboutToAppear(): void {
    const context = this.getUIContext().getHostContext();
    if (context !== undefined) {
      this.audioService.init(context as common.Context);
    }
  }

  aboutToDisappear(): void {
    this.stopTimer();
    this.stopAutoComplete();
    this.clearToastTimer();
    this.audioService.release();
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Image($rawfile('games/freecell/page_bg_coop_garden.png'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(255,251,232,0.08)')

      FreecellDecor({
        pageWidth: this.pageWidth,
        pageHeight: this.pageHeight
      })

      FreecellBoard({
        pageWidth: this.pageWidth,
        pageHeight: this.pageHeight,
        state: this.gameState,
        selectedLocation: this.selectedLocation,
        hintMarks: this.hintMarks,
        tapSource: (source: FreecellLocation, cardId: string) => {
          this.handleSourceTap(source, cardId);
        },
        tapTarget: (target: FreecellLocation) => {
          this.handleTargetTap(target);
        },
        dropSource: (source: FreecellLocation, target: FreecellLocation) => {
          this.handleDrop(source, target);
        }
      })

      this.HudView()

      FreecellToolbar({
        pageWidth: this.pageWidth,
        pageHeight: this.pageHeight,
        autoRunning: this.autoRunning,
        newGame: () => {
          this.newGame();
        },
        undo: () => {
          this.undo();
        },
        autoMove: () => {
          this.toggleAutoComplete();
        },
        hint: () => {
          this.showHint();
        }
      })

      if (this.toastVisible) {
        this.ToastView()
      }

      if (this.won && this.showResultOverlay) {
        FreecellResultOverlay({
          score: this.currentScore(),
          moves: this.currentMoves(),
          elapsedText: this.timeText(),
          restartGame: () => {
            this.newGame();
          },
          exitToHub: () => {
            this.exitToHub();
          },
          closeOverlay: () => {
            this.showResultOverlay = false;
          }
        })
      }
    }
    .width('100%')
    .height('100%')
    .onAreaChange((oldArea, newArea) => {
      const width = Number.parseFloat(`${newArea.width}`);
      const height = Number.parseFloat(`${newArea.height}`);
      if (!Number.isNaN(width) && !Number.isNaN(height)) {
        this.pageWidth = Math.max(280, width);
        this.pageHeight = Math.max(520, height);
      }
    })
  }

  @Builder
  ToastView() {
    Text(this.toastText)
      .width(this.toastWidth())
      .padding({ left: 12, right: 12, top: 9, bottom: 9 })
      .borderRadius(8)
      .backgroundColor(FreecellTheme.toastBg)
      .fontSize(13)
      .fontWeight(FontWeight.Bold)
      .fontColor('#fff7df')
      .lineHeight(18)
      .textAlign(TextAlign.Center)
      .position({ x: (this.pageWidth - this.toastWidth()) * 0.5, y: this.toastY() })
  }

  @Builder
  HudView() {
    Stack({ alignContent: Alignment.TopStart }) {
      this.HudTitle()
      this.HudBackButton()
      this.HudTopActions()
      this.HudStats()
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.Transparent)
  }

  @Builder
  HudTitle() {
    Image($rawfile('games/freecell/klondike_title_banner_cut.png'))
      .width(this.layout().titleWidth)
      .height(this.layout().titleHeight)
      .objectFit(ImageFit.Contain)
      .position({
        x: this.layout().offsetX + (this.layout().appWidth - this.layout().titleWidth) * 0.5,
        y: this.layout().titleTop
      })
      .shadow({ radius: 4, color: 'rgba(88,45,8,0.16)', offsetX: 0, offsetY: 4 })
  }

  @Builder
  HudBackButton() {
    Image($rawfile('games/freecell/btn_back_hall.png'))
      .width(this.hudBackWidth())
      .height(this.hudBackHeight())
      .objectFit(ImageFit.Contain)
      .position({
        x: this.layout().offsetX + (this.layout().tiny ? 4 : 5),
        y: this.layout().titleTop + this.layout().titleHeight * (this.layout().tiny ? 0.38 : 0.42)
      })
      .onClick(() => {
        this.exitToHub();
      })
  }

  @Builder
  HudTopActions() {
    if (this.layout().tiny) {
      this.HudTopAction('games/freecell/btn_settings_cut.png', '设置', 0, () => {
        this.newGame();
      })
    } else {
      this.HudTopAction('games/freecell/btn_undo_cut.png', '撤销', 0, () => {
        this.undo();
      })
      this.HudTopAction('games/freecell/btn_hint_cut_cut.png', '提示', 1, () => {
        this.showHint();
      })
      this.HudTopAction('games/freecell/btn_settings_cut.png', '设置', 2, () => {
        this.newGame();
      })
    }
  }

  @Builder
  HudTopAction(path: string, label: string, index: number, action: () => void) {
    Stack({ alignContent: Alignment.Top }) {
      Image($rawfile(path))
        .width(this.hudTopIconWidth())
        .height(this.hudTopIconWidth())
        .objectFit(ImageFit.Contain)
      Text(label)
        .width(this.hudTopIconWidth())
        .fontSize(this.layout().tiny ? 6 : 8)
        .fontWeight(FontWeight.Bold)
        .fontColor(FreecellTheme.brown)
        .textAlign(TextAlign.Center)
        .textShadow({ radius: 1, color: 'rgba(255,248,224,0.86)', offsetX: 0, offsetY: 1 })
        .position({ x: 0, y: this.hudTopIconWidth() + (this.layout().tiny ? 4 : 6) })
    }
    .width(this.hudTopIconWidth())
    .height(this.hudTopIconWidth() + 16)
    .position({
      x: this.hudTopStartX() + index * (this.hudTopIconWidth() + this.hudTopGap()),
      y: this.hudTopY()
    })
    .onClick(() => {
      action();
    })
  }

  @Builder
  HudStats() {
    this.HudStatCard('games/freecell/card_score_cut.png', 'score', 0, false)
    this.HudStatCard('games/freecell/card_timer_cut.png', 'timer', 1, true)
    this.HudStatCard('games/freecell/card_steps_cut.png', 'moves', 2, false)
    this.HudStatCard('games/freecell/card_best_score_cut.png', 'best', 3, false)
    if (!this.layout().compact) {
      Image($rawfile('games/freecell/coop_badge_corner_cut.png'))
        .width(Math.min(44, this.layout().appWidth * 0.13))
        .height(Math.min(44, this.layout().appWidth * 0.13) * 364 / 448)
        .objectFit(ImageFit.Contain)
        .position({
          x: this.layout().offsetX + this.layout().appWidth - Math.min(44, this.layout().appWidth * 0.13) - 2,
          y: this.layout().statsTop + this.layout().statHeight * 0.08
        })
    }
  }

  @Builder
  HudStatCard(path: string, kind: string, index: number, timer: boolean) {
    Stack({ alignContent: Alignment.TopStart }) {
      Image($rawfile(path))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Contain)
      if (kind === 'score') {
        Text(`${this.score}`)
          .width(this.hudStatValueWidth(timer))
          .height(this.hudStatValueHeight())
          .fontSize(this.hudStatValueFontSize(timer))
          .fontWeight(FontWeight.Bold)
          .fontColor(FreecellTheme.deepBrown)
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .backgroundColor('#fff4dc')
          .position({ x: this.hudStatValueX(timer), y: this.hudStatValueY() })
      } else if (kind === 'timer') {
        Text(this.formatTime(this.elapsed))
          .width(this.hudStatValueWidth(timer))
          .height(this.hudStatValueHeight())
          .fontSize(this.hudStatValueFontSize(timer))
          .fontWeight(FontWeight.Bold)
          .fontColor(FreecellTheme.deepBrown)
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .backgroundColor('#fff4dc')
          .position({ x: this.hudStatValueX(timer), y: this.hudStatValueY() })
      } else if (kind === 'moves') {
        Text(`${this.moves}`)
          .width(this.hudStatValueWidth(timer))
          .height(this.hudStatValueHeight())
          .fontSize(this.hudStatValueFontSize(timer))
          .fontWeight(FontWeight.Bold)
          .fontColor(FreecellTheme.deepBrown)
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .backgroundColor('#fff4dc')
          .position({ x: this.hudStatValueX(timer), y: this.hudStatValueY() })
      } else {
        Text(`${Math.max(this.bestScore, this.score)}`)
          .width(this.hudStatValueWidth(timer))
          .height(this.hudStatValueHeight())
          .fontSize(this.hudStatValueFontSize(timer))
          .fontWeight(FontWeight.Bold)
          .fontColor(FreecellTheme.deepBrown)
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .backgroundColor('#fff4dc')
          .position({ x: this.hudStatValueX(timer), y: this.hudStatValueY() })
      }
    }
    .width(this.layout().statWidth)
    .height(this.layout().statHeight)
    .position({
      x: this.layout().offsetX + this.layout().side + index * (this.layout().statWidth + this.layout().statGap),
      y: this.layout().statsTop
    })
  }

  private handleSourceTap(source: FreecellLocation, cardId: string): void {
    if (this.won) {
      return;
    }
    this.stopAutoComplete();
    const now = Date.now();
    if (this.lastTapCardId === cardId && now - this.lastTapAt <= DOUBLE_TAP_MS) {
      this.lastTapCardId = '';
      this.smartMove(source);
      return;
    }
    this.lastTapCardId = cardId;
    this.lastTapAt = now;

    if (this.selectedLocation !== null) {
      if (locationMatches(this.selectedLocation, source)) {
        this.smartMove(source);
        return;
      }
      const target = this.sourceAsTarget(source);
      if (target !== null && this.performMove(this.selectedLocation, target)) {
        return;
      }
    }

    const movableCards = getMovableCards(this.gameState, source);
    if (movableCards.length <= 0) {
      this.showToast('这组牌暂时不能整体移动');
      return;
    }
    this.selectedLocation = cloneLocation(source);
    this.hintMarks = [];
    this.lastHintKey = '';
    this.playClick();
  }

  private handleTargetTap(target: FreecellLocation): void {
    if (this.won) {
      return;
    }
    this.stopAutoComplete();
    if (this.selectedLocation === null) {
      return;
    }
    this.performMove(this.selectedLocation, target);
  }

  private handleDrop(source: FreecellLocation, target: FreecellLocation): void {
    if (this.won) {
      return;
    }
    this.stopAutoComplete();
    this.performMove(source, target);
  }

  private sourceAsTarget(source: FreecellLocation): FreecellLocation | null {
    if (source.area === 'tableau') {
      return { area: 'tableau', index: source.index };
    }
    if (source.area === 'freecell') {
      return { area: 'freecell', index: source.index };
    }
    return null;
  }

  private smartMove(source: FreecellLocation): void {
    const target = findSmartMove(this.gameState, source);
    if (target === null) {
      this.selectedLocation = cloneLocation(source);
      this.showToast('暂时没有更合适的位置');
      return;
    }
    this.performMove(source, target);
  }

  private performMove(source: FreecellLocation, target: FreecellLocation): boolean {
    const nextState = cloneState(this.gameState);
    const before = this.snapshot();
    const move = applyMove(nextState, source, target);
    if (move === null) {
      this.showToast('不能移动到这里');
      return false;
    }

    const history = this.history.slice();
    history.push(before);
    if (history.length > 100) {
      history.shift();
    }
    this.history = history;

    const recent = this.recentMoves.map((item: FreecellMove) => cloneMove(item));
    recent.push(cloneMove(move));
    if (recent.length > 8) {
      recent.shift();
    }
    this.recentMoves = recent;

    this.moves = history.length;
    this.score = this.scoreForState(nextState);
    this.ensureStarted();
    this.gameState = nextState;
    this.selectedLocation = null;
    this.hintMarks = [];
    this.lastHintKey = '';
    this.playClick();
    this.checkWin();
    return true;
  }

  private showHint(): void {
    if (this.won) {
      return;
    }
    this.stopAutoComplete();
    const hints = collectHints(this.gameState, this.recentMoves, this.lastHintKey);
    this.playHint();
    if (hints.length <= 0) {
      this.hintMarks = [];
      this.lastHintKey = '';
      this.showToast('暂时没有明显可走的牌');
      return;
    }
    const hint = hints[0];
    this.hintMarks = [cloneLocation(hint.source), cloneLocation(hint.target)];
    this.lastHintKey = hintKey(hint);
    this.selectedLocation = null;
    this.showToast('已标出一个可行移动');
  }

  private toggleAutoComplete(): void {
    if (this.won) {
      return;
    }
    if (this.autoTimer !== -1) {
      this.stopAutoComplete();
      this.showToast('已停止自动推进');
      return;
    }
    this.selectedLocation = null;
    this.hintMarks = [];
    this.lastHintKey = '';
    this.autoVisited = [gameStateKey(this.gameState)];
    this.autoRunning = true;
    this.ensureStarted();
    this.autoCompleteStep(0);
  }

  private autoCompleteStep(movedCount: number): void {
    this.autoTimer = -1;
    if (this.won) {
      this.autoRunning = false;
      return;
    }
    let move = findSafeFoundationMove(this.gameState);
    if (move === null) {
      move = findAutoCompleteMove(this.gameState, this.recentMoves, this.autoVisited);
    }
    if (move === null) {
      this.autoRunning = false;
      this.showToast(movedCount > 0 ? '自动推进已暂停' : '暂无可自动推进的牌');
      return;
    }
    if (!this.performMove(move.source, move.target)) {
      this.autoRunning = false;
      this.showToast(movedCount > 0 ? '自动推进已暂停' : '暂无可自动推进的牌');
      return;
    }
    this.autoVisited.push(gameStateKey(this.gameState));
    if (movedCount >= 220) {
      this.autoRunning = false;
      this.showToast('自动推进已暂停');
      return;
    }
    this.autoTimer = setTimeout(() => {
      this.autoCompleteStep(movedCount + 1);
    }, 150);
  }

  private undo(): void {
    this.stopAutoComplete();
    if (this.history.length <= 0) {
      this.showToast('没有可撤销的步骤');
      return;
    }
    const history = this.history.slice();
    const previous = history.pop();
    if (previous === undefined) {
      return;
    }
    this.history = history;
    this.gameState = cloneState(previous.state);
    this.moves = previous.moves;
    this.moves = history.length;
    this.score = this.scoreForState(previous.state);
    this.recentMoves = previous.recentMoves.map((item: FreecellMove) => cloneMove(item));
    this.selectedLocation = null;
    this.hintMarks = [];
    this.lastHintKey = '';
    this.won = false;
    this.showResultOverlay = false;
    this.settled = false;
    this.playClick();
  }

  private newGame(): void {
    this.stopAutoComplete();
    this.stopTimer();
    this.gameState = createSolvableGame(randomSeed());
    this.history = [];
    this.recentMoves = [];
    this.selectedLocation = null;
    this.hintMarks = [];
    this.lastHintKey = '';
    this.moves = 0;
    this.score = 0;
    this.elapsed = 0;
    this.started = false;
    this.won = false;
    this.showResultOverlay = false;
    this.settled = false;
    this.playClick();
  }

  private snapshot(): FreecellSnapshot {
    return {
      state: cloneState(this.gameState),
      moves: this.moves,
      score: this.score,
      recentMoves: this.recentMoves.map((item: FreecellMove) => cloneMove(item))
    };
  }

  private checkWin(): void {
    if (!isWon(this.gameState) || this.settled) {
      return;
    }
    this.won = true;
    this.showResultOverlay = true;
    this.settled = true;
    this.stopAutoComplete();
    this.stopTimer();
    this.recordScore(this.currentScore());
  }

  private ensureStarted(): void {
    if (!this.started) {
      this.started = true;
    }
    if (this.timer !== -1) {
      return;
    }
    this.timer = setInterval(() => {
      if (this.started && !this.won) {
        this.elapsed += 1;
        this.gameState = cloneState(this.gameState);
      }
    }, 1000);
  }

  private stopTimer(): void {
    if (this.timer !== -1) {
      clearInterval(this.timer);
      this.timer = -1;
    }
  }

  private stopAutoComplete(): void {
    if (this.autoTimer !== -1) {
      clearTimeout(this.autoTimer);
      this.autoTimer = -1;
    }
    this.autoRunning = false;
    this.autoVisited = [];
  }

  private showToast(text: string): void {
    this.toastText = text;
    this.toastVisible = true;
    this.clearToastTimer();
    this.toastTimer = setTimeout(() => {
      this.toastVisible = false;
    }, 1700);
  }

  private clearToastTimer(): void {
    if (this.toastTimer !== -1) {
      clearTimeout(this.toastTimer);
      this.toastTimer = -1;
    }
  }

  private playClick(): void {
    this.audioService.play('freecellClick');
  }

  private playHint(): void {
    this.audioService.play('freecellHint');
  }

  private layout(): FreecellLayout {
    return computeFreecellLayout(this.pageWidth, this.pageHeight);
  }

  private timeText(): string {
    return this.formatTime(this.elapsed);
  }

  private formatTime(seconds: number): string {
    const min = Math.floor(seconds / 60);
    const sec = seconds % 60;
    const minText = min < 10 ? `0${min}` : `${min}`;
    const secText = sec < 10 ? `0${sec}` : `${sec}`;
    return `${minText}:${secText}`;
  }

  private currentMoves(): number {
    return this.history.length;
  }

  private currentScore(): number {
    return this.scoreForState(this.gameState);
  }

  private scoreForState(state: FreecellState): number {
    return (state.foundations.S.length +
      state.foundations.H.length +
      state.foundations.D.length +
      state.foundations.C.length) * 10;
  }

  private toastWidth(): number {
    return Math.min(this.pageWidth * 0.88, 390);
  }

  private toastY(): number {
    return Math.max(80, this.layout().toolbarTop - 46);
  }

  private hudBackWidth(): number {
    return Math.min(this.layout().appWidth * 0.2, this.layout().tiny ? 48 : 75);
  }

  private hudBackHeight(): number {
    return this.hudBackWidth() * 246 / 418;
  }

  private hudTopIconWidth(): number {
    return this.layout().tiny
      ? Math.min(23, Math.max(21, this.layout().cardWidth * 0.9))
      : Math.min(36, Math.max(28, this.layout().cardWidth * 1.05));
  }

  private hudTopGap(): number {
    return this.layout().tiny ? 0 : 4;
  }

  private hudTopStartX(): number {
    if (this.layout().tiny) {
      return this.layout().offsetX + this.layout().appWidth - this.layout().side - this.hudTopIconWidth();
    }
    return this.layout().offsetX + this.layout().appWidth - this.hudTopIconWidth() * 3 - this.hudTopGap() * 2 - 8;
  }

  private hudTopY(): number {
    return this.layout().titleTop + this.layout().titleHeight * (this.layout().tiny ? 0.38 : 0.46);
  }

  private hudStatValueX(timer: boolean): number {
    return this.layout().statWidth * (timer ? 0.38 : 0.5);
  }

  private hudStatValueY(): number {
    return this.layout().statHeight * (this.layout().compact && !this.layout().tiny ? 0.54 : 0.5);
  }

  private hudStatValueWidth(timer: boolean): number {
    return this.layout().statWidth * (timer ? 0.54 : 0.34);
  }

  private hudStatValueHeight(): number {
    return Math.max(14, this.layout().statHeight * 0.34);
  }

  private hudStatValueFontSize(timer: boolean): number {
    if (this.layout().tiny) {
      return timer ? Math.max(8, Math.min(10, this.layout().statHeight * 0.3)) : Math.max(10, Math.min(13, this.layout().statHeight * 0.36));
    }
    if (this.layout().compact) {
      return timer ? Math.max(9, Math.min(12, this.layout().statHeight * 0.24)) : Math.max(12, Math.min(17, this.layout().statHeight * 0.33));
    }
    return timer ? Math.max(9, this.layout().statHeight * 0.31) : Math.max(12, this.layout().statHeight * 0.45);
  }
}
