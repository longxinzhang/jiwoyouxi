import { computeFreecellLayout } from './FreecellLayout';
import { FreecellLayout } from './FreecellTypes';
import { FreecellTheme } from './FreecellTheme';

@Component
export struct FreecellDecor {
  @Prop pageWidth: number = 390;
  @Prop pageHeight: number = 760;

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      if (!this.layout().tiny) {
        this.RulesBoard()
        this.Scene()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  RulesBoard() {
    if (this.rulesY() > this.layout().tableTop + this.layout().cardHeight * 0.6) {
      Stack({ alignContent: Alignment.TopStart }) {
        Image($rawfile('games/freecell/rules_sign_board_cut.png'))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Contain)
        Column({ space: 2 }) {
          Text('红黑交替递减移动')
            .fontSize(this.ruleFontSize())
            .fontWeight(FontWeight.Bold)
            .fontColor(FreecellTheme.brown)
            .maxLines(1)
          Text('借助空当周转')
            .fontSize(this.ruleFontSize())
            .fontWeight(FontWeight.Bold)
            .fontColor(FreecellTheme.brown)
            .maxLines(1)
          Text('同花色 A 到 K 归位')
            .fontSize(this.ruleFontSize())
            .fontWeight(FontWeight.Bold)
            .fontColor(FreecellTheme.brown)
            .maxLines(1)
        }
        .width(this.layout().rulesWidth * 0.64)
        .position({
          x: this.layout().rulesWidth * 0.19,
          y: this.rulesHeight() * 0.31
        })
      }
      .width(this.layout().rulesWidth)
      .height(this.rulesHeight())
      .position({ x: this.layout().offsetX + 7, y: this.rulesY() })
    }
  }

  @Builder
  Scene() {
    Image($rawfile('games/freecell/foreground_scene_1_cut.png'))
      .width(this.layout().decorHeight * 0.58)
      .height(this.layout().decorHeight * 0.42)
      .objectFit(ImageFit.Contain)
      .position({ x: this.layout().offsetX + this.layout().appWidth * 0.03, y: this.baseY() - this.layout().decorHeight * 0.48 })
    Image($rawfile('games/freecell/foreground_scene_2_cut.png'))
      .width(this.layout().decorHeight * 0.52)
      .height(this.layout().decorHeight * 0.6)
      .objectFit(ImageFit.Contain)
      .position({ x: this.layout().offsetX + this.layout().appWidth * 0.19, y: this.baseY() - this.layout().decorHeight * 0.6 })
    Image($rawfile('games/freecell/mascot_reading_chicken_cut.png'))
      .width(this.layout().decorHeight * 0.92)
      .height(this.layout().decorHeight * 0.78)
      .objectFit(ImageFit.Contain)
      .position({
        x: this.layout().offsetX + this.layout().appWidth * 0.48 - this.layout().decorHeight * 0.5,
        y: this.baseY() - this.layout().decorHeight * 0.72
      })
    Image($rawfile('games/freecell/foreground_scene_5_cut.png'))
      .width(this.layout().decorHeight * 0.42)
      .height(this.layout().decorHeight * 0.62)
      .objectFit(ImageFit.Contain)
      .position({ x: this.layout().offsetX + this.layout().appWidth * 0.62, y: this.baseY() - this.layout().decorHeight * 0.62 })
    Image($rawfile('games/freecell/foreground_scene_3_cut.png'))
      .width(this.layout().decorHeight * 0.5)
      .height(this.layout().decorHeight * 0.52)
      .objectFit(ImageFit.Contain)
      .position({ x: this.layout().offsetX + this.layout().appWidth * 0.73, y: this.baseY() - this.layout().decorHeight * 0.52 })
    Image($rawfile('games/freecell/foreground_scene_4_cut.png'))
      .width(this.layout().decorHeight * 0.68)
      .height(this.layout().decorHeight * 0.48)
      .objectFit(ImageFit.Contain)
      .position({ x: this.layout().offsetX + this.layout().appWidth * 0.84, y: this.baseY() - this.layout().decorHeight * 0.48 })
  }

  private layout(): FreecellLayout {
    return computeFreecellLayout(this.pageWidth, this.pageHeight);
  }

  private baseY(): number {
    return this.layout().toolbarTop - 6;
  }

  private rulesHeight(): number {
    return this.layout().rulesWidth * 562 / 718;
  }

  private rulesY(): number {
    return this.layout().toolbarTop - this.rulesHeight() - 16;
  }

  private ruleFontSize(): number {
    return Math.max(9, this.layout().rulesWidth * 0.068);
  }
}
