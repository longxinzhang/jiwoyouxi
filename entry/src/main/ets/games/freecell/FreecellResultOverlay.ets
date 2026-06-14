import { CoopModalTransition } from '../../components/CoopModalTransition';
import { FreecellTheme } from './FreecellTheme';

@Component
export struct FreecellResultOverlay {
  @Prop score: number = 0;
  @Prop moves: number = 0;
  @Prop elapsedText: string = '00:00';
  restartGame: () => void = () => {};
  exitToHub: () => void = () => {};
  closeOverlay: () => void = () => {};

  build() {
    CoopModalTransition({
      maskColor: 'rgba(55,31,9,0.46)',
      panelScaleFrom: 0.96,
      panelOffsetVp: 8
    }) {
      Stack({ alignContent: Alignment.TopStart }) {
        Image($rawfile('games/freecell/panel_card_base_cut.png'))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Fill)
        Column({ space: 8 }) {
          Text('通关')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(FreecellTheme.deepBrown)
            .textAlign(TextAlign.Center)
          Text(`得分 ${this.score}`)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(FreecellTheme.brown)
            .textAlign(TextAlign.Center)
          Text(`${this.moves} 步 · ${this.elapsedText}`)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#80603f')
            .textAlign(TextAlign.Center)
          this.GoldButton('再来一局', () => {
            this.restartGame();
          })
          this.CreamButton('回大厅', () => {
            this.exitToHub();
          })
        }
        .width('100%')
        .height('100%')
        .padding({ left: 34, right: 34, top: 64, bottom: 34 })
        .alignItems(HorizontalAlign.Center)
      }
      .width(260)
      .height(410)
    }
  }

  @Builder
  GoldButton(label: string, action: () => void) {
    Stack({ alignContent: Alignment.Center }) {
      Image($rawfile('games/freecell/btn_highlight_gold_cut.png'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Fill)
      Text(label)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#5f310b')
        .textAlign(TextAlign.Center)
        .width('100%')
    }
    .width(172)
    .height(58)
    .margin({ top: 12 })
    .onClick(() => {
      action();
    })
  }

  @Builder
  CreamButton(label: string, action: () => void) {
    Stack({ alignContent: Alignment.Center }) {
      Text(label)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(FreecellTheme.brown)
        .textAlign(TextAlign.Center)
        .width('100%')
    }
    .width(154)
    .height(48)
    .borderRadius(24)
    .backgroundColor('#fff0d2')
    .border({ width: 2, color: '#d89234' })
    .shadow({ radius: 5, color: 'rgba(103,55,12,0.18)', offsetX: 0, offsetY: 2 })
    .onClick(() => {
      action();
    })
  }
}
