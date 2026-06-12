import { common } from '@kit.AbilityKit';
import image from '@ohos.multimedia.image';
import { CoopTheme } from '../../design/CoopTheme';
import { NativeAudioService } from '../../services/AudioService';
import { integrateFruits, resolveSuikaCollisions } from './SuikaPhysics';
import { getSpawnLevel, NEXT_FRUIT_DELAY_MS, resolveOverflowState } from './SuikaRules';
import { FRUITS, FruitBody, SuikaBounds } from './SuikaTypes';

const SUIKA_BACKGROUND_IMAGE: string = 'games/suika/backgrounds/market_full.png';
const SUIKA_BACKGROUND_WIDTH: number = 854;
const SUIKA_BACKGROUND_HEIGHT: number = 1842;
// 可调整：Canvas 图片缩放平滑开关。true 可以减少切图缩放后的锯齿感。
const SUIKA_IMAGE_SMOOTHING_ENABLED: boolean = true;
// 可调整：背景整体上下位置。数值越小越往上，数值越大越往下；建议每次只改 0.005 到 0.02。
const SUIKA_BACKGROUND_OFFSET_Y_RATIO: number = 0.11;
// 可调整：投放区域上下位置。数值越小越往上，数值越大越往下。
const SUIKA_BOARD_TOP_RATIO: number = 0.423;
// 可调整：小屏兜底顶部位置。数值越小越往上，数值越大越往下。
const SUIKA_BOARD_TOP_MIN: number = 250;
// 可调整：投放区域底部留白。数值越大，底部越短；数值越小，底部越高。
const SUIKA_BOARD_BOTTOM_MARGIN: number = 50;
// 可调整：投放区域最小高度兜底。数值越大，最小可玩区域越高。
const SUIKA_BOARD_MIN_HEIGHT: number = 130;
// 可调整：投放区域高度微调。正数变高，负数变矮；主要从底部扩展，不会把顶部往上顶。
const SUIKA_BOARD_HEIGHT_EXTRA: number = -16;
// 可调整：是否显示水果区域调试白框。true 显示白色定位框，false 只显示素材图。
const SUIKA_SHOW_BOARD_DEBUG_FRAME: boolean = false;
// 可调整：是否显示红色失败线。true 显示红线，false 隐藏红线；只影响显示，不影响失败判定。
const SUIKA_SHOW_FAIL_LINE: boolean = false;
// 可调整：顶部投放提示条上下位置。数值越小越往上，数值越大越往下。
const SUIKA_DROP_ZONE_TOP: number = 102;
// 可调整：顶部投放提示条高度。数值越大条越高，数值越小条越矮。
const SUIKA_DROP_ZONE_HEIGHT: number = 74;
// 可调整：顶部提示文字上下位置。数值越小越往上，数值越大越往下。
const SUIKA_DROP_ZONE_TEXT_Y: number = 128;
// 可调整：预览水果和投放杆起点。数值越小越往上，数值越大越往下。
const SUIKA_DROP_PREVIEW_Y: number = 295;
// 可调整：投放木板左边界。0.28 表示屏幕宽度 28% 的位置；数值越大，水果越不靠左。
const SUIKA_DROP_RAIL_LEFT_RATIO: number = 0.3;
// 可调整：投放木板右边界。0.72 表示屏幕宽度 72% 的位置；数值越小，水果越不靠右。
const SUIKA_DROP_RAIL_RIGHT_RATIO: number = 0.67;
// 可调整：投放木板左边界像素微调。正数向右，负数向左。
const SUIKA_DROP_RAIL_LEFT_OFFSET_X: number = 0;
// 可调整：投放木板右边界像素微调。正数向右，负数向左。
const SUIKA_DROP_RAIL_RIGHT_OFFSET_X: number = 0;
// 可调整：是否显示投放木板左右边界调试线。true 显示，false 隐藏。
const SUIKA_SHOW_DROP_RAIL_DEBUG: boolean = false;
// 可调整：预览水果横向偏移。正数向右，负数向左；只影响展示，不改变真实落点。
const SUIKA_DROP_PREVIEW_OFFSET_X: number = 0;
// 可调整：预览水果纵向偏移。正数向下，负数向上；用来把水果放到背景图木板上。
const SUIKA_DROP_PREVIEW_OFFSET_Y: number = 0;
// 可调整：投放前预览水果固定半径。所有水果投放前都显示这个大小；真实落下后仍按水果本身大小。
const SUIKA_DROP_PREVIEW_FIXED_RADIUS: number = 35;
// 可调整：预览水果大小倍率。1 表示使用固定半径原尺寸；0.8 更小，1.2 更大。
const SUIKA_DROP_PREVIEW_SCALE: number = 1.1;
// 可调整：是否显示投放前预览水果底部阴影。只画在木板接触处，不影响水果边缘。
const SUIKA_SHOW_DROP_PREVIEW_SHADOW: boolean = true;
// 可调整：木板预览水果阴影透明度。数值越大越明显，建议 0.12 到 0.24。
const SUIKA_DROP_PREVIEW_SHADOW_ALPHA: number = 0.18;
// 可调整：木板预览水果阴影上下位置。数值越大越靠下，建议 0.72 到 0.9。
const SUIKA_DROP_PREVIEW_SHADOW_Y_RATIO: number = 0.82;
// 可调整：木板预览水果阴影宽度。数值越大阴影越铺开，建议 0.62 到 0.9。
const SUIKA_DROP_PREVIEW_SHADOW_WIDTH_RATIO: number = 0.76;
// 可调整：木板预览水果阴影高度。数值越大阴影越厚，建议 0.08 到 0.18。
const SUIKA_DROP_PREVIEW_SHADOW_HEIGHT_RATIO: number = 0.12;
// 可调整：投放前预览水果是否叠加场景光影。false 会避免脸上蒙一层色块。
const SUIKA_DROP_PREVIEW_TINT_ENABLED: boolean = false;
// 可调整：是否显示投放竖线。false 隐藏，只保留水果展示和真实点击落点。
const SUIKA_SHOW_DROP_LINE: boolean = false;
// 可调整：投放杆底部长度。数值越大杆子越短，数值越小杆子越接近投放区域。
const SUIKA_DROP_LINE_BOTTOM_GAP: number = 8;
// 可调整：水果场景融合开关。当前默认关闭，避免透明边缘被遮罩放大成黑圈；false 保持原贴图。
const SUIKA_FRUIT_SCENE_TINT_ENABLED: boolean = false;
// 可调整：水果下半部压暗强度。数值越大越暗，建议 0.06 到 0.16。
const SUIKA_FRUIT_SCENE_TINT_ALPHA: number = 0.14;
// 可调整：水果暖光强度。数值越大越偏暖，建议 0.04 到 0.12。
const SUIKA_FRUIT_WARM_LIGHT_ALPHA: number = 0.07;
// 可调整：水果底部暗边强度。数值越大，底部阴影越重，建议 0.04 到 0.12。
const SUIKA_FRUIT_BOTTOM_SHADE_ALPHA: number = 0.08;
// 可调整：玩法区水果接触阴影开关。只画在地板或下方水果接触处，不影响贴图边缘。
const SUIKA_FRUIT_PLAY_SHADOW_ENABLED: boolean = true;
// 可调整：玩法区水果地板接触阴影强度。数值越大越明显，建议 0.08 到 0.14。
const SUIKA_FRUIT_FLOOR_SHADOW_ALPHA: number = 0.11;
// 可调整：玩法区水果堆叠接触阴影强度。数值越大越明显，建议 0.04 到 0.10。
const SUIKA_FRUIT_STACK_SHADOW_ALPHA: number = 0.065;
// 可调整：水果离下方支撑物多近时显示堆叠阴影。数值越大，越早出现阴影。
const SUIKA_FRUIT_STACK_SHADOW_MAX_GAP_RATIO: number = 0.42;

interface MergeParticle {
  x: number;
  y: number;
  vx: number;
  vy: number;
  startRadius: number;
  color: string;
  bornAt: number;
  duration: number;
}

interface MergeRing {
  x: number;
  y: number;
  startRadius: number;
  endRadius: number;
  color: string;
  bornAt: number;
  duration: number;
  lineWidth: number;
}

interface FruitShadowSupport {
  x: number;
  y: number;
  radius: number;
  contact: number;
}

@Component
export struct SuikaPage {
  @Prop bestScore: number = 0;
  exitToHub: () => void = () => {};
  recordScore: (score: number) => void = () => {};
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private audioService: NativeAudioService = new NativeAudioService();
  private timer: number = -1;
  private nextId: number = 1;
  private fruits: FruitBody[] = [];
  private spawnIndex: number = 0;
  private currentLevel: number = 0;
  private nextLevel: number = 0;
  private hasCurrentFruit: boolean = true;
  private pendingSpawnAt: number = 0;
  private overflowSince: number = 0;
  private settled: boolean = false;
  private mergeText: string = '';
  private mergeTextX: number = 0;
  private mergeTextY: number = 0;
  private mergeTextUntil: number = 0;
  private finalMergeUntil: number = 0;
  private backgroundPixelMap: image.PixelMap | undefined = undefined;
  private fruitPixelMaps: Array<image.PixelMap | undefined> = new Array(FRUITS.length);
  private fruitPreviewPixelMaps: Array<image.PixelMap | undefined> = new Array(FRUITS.length);
  private mergeParticles: MergeParticle[] = [];
  private mergeRings: MergeRing[] = [];
  private lastMergeSoundAt: number = 0;
  private mergeSoundCooldownMs: number = 80;
  private disposed: boolean = false;
  @State pageWidth: number = 390;
  @State pageHeight: number = 760;
  @State score: number = 0;
  @State aimX: number = 195;
  @State paused: boolean = false;
  @State gameOver: boolean = false;
  @State tick: number = 0;

  aboutToAppear(): void {
    this.disposed = false;
    const context = this.getUIContext().getHostContext();
    if (context !== undefined) {
      this.audioService.init(context as common.Context);
    }
    this.loadBackgroundImage();
    this.loadFruitImages();
    this.loadFruitPreviewImages();
    this.restart();
  }

  aboutToDisappear(): void {
    this.disposed = true;
    this.stopLoop();
    this.audioService.release();
    this.releaseBackgroundImage();
    this.releaseFruitImages();
    this.releaseFruitPreviewImages();
  }

  build() {
    Stack() {
      Canvas(this.context)
        .width('100%')
        .height('100%')
        .zIndex(0)
        .onReady(() => {
          this.draw();
        })
        .onAreaChange((oldArea, newArea) => {
          const width = Number.parseFloat(`${newArea.width}`);
          const height = Number.parseFloat(`${newArea.height}`);
          if (!Number.isNaN(width) && !Number.isNaN(height)) {
            this.pageWidth = Math.max(280, width);
            this.pageHeight = Math.max(420, height);
            this.aimX = this.clampAimToCurrentFruit(this.containerLeft() + this.containerWidth() * 0.5);
            this.draw();
          }
        })
        .onTouch((event: TouchEvent) => {
          this.handleTouch(event);
        })

      this.TopBar()
      if (this.paused && !this.gameOver) {
        this.PauseOverlay()
      }
      if (this.gameOver) {
        this.ResultOverlay()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(CoopTheme.bg)
  }

  @Builder
  TopBar() {
    Row({ space: 8 }) {
      Button('大厅')
        .width(62)
        .height(36)
        .borderRadius(8)
        .backgroundColor(CoopTheme.panel)
        .fontColor(CoopTheme.ink)
        .border({ width: 1, color: CoopTheme.glassLine })
        .onClick(() => {
          this.exitToHub();
        })
      Column({ space: 2 }) {
        Text('鸡窝水果摊')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(CoopTheme.ink)
        Text(`今日瓜分：${this.score} · 最高瓜分：${Math.max(this.bestScore, this.score)}`)
          .fontSize(12)
          .fontColor(CoopTheme.muted)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Button(this.paused ? '继续' : '暂停')
        .width(66)
        .height(36)
        .borderRadius(8)
        .backgroundColor(CoopTheme.ink)
        .fontColor('#ffffff')
        .onClick(() => {
          this.paused = !this.paused;
        })
    }
    .position({ x: 0, y: 0 })
    .width('100%')
    .height(88)
    .zIndex(5)
    .padding({ left: 12, right: 12, top: 30 })
    .backgroundColor(CoopTheme.glassStrong)
    .border({ width: { bottom: 1 }, color: CoopTheme.glassLine })
    .shadow({
      radius: 16,
      color: 'rgba(66,92,120,0.10)',
      offsetX: 0,
      offsetY: 8
    })
  }

  @Builder
  PauseOverlay() {
    Column({ space: 12 }) {
      Text('水果摊暂停')
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor('#ffffff')
      Button('继续')
        .width(160)
        .height(42)
        .borderRadius(8)
        .backgroundColor('#ffffff')
        .fontColor(CoopTheme.ink)
        .onClick(() => {
          this.paused = false;
        })
      Button('重新开始')
        .width(160)
        .height(42)
        .borderRadius(8)
        .backgroundColor(CoopTheme.brand)
        .fontColor('#ffffff')
        .onClick(() => {
          this.restart();
        })
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height('100%')
    .zIndex(10)
    .backgroundColor('rgba(7,8,18,0.62)')
  }

  @Builder
  ResultOverlay() {
    Column({ space: 12 }) {
      Text('鸡窝被塞满了！')
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor(CoopTheme.ink)
      Text(`今日瓜分：${this.score} · 最高瓜分：${Math.max(this.bestScore, this.score)}`)
        .fontSize(14)
        .fontColor(CoopTheme.muted)
      Button('再摆一摊')
        .width('100%')
        .height(44)
        .borderRadius(8)
        .backgroundColor(CoopTheme.ink)
        .fontColor('#ffffff')
        .onClick(() => {
          this.restart();
        })
      Button('回大厅')
        .width('100%')
        .height(40)
        .borderRadius(8)
        .backgroundColor(CoopTheme.panel)
        .fontColor(CoopTheme.ink)
        .border({ width: 1, color: CoopTheme.glassLine })
        .onClick(() => {
          this.exitToHub();
        })
    }
    .width(Math.min(this.pageWidth - 36, 340))
    .zIndex(10)
    .padding(18)
    .borderRadius(8)
    .backgroundColor(CoopTheme.glassStrong)
    .border({ width: 1, color: CoopTheme.glassLine })
    .shadow(CoopTheme.shadow)
  }

  private restart(): void {
    this.stopLoop();
    this.fruits = [];
    this.nextId = 1;
    this.spawnIndex = 0;
    this.currentLevel = getSpawnLevel(0);
    this.nextLevel = getSpawnLevel(1);
    this.hasCurrentFruit = true;
    this.score = 0;
    this.paused = false;
    this.gameOver = false;
    this.settled = false;
    this.pendingSpawnAt = 0;
    this.overflowSince = 0;
    this.mergeText = '';
    this.mergeTextUntil = 0;
    this.finalMergeUntil = 0;
    this.mergeParticles = [];
    this.mergeRings = [];
    this.lastMergeSoundAt = 0;
    this.startLoop();
    this.draw();
  }

  private startLoop(): void {
    if (this.timer !== -1) {
      return;
    }
    this.timer = setInterval(() => this.step(), 16);
  }

  private stopLoop(): void {
    if (this.timer !== -1) {
      clearInterval(this.timer);
      this.timer = -1;
    }
  }

  private step(): void {
    if (this.paused || this.gameOver) {
      this.draw();
      return;
    }
    const now = Date.now();
    this.activatePendingFruit(now);
    this.applyPhysics();
    this.resolveCollisions(now);
    this.checkOverflow(now);
    this.tick += 1;
    this.draw();
  }

  private handleTouch(event: TouchEvent): void {
    if (this.paused || this.gameOver) {
      return;
    }
    if (!this.hasCurrentFruit) {
      return;
    }
    if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
      this.dropFruit();
      return;
    }
    if (event.touches === undefined || event.touches.length === 0) {
      return;
    }
    const touch = event.touches[0];
    this.aimX = this.clampAimToCurrentFruit(touch.x);
    this.draw();
  }

  private dropFruit(): void {
    const now = Date.now();
    if (!this.hasCurrentFruit) {
      return;
    }
    const radius = FRUITS[this.currentLevel].radius;
    const x = this.clampAimToCurrentFruit(this.aimX);
    this.fruits.push({
      id: this.nextId++,
      level: this.currentLevel,
      x: x,
      y: this.containerTop() - Math.max(24, radius * 0.55),
      vx: 0,
      vy: 0.8,
      visualAngle: 0,
      visualSpin: 0,
      bornAt: now,
      releasedAt: now,
      mergeLockedUntil: now + 120
    });
    this.spawnIndex += 1;
    this.currentLevel = this.nextLevel;
    this.nextLevel = getSpawnLevel(this.spawnIndex + 1);
    this.hasCurrentFruit = false;
    this.pendingSpawnAt = now + NEXT_FRUIT_DELAY_MS;
    this.aimX = this.clampAimToCurrentFruit(x);
    this.draw();
  }

  private applyPhysics(): void {
    this.fruits = integrateFruits(this.fruits, FRUITS, this.containerBounds());
  }

  private resolveCollisions(now: number): void {
    const result = resolveSuikaCollisions(this.fruits, FRUITS, now, this.nextId);
    this.fruits = result.fruits;
    this.nextId = result.nextId;
    if (result.didMerge) {
      this.score += result.scoreDelta;
      this.mergeText = `+${result.scoreDelta}`;
      this.mergeTextX = result.mergeX;
      this.mergeTextY = result.mergeY;
      this.mergeTextUntil = now + 900;
      this.playMergeFeedback(result.isFinalMerge, now);
      this.spawnMergeEffects(result.mergeX, result.mergeY, result.mergeLevel, result.isFinalMerge, now);
      if (result.isFinalMerge) {
        this.finalMergeUntil = now + 1400;
      }
    }
  }

  private checkOverflow(now: number): void {
    const state = resolveOverflowState(this.fruits, FRUITS, this.failLineY(), now, this.overflowSince);
    this.overflowSince = state.overflowSince;
    if (state.shouldFinish) {
      this.finish();
    }
  }

  private activatePendingFruit(now: number): void {
    if (this.hasCurrentFruit || this.pendingSpawnAt === 0 || now < this.pendingSpawnAt) {
      return;
    }
    this.hasCurrentFruit = true;
    this.pendingSpawnAt = 0;
    this.aimX = this.clampAimToCurrentFruit(this.aimX);
  }

  private finish(): void {
    if (this.settled) {
      return;
    }
    this.settled = true;
    this.gameOver = true;
    this.stopLoop();
    this.recordScore(this.score);
    this.draw();
  }

  private draw(): void {
    const ctx = this.context;
    ctx.clearRect(0, 0, this.pageWidth, this.pageHeight);
    this.configureImageSmoothing(ctx);
    this.drawSceneBackground(ctx);
    this.drawDropZone(ctx);
    this.drawContainer(ctx);
    for (let i = 0; i < this.fruits.length; i += 1) {
      this.drawFruitShadow(ctx, this.fruits[i], i);
      this.drawFruit(ctx, this.fruits[i], this.gameOver ? 0.56 : 1);
    }
    const now = Date.now();
    this.drawMergeEffects(ctx, now);
    this.drawMergeFeedback(ctx, now);
  }

  private drawDropZone(ctx: CanvasRenderingContext2D): void {
    const def = FRUITS[this.currentLevel];
    ctx.fillStyle = 'rgba(71,43,24,0.42)';
    ctx.fillRect(12, SUIKA_DROP_ZONE_TOP, this.pageWidth - 24, SUIKA_DROP_ZONE_HEIGHT);
    ctx.strokeStyle = 'rgba(255,235,197,0.60)';
    ctx.strokeRect(12, SUIKA_DROP_ZONE_TOP, this.pageWidth - 24, SUIKA_DROP_ZONE_HEIGHT);
    ctx.fillStyle = '#fff2d2';
    ctx.font = '700 12vp sans-serif';
    ctx.textAlign = 'left';
    const title = this.hasCurrentFruit ? `手上 ${def.name}` : `备货 ${def.name}`;
    ctx.fillText(`${title} · 下个 ${FRUITS[this.nextLevel].name}`, 22, SUIKA_DROP_ZONE_TEXT_Y);
    const previewRadius = this.dropPreviewRadius();
    const previewX = this.clampDropPreviewX(this.aimX + SUIKA_DROP_PREVIEW_OFFSET_X, previewRadius);
    const previewY = SUIKA_DROP_PREVIEW_Y + SUIKA_DROP_PREVIEW_OFFSET_Y;
    if (SUIKA_SHOW_DROP_RAIL_DEBUG) {
      this.drawDropRailDebug(ctx, previewY);
    }
    if (SUIKA_SHOW_DROP_LINE) {
      ctx.beginPath();
      ctx.strokeStyle = this.hasCurrentFruit ? 'rgba(255,244,214,0.82)' : 'rgba(255,244,214,0.22)';
      ctx.lineWidth = 2;
      ctx.moveTo(this.aimX, previewY);
      ctx.lineTo(this.aimX, this.containerTop() - SUIKA_DROP_LINE_BOTTOM_GAP);
      ctx.stroke();
    }
    if (this.hasCurrentFruit) {
      if (SUIKA_SHOW_DROP_PREVIEW_SHADOW) {
        this.drawPreviewShadow(ctx, previewX, previewY, previewRadius);
      }
      this.drawFruitByLevel(
        ctx,
        this.currentLevel,
        previewX,
        previewY,
        previewRadius,
        1,
        0,
        SUIKA_DROP_PREVIEW_TINT_ENABLED,
        true
      );
    }
  }

  private drawDropRailDebug(ctx: CanvasRenderingContext2D, y: number): void {
    const left = this.dropRailLeft();
    const right = this.dropRailRight();
    ctx.save();
    ctx.setLineDash([5, 5]);
    ctx.strokeStyle = 'rgba(255,255,255,0.72)';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(left, y - 42);
    ctx.lineTo(left, y + 42);
    ctx.moveTo(right, y - 42);
    ctx.lineTo(right, y + 42);
    ctx.stroke();
    ctx.setLineDash([]);
    ctx.restore();
  }

  private drawContainer(ctx: CanvasRenderingContext2D): void {
    const left = this.containerLeft();
    const top = this.containerTop();
    const width = this.containerWidth();
    const height = this.containerHeight();
    if (SUIKA_SHOW_BOARD_DEBUG_FRAME) {
      ctx.fillStyle = 'rgba(255,255,255,0.18)';
      ctx.fillRect(left, top, width, height);
      ctx.strokeStyle = 'rgba(255,255,255,0.92)';
      ctx.lineWidth = 2;
      ctx.strokeRect(left, top, width, height);
    }
    if (SUIKA_SHOW_FAIL_LINE) {
      ctx.setLineDash([6, 6]);
      const isWarning = this.overflowSince !== 0 && Math.floor(this.tick / 12) % 2 === 0;
      ctx.strokeStyle = isWarning ? '#f97316' : '#dc2626';
      ctx.lineWidth = isWarning ? 3 : 2;
      ctx.beginPath();
      ctx.moveTo(left, this.failLineY());
      ctx.lineTo(left + width, this.failLineY());
      ctx.stroke();
      ctx.setLineDash([]);
    }
  }

  private drawFruitShadow(ctx: CanvasRenderingContext2D, fruit: FruitBody, index: number): void {
    if (!SUIKA_FRUIT_PLAY_SHADOW_ENABLED) {
      return;
    }
    const def = FRUITS[fruit.level];
    this.drawFruitFloorShadow(ctx, fruit, def.radius);
    const support = this.findFruitShadowSupport(fruit, index, def.radius);
    if (support !== undefined) {
      this.drawFruitStackShadow(ctx, fruit, def.radius, support);
    }
  }

  private drawFruitFloorShadow(ctx: CanvasRenderingContext2D, fruit: FruitBody, radius: number): void {
    const groundGap = Math.max(0, this.containerBottom() - (fruit.y + radius));
    const contact = 1 - Math.min(1, groundGap / Math.max(1, radius * 0.72));
    if (contact <= 0) {
      return;
    }
    const speed = Math.min(1, (Math.abs(fruit.vx) + Math.abs(fruit.vy)) / 8);
    const shadowX = fruit.x - fruit.vx * 0.16;
    const shadowY = Math.min(this.containerBottom() - 2, fruit.y + radius * 1.02);
    const width = radius * (0.50 + contact * 0.30 + speed * 0.04);
    const height = radius * (0.06 + contact * 0.06);
    const alpha = (this.gameOver ? 0.07 : SUIKA_FRUIT_FLOOR_SHADOW_ALPHA) * contact;
    this.drawSoftShadow(ctx, shadowX, shadowY, width, height, alpha);
  }

  private drawFruitStackShadow(
    ctx: CanvasRenderingContext2D,
    fruit: FruitBody,
    radius: number,
    support: FruitShadowSupport
  ): void {
    const speed = Math.min(1, (Math.abs(fruit.vx) + Math.abs(fruit.vy)) / 8);
    const shadowX = fruit.x * 0.78 + support.x * 0.22 - fruit.vx * 0.08;
    const shadowY = Math.min(fruit.y + radius * 0.82, support.y - support.radius * 0.12);
    const width = radius * (0.34 + support.contact * 0.20 + speed * 0.03);
    const height = radius * (0.035 + support.contact * 0.045);
    const alpha = SUIKA_FRUIT_STACK_SHADOW_ALPHA * support.contact;
    this.drawSoftShadow(ctx, shadowX, shadowY, width, height, alpha);
  }

  private findFruitShadowSupport(
    fruit: FruitBody,
    index: number,
    radius: number
  ): FruitShadowSupport | undefined {
    const maxGap = Math.max(4, radius * SUIKA_FRUIT_STACK_SHADOW_MAX_GAP_RATIO);
    let bestSupport: FruitShadowSupport | undefined = undefined;
    let bestScore = Number.POSITIVE_INFINITY;
    for (let i = 0; i < this.fruits.length; i += 1) {
      if (i === index) {
        continue;
      }
      const candidate = this.fruits[i];
      if (candidate.y <= fruit.y) {
        continue;
      }
      const candidateRadius = FRUITS[candidate.level].radius;
      const dx = fruit.x - candidate.x;
      const maxDx = radius * 0.78 + candidateRadius * 0.72;
      if (Math.abs(dx) > maxDx) {
        continue;
      }
      const surfaceGap = (candidate.y - candidateRadius) - (fruit.y + radius);
      if (surfaceGap < -radius * 0.85 || surfaceGap > maxGap) {
        continue;
      }
      const gapContact = 1 - Math.max(0, surfaceGap) / maxGap;
      const xContact = 1 - Math.abs(dx) / maxDx;
      const contact = Math.max(0, Math.min(1, gapContact * 0.7 + xContact * 0.3));
      if (contact <= 0.12) {
        continue;
      }
      const score = Math.max(0, surfaceGap) + Math.abs(dx) * 0.16 - contact * 8;
      if (score < bestScore) {
        bestScore = score;
        bestSupport = {
          x: candidate.x,
          y: candidate.y,
          radius: candidateRadius,
          contact: contact
        };
      }
    }
    return bestSupport;
  }

  private drawFruit(ctx: CanvasRenderingContext2D, fruit: FruitBody, opacity: number): void {
    const def = FRUITS[fruit.level];
    this.drawFruitByLevel(ctx, fruit.level, fruit.x, fruit.y, def.radius, opacity, fruit.visualAngle, true, false);
  }

  private drawFruitByLevel(
    ctx: CanvasRenderingContext2D,
    level: number,
    x: number,
    y: number,
    radius: number,
    opacity: number,
    rotation: number,
    applySceneTint: boolean,
    usePreviewImage: boolean
  ): void {
    const pixelMap = this.fruitPixelMapForLevel(level, usePreviewImage);
    const size = this.fruitImageSize(radius);
    ctx.save();
    ctx.translate(x, y);
    if (Math.abs(rotation) > 0.001) {
      ctx.rotate(rotation);
    }
    ctx.globalAlpha = opacity;
    if (pixelMap !== undefined) {
      this.configureImageSmoothing(ctx);
      ctx.drawImage(pixelMap, -size * 0.5, -size * 0.5, size, size);
    } else {
      this.drawFallbackFruit(ctx, level, 0, 0, radius);
    }
    if (applySceneTint) {
      ctx.save();
      if (Math.abs(rotation) > 0.001) {
        ctx.rotate(-rotation);
      }
      this.drawFruitSceneTint(ctx, radius, opacity);
      ctx.restore();
    }
    ctx.restore();
  }

  private configureImageSmoothing(ctx: CanvasRenderingContext2D): void {
    ctx.imageSmoothingEnabled = SUIKA_IMAGE_SMOOTHING_ENABLED;
  }

  private fruitPixelMapForLevel(level: number, usePreviewImage: boolean): image.PixelMap | undefined {
    if (level < 0 || level >= FRUITS.length) {
      return undefined;
    }
    if (usePreviewImage && this.fruitPreviewPixelMaps[level] !== undefined) {
      return this.fruitPreviewPixelMaps[level];
    }
    return this.fruitPixelMaps[level];
  }

  private drawFruitSceneTint(ctx: CanvasRenderingContext2D, radius: number, opacity: number): void {
    if (!SUIKA_FRUIT_SCENE_TINT_ENABLED || opacity <= 0) {
      return;
    }
    const clipRadius = radius * 1.03;
    ctx.save();
    ctx.beginPath();
    ctx.arc(0, 0, clipRadius, 0, Math.PI * 2);
    ctx.clip();

    ctx.globalAlpha = opacity * SUIKA_FRUIT_WARM_LIGHT_ALPHA;
    ctx.fillStyle = '#f4a62a';
    ctx.beginPath();
    ctx.ellipse(-radius * 0.22, -radius * 0.34, radius * 0.54, radius * 0.34, -0.3, 0, Math.PI * 2);
    ctx.fill();

    ctx.globalAlpha = opacity * SUIKA_FRUIT_SCENE_TINT_ALPHA;
    ctx.fillStyle = '#4b2410';
    ctx.beginPath();
    ctx.ellipse(0, radius * 0.22, radius * 0.96, radius * 0.52, 0, 0, Math.PI * 2);
    ctx.fill();

    ctx.globalAlpha = opacity * SUIKA_FRUIT_BOTTOM_SHADE_ALPHA;
    ctx.fillStyle = '#2b160b';
    ctx.beginPath();
    ctx.ellipse(0, radius * 0.42, clipRadius * 1.04, radius * 0.64, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.restore();
    ctx.globalAlpha = opacity;
  }

  private drawFallbackFruit(ctx: CanvasRenderingContext2D, level: number, x: number, y: number, radius: number): void {
    const def = FRUITS[level];
    ctx.beginPath();
    ctx.fillStyle = def.color;
    ctx.arc(x, y, radius, 0, Math.PI * 2);
    ctx.fill();
    ctx.lineWidth = Math.max(2, radius * 0.08);
    ctx.strokeStyle = 'rgba(255,255,255,0.76)';
    ctx.stroke();
    ctx.beginPath();
    ctx.fillStyle = 'rgba(255,255,255,0.52)';
    ctx.arc(x - radius * 0.28, y - radius * 0.32, Math.max(2, radius * 0.2), 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = 'rgba(47,55,72,0.72)';
    ctx.font = `700 ${Math.max(10, radius * 0.52)}vp sans-serif`;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(`${level + 1}`, x, y + radius * 0.04);
  }

  private drawMergeFeedback(ctx: CanvasRenderingContext2D, now: number): void {
    if (this.mergeTextUntil > now) {
      const progress = (this.mergeTextUntil - now) / 900;
      ctx.globalAlpha = Math.max(0, Math.min(1, progress));
      ctx.fillStyle = '#f97316';
      ctx.font = '800 18vp sans-serif';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText(this.mergeText, this.mergeTextX, this.mergeTextY - (1 - progress) * 30);
      ctx.globalAlpha = 1;
    }

    if (this.finalMergeUntil > now) {
      ctx.fillStyle = 'rgba(255,255,255,0.86)';
      ctx.fillRect(this.pageWidth * 0.5 - 104, this.pageHeight * 0.38 - 24, 208, 48);
      ctx.strokeStyle = 'rgba(22,163,74,0.42)';
      ctx.strokeRect(this.pageWidth * 0.5 - 104, this.pageHeight * 0.38 - 24, 208, 48);
      ctx.fillStyle = '#166534';
      ctx.font = '800 20vp sans-serif';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText('巨型鸡窝西瓜！', this.pageWidth * 0.5, this.pageHeight * 0.38);
    }
  }

  private drawSceneBackground(ctx: CanvasRenderingContext2D): void {
    if (this.backgroundPixelMap === undefined) {
      ctx.fillStyle = '#3d2413';
      ctx.fillRect(0, 0, this.pageWidth, this.pageHeight);
      ctx.fillStyle = '#9b5b25';
      ctx.fillRect(0, this.pageHeight * 0.36, this.pageWidth, this.pageHeight * 0.64);
      return;
    }
    const scale = Math.max(
      this.pageWidth / SUIKA_BACKGROUND_WIDTH,
      this.pageHeight / SUIKA_BACKGROUND_HEIGHT
    );
    const drawWidth = SUIKA_BACKGROUND_WIDTH * scale;
    const drawHeight = SUIKA_BACKGROUND_HEIGHT * scale;
    const dx = (this.pageWidth - drawWidth) * 0.5;
    const dy = (this.pageHeight - drawHeight) * 0.5 + this.pageHeight * SUIKA_BACKGROUND_OFFSET_Y_RATIO;
    ctx.drawImage(this.backgroundPixelMap, dx, dy, drawWidth, drawHeight);

    ctx.fillStyle = 'rgba(32,16,8,0.12)';
    ctx.fillRect(0, 0, this.pageWidth, this.pageHeight);
    ctx.fillStyle = 'rgba(255,229,178,0.08)';
    ctx.fillRect(0, this.pageHeight * 0.42, this.pageWidth, this.pageHeight * 0.58);
  }

  private playMergeFeedback(isFinalMerge: boolean, now: number): void {
    const canPlayBase = isFinalMerge || now - this.lastMergeSoundAt >= this.mergeSoundCooldownMs;
    if (canPlayBase) {
      this.audioService.play('suika_merge_pop', 0.72);
      this.audioService.play('suika_merge_splash', 0.34);
      this.lastMergeSoundAt = now;
    }
    if (isFinalMerge) {
      this.audioService.play('suika_merge_final', 0.9);
    }
  }

  private spawnMergeEffects(x: number, y: number, level: number, isFinalMerge: boolean, now: number): void {
    const safeLevel = Math.max(0, Math.min(FRUITS.length - 1, level));
    const baseRadius = FRUITS[safeLevel].radius;
    const baseColor = FRUITS[safeLevel].color;
    const particleCount = isFinalMerge ? 34 : 14;
    const duration = isFinalMerge ? 760 : 520;
    this.mergeRings.push({
      x: x,
      y: y,
      startRadius: Math.max(8, baseRadius * 0.42),
      endRadius: baseRadius * (isFinalMerge ? 2.05 : 1.38),
      color: isFinalMerge ? '#fde68a' : baseColor,
      bornAt: now,
      duration: isFinalMerge ? 700 : 420,
      lineWidth: isFinalMerge ? 5 : 3
    });
    if (isFinalMerge) {
      this.mergeRings.push({
        x: x,
        y: y,
        startRadius: baseRadius * 0.72,
        endRadius: baseRadius * 2.6,
        color: '#fb7185',
        bornAt: now + 60,
        duration: 760,
        lineWidth: 4
      });
    }

    for (let i = 0; i < particleCount; i += 1) {
      const angle = Math.PI * 2 * (i / particleCount) + (Math.random() - 0.5) * 0.5;
      const speed = (isFinalMerge ? 3.2 : 2.0) + Math.random() * (isFinalMerge ? 3.8 : 2.2);
      const color = this.mergeParticleColor(i, baseColor, isFinalMerge);
      this.mergeParticles.push({
        x: x,
        y: y,
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed - (isFinalMerge ? 1.5 : 0.8),
        startRadius: (isFinalMerge ? 2.4 : 1.8) + Math.random() * (isFinalMerge ? 3.2 : 2.4),
        color: color,
        bornAt: now,
        duration: duration + Math.random() * 160
      });
    }

    if (this.mergeParticles.length > 160) {
      this.mergeParticles = this.mergeParticles.slice(this.mergeParticles.length - 160);
    }
    if (this.mergeRings.length > 12) {
      this.mergeRings = this.mergeRings.slice(this.mergeRings.length - 12);
    }
  }

  private drawMergeEffects(ctx: CanvasRenderingContext2D, now: number): void {
    const activeRings: MergeRing[] = [];
    for (let i = 0; i < this.mergeRings.length; i += 1) {
      const ring = this.mergeRings[i];
      const elapsed = now - ring.bornAt;
      if (elapsed < 0) {
        activeRings.push(ring);
        continue;
      }
      if (elapsed > ring.duration) {
        continue;
      }
      activeRings.push(ring);
      const progress = Math.max(0, Math.min(1, elapsed / ring.duration));
      const eased = 1 - Math.pow(1 - progress, 2);
      const radius = ring.startRadius + (ring.endRadius - ring.startRadius) * eased;
      ctx.save();
      ctx.globalAlpha = 0.72 * (1 - progress);
      ctx.strokeStyle = ring.color;
      ctx.lineWidth = ring.lineWidth * (1 - progress * 0.42);
      ctx.beginPath();
      ctx.arc(ring.x, ring.y, radius, 0, Math.PI * 2);
      ctx.stroke();
      ctx.restore();
    }
    this.mergeRings = activeRings;

    const activeParticles: MergeParticle[] = [];
    for (let i = 0; i < this.mergeParticles.length; i += 1) {
      const particle = this.mergeParticles[i];
      const elapsed = now - particle.bornAt;
      if (elapsed > particle.duration) {
        continue;
      }
      activeParticles.push(particle);
      const progress = Math.max(0, Math.min(1, elapsed / particle.duration));
      const frameProgress = elapsed / 16.67;
      const x = particle.x + particle.vx * frameProgress;
      const y = particle.y + particle.vy * frameProgress + 0.032 * frameProgress * frameProgress;
      const radius = particle.startRadius * (1 - progress * 0.48);
      ctx.save();
      ctx.globalAlpha = 0.88 * (1 - progress);
      ctx.fillStyle = particle.color;
      ctx.beginPath();
      ctx.arc(x, y, radius, 0, Math.PI * 2);
      ctx.fill();
      if (radius > 2.4) {
        ctx.globalAlpha = 0.42 * (1 - progress);
        ctx.fillStyle = '#ffffff';
        ctx.beginPath();
        ctx.arc(x - radius * 0.22, y - radius * 0.22, radius * 0.32, 0, Math.PI * 2);
        ctx.fill();
      }
      ctx.restore();
    }
    this.mergeParticles = activeParticles;
  }

  private mergeParticleColor(index: number, baseColor: string, isFinalMerge: boolean): string {
    const colors: string[] = isFinalMerge
      ? [baseColor, '#fde68a', '#fbbf24', '#fb7185', '#ffffff']
      : [baseColor, '#fff7cc', '#fbbf24', '#ffffff'];
    return colors[index % colors.length];
  }

  private drawPreviewShadow(ctx: CanvasRenderingContext2D, x: number, y: number, radius: number): void {
    const shadowY = y + radius * SUIKA_DROP_PREVIEW_SHADOW_Y_RATIO;
    const width = radius * SUIKA_DROP_PREVIEW_SHADOW_WIDTH_RATIO;
    const height = radius * SUIKA_DROP_PREVIEW_SHADOW_HEIGHT_RATIO;
    const alpha = SUIKA_DROP_PREVIEW_SHADOW_ALPHA;
    ctx.save();
    ctx.fillStyle = `rgba(74,44,22,${Math.max(0, Math.min(0.18, alpha * 0.58))})`;
    ctx.beginPath();
    ctx.ellipse(x + radius * 0.08, shadowY + radius * 0.02, width * 1.22, height * 1.7, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = `rgba(54,32,17,${Math.max(0, Math.min(0.24, alpha))})`;
    ctx.beginPath();
    ctx.ellipse(x, shadowY, width, height, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = `rgba(38,24,14,${Math.max(0, Math.min(0.18, alpha * 0.72))})`;
    ctx.beginPath();
    ctx.ellipse(x, shadowY + radius * 0.03, width * 0.62, height * 0.55, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.restore();
  }

  private drawSoftShadow(
    ctx: CanvasRenderingContext2D,
    x: number,
    y: number,
    width: number,
    height: number,
    alpha: number
  ): void {
    ctx.save();
    ctx.beginPath();
    ctx.fillStyle = `rgba(70,52,35,${Math.max(0, Math.min(0.22, alpha * 0.46))})`;
    ctx.ellipse(x, y, width * 1.26, height * 1.4, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.beginPath();
    ctx.fillStyle = `rgba(70,52,35,${Math.max(0, Math.min(0.28, alpha))})`;
    ctx.ellipse(x, y, width, height, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.restore();
  }

  private fruitImageSize(radius: number): number {
    return radius * 2.35;
  }

  private async loadBackgroundImage(): Promise<void> {
    const hostContext = this.getUIContext().getHostContext();
    if (hostContext === undefined) {
      return;
    }
    let source: image.ImageSource | undefined = undefined;
    try {
      const content = await hostContext.resourceManager.getRawFileContent(SUIKA_BACKGROUND_IMAGE);
      source = image.createImageSource(content.buffer);
      const pixelMap = await source.createPixelMap({ editable: false });
      if (this.disposed) {
        await pixelMap.release();
        return;
      }
      this.backgroundPixelMap = pixelMap;
      this.draw();
    } catch (error) {
      console.error(`Suika background image load failed (${SUIKA_BACKGROUND_IMAGE}): ${JSON.stringify(error)}`);
    } finally {
      if (source !== undefined) {
        await source.release();
      }
    }
  }

  private async loadFruitImages(): Promise<void> {
    const hostContext = this.getUIContext().getHostContext();
    if (hostContext === undefined) {
      return;
    }
    const resourceManager = hostContext.resourceManager;
    for (let i = 0; i < FRUITS.length; i += 1) {
      let source: image.ImageSource | undefined = undefined;
      try {
        const content = await resourceManager.getRawFileContent(FRUITS[i].image);
        source = image.createImageSource(content.buffer);
        const pixelMap = await source.createPixelMap({ editable: false });
        if (this.disposed) {
          await pixelMap.release();
          return;
        }
        this.fruitPixelMaps[i] = pixelMap;
      } catch (error) {
        console.error(`Suika fruit image load failed (${FRUITS[i].image}): ${JSON.stringify(error)}`);
      } finally {
        if (source !== undefined) {
          await source.release();
        }
      }
    }
    this.draw();
  }

  private async loadFruitPreviewImages(): Promise<void> {
    const hostContext = this.getUIContext().getHostContext();
    if (hostContext === undefined) {
      return;
    }
    const resourceManager = hostContext.resourceManager;
    for (let i = 0; i < FRUITS.length; i += 1) {
      let source: image.ImageSource | undefined = undefined;
      try {
        const content = await resourceManager.getRawFileContent(FRUITS[i].previewImage);
        source = image.createImageSource(content.buffer);
        const pixelMap = await source.createPixelMap({ editable: false });
        if (this.disposed) {
          await pixelMap.release();
          return;
        }
        this.fruitPreviewPixelMaps[i] = pixelMap;
      } catch (error) {
        console.error(`Suika preview fruit image load failed (${FRUITS[i].previewImage}): ${JSON.stringify(error)}`);
      } finally {
        if (source !== undefined) {
          await source.release();
        }
      }
    }
    this.draw();
  }

  private releaseFruitImages(): void {
    for (let i = 0; i < this.fruitPixelMaps.length; i += 1) {
      const pixelMap = this.fruitPixelMaps[i];
      if (pixelMap !== undefined) {
        pixelMap.release();
        this.fruitPixelMaps[i] = undefined;
      }
    }
  }

  private releaseFruitPreviewImages(): void {
    for (let i = 0; i < this.fruitPreviewPixelMaps.length; i += 1) {
      const pixelMap = this.fruitPreviewPixelMaps[i];
      if (pixelMap !== undefined) {
        pixelMap.release();
        this.fruitPreviewPixelMaps[i] = undefined;
      }
    }
  }

  private releaseBackgroundImage(): void {
    if (this.backgroundPixelMap !== undefined) {
      this.backgroundPixelMap.release();
      this.backgroundPixelMap = undefined;
    }
  }

  private clampAimToCurrentFruit(x: number): number {
    const fruitRadius = FRUITS[this.currentLevel].radius;
    const left = this.containerLeft() + fruitRadius;
    const right = this.containerRight() - fruitRadius;
    if (left > right) {
      return (left + right) * 0.5;
    }
    return Math.max(left, Math.min(right, x));
  }

  private clampDropPreviewX(x: number, previewRadius: number): number {
    const left = this.dropRailLeft() + previewRadius;
    const right = this.dropRailRight() - previewRadius;
    if (left > right) {
      return (left + right) * 0.5;
    }
    return Math.max(left, Math.min(right, x));
  }

  private dropPreviewRadius(): number {
    return Math.max(10, SUIKA_DROP_PREVIEW_FIXED_RADIUS * SUIKA_DROP_PREVIEW_SCALE);
  }

  private dropRailLeft(): number {
    return this.pageWidth * SUIKA_DROP_RAIL_LEFT_RATIO + SUIKA_DROP_RAIL_LEFT_OFFSET_X;
  }

  private dropRailRight(): number {
    return this.pageWidth * SUIKA_DROP_RAIL_RIGHT_RATIO + SUIKA_DROP_RAIL_RIGHT_OFFSET_X;
  }

  private containerBounds(): SuikaBounds {
    return {
      left: this.containerLeft(),
      right: this.containerRight(),
      bottom: this.containerBottom()
    };
  }

  private failLineY(): number {
    return this.containerTop() + 10;
  }

  private containerWidth(): number {
    return Math.max(260, this.pageWidth * 0.85);
  }

  private containerHeight(): number {
    return Math.max(SUIKA_BOARD_MIN_HEIGHT, this.containerBottomTarget() - this.containerTop());
  }

  private containerLeft(): number {
    return (this.pageWidth - this.containerWidth()) * 0.5;
  }

  private containerRight(): number {
    return this.containerLeft() + this.containerWidth();
  }

  private containerTop(): number {
    return Math.max(SUIKA_BOARD_TOP_MIN, this.pageHeight * SUIKA_BOARD_TOP_RATIO);
  }

  private containerBottom(): number {
    return this.containerTop() + this.containerHeight();
  }

  private containerBottomTarget(): number {
    return Math.min(this.pageHeight - 8, this.pageHeight - SUIKA_BOARD_BOTTOM_MARGIN + SUIKA_BOARD_HEIGHT_EXTRA);
  }
}
