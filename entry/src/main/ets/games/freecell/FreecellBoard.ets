import { computeFreecellLayout } from './FreecellLayout';
import { FreecellTheme } from './FreecellTheme';
import {
  FreecellCard,
  FreecellLayout,
  FreecellLocation,
  FreecellState,
  FreecellSuit
} from './FreecellTypes';
import {
  FREECELL_SUITS,
  cardColor,
  getMovableCards,
  markMatches,
  rankLabel,
  suitLabel
} from './FreecellRules';

interface FreecellCardRenderItem {
  key: string;
  card: FreecellCard;
  source: FreecellLocation;
  x: number;
  y: number;
  covered: boolean;
  dimmed: boolean;
}

interface FreecellTouchPoint {
  x: number;
  y: number;
}

interface FreecellSourceHit {
  source: FreecellLocation;
  cardId: string;
}

@Component
export struct FreecellBoard {
  @Prop pageWidth: number = 390;
  @Prop pageHeight: number = 760;
  @Prop state: FreecellState = {
    seed: 1,
    freecells: [null, null, null, null],
    foundations: { S: [], H: [], D: [], C: [] },
    tableau: [[], [], [], [], [], [], [], []]
  };
  @Prop selectedLocation: FreecellLocation | null = null;
  @Prop hintMarks: FreecellLocation[] = [];
  @State touchActive: boolean = false;
  @State touchSource: FreecellLocation | null = null;
  @State touchCardId: string = '';
  @State touchStartX: number = 0;
  @State touchStartY: number = 0;
  @State touchLastX: number = 0;
  @State touchLastY: number = 0;
  tapSource: (source: FreecellLocation, cardId: string) => void = () => {};
  tapTarget: (target: FreecellLocation) => void = () => {};
  dropSource: (source: FreecellLocation, target: FreecellLocation) => void = () => {};

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width(this.layout().appWidth - (this.layout().tiny ? 0 : 4))
        .height(Math.max(this.layout().cardHeight + 10, this.layout().tableBottom - this.layout().slotsTop))
        .borderRadius(this.layout().tiny ? 8 : 12)
        .backgroundColor(FreecellTheme.boardTint)
        .position({
          x: this.layout().offsetX + (this.layout().tiny ? 0 : 2),
          y: this.layout().slotsTop - 6
        })

      this.FoundationSlots()
      this.FreecellSlots()
      this.TableauTargets()
      this.TableauCards()
      this.FreecellCards()
      this.FoundationCards()
      this.DragPreview()
      if (!this.layout().compact) {
        this.CardBack()
      }
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.Block)
    .onTouch((event: TouchEvent) => {
      this.handleBoardTouch(event);
    })
  }

  @Builder
  FoundationSlots() {
    ForEach(FREECELL_SUITS, (suit: FreecellSuit) => {
      this.SlotView(
        this.foundationAsset(suit),
        suitLabel(suit),
        this.slotX(FREECELL_SUITS.indexOf(suit)),
        this.layout().slotsTop,
        { area: 'foundation', suit: suit }
      )
    }, (suit: FreecellSuit) => suit)
  }

  @Builder
  FreecellSlots() {
    ForEach([0, 1, 2, 3], (index: number) => {
      this.SlotView(
        'games/freecell/freecell_empty_slot_cut.png',
        '',
        this.slotX(index + 4),
        this.layout().slotsTop,
        { area: 'freecell', index: index }
      )
    }, (index: number) => `${index}`)
  }

  @Builder
  TableauTargets() {
    ForEach([0, 1, 2, 3, 4, 5, 6, 7], (index: number) => {
      if (this.selectedLocation !== null) {
        Stack()
          .width(this.layout().cardWidth)
          .height(this.columnTargetHeight(index))
          .position({ x: this.slotX(index), y: this.layout().tableTop })
          .onClick(() => {
            this.tapTarget({ area: 'tableau', index: index });
          })
      }
      if (this.state.tableau[index].length === 0) {
        this.SlotView(
          'games/freecell/freecell_empty_slot_cut.png',
          '',
          this.slotX(index),
          this.layout().tableTop,
          { area: 'tableau', index: index }
        )
      }
    }, (index: number) => `${index}`)
  }

  @Builder
  TableauCards() {
    ForEach(this.tableauCardItems(), (item: FreecellCardRenderItem) => {
      this.CardView(item)
    }, (item: FreecellCardRenderItem) => item.key)
  }

  @Builder
  FreecellCards() {
    ForEach([0, 1, 2, 3], (index: number) => {
      if (this.state.freecells[index] !== null) {
        this.FreecellCard(index)
      }
    }, (index: number) => `free-${index}-${this.state.freecells[index] === null ? '_' : this.state.freecells[index]?.id}`)
  }

  @Builder
  FreecellCard(index: number) {
    if (this.state.freecells[index] !== null) {
      this.CardView({
        key: `freecell-${index}-${this.state.freecells[index]?.id}`,
        card: this.state.freecells[index] as FreecellCard,
        source: { area: 'freecell', index: index },
        x: this.slotX(index + 4),
        y: this.layout().slotsTop,
        covered: false,
        dimmed: this.isDimmed({ area: 'freecell', index: index })
      })
    }
  }

  @Builder
  FoundationCards() {
    ForEach(FREECELL_SUITS, (suit: FreecellSuit) => {
      if (this.foundationTop(suit) !== null) {
        this.FoundationTopCard(suit, this.foundationTop(suit) as FreecellCard)
      }
    }, (suit: FreecellSuit) => `foundation-${suit}-${this.foundationTop(suit) === null ? '_' : this.foundationTop(suit)?.id}`)
  }

  @Builder
  FoundationTopCard(suit: FreecellSuit, card: FreecellCard) {
    Stack() {
      this.CardFace(card, false, this.isMarked({ area: 'foundation', suit: suit }), false)
    }
      .width(this.layout().cardWidth)
      .height(this.layout().cardHeight)
      .position({ x: this.slotX(FREECELL_SUITS.indexOf(suit)), y: this.layout().slotsTop })
  }

  @Builder
  CardView(item: FreecellCardRenderItem) {
    Stack() {
      this.CardFace(item.card, item.covered, this.isMarked(item.source), item.dimmed)
      if (this.isMarked(item.source)) {
        Column()
          .width('100%')
          .height('100%')
          .borderRadius(this.cardRadius() + 2)
          .border({ width: 4, color: FreecellTheme.hint })
          .backgroundColor('rgba(255,216,56,0.08)')
          .hitTestBehavior(HitTestMode.None)
      }
    }
      .width(this.layout().cardWidth)
      .height(this.layout().cardHeight)
      .backgroundColor('rgba(255,255,255,0.001)')
      .hitTestBehavior(HitTestMode.None)
      .position({ x: item.x, y: item.y })
  }

  @Builder
  CardFace(card: FreecellCard, covered: boolean, highlighted: boolean, dimmed: boolean) {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width('100%')
        .height('100%')
        .borderRadius(this.cardRadius())
        .backgroundColor(FreecellTheme.cardFace)
        .border({
          width: highlighted ? 3 : 1,
          color: highlighted ? FreecellTheme.hint : FreecellTheme.cardBorder
        })
      Column()
        .width(this.layout().cardWidth - 2)
        .height(this.layout().cardHeight * 0.36)
        .borderRadius({ bottomLeft: this.cardRadius(), bottomRight: this.cardRadius() })
        .backgroundColor(FreecellTheme.cardBottomTint)
        .position({ x: 1, y: this.layout().cardHeight * 0.62 })
      Text(rankLabel(card.rank))
        .fontSize(this.cornerFontSize())
        .fontWeight(FontWeight.Bold)
        .fontColor(this.cardFontColor(card))
        .textAlign(TextAlign.Center)
        .width(this.cornerBoxWidth())
        .height(this.cornerFontSize() + 2)
        .position({ x: this.cornerInset() - this.cornerBoxWidth() * 0.5, y: this.cornerInset() - 1 })
      Text(suitLabel(card.suit))
        .fontSize(this.smallSuitFontSize())
        .fontWeight(FontWeight.Bold)
        .fontColor(this.cardFontColor(card))
        .textAlign(TextAlign.Center)
        .width(this.cornerBoxWidth())
        .height(this.smallSuitFontSize() + 2)
        .position({
          x: this.cornerInset() - this.cornerBoxWidth() * 0.5,
          y: this.cornerInset() + this.smallSuitFontSize()
        })
      if (!covered) {
        if (card.rank >= 11) {
          Column({ space: 1 }) {
            Text(rankLabel(card.rank))
              .fontSize(this.bigSuitFontSize())
              .fontWeight(FontWeight.Bold)
              .fontColor(this.cardFontColor(card))
              .textAlign(TextAlign.Center)
              .width('100%')
              .height(this.bigSuitFontSize() + 3)
            Text(suitLabel(card.suit))
              .fontSize(Math.max(7, this.layout().cardWidth * 0.2))
              .fontWeight(FontWeight.Bold)
              .fontColor(this.cardFontColor(card))
              .textAlign(TextAlign.Center)
              .width('100%')
          }
          .width(this.layout().cardWidth)
          .height(this.layout().cardHeight * 0.48)
          .justifyContent(FlexAlign.Center)
          .position({ x: 0, y: this.layout().cardHeight * 0.46 })
        } else {
          Text(suitLabel(card.suit))
            .fontSize(this.bigSuitFontSize())
            .fontWeight(FontWeight.Bold)
            .fontColor(this.cardFontColor(card))
            .textAlign(TextAlign.Center)
            .width(this.layout().cardWidth)
            .height(this.bigSuitFontSize() + 6)
            .position({ x: 0, y: this.layout().cardHeight * 0.61 })
        }
      }
    }
    .opacity(dimmed ? 0.34 : 1)
    .hitTestBehavior(HitTestMode.None)
    .shadow({
      radius: Math.max(2, this.layout().cardWidth * 0.08),
      color: 'rgba(82,45,12,0.18)',
      offsetX: Math.max(0.6, this.layout().cardWidth * 0.02),
      offsetY: Math.max(1.2, this.layout().cardWidth * 0.04)
    })
  }

  @Builder
  SlotView(path: string, markText: string, x: number, y: number, target: FreecellLocation) {
    Stack({ alignContent: Alignment.Center }) {
      Image($rawfile(path))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Fill)
      if (this.isMarked(target)) {
        Column()
          .width('100%')
          .height('100%')
          .borderRadius(8)
          .border({ width: 4, color: FreecellTheme.hint })
          .backgroundColor('rgba(255,216,56,0.08)')
      }
      if (markText.length > 0) {
        Text(markText)
          .fontSize(this.layout().tiny ? 18 : 25)
          .fontWeight(FontWeight.Bold)
          .fontColor('#6b4a2a')
          .textAlign(TextAlign.Center)
          .width('100%')
      }
    }
    .width(this.layout().cardWidth)
    .height(this.layout().cardHeight)
    .borderRadius(7)
    .position({ x: x, y: y })
    .hitTestBehavior(HitTestMode.None)
  }

  @Builder
  CardBack() {
    Image($rawfile('games/freecell/card_back_checkered.png'))
      .width(this.cardBackWidth())
      .height(this.cardBackWidth() * 564 / 408)
      .objectFit(ImageFit.Contain)
      .position({
        x: this.layout().offsetX + this.layout().appWidth - this.cardBackWidth() - 1,
        y: this.layout().slotsTop + this.layout().cardHeight + 2
      })
      .shadow({ radius: 3, color: 'rgba(92,50,14,0.22)', offsetX: 0, offsetY: 3 })
  }

  @Builder
  DragPreview() {
    if (this.touchSource !== null && this.touchMoved(this.touchLastX, this.touchLastY)) {
      ForEach(this.dragCards(), (card: FreecellCard, index?: number) => {
        Stack() {
          this.CardFace(card, false, false, false)
        }
        .width(this.layout().cardWidth)
        .height(this.layout().cardHeight)
        .position({
          x: this.touchLastX - this.layout().cardWidth * 0.5,
          y: this.touchLastY - this.layout().cardHeight * 0.35 + (index === undefined ? 0 : index) * this.layout().fan
        })
        .hitTestBehavior(HitTestMode.None)
      }, (card: FreecellCard) => `drag-${card.id}`)
    }
  }

  private layout(): FreecellLayout {
    return computeFreecellLayout(this.pageWidth, this.pageHeight);
  }

  private slotX(index: number): number {
    return this.layout().offsetX + this.layout().side + index * (this.layout().cardWidth + this.layout().gap);
  }

  private foundationAsset(suit: FreecellSuit): string {
    if (suit === 'S') {
      return 'games/freecell/foundation_slot_spades_cut.png';
    }
    if (suit === 'H') {
      return 'games/freecell/foundation_slot_hearts_cut.png';
    }
    if (suit === 'D') {
      return 'games/freecell/foundation_slot_diamonds_cut.png';
    }
    return 'games/freecell/foundation_slot_clubs_cut.png';
  }

  private foundationTop(suit: FreecellSuit): FreecellCard | null {
    const stack = this.foundationStack(suit);
    return stack.length > 0 ? stack[stack.length - 1] : null;
  }

  private foundationStack(suit: FreecellSuit): FreecellCard[] {
    if (suit === 'S') {
      return this.state.foundations.S;
    }
    if (suit === 'H') {
      return this.state.foundations.H;
    }
    if (suit === 'D') {
      return this.state.foundations.D;
    }
    return this.state.foundations.C;
  }

  private tableauCardItems(): FreecellCardRenderItem[] {
    const items: FreecellCardRenderItem[] = [];
    for (let columnIndex = 0; columnIndex < this.state.tableau.length; columnIndex += 1) {
      const column = this.state.tableau[columnIndex];
      for (let cardIndex = 0; cardIndex < column.length; cardIndex += 1) {
        const source: FreecellLocation = { area: 'tableau', index: columnIndex, cardIndex: cardIndex };
        const card = column[cardIndex];
        items.push({
          key: `tableau-${card.id}-${columnIndex}-${cardIndex}`,
          card: card,
          source: source,
          x: this.slotX(columnIndex),
          y: this.layout().tableTop + cardIndex * this.layout().fan,
          covered: cardIndex < column.length - 1,
          dimmed: this.isDimmed(source)
        });
      }
    }
    return items;
  }

  private columnTargetHeight(index: number): number {
    const column = this.state.tableau[index];
    return Math.max(this.layout().cardHeight, column.length * this.layout().fan + this.layout().cardHeight);
  }

  private cardBackWidth(): number {
    return this.layout().cardWidth * 0.92;
  }

  private handleBoardTouch(event: TouchEvent): void {
    const point = this.touchPoint(event);
    if (event.type === TouchType.Down) {
      this.touchActive = true;
      this.touchStartX = point.x;
      this.touchStartY = point.y;
      this.touchLastX = point.x;
      this.touchLastY = point.y;
      const hit = this.sourceAt(point.x, point.y);
      if (hit !== null) {
        this.touchSource = hit.source;
        this.touchCardId = hit.cardId;
      } else {
        this.touchSource = null;
        this.touchCardId = '';
      }
      return;
    }

    if (!this.touchActive) {
      return;
    }

    if (event.type === TouchType.Move) {
      this.touchLastX = point.x;
      this.touchLastY = point.y;
      return;
    }

    if (event.type === TouchType.Up) {
      const source = this.touchSource;
      const cardId = this.touchCardId;
      const moved = this.touchMoved(point.x, point.y);
      this.clearTouchState();
      if (source !== null) {
        const target = this.targetAt(point.x, point.y);
        if (moved && target !== null) {
          this.dropSource(source, target);
          return;
        }
        this.tapSource(source, cardId);
        return;
      }
      if (this.selectedLocation !== null) {
        const target = this.targetAt(point.x, point.y);
        if (target !== null) {
          this.tapTarget(target);
        }
      }
      return;
    }

    if (event.type === TouchType.Cancel) {
      this.clearTouchState();
    }
  }

  private touchPoint(event: TouchEvent): FreecellTouchPoint {
    if (event.touches !== undefined && event.touches.length > 0) {
      return { x: event.touches[0].x, y: event.touches[0].y };
    }
    if (event.changedTouches !== undefined && event.changedTouches.length > 0) {
      return { x: event.changedTouches[0].x, y: event.changedTouches[0].y };
    }
    return { x: this.touchLastX, y: this.touchLastY };
  }

  private touchMoved(x: number, y: number): boolean {
    const dx = x - this.touchStartX;
    const dy = y - this.touchStartY;
    return dx * dx + dy * dy > 144;
  }

  private clearTouchState(): void {
    this.touchActive = false;
    this.touchSource = null;
    this.touchCardId = '';
  }

  private sourceAt(x: number, y: number): FreecellSourceHit | null {
    for (let index = 0; index < this.state.freecells.length; index += 1) {
      const card = this.state.freecells[index];
      if (card !== null && this.inRect(x, y, this.slotX(index + 4), this.layout().slotsTop, this.layout().cardWidth, this.layout().cardHeight)) {
        return { source: { area: 'freecell', index: index }, cardId: card.id };
      }
    }

    for (let columnIndex = this.state.tableau.length - 1; columnIndex >= 0; columnIndex -= 1) {
      const column = this.state.tableau[columnIndex];
      const x0 = this.slotX(columnIndex);
      if (x < x0 || x > x0 + this.layout().cardWidth) {
        continue;
      }
      for (let cardIndex = column.length - 1; cardIndex >= 0; cardIndex -= 1) {
        const y0 = this.layout().tableTop + cardIndex * this.layout().fan;
        const visibleHeight = cardIndex === column.length - 1 ? this.layout().cardHeight : this.layout().fan;
        if (y >= y0 && y <= y0 + visibleHeight) {
          const card = column[cardIndex];
          return {
            source: { area: 'tableau', index: columnIndex, cardIndex: cardIndex },
            cardId: card.id
          };
        }
      }
    }
    return null;
  }

  private targetAt(x: number, y: number): FreecellLocation | null {
    if (y >= this.layout().slotsTop && y <= this.layout().slotsTop + this.layout().cardHeight) {
      for (let index = 0; index < 8; index += 1) {
        if (this.inRect(x, y, this.slotX(index), this.layout().slotsTop, this.layout().cardWidth, this.layout().cardHeight)) {
          if (index < 4) {
            return { area: 'foundation', suit: FREECELL_SUITS[index] };
          }
          return { area: 'freecell', index: index - 4 };
        }
      }
    }

    if (y >= this.layout().tableTop) {
      for (let index = 0; index < this.state.tableau.length; index += 1) {
        const height = this.columnTargetHeight(index);
        if (this.inRect(x, y, this.slotX(index), this.layout().tableTop, this.layout().cardWidth, height)) {
          return { area: 'tableau', index: index };
        }
      }
    }
    return null;
  }

  private inRect(x: number, y: number, rectX: number, rectY: number, rectW: number, rectH: number): boolean {
    return x >= rectX && x <= rectX + rectW && y >= rectY && y <= rectY + rectH;
  }

  private cardRadius(): number {
    if (this.layout().tiny) {
      return 2.5;
    }
    if (this.layout().compact) {
      return 3;
    }
    return Math.max(4, Math.min(6, this.layout().cardWidth * 0.1));
  }

  private cornerInset(): number {
    if (this.layout().tiny) {
      return Math.max(4, this.layout().cardWidth * 0.18);
    }
    if (this.layout().compact) {
      return Math.max(4, this.layout().cardWidth * 0.15);
    }
    return Math.max(5, this.layout().cardWidth * 0.2);
  }

  private cornerBoxWidth(): number {
    return Math.max(18, this.layout().cardWidth * 0.42);
  }

  private cornerFontSize(): number {
    if (this.layout().tiny) {
      return Math.max(8, Math.min(9, this.layout().cardWidth * 0.32));
    }
    if (this.layout().compact) {
      return Math.max(9, Math.min(11, this.layout().cardWidth * 0.28));
    }
    return Math.max(10, this.layout().cardWidth * 0.32);
  }

  private smallSuitFontSize(): number {
    if (this.layout().tiny) {
      return Math.max(6, Math.min(7, this.layout().cardWidth * 0.24));
    }
    if (this.layout().compact) {
      return Math.max(7, Math.min(8, this.layout().cardWidth * 0.2));
    }
    return Math.max(8, this.layout().cardWidth * 0.24);
  }

  private bigSuitFontSize(): number {
    if (this.layout().tiny) {
      return Math.max(13, Math.min(16, this.layout().cardWidth * 0.58));
    }
    if (this.layout().compact) {
      return Math.max(17, Math.min(22, this.layout().cardWidth * 0.54));
    }
    return Math.max(16, this.layout().cardWidth * 0.62);
  }

  private cardFontColor(card: FreecellCard): string {
    return cardColor(card) === 'red' ? FreecellTheme.red : FreecellTheme.black;
  }

  private isMarked(location: FreecellLocation): boolean {
    for (let index = 0; index < this.hintMarks.length; index += 1) {
      if (markMatches(this.hintMarks[index], location)) {
        return true;
      }
    }
    return this.selectedLocation !== null && markMatches(this.selectedLocation, location);
  }

  private isDimmed(location: FreecellLocation): boolean {
    if (this.selectedLocation !== null && markMatches(this.selectedLocation, location)) {
      return true;
    }
    return this.touchSource !== null && this.touchMoved(this.touchLastX, this.touchLastY) &&
      markMatches(this.touchSource, location);
  }

  private dragCards(): FreecellCard[] {
    if (this.touchSource === null) {
      return [];
    }
    return getMovableCards(this.state, this.touchSource);
  }
}
