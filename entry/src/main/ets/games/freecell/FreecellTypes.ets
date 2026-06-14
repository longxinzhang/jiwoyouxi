export type FreecellSuit = 'S' | 'H' | 'D' | 'C';
export type FreecellArea = 'freecell' | 'foundation' | 'tableau';

export interface FreecellCard {
  id: string;
  suit: FreecellSuit;
  rank: number;
}

export interface FreecellFoundations {
  S: FreecellCard[];
  H: FreecellCard[];
  D: FreecellCard[];
  C: FreecellCard[];
}

export interface FreecellState {
  seed: number;
  freecells: Array<FreecellCard | null>;
  foundations: FreecellFoundations;
  tableau: FreecellCard[][];
}

export interface FreecellLocation {
  area: FreecellArea;
  index?: number;
  cardIndex?: number;
  suit?: FreecellSuit;
}

export interface FreecellMove {
  source: FreecellLocation;
  target: FreecellLocation;
  cards: FreecellCard[];
  score?: number;
  nextKey?: string;
}

export interface FreecellSnapshot {
  state: FreecellState;
  moves: number;
  score: number;
  recentMoves: FreecellMove[];
}

export interface FreecellLayout {
  appWidth: number;
  offsetX: number;
  tiny: boolean;
  compact: boolean;
  side: number;
  gap: number;
  cardWidth: number;
  cardHeight: number;
  fan: number;
  titleTop: number;
  titleWidth: number;
  titleHeight: number;
  statsTop: number;
  statWidth: number;
  statHeight: number;
  statGap: number;
  slotsTop: number;
  tableTop: number;
  tableBottom: number;
  toolbarTop: number;
  toolbarHeight: number;
  decorHeight: number;
  rulesWidth: number;
}
