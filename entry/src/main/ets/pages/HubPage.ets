import { MotionPressable } from '../components/MotionPressable';
import { CoopMotion } from '../design/CoopMotion';
import { CoopTheme } from '../design/CoopTheme';
import {
  APPEARANCE_DARK,
  APPEARANCE_LIGHT,
  CoopAppSnapshot,
  GameModule,
  GameRecord
} from '../shell/GameModule';
import { GAME_MODULES, moduleById } from '../shell/GameRegistry';

const HOME_GAME_ORDER: string[] = ['suika', 'minesweeper', 'tetris', 'chicken2048', 'eggSling', 'freecell', 'rps'];
const HOME_SIDE_PADDING: number = 20;
const HOME_TOP_PADDING: number = 56;
const HOME_CONTENT_BOTTOM_SPACE: number = 108;
const HOME_TAB_BAR_HEIGHT: number = 96;
const HOME_TAB_BAR_TOP_PADDING: number = 10;
const HOME_TAB_BAR_BOTTOM_PADDING: number = 24;
const HOME_TAB_ITEM_RADIUS: number = 14;
const HOME_TAB_ICON_SIZE: number = 26;
const HOME_TAB_SYMBOL_SIZE: number = 23;
const HOME_TAB_LABEL_HEIGHT: number = 16;
const HOME_HEADER_ACTION_SIZE: number = 42;
const HOME_HEADER_SYMBOL_SIZE: number = 22;

@Component
export struct HubPage {
  @Prop snapshot: CoopAppSnapshot;
  openGame: (gameId: string) => void = () => {};
  toggleFavorite: (gameId: string) => void = () => {};
  updateSound: (enabled: boolean) => void = () => {};
  updateHaptic: (enabled: boolean) => void = () => {};
  updateAppearanceMode: (appearanceMode: string) => void = () => {};
  @State activeTab: number = 0;
  @State pressedTab: number = -1;

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Scroll() {
        Column({ space: 14 }) {
          this.ActiveTabContent()
          Blank()
            .height(HOME_CONTENT_BOTTOM_SPACE)
        }
        .width('100%')
        .constraintSize({ minHeight: '100%' })
        .padding({ left: HOME_SIDE_PADDING, right: HOME_SIDE_PADDING, top: HOME_TOP_PADDING, bottom: 18 })
      }
      .width('100%')
      .height('100%')

      this.BottomTabBar()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.homeBgColor())
  }

  @Builder
  ActiveTabContent() {
    if (this.activeTab === 0) {
      Stack() {
        this.HomeContent()
      }
      .width('100%')
      .transition(this.tabTransition())
    } else if (this.activeTab === 1) {
      Stack() {
        this.FavoriteList()
      }
      .width('100%')
      .transition(this.tabTransition())
    } else if (this.activeTab === 2) {
      Stack() {
        this.Achievements()
      }
      .width('100%')
      .transition(this.tabTransition())
    } else {
      Stack() {
        this.Settings()
      }
      .width('100%')
      .transition(this.tabTransition())
    }
  }

  @Builder
  HomeContent() {
    Column({ space: 14 }) {
      this.WelcomeHeader()
      this.HeroBanner()
      this.SectionTitleRow('精选游戏', '🐔', true)
      this.HomeGameGrid()
      this.StatsGrid()
    }
    .width('100%')
  }

  @Builder
  WelcomeHeader() {
    Row() {
      Column({ space: 4 }) {
        Text(this.greetingTitle())
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.inkColor())
        Text('今天玩什么呢？')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.mutedColor())
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Row({ space: 10 }) {
        Stack({ alignContent: Alignment.Center }) {
          SymbolGlyph(this.appearanceToggleIcon())
            .fontSize(HOME_HEADER_SYMBOL_SIZE)
            .fontColor([this.activeColor()])
        }
          .width(HOME_HEADER_ACTION_SIZE)
          .height(HOME_HEADER_ACTION_SIZE)
          .backgroundColor(this.iconButtonBgColor())
          .border({ width: 1, color: this.lineColor() })
          .borderRadius(HOME_HEADER_ACTION_SIZE / 2)
          .shadow(this.softShadow())
          .onClick(() => {
            this.toggleAppearanceMode();
          })
        Image($r('app.media.app_icon'))
          .width(HOME_HEADER_ACTION_SIZE)
          .height(HOME_HEADER_ACTION_SIZE)
          .objectFit(ImageFit.Cover)
          .borderRadius(HOME_HEADER_ACTION_SIZE / 2)
          .backgroundColor(this.iconButtonBgColor())
          .border({ width: 1, color: this.lineColor() })
          .shadow(this.softShadow())
      }
    }
    .width('100%')
  }

  @Builder
  HeroBanner() {
    MotionPressable({
      pressScale: 0.985,
      pressedOpacity: 0.98,
      action: () => {
        this.openGame(this.heroGameId());
      }
    }) {
      Stack() {
        Row()
          .width('100%')
          .height('100%')
          .backgroundColor(this.heroBannerBgColor())
        Row() {
          Image($r('app.media.app_icon'))
            .width(128)
            .height(118)
            .objectFit(ImageFit.Contain)
            .shadow(this.softShadow())
          Column({ space: 7 }) {
            Text('鸡窝游戏')
              .fontSize(30)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.inkColor())
            Text('没网也能玩一窝')
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.mutedColor())
            Text('开始游戏 ▶')
              .height(38)
              .padding({ left: 18, right: 18 })
              .borderRadius(19)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor('#fffaf2')
              .textAlign(TextAlign.Center)
              .backgroundColor(this.activeColor())
              .shadow({
                radius: 18,
                color: 'rgba(255,111,118,0.30)',
                offsetX: 0,
                offsetY: 8
              })
          }
          .alignItems(HorizontalAlign.Center)
          .layoutWeight(1)
        }
        .height('100%')
        .width('100%')
        .padding({ left: 10, right: 16 })
      }
      .width('100%')
      .height(178)
      .borderRadius(28)
      .clip(true)
      .border({ width: 1, color: this.lineColor() })
      .shadow(this.cardShadow())
    }
  }

  @Builder
  SectionTitleRow(title: string, icon: string, showMore: boolean) {
    Row() {
      Row({ space: 8 }) {
        Text(icon)
          .width(28)
          .height(28)
          .fontSize(17)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.sectionIconBgColor())
          .borderRadius(14)
          .border({ width: 1, color: this.lineColor() })
        Text(title)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.inkColor())
      }
      Blank()
      if (showMore) {
        Text('›')
          .width(34)
          .height(30)
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.inkColor())
          .textAlign(TextAlign.Center)
          .backgroundColor(this.sectionActionBgColor())
          .borderRadius(15)
          .border({ width: 1, color: this.lineColor() })
          .onClick(() => {
            this.activeTab = 0;
          })
      }
    }
    .width('100%')
    .margin({ top: 2 })
  }

  @Builder
  HomeGameGrid() {
    Grid() {
      ForEach(this.homeModules(), (item: GameModule) => {
        GridItem() {
          this.HomeGameCard(item)
        }
      }, (item: GameModule) => item.id)
    }
    .columnsTemplate('1fr 1fr')
    .rowsGap(10)
    .columnsGap(10)
    .width('100%')
    .height(this.homeGridHeight())
  }

  @Builder
  HomeGameCard(module: GameModule) {
    MotionPressable({
      action: () => {
        this.openGame(module.id);
      }
    }) {
      Row({ space: 10 }) {
        Stack() {
          Text(module.icon)
            .fontSize(30)
            .fontColor(module.accent)
          Text(this.isFavorite(module.id) ? '★' : '☆')
            .width(24)
            .height(24)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isFavorite(module.id) ? CoopTheme.brand : this.favoriteInactiveColor())
            .textAlign(TextAlign.Center)
            .backgroundColor(this.favoriteBadgeBgColor())
            .borderRadius(12)
            .border({ width: 1, color: this.lineColor() })
            .position({ x: 31, y: -7 })
            .onClick(() => {
              this.toggleFavorite(module.id);
            })
        }
        .width(48)
        .height(48)
        .borderRadius(16)
        .backgroundColor(this.gameIconBgColor())
        .border({ width: 1, color: this.iconTileLineColor() })

        Column({ space: 5 }) {
          Text(module.title)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.inkColor())
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.homeTag(module.id))
            .fontSize(10)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.mutedColor())
            .maxLines(1)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .height(96)
      .padding(12)
      .borderRadius(20)
      .backgroundColor(this.panelColor())
      .border({ width: 1, color: this.lineColor() })
      .shadow(this.cardShadow())
    }
  }

  @Builder
  StatsGrid() {
    Row({ space: 10 }) {
      this.StatCard('连续游玩', `${this.playStreak()}`, '天', '🔥')
      this.StatCard('鸡窝徽章', `${this.unlockedBadges()}`, `/ ${this.badgeTotal()}`, '⭐')
    }
    .width('100%')
  }

  @Builder
  StatCard(label: string, value: string, suffix: string, icon: string) {
    Stack({ alignContent: Alignment.TopEnd }) {
      Column({ space: 6 }) {
        Text(label)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.mutedColor())
        Row({ space: 3 }) {
          Text(value)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.inkColor())
          Text(suffix)
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.brandDarkColor())
        }
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      Text(icon)
        .fontSize(24)
        .opacity(0.72)
        .position({ x: 100, y: 10 })
    }
    .layoutWeight(1)
    .height(84)
    .padding(14)
    .borderRadius(22)
    .backgroundColor(this.panelColor())
    .border({ width: 1, color: this.lineColor() })
    .shadow(this.cardShadow())
  }

  @Builder
  BottomTabBar() {
    Row() {
      this.BottomTabItem(0, $r('sys.symbol.house'), '首页')
      this.BottomTabItem(1, $r('sys.symbol.heart'), '收藏')
      this.BottomTabItem(2, $r('sys.symbol.star'), '成就')
      this.BottomTabItem(3, $r('sys.symbol.more'), '设置')
    }
    .width('100%')
    .height(HOME_TAB_BAR_HEIGHT)
    .padding({
      left: HOME_SIDE_PADDING,
      right: HOME_SIDE_PADDING,
      top: HOME_TAB_BAR_TOP_PADDING,
      bottom: HOME_TAB_BAR_BOTTOM_PADDING
    })
    .backgroundColor(this.tabBarBgColor())
    .border({ width: { top: 1 }, color: this.tabBarLineColor() })
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
  }

  @Builder
  BottomTabItem(index: number, icon: Resource, label: string) {
    Column({ space: 3 }) {
      Stack({ alignContent: Alignment.Center }) {
        SymbolGlyph(icon)
          .fontSize(HOME_TAB_SYMBOL_SIZE)
          .fontColor([this.activeTab === index ? this.activeColor() : this.tabMutedColor()])
      }
      .width(HOME_TAB_ICON_SIZE)
      .height(HOME_TAB_ICON_SIZE)
      Text(label)
        .height(HOME_TAB_LABEL_HEIGHT)
        .fontSize(11)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.activeTab === index ? this.activeColor() : this.tabMutedColor())
        .textAlign(TextAlign.Center)
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .borderRadius(HOME_TAB_ITEM_RADIUS)
    .backgroundColor(this.activeTab === index ? this.activeTabBgColor() : 'rgba(255,255,255,0.00)')
    .scale({
      x: this.pressedTab === index ? CoopMotion.pressScale : 1,
      y: this.pressedTab === index ? CoopMotion.pressScale : 1
    })
    .opacity(this.pressedTab === index ? 0.96 : 1)
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.setPressedTab(index);
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.setPressedTab(-1);
      }
    })
    .onClick(() => {
      this.switchTab(index);
    })
  }

  @Builder
  FavoriteList() {
    Column({ space: 10 }) {
      this.SectionTitleRow('收藏', '♡', false)
      if (this.snapshot.favorites.length === 0) {
        this.EmptyPanel('在游戏卡片右上角点星标收藏。')
      } else {
        ForEach(this.snapshot.favorites, (gameId: string) => {
          this.WideGameRow(moduleById(gameId))
        }, (gameId: string) => gameId)
      }
    }
    .width('100%')
  }

  @Builder
  WideGameRow(module: GameModule) {
    MotionPressable({
      action: () => {
        this.openGame(module.id);
      }
    }) {
      Row({ space: 12 }) {
        Text(module.icon)
          .width(48)
          .height(48)
          .fontSize(28)
          .fontColor(module.accent)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.gameIconBgColor())
          .borderRadius(16)
        Column({ space: 3 }) {
          Text(module.title)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.inkColor())
          Text(`${module.highScoreLabel} ${this.recordFor(module.id).highScore} · ${this.recordFor(module.id).playCount} 局`)
            .fontSize(12)
            .fontColor(this.mutedColor())
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Text('开始')
          .height(36)
          .width(78)
          .borderRadius(18)
          .fontColor('#ffffff')
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .backgroundColor(module.accent)
      }
      .width('100%')
      .padding(12)
      .borderRadius(20)
      .backgroundColor(this.panelColor())
      .border({ width: 1, color: this.lineColor() })
      .shadow(this.softShadow())
    }
  }

  @Builder
  Achievements() {
    Column({ space: 10 }) {
      this.SectionTitleRow('成就墙', '♕', false)
      this.AchievementRow('鸡窝开张', this.totalPlayCount() >= 1, '完成任意 1 局')
      this.AchievementRow('七巧鸡仔', this.playedGameCount() >= 7, '7 个游戏都玩过')
      this.AchievementRow('收藏家', this.snapshot.favorites.length >= 3, '收藏 3 个游戏')
      this.AchievementRow('纸牌归位', this.recordFor('freecell').highScore >= 520, '空当接龙完成四花色归位')
      this.AchievementRow('2048 高手', this.recordFor('chicken2048').highScore >= 2048, '鸡窝 2048 本局得分达到 2048')
      this.AchievementRow('方块脑', this.recordFor('tetris').highScore >= 1000, '俄罗斯方块达到 1000 分')
      this.AchievementRow('瓜摊老板', this.recordFor('suika').highScore >= 500, '鸡窝水果摊今日瓜分达到 500')
    }
    .width('100%')
  }

  @Builder
  AchievementRow(title: string, unlocked: boolean, hint: string) {
    Row({ space: 10 }) {
      Text(unlocked ? '✓' : '·')
        .width(34)
        .height(34)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(unlocked ? '#ffffff' : this.mutedColor())
        .textAlign(TextAlign.Center)
        .backgroundColor(unlocked ? CoopTheme.green : this.panelSoftColor())
        .border({ width: 1, color: this.lineColor() })
        .borderRadius(12)
      Column({ space: 2 }) {
        Text(title)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.inkColor())
        Text(hint)
          .fontSize(12)
          .fontColor(this.mutedColor())
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(12)
    .borderRadius(20)
    .backgroundColor(this.panelColor())
    .border({ width: 1, color: this.lineColor() })
    .shadow(this.softShadow())
  }

  @Builder
  Settings() {
    Column({ space: 10 }) {
      this.SectionTitleRow('设置', '⚙', false)
      this.SettingSwitch('声音', this.snapshot.soundEnabled, () => {
        this.updateSound(!this.snapshot.soundEnabled);
      })
      this.SettingSwitch('触感反馈', this.snapshot.hapticEnabled, () => {
        this.updateHaptic(!this.snapshot.hapticEnabled);
      })
      this.SettingSwitch('深色模式', this.isDarkMode(), () => {
        this.toggleAppearanceMode();
      })
      Text('当前阶段只维护鸿蒙原生离线版本。iOS / Android 等你口令再做。')
        .width('100%')
        .fontSize(12)
        .fontColor(this.mutedColor())
        .padding(14)
        .borderRadius(20)
        .backgroundColor(this.panelColor())
        .border({ width: 1, color: this.lineColor() })
    }
    .width('100%')
  }

  @Builder
  SettingSwitch(label: string, enabled: boolean, action: () => void) {
    MotionPressable({
      action: action
    }) {
      Row() {
        Text(label)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.inkColor())
        Blank()
        Text(enabled ? '开' : '关')
          .width(64)
          .height(34)
          .borderRadius(17)
          .fontColor(enabled ? '#ffffff' : this.inkColor())
          .textAlign(TextAlign.Center)
          .backgroundColor(enabled ? CoopTheme.teal : this.panelSoftColor())
          .border({ width: 1, color: this.lineColor() })
      }
      .width('100%')
      .padding(14)
      .borderRadius(20)
      .backgroundColor(this.panelColor())
      .border({ width: 1, color: this.lineColor() })
      .shadow(this.softShadow())
    }
  }

  @Builder
  EmptyPanel(text: string) {
    Text(text)
      .width('100%')
      .padding(16)
      .fontSize(13)
      .fontColor(this.mutedColor())
      .borderRadius(20)
      .backgroundColor(this.panelColor())
      .border({ width: 1, color: this.lineColor() })
      .shadow(this.softShadow())
  }

  private homeModules(): GameModule[] {
    const modules: GameModule[] = [];
    HOME_GAME_ORDER.forEach((id: string) => {
      modules.push(moduleById(id));
    });
    return modules;
  }

  private homeGridHeight(): number {
    const rows = Math.ceil(this.homeModules().length / 2);
    return rows * 96 + Math.max(0, rows - 1) * 10;
  }

  private heroGameId(): string {
    if (this.snapshot.recent.length > 0) {
      const id = this.snapshot.recent[0];
      const found = GAME_MODULES.find((item: GameModule) => item.id === id);
      if (found !== undefined) {
        return id;
      }
    }
    return 'suika';
  }

  private homeTag(gameId: string): string {
    if (gameId === 'suika') return '鸡窝瓜摊';
    if (gameId === 'chicken2048') return '数字叠叠乐';
    if (gameId === 'minesweeper') return '小心鸡雷';
    if (gameId === 'tetris') return '方块下蛋';
    if (gameId === 'eggSling') return '咻啪发射';
    if (gameId === 'freecell') return '纸牌归位';
    return '鸡窝乱斗';
  }

  private greetingTitle(): string {
    const hour = new Date().getHours();
    if (hour >= 5 && hour < 11) return '早上好，鸡仔！';
    if (hour >= 11 && hour < 14) return '中午好，鸡仔！';
    if (hour >= 14 && hour < 18) return '下午好，鸡仔！';
    if (hour >= 18 && hour < 23) return '晚上好，鸡仔！';
    return '还不睡，鸡仔？';
  }

  private isFavorite(gameId: string): boolean {
    return this.snapshot.favorites.includes(gameId);
  }

  private isDarkMode(): boolean {
    return this.snapshot.appearanceMode === APPEARANCE_DARK;
  }

  private toggleAppearanceMode(): void {
    const nextMode = this.isDarkMode() ? APPEARANCE_LIGHT : APPEARANCE_DARK;
    this.getUIContext().animateTo({
      duration: CoopMotion.modalDuration,
      curve: Curve.EaseOut
    }, () => {
      this.updateAppearanceMode(nextMode);
    });
  }

  private appearanceToggleIcon(): Resource {
    return $r('sys.symbol.exposure');
  }

  private homeBgColor(): string {
    return this.isDarkMode() ? '#101110' : '#fff4e4';
  }

  private inkColor(): string {
    return this.isDarkMode() ? '#fff2df' : CoopTheme.ink;
  }

  private mutedColor(): string {
    return this.isDarkMode() ? '#c8b7a2' : '#786555';
  }

  private brandDarkColor(): string {
    return this.isDarkMode() ? '#ffc46f' : CoopTheme.brandDark;
  }

  private activeColor(): string {
    return this.isDarkMode() ? '#ffb079' : CoopTheme.coral;
  }

  private tabMutedColor(): string {
    return this.isDarkMode() ? '#a99a88' : CoopTheme.muted;
  }

  private panelColor(): string {
    return this.isDarkMode() ? '#211f1b' : '#fffaf2';
  }

  private panelSoftColor(): string {
    return this.isDarkMode() ? '#2a2621' : '#fff0da';
  }

  private lineColor(): string {
    return this.isDarkMode() ? 'rgba(255,236,205,0.14)' : 'rgba(132,91,45,0.12)';
  }

  private iconButtonBgColor(): string {
    return this.panelColor();
  }

  private sectionIconBgColor(): string {
    return this.panelSoftColor();
  }

  private sectionActionBgColor(): string {
    return this.panelSoftColor();
  }

  private favoriteBadgeBgColor(): string {
    return this.isDarkMode() ? '#1b1916' : '#fffaf2';
  }

  private favoriteInactiveColor(): string {
    return this.isDarkMode() ? 'rgba(201,181,156,0.62)' : 'rgba(123,108,98,0.58)';
  }

  private gameIconBgColor(): string {
    return this.isDarkMode() ? '#2d261f' : '#fff0d2';
  }

  private iconTileLineColor(): string {
    return this.isDarkMode() ? 'rgba(255,236,205,0.14)' : 'rgba(111,73,39,0.12)';
  }

  private tabBarBgColor(): string {
    return this.homeBgColor();
  }

  private tabBarLineColor(): string {
    return this.isDarkMode() ? 'rgba(255,236,205,0.16)' : 'rgba(132,91,45,0.14)';
  }

  private activeTabBgColor(): string {
    return this.isDarkMode() ? 'rgba(255,128,112,0.20)' : 'rgba(255,127,123,0.16)';
  }

  private heroBannerBgColor(): string {
    return this.isDarkMode() ? '#26221d' : '#fff8ee';
  }

  private softShadow(): ShadowOptions {
    if (this.isDarkMode()) {
      return {
        radius: 22,
        color: 'rgba(0,0,0,0.34)',
        offsetX: 0,
        offsetY: 10
      };
    }
    return CoopTheme.shadow;
  }

  private cardShadow(): ShadowOptions {
    if (this.isDarkMode()) {
      return {
        radius: 18,
        color: 'rgba(0,0,0,0.30)',
        offsetX: 0,
        offsetY: 8
      };
    }
    return {
      radius: 20,
      color: 'rgba(111,74,34,0.12)',
      offsetX: 0,
      offsetY: 8
    };
  }

  private tabTransition(): TransitionEffect {
    return TransitionEffect.OPACITY
      .combine(TransitionEffect.translate({ x: 0, y: CoopMotion.tabOffsetVp }))
      .animation({ duration: CoopMotion.tabDuration, curve: Curve.EaseOut });
  }

  private switchTab(index: number): void {
    if (this.activeTab === index) {
      return;
    }
    this.getUIContext().animateTo({
      duration: CoopMotion.tabDuration,
      curve: Curve.EaseOut
    }, () => {
      this.activeTab = index;
    });
  }

  private setPressedTab(index: number): void {
    if (this.pressedTab === index) {
      return;
    }
    this.getUIContext().animateTo({
      duration: CoopMotion.pressDuration,
      curve: Curve.EaseOut
    }, () => {
      this.pressedTab = index;
    });
  }

  private recordFor(gameId: string): GameRecord {
    const found = this.snapshot.records.find((item: GameRecord) => item.gameId === gameId);
    if (found !== undefined) {
      return found;
    }
    return { gameId: gameId, highScore: 0, playCount: 0, lastPlayedAt: 0 };
  }

  private totalPlayCount(): number {
    let total = 0;
    this.snapshot.records.forEach((item: GameRecord) => {
      total += item.playCount;
    });
    return total;
  }

  private playedGameCount(): number {
    let total = 0;
    this.snapshot.records.forEach((item: GameRecord) => {
      if (item.playCount > 0) {
        total += 1;
      }
    });
    return total;
  }

  private unlockedBadges(): number {
    let count = 0;
    if (this.totalPlayCount() >= 1) count += 1;
    if (this.playedGameCount() >= 7) count += 1;
    if (this.snapshot.favorites.length >= 3) count += 1;
    if (this.recordFor('freecell').highScore >= 520) count += 1;
    if (this.recordFor('chicken2048').highScore >= 2048) count += 1;
    if (this.recordFor('tetris').highScore >= 1000) count += 1;
    if (this.recordFor('suika').highScore >= 500) count += 1;
    return count;
  }

  private badgeTotal(): number {
    return 7;
  }

  private playStreak(): number {
    const days: number[] = [];
    this.snapshot.records.forEach((item: GameRecord) => {
      if (item.lastPlayedAt > 0) {
        const day = Math.floor(item.lastPlayedAt / 86400000);
        if (!days.includes(day)) {
          days.push(day);
        }
      }
    });
    if (days.length === 0) {
      return 0;
    }
    const today = Math.floor(Date.now() / 86400000);
    let streak = 0;
    for (let offset = 0; offset < 30; offset += 1) {
      if (days.includes(today - offset)) {
        streak += 1;
      } else if (offset === 0) {
        continue;
      } else {
        break;
      }
    }
    return streak;
  }
}
