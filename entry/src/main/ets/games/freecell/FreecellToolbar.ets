import { computeFreecellLayout } from './FreecellLayout';
import { FreecellLayout } from './FreecellTypes';
import { FreecellTheme } from './FreecellTheme';

interface FreecellToolItem {
  id: string;
  icon: string;
}

const TOOL_ITEMS: FreecellToolItem[] = [
  { id: 'new', icon: 'games/freecell/icon_new_game_cut.png' },
  { id: 'prev', icon: 'games/freecell/icon_prev_step_cut.png' },
  { id: 'auto', icon: 'games/freecell/icon_auto_finish_cut.png' },
  { id: 'hint', icon: 'games/freecell/icon_hint_cut.png' },
  { id: 'undo', icon: 'games/freecell/icon_undo_cut.png' }
];

@Component
export struct FreecellToolbar {
  @Prop pageWidth: number = 390;
  @Prop pageHeight: number = 760;
  @Prop autoRunning: boolean = false;
  newGame: () => void = () => {};
  undo: () => void = () => {};
  autoMove: () => void = () => {};
  hint: () => void = () => {};

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Stack({ alignContent: Alignment.Center }) {
        Image($rawfile('games/freecell/bottom_toolbar_bg.png'))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Fill)
        Row() {
          ForEach(TOOL_ITEMS, (item: FreecellToolItem) => {
            this.ToolButton(item)
          }, (item: FreecellToolItem) => item.id)
        }
        .width('100%')
        .height('100%')
        .padding({ left: this.panelPaddingX(), right: this.panelPaddingX(), top: this.panelPaddingTop(), bottom: this.panelPaddingBottom() })
      }
      .width(this.panelWidth())
      .height(this.layout().toolbarHeight)
      .position({ x: this.layout().offsetX + 8, y: this.layout().toolbarTop })
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.Transparent)
  }

  @Builder
  ToolButton(item: FreecellToolItem) {
    Stack({ alignContent: Alignment.Center }) {
      Image($rawfile(item.icon))
        .width(this.iconSize())
        .height(this.iconSize())
        .objectFit(ImageFit.Contain)
        .opacity(item.id === 'auto' && this.autoRunning ? 0.72 : 1)
      if (item.id === 'auto' && this.autoRunning) {
        Text('...')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(FreecellTheme.brown)
          .textAlign(TextAlign.Center)
          .width('100%')
          .position({ x: 0, y: this.iconSize() * 0.68 })
      }
    }
    .height('100%')
    .layoutWeight(1)
    .border({
      width: item.id === 'new' ? 0 : 1,
      color: item.id === 'new' ? 'rgba(0,0,0,0)' : 'rgba(167,105,34,0.18)'
    })
    .onClick(() => {
      this.handleTool(item.id);
    })
  }

  private handleTool(id: string): void {
    if (id === 'new') {
      this.newGame();
    } else if (id === 'auto') {
      this.autoMove();
    } else if (id === 'hint') {
      this.hint();
    } else {
      this.undo();
    }
  }

  private layout(): FreecellLayout {
    return computeFreecellLayout(this.pageWidth, this.pageHeight);
  }

  private panelWidth(): number {
    return this.layout().appWidth - 16;
  }

  private iconSize(): number {
    if (this.layout().tiny) {
      return 42;
    }
    return Math.min(72, Math.max(46, this.layout().appWidth * 0.135));
  }

  private panelPaddingX(): number {
    return this.layout().tiny ? 10 : this.layout().compact ? 15 : 24;
  }

  private panelPaddingTop(): number {
    return this.layout().tiny ? 7 : 10;
  }

  private panelPaddingBottom(): number {
    return this.layout().tiny ? 5 : 8;
  }
}
