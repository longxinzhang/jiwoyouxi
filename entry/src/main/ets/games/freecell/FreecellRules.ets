import {
  FreecellCard,
  FreecellLocation,
  FreecellMove,
  FreecellState,
  FreecellSuit
} from './FreecellTypes';

export const FREECELL_SUITS: FreecellSuit[] = ['S', 'H', 'D', 'C'];

export function rankLabel(rank: number): string {
  if (rank === 1) {
    return 'A';
  }
  if (rank === 11) {
    return 'J';
  }
  if (rank === 12) {
    return 'Q';
  }
  if (rank === 13) {
    return 'K';
  }
  return `${rank}`;
}

export function suitLabel(suit: FreecellSuit): string {
  if (suit === 'S') {
    return '♠';
  }
  if (suit === 'H') {
    return '♥';
  }
  if (suit === 'D') {
    return '♦';
  }
  return '♣';
}

export function cardColor(card: FreecellCard): string {
  return card.suit === 'H' || card.suit === 'D' ? 'red' : 'black';
}

export function suitColor(suit: FreecellSuit): string {
  return suit === 'H' || suit === 'D' ? 'red' : 'black';
}

export function randomSeed(): number {
  return Math.floor(Math.random() * 1000000) + 1;
}

export function normalizeSeed(seed: number): number {
  if (!Number.isFinite(seed)) {
    return 1;
  }
  return Math.max(1, Math.min(1000000, Math.floor(seed)));
}

export function createSolvableGame(seed: number): FreecellState {
  const normalized = normalizeSeed(seed);
  const random = createRandom(normalized);
  const tableau: FreecellCard[][] = [[], [], [], [], [], [], [], []];
  const capacities: number[] = [7, 7, 7, 7, 6, 6, 6, 6];
  const ranks: number[] = [13, 13, 13, 13];

  for (let i = capacities.length - 1; i > 0; i -= 1) {
    const swapIndex = Math.floor(random() * (i + 1));
    const current = capacities[i];
    capacities[i] = capacities[swapIndex];
    capacities[swapIndex] = current;
  }

  while (hasRemainingRanks(ranks)) {
    const suitIndex = randomSuitIndex(ranks, random);
    const suit = FREECELL_SUITS[suitIndex];
    const rank = ranks[suitIndex];
    ranks[suitIndex] -= 1;

    const availableColumns: number[] = [];
    for (let index = 0; index < tableau.length; index += 1) {
      if (tableau[index].length < capacities[index]) {
        availableColumns.push(index);
      }
    }

    let shortest = availableColumns[0];
    for (let i = 0; i < availableColumns.length; i += 1) {
      const columnIndex = availableColumns[i];
      if (tableau[columnIndex].length < tableau[shortest].length && random() < 0.72) {
        shortest = columnIndex;
      }
    }

    const useShortest = random() < 0.58;
    const targetIndex = useShortest
      ? shortest
      : availableColumns[Math.floor(random() * availableColumns.length)];
    tableau[targetIndex].push({ id: `${suit}${rank}`, suit: suit, rank: rank });
  }

  return {
    seed: normalized,
    freecells: [null, null, null, null],
    foundations: { S: [], H: [], D: [], C: [] },
    tableau: tableau
  };
}

export function cloneState(source: FreecellState): FreecellState {
  return {
    seed: source.seed,
    freecells: source.freecells.map((card: FreecellCard | null) => cloneCard(card)),
    foundations: {
      S: source.foundations.S.map((card: FreecellCard) => cloneCardValue(card)),
      H: source.foundations.H.map((card: FreecellCard) => cloneCardValue(card)),
      D: source.foundations.D.map((card: FreecellCard) => cloneCardValue(card)),
      C: source.foundations.C.map((card: FreecellCard) => cloneCardValue(card))
    },
    tableau: source.tableau.map((column: FreecellCard[]) => {
      return column.map((card: FreecellCard) => cloneCardValue(card));
    })
  };
}

export function cloneMove(move: FreecellMove): FreecellMove {
  return {
    source: cloneLocation(move.source),
    target: cloneLocation(move.target),
    cards: move.cards.map((card: FreecellCard) => cloneCardValue(card)),
    score: move.score,
    nextKey: move.nextKey
  };
}

export function cloneLocation(location: FreecellLocation): FreecellLocation {
  return {
    area: location.area,
    index: location.index,
    cardIndex: location.cardIndex,
    suit: location.suit
  };
}

export function getMovableCards(state: FreecellState, source: FreecellLocation | null): FreecellCard[] {
  if (source === null) {
    return [];
  }
  if (source.area === 'freecell') {
    const freeIndex = source.index ?? -1;
    if (freeIndex < 0 || freeIndex >= state.freecells.length) {
      return [];
    }
    const card = state.freecells[freeIndex];
    return card === null ? [] : [card];
  }
  if (source.area === 'tableau') {
    const columnIndex = source.index ?? -1;
    const cardIndex = source.cardIndex ?? -1;
    if (columnIndex < 0 || columnIndex >= state.tableau.length) {
      return [];
    }
    const column = state.tableau[columnIndex];
    if (cardIndex < 0 || cardIndex >= column.length) {
      return [];
    }
    const cards = column.slice(cardIndex);
    return isOrderedStack(cards) ? cards : [];
  }
  return [];
}

export function canDrop(
  state: FreecellState,
  cards: FreecellCard[],
  source: FreecellLocation,
  target: FreecellLocation
): boolean {
  if (cards.length <= 0) {
    return false;
  }
  if (target.area === source.area && target.index === source.index && target.suit === source.suit) {
    return false;
  }

  const firstCard = cards[0];
  if (target.area === 'freecell') {
    const freeIndex = target.index ?? -1;
    return cards.length === 1 && freeIndex >= 0 && freeIndex < 4 && state.freecells[freeIndex] === null;
  }
  if (target.area === 'foundation') {
    return cards.length === 1 && target.suit === firstCard.suit && canMoveToFoundation(firstCard, state);
  }
  if (target.area === 'tableau') {
    const columnIndex = target.index ?? -1;
    if (columnIndex < 0 || columnIndex >= state.tableau.length || cards.length > maxMovableCards(state)) {
      return false;
    }
    const column = state.tableau[columnIndex];
    const top = column.length > 0 ? column[column.length - 1] : null;
    return top === null ? true : canStackOn(firstCard, top);
  }
  return false;
}

export function applyMove(state: FreecellState, source: FreecellLocation, target: FreecellLocation): FreecellMove | null {
  const cards = getMovableCards(state, source);
  if (!canDrop(state, cards, source, target)) {
    return null;
  }
  const moved = removeFromSource(state, source, cards.length);
  appendToTarget(state, moved, target);
  return {
    source: cloneLocation(source),
    target: cloneLocation(target),
    cards: moved.map((card: FreecellCard) => cloneCardValue(card))
  };
}

export function canMoveToFoundation(card: FreecellCard | null, state: FreecellState): boolean {
  if (card === null) {
    return false;
  }
  const foundation = foundationCards(state, card.suit);
  const top = foundation.length > 0 ? foundation[foundation.length - 1] : null;
  return top === null ? card.rank === 1 : card.rank === top.rank + 1;
}

export function isSafeFoundationMove(card: FreecellCard | null, state: FreecellState): boolean {
  if (card === null || !canMoveToFoundation(card, state)) {
    return false;
  }
  if (card.rank <= 2) {
    return true;
  }
  const oppositeSuits = oppositeColorSuits(card.suit);
  return foundationRank(state, oppositeSuits[0]) >= card.rank - 1 &&
    foundationRank(state, oppositeSuits[1]) >= card.rank - 1;
}

export function findSafeFoundationMove(state: FreecellState): FreecellMove | null {
  for (let index = 0; index < state.freecells.length; index += 1) {
    const card = state.freecells[index];
    if (isSafeFoundationMove(card, state) && card !== null) {
      return {
        source: { area: 'freecell', index: index },
        target: { area: 'foundation', suit: card.suit },
        cards: [cloneCardValue(card)]
      };
    }
  }

  for (let index = 0; index < state.tableau.length; index += 1) {
    const column = state.tableau[index];
    if (column.length <= 0) {
      continue;
    }
    const cardIndex = column.length - 1;
    const card = column[cardIndex];
    if (isSafeFoundationMove(card, state)) {
      return {
        source: { area: 'tableau', index: index, cardIndex: cardIndex },
        target: { area: 'foundation', suit: card.suit },
        cards: [cloneCardValue(card)]
      };
    }
  }
  return null;
}

export function collectHints(
  state: FreecellState,
  recentMoves: FreecellMove[],
  lastHintKey: string
): FreecellMove[] {
  const candidates: FreecellMove[] = [];
  const seen = new Map<string, boolean>();
  const seenEquivalent = new Map<string, boolean>();
  const sources = possibleSources(state);
  for (let i = 0; i < sources.length; i += 1) {
    const source = sources[i];
    const cards = getMovableCards(state, source);
    if (cards.length <= 0) {
      continue;
    }
    const targets = possibleTargets(cards[0]);
    for (let j = 0; j < targets.length; j += 1) {
      const target = targets[j];
      if (!canDrop(state, cards, source, target)) {
        continue;
      }
      const priority = hintPriority(state, source, target);
      const candidate: FreecellMove = {
        source: cloneLocation(source),
        target: cloneLocation(target),
        cards: cards.map((card: FreecellCard) => cloneCardValue(card)),
        score: priority
      };
      const key = hintKey(candidate);
      const equivalentKey = hintEquivalentKey(state, candidate);
      if (priority > 0 && !seen.has(key) && !seenEquivalent.has(equivalentKey) &&
        !isReverseOfRecentMove(candidate, recentMoves)) {
        seen.set(key, true);
        seenEquivalent.set(equivalentKey, true);
        candidates.push(candidate);
      }
    }
  }
  candidates.sort((left: FreecellMove, right: FreecellMove) => compareMoves(left, right));
  if (lastHintKey.length <= 0 || candidates.length <= 1) {
    return candidates;
  }
  const ordered: FreecellMove[] = [];
  let startIndex = 0;
  for (let index = 0; index < candidates.length; index += 1) {
    if (hintKey(candidates[index]) === lastHintKey) {
      startIndex = (index + 1) % candidates.length;
      break;
    }
  }
  for (let index = 0; index < candidates.length; index += 1) {
    ordered.push(candidates[(startIndex + index) % candidates.length]);
  }
  return ordered;
}

export function findSmartMove(state: FreecellState, source: FreecellLocation): FreecellLocation | null {
  const cards = getMovableCards(state, source);
  if (cards.length <= 0) {
    return null;
  }
  const targets = possibleTargets(cards[0]);
  for (let index = 0; index < targets.length; index += 1) {
    const target = targets[index];
    if (canDrop(state, cards, source, target) && hintPriority(state, source, target) >= 80) {
      return cloneLocation(target);
    }
  }
  return null;
}

export function findAutoCompleteMove(
  state: FreecellState,
  recentMoves: FreecellMove[],
  visited: string[]
): FreecellMove | null {
  const candidates: FreecellMove[] = [];
  const seen = new Map<string, boolean>();
  const sources = possibleSources(state);
  for (let i = 0; i < sources.length; i += 1) {
    const source = sources[i];
    const cards = getMovableCards(state, source);
    if (cards.length <= 0) {
      continue;
    }
    const targets = possibleTargets(cards[0]);
    for (let j = 0; j < targets.length; j += 1) {
      const target = targets[j];
      if (!canDrop(state, cards, source, target)) {
        continue;
      }
      const candidate: FreecellMove = {
        source: cloneLocation(source),
        target: cloneLocation(target),
        cards: cards.map((card: FreecellCard) => cloneCardValue(card))
      };
      const score = autoMoveScore(state, candidate);
      if (score <= 0 || (target.area !== 'foundation' && isReverseOfRecentMove(candidate, recentMoves))) {
        continue;
      }
      const nextKey = nextStateKeyFor(state, candidate);
      if (nextKey.length <= 0 || visited.indexOf(nextKey) >= 0) {
        continue;
      }
      const equivalentKey = hintEquivalentKey(state, candidate);
      if (seen.has(equivalentKey)) {
        continue;
      }
      seen.set(equivalentKey, true);
      candidate.score = score;
      candidate.nextKey = nextKey;
      candidates.push(candidate);
    }
  }
  candidates.sort((left: FreecellMove, right: FreecellMove) => compareMoves(left, right));
  return candidates.length > 0 ? candidates[0] : null;
}

export function isWon(state: FreecellState): boolean {
  for (let index = 0; index < FREECELL_SUITS.length; index += 1) {
    if (foundationCards(state, FREECELL_SUITS[index]).length !== 13) {
      return false;
    }
  }
  return true;
}

export function gameStateKey(state: FreecellState): string {
  const foundationParts: string[] = [];
  for (let i = 0; i < FREECELL_SUITS.length; i += 1) {
    const suit = FREECELL_SUITS[i];
    foundationParts.push(`${suit}${foundationRank(state, suit)}`);
  }
  const freeParts: string[] = [];
  for (let i = 0; i < state.freecells.length; i += 1) {
    const card = state.freecells[i];
    freeParts.push(card === null ? '_' : card.id);
  }
  const tableauParts: string[] = [];
  for (let i = 0; i < state.tableau.length; i += 1) {
    const columnParts: string[] = [];
    for (let j = 0; j < state.tableau[i].length; j += 1) {
      columnParts.push(state.tableau[i][j].id);
    }
    tableauParts.push(columnParts.join('.'));
  }
  return `${foundationParts.join(',')}/${freeParts.join(',')}/${tableauParts.join('|')}`;
}

export function hintKey(hint: FreecellMove): string {
  const cardIds: string[] = [];
  for (let index = 0; index < hint.cards.length; index += 1) {
    cardIds.push(hint.cards[index].id);
  }
  return `${moveLocationKey(hint.source)}>${moveLocationKey(hint.target)}:${cardIds.join(',')}`;
}

export function locationMatches(left: FreecellLocation | null, right: FreecellLocation | null): boolean {
  if (left === null || right === null) {
    return false;
  }
  return left.area === right.area &&
    left.index === right.index &&
    left.cardIndex === right.cardIndex &&
    left.suit === right.suit;
}

export function markMatches(mark: FreecellLocation, location: FreecellLocation): boolean {
  if (mark.area !== location.area) {
    return false;
  }
  if (mark.area === 'foundation') {
    return mark.suit === location.suit;
  }
  if (mark.area === 'freecell') {
    return mark.index === location.index;
  }
  if (mark.area === 'tableau') {
    if (mark.index !== location.index) {
      return false;
    }
    if (mark.cardIndex === undefined) {
      return location.cardIndex === undefined;
    }
    return location.cardIndex !== undefined && location.cardIndex >= mark.cardIndex;
  }
  return false;
}

function createRandom(seed: number): () => number {
  let value = normalizeSeed(seed) % 2147483647;
  if (value <= 0) {
    value += 2147483646;
  }
  return (): number => {
    value = value * 16807 % 2147483647;
    return (value - 1) / 2147483646;
  };
}

function hasRemainingRanks(ranks: number[]): boolean {
  for (let index = 0; index < ranks.length; index += 1) {
    if (ranks[index] > 0) {
      return true;
    }
  }
  return false;
}

function randomSuitIndex(ranks: number[], random: () => number): number {
  const available: number[] = [];
  for (let index = 0; index < ranks.length; index += 1) {
    if (ranks[index] > 0) {
      available.push(index);
    }
  }
  return available[Math.floor(random() * available.length)];
}

function cloneCard(card: FreecellCard | null): FreecellCard | null {
  return card === null ? null : cloneCardValue(card);
}

function cloneCardValue(card: FreecellCard): FreecellCard {
  return { id: card.id, suit: card.suit, rank: card.rank };
}

function foundationCards(state: FreecellState, suit: FreecellSuit): FreecellCard[] {
  if (suit === 'S') {
    return state.foundations.S;
  }
  if (suit === 'H') {
    return state.foundations.H;
  }
  if (suit === 'D') {
    return state.foundations.D;
  }
  return state.foundations.C;
}

function foundationRank(state: FreecellState, suit: FreecellSuit): number {
  return foundationCards(state, suit).length;
}

function oppositeColorSuits(suit: FreecellSuit): FreecellSuit[] {
  return suitColor(suit) === 'red' ? ['S', 'C'] : ['H', 'D'];
}

function canStackOn(card: FreecellCard, target: FreecellCard): boolean {
  return card.rank + 1 === target.rank && cardColor(card) !== cardColor(target);
}

function isOrderedStack(cards: FreecellCard[]): boolean {
  if (cards.length <= 1) {
    return true;
  }
  for (let index = 0; index < cards.length - 1; index += 1) {
    if (!canStackOn(cards[index + 1], cards[index])) {
      return false;
    }
  }
  return true;
}

function emptyFreecellCount(state: FreecellState): number {
  let count = 0;
  for (let index = 0; index < state.freecells.length; index += 1) {
    if (state.freecells[index] === null) {
      count += 1;
    }
  }
  return count;
}

function emptyColumnCount(state: FreecellState): number {
  let count = 0;
  for (let index = 0; index < state.tableau.length; index += 1) {
    if (state.tableau[index].length === 0) {
      count += 1;
    }
  }
  return count;
}

function maxMovableCards(state: FreecellState): number {
  return (emptyFreecellCount(state) + 1) * Math.pow(2, emptyColumnCount(state));
}

function removeFromSource(state: FreecellState, source: FreecellLocation, count: number): FreecellCard[] {
  if (source.area === 'freecell') {
    const index = source.index ?? -1;
    const card = state.freecells[index];
    state.freecells[index] = null;
    return card === null ? [] : [card];
  }
  if (source.area === 'tableau') {
    const index = source.index ?? -1;
    const cardIndex = source.cardIndex ?? -1;
    return state.tableau[index].splice(cardIndex, count);
  }
  return [];
}

function appendToTarget(state: FreecellState, cards: FreecellCard[], target: FreecellLocation): void {
  if (cards.length <= 0) {
    return;
  }
  if (target.area === 'freecell') {
    const index = target.index ?? -1;
    state.freecells[index] = cards[0];
  } else if (target.area === 'foundation') {
    const suit = target.suit ?? cards[0].suit;
    foundationCards(state, suit).push(cards[0]);
  } else if (target.area === 'tableau') {
    const index = target.index ?? -1;
    for (let i = 0; i < cards.length; i += 1) {
      state.tableau[index].push(cards[i]);
    }
  }
}

function possibleSources(state: FreecellState): FreecellLocation[] {
  const sources: FreecellLocation[] = [];
  for (let index = 0; index < state.freecells.length; index += 1) {
    if (state.freecells[index] !== null) {
      sources.push({ area: 'freecell', index: index });
    }
  }
  for (let columnIndex = 0; columnIndex < state.tableau.length; columnIndex += 1) {
    const column = state.tableau[columnIndex];
    for (let cardIndex = 0; cardIndex < column.length; cardIndex += 1) {
      const source: FreecellLocation = { area: 'tableau', index: columnIndex, cardIndex: cardIndex };
      if (getMovableCards(state, source).length > 0) {
        sources.push(source);
      }
    }
  }
  return sources;
}

function possibleTargets(card: FreecellCard): FreecellLocation[] {
  return [
    { area: 'foundation', suit: card.suit },
    { area: 'tableau', index: 0 },
    { area: 'tableau', index: 1 },
    { area: 'tableau', index: 2 },
    { area: 'tableau', index: 3 },
    { area: 'tableau', index: 4 },
    { area: 'tableau', index: 5 },
    { area: 'tableau', index: 6 },
    { area: 'tableau', index: 7 },
    { area: 'freecell', index: 0 },
    { area: 'freecell', index: 1 },
    { area: 'freecell', index: 2 },
    { area: 'freecell', index: 3 }
  ];
}

function hintPriority(state: FreecellState, source: FreecellLocation, target: FreecellLocation): number {
  if (source.area === 'freecell' && target.area === 'freecell') {
    return 0;
  }
  if (target.area === 'foundation') {
    return 100;
  }
  if (target.area === 'tableau') {
    const index = target.index ?? -1;
    return index >= 0 && state.tableau[index].length > 0 ? 80 : 55;
  }
  if (target.area === 'freecell') {
    return source.area === 'tableau' ? 30 : 0;
  }
  return 0;
}

function autoMoveScore(state: FreecellState, candidate: FreecellMove): number {
  const source = candidate.source;
  const target = candidate.target;
  const cards = candidate.cards;
  const first = cards[0];
  if (target.area === 'foundation') {
    return canMoveToFoundation(first, state) ? 10000 + first.rank + (isSafeFoundationMove(first, state) ? 50 : 0) : 0;
  }
  if (target.area === 'tableau') {
    const targetIndex = target.index ?? -1;
    const targetColumn = state.tableau[targetIndex];
    let score = 0;
    if (source.area === 'freecell') {
      score += 850;
    }
    if (source.area === 'tableau') {
      const sourceIndex = source.index ?? -1;
      const sourceCardIndex = source.cardIndex ?? -1;
      const sourceColumn = state.tableau[sourceIndex];
      const exposesCard = sourceCardIndex > 0;
      if (sourceIndex === targetIndex) {
        return 0;
      }
      if (sourceCardIndex === 0 && targetColumn.length === 0) {
        return 0;
      }
      if (exposesCard) {
        score += 360 + sourceCardIndex * 8;
        const exposed = sourceColumn[sourceCardIndex - 1];
        if (canMoveToFoundation(exposed, state)) {
          score += 130;
        }
      }
      if (cards.length > 1) {
        score += 90 + cards.length * 28;
      }
      if (cards.length === 1 && sourceCardIndex === sourceColumn.length - 1 && targetColumn.length === 0) {
        score -= 260;
      }
    }
    if (targetColumn.length > 0) {
      score += 260;
      const targetTop = targetColumn[targetColumn.length - 1];
      if (first.rank + 1 === targetTop.rank) {
        score += 40;
      }
    } else {
      score += source.area === 'freecell' ? 220 : 80;
      if (cards.length > 1) {
        score += 190;
      }
      if (first.rank >= 11) {
        score += 90;
      }
    }
    return score;
  }
  if (target.area === 'freecell') {
    if (source.area !== 'tableau' || cards.length !== 1) {
      return 0;
    }
    const sourceIndex = source.index ?? -1;
    const sourceCardIndex = source.cardIndex ?? -1;
    const column = state.tableau[sourceIndex];
    if (emptyFreecellCount(state) <= 1 && emptyColumnCount(state) === 0) {
      return 0;
    }
    if (sourceCardIndex > 0) {
      return 170 + sourceCardIndex * 14;
    }
    return column.length === 1 && emptyFreecellCount(state) >= 2 ? 70 : 0;
  }
  return 0;
}

function nextStateKeyFor(state: FreecellState, candidate: FreecellMove): string {
  const nextState = cloneState(state);
  const move = applyMove(nextState, candidate.source, candidate.target);
  return move === null ? '' : gameStateKey(nextState);
}

function stackLocationKey(location: FreecellLocation): string {
  if (location.area === 'foundation') {
    return `${location.area}:${location.suit ?? ''}`;
  }
  return `${location.area}:${location.index ?? -1}`;
}

function moveLocationKey(location: FreecellLocation): string {
  let key = stackLocationKey(location);
  if (location.cardIndex !== undefined) {
    key = `${key}:${location.cardIndex}`;
  }
  return key;
}

function sameCards(left: FreecellCard[], right: FreecellCard[]): boolean {
  if (left.length !== right.length) {
    return false;
  }
  for (let index = 0; index < left.length; index += 1) {
    if (left[index].id !== right[index].id) {
      return false;
    }
  }
  return true;
}

function isReverseOfRecentMove(candidate: FreecellMove, recentMoves: FreecellMove[]): boolean {
  for (let index = 0; index < recentMoves.length; index += 1) {
    const move = recentMoves[index];
    if (sameCards(candidate.cards, move.cards) &&
      stackLocationKey(candidate.source) === stackLocationKey(move.target) &&
      stackLocationKey(candidate.target) === stackLocationKey(move.source)) {
      return true;
    }
  }
  return false;
}

function hintEquivalentKey(state: FreecellState, hint: FreecellMove): string {
  let targetKey = moveLocationKey(hint.target);
  if (hint.target.area === 'freecell') {
    targetKey = 'freecell:any';
  } else if (hint.target.area === 'tableau') {
    const index = hint.target.index ?? -1;
    if (index >= 0 && state.tableau[index].length === 0) {
      targetKey = 'tableau:empty';
    }
  }
  const cardIds: string[] = [];
  for (let index = 0; index < hint.cards.length; index += 1) {
    cardIds.push(hint.cards[index].id);
  }
  return `${moveLocationKey(hint.source)}>${targetKey}:${cardIds.join(',')}`;
}

function compareMoves(left: FreecellMove, right: FreecellMove): number {
  const leftScore = left.score ?? 0;
  const rightScore = right.score ?? 0;
  if (rightScore !== leftScore) {
    return rightScore - leftScore;
  }
  if (left.cards.length !== right.cards.length) {
    return right.cards.length - left.cards.length;
  }
  return hintKey(left) < hintKey(right) ? -1 : 1;
}
