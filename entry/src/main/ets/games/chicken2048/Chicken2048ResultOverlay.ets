import { CoopModalTransition } from '../../components/CoopModalTransition';
import { SuikaFeatherLayer } from '../suika/SuikaFeatherLayer';
import { SuikaImageButton } from '../suika/SuikaImageButton';

@Component
export struct Chicken2048ResultOverlay {
  @Prop success: boolean = false;
  @Prop pageWidth: number = 390;
  @Prop pageHeight: number = 760;
  @Prop currentScore: number = 0;
  @Prop maxTileValue: number = 0;
  continueGame: () => void = () => {};
  restartGame: () => void = () => {};
  exitToHub: () => void = () => {};

  build() {
    CoopModalTransition({
      maskColor: 'rgba(22,13,8,0.42)',
      panelScaleFrom: 0.94,
      panelOffsetVp: 10
    }) {
      Stack({ alignContent: Alignment.Center }) {
        SuikaFeatherLayer({
          success: this.success,
          pageWidth: this.pageWidth,
          pageHeight: this.pageHeight
        })
        this.ResultCard()
      }
      .width('100%')
      .height('100%')
    }
  }

  @Builder
  ResultCard() {
    Stack({ alignContent: Alignment.TopStart }) {
      Image($rawfile(this.cardImage()))
        .width(this.cardWidth())
        .height(this.cardHeight())
        .objectFit(ImageFit.Fill)
      Column({ space: this.contentGap() }) {
        Text(this.titleText())
          .width('100%')
          .fontSize(this.titleFontSize())
          .fontWeight(FontWeight.Bold)
          .fontColor(this.success ? '#946112' : '#794022')
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textShadow({ radius: 1, color: 'rgba(255,255,255,0.72)', offsetX: 0, offsetY: 1 })
        Text(this.subtitleText())
          .width('100%')
          .fontSize(this.subtitleFontSize())
          .fontColor('#7e6247')
          .textAlign(TextAlign.Center)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.infoText())
          .width('100%')
          .fontSize(this.infoFontSize())
          .fontWeight(FontWeight.Medium)
          .fontColor('#9a7149')
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: 10 }) {
          SuikaImageButton({
            label: this.primaryButtonText(),
            imagePath: 'games/minesweeper/button_yellow.png',
            buttonWidth: this.buttonWidth(),
            buttonHeight: this.buttonHeight(),
            fontSize: this.buttonFontSize(),
            action: () => {
              this.primaryAction();
            }
          })
          SuikaImageButton({
            label: '回大厅',
            imagePath: 'games/minesweeper/button_green.png',
            buttonWidth: this.buttonWidth(),
            buttonHeight: this.buttonHeight(),
            fontSize: this.buttonFontSize(),
            action: () => {
              this.exitToHub();
            }
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
      }
      .width(this.contentWidth())
      .alignItems(HorizontalAlign.Center)
      .position({ x: this.contentX(), y: this.contentY() })
    }
    .width(this.cardWidth())
    .height(this.cardHeight())
    .shadow({
      radius: 20,
      color: 'rgba(80,46,19,0.24)',
      offsetX: 0,
      offsetY: 8
    })
  }

  private cardImage(): string {
    return this.success ? 'games/minesweeper/popup_success_card.png' : 'games/minesweeper/popup_failure_card.png';
  }

  private cardWidth(): number {
    return Math.min(this.pageWidth - 24, this.pageWidth < 340 ? 330 : 382);
  }

  private cardHeight(): number {
    return Math.round(this.cardWidth() * (this.success ? 1004 / 1132 : 970 / 1259));
  }

  private contentWidth(): number {
    return Math.round(this.cardWidth() * 0.78);
  }

  private contentX(): number {
    return Math.round((this.cardWidth() - this.contentWidth()) * 0.5);
  }

  private contentY(): number {
    return Math.round(this.cardHeight() * (this.success ? 0.535 : 0.475));
  }

  private contentGap(): number {
    return this.pageWidth < 340 ? 5 : 7;
  }

  private titleFontSize(): number {
    return this.pageWidth < 340 ? 21 : 24;
  }

  private subtitleFontSize(): number {
    return this.pageWidth < 340 ? 12 : 13;
  }

  private infoFontSize(): number {
    return this.pageWidth < 340 ? 11 : 12;
  }

  private buttonWidth(): number {
    return Math.round(this.contentWidth() * 0.44);
  }

  private buttonHeight(): number {
    return this.pageWidth < 340 ? 42 : 46;
  }

  private buttonFontSize(): number {
    return this.pageWidth < 340 ? 14 : 16;
  }

  private titleText(): string {
    return this.success ? '合成 2048！' : '棋盘挤满了！';
  }

  private subtitleText(): string {
    return this.success ? '目标达成，还可以继续冲更高数字。' : '没有可移动方块了。';
  }

  private infoText(): string {
    return `本局得分 ${this.currentScore} · 最大数字 ${this.maxTileValue}`;
  }

  private primaryButtonText(): string {
    return this.success ? '继续挑战' : '再来一局';
  }

  private primaryAction(): void {
    if (this.success) {
      this.continueGame();
      return;
    }
    this.restartGame();
  }
}
