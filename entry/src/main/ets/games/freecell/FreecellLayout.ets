import { FreecellLayout } from './FreecellTypes';

export function computeFreecellLayout(pageWidth: number, pageHeight: number): FreecellLayout {
  const appWidth = Math.min(pageWidth, 500);
  const offsetX = (pageWidth - appWidth) * 0.5;
  const compact = appWidth <= 430 || pageHeight < 760;
  const tiny = appWidth < 300 || pageHeight < 600;
  const side = tiny ? 4 : compact ? 6 : 10;
  const minGap = tiny ? 2 : compact ? 3 : 5;
  let cardWidth = Math.min(tiny ? 28 : compact ? 44 : 60, (appWidth - side * 2 - minGap * 7) / 8);
  cardWidth = Math.max(tiny ? 23 : compact ? 38 : 38, cardWidth);
  const cardHeight = cardWidth * 1.42;
  const gap = Math.max(minGap, (appWidth - side * 2 - cardWidth * 8) / 7);
  const toolbarHeight = tiny ? Math.max(52, Math.min(58, pageHeight * 0.115)) : compact ? 82 : 96;
  const titleWidth = tiny
    ? Math.min(110, Math.max(96, appWidth * 0.45))
    : Math.min(compact ? 168 : 260, Math.max(compact ? 156 : 184, appWidth * 0.47));
  const titleHeight = tiny ? titleWidth * 0.52 : titleWidth * 0.512;
  const titleTop = tiny ? 3 : compact ? 8 : 10;
  const statsTop = titleTop + titleHeight + (tiny ? 2 : 4);
  const statGap = tiny ? 3 : compact ? 5 : 8;
  const statReserve = tiny ? 0 : compact ? 0 : 38;
  const statWidth = (appWidth - side * 2 - statGap * 3 - statReserve) / 4;
  const statHeight = statWidth * 0.62;
  const slotsTop = statsTop + statHeight + (tiny ? 8 : compact ? 12 : 18);
  const tableTop = slotsTop + cardHeight + (tiny ? 10 : compact ? 14 : 26);
  const toolbarTop = pageHeight - toolbarHeight - (tiny ? 6 : compact ? 8 : 10);
  const decorHeight = tiny
    ? Math.max(78, Math.min(100, appWidth * 0.42, pageHeight * 0.22))
    : compact ? 112 : 132;
  const tableBottom = Math.max(tableTop + cardHeight, toolbarTop - (tiny ? decorHeight * 1.05 : compact ? 104 : 130));
  const fan = tiny
    ? Math.max(14.5, Math.min(17, cardWidth * 0.6))
    : compact ? Math.max(21, Math.min(24, cardWidth * 0.56)) : Math.max(19, Math.min(27, cardWidth * 0.45));

  return {
    appWidth: appWidth,
    offsetX: offsetX,
    tiny: tiny,
    compact: compact,
    side: side,
    gap: gap,
    cardWidth: cardWidth,
    cardHeight: cardHeight,
    fan: fan,
    titleTop: titleTop,
    titleWidth: titleWidth,
    titleHeight: titleHeight,
    statsTop: statsTop,
    statWidth: statWidth,
    statHeight: statHeight,
    statGap: statGap,
    slotsTop: slotsTop,
    tableTop: tableTop,
    tableBottom: tableBottom,
    toolbarTop: toolbarTop,
    toolbarHeight: toolbarHeight,
    decorHeight: decorHeight,
    rulesWidth: tiny ? Math.min(100, appWidth * 0.43) : compact ? Math.min(150, appWidth * 0.43) : Math.min(190, appWidth * 0.43)
  };
}
