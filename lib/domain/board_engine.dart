import 'dart:math';

const int boardSize = 8;

/// A polyomino piece: list of (row, col) offsets from its top-left cell.
class PieceShape {
  const PieceShape(this.cells);
  final List<Point<int>> cells;

  int get width => cells.map((c) => c.y).reduce(max) + 1;
  int get height => cells.map((c) => c.x).reduce(max) + 1;

  static const List<PieceShape> library = [
    PieceShape([Point(0, 0)]),
    PieceShape([Point(0, 0), Point(0, 1)]),
    PieceShape([Point(0, 0), Point(1, 0)]),
    PieceShape([Point(0, 0), Point(0, 1), Point(0, 2)]),
    PieceShape([Point(0, 0), Point(1, 0), Point(2, 0)]),
    PieceShape([Point(0, 0), Point(0, 1), Point(1, 0), Point(1, 1)]),
    PieceShape([Point(0, 0), Point(0, 1), Point(0, 2), Point(1, 0)]),
    PieceShape([Point(0, 0), Point(0, 1), Point(0, 2), Point(1, 2)]),
    PieceShape([Point(0, 0), Point(1, 0), Point(1, 1), Point(1, 2)]),
    PieceShape([Point(0, 2), Point(1, 0), Point(1, 1), Point(1, 2)]),
    PieceShape([Point(0, 0), Point(1, 0), Point(2, 0), Point(2, 1)]),
    PieceShape([Point(0, 1), Point(1, 1), Point(2, 0), Point(2, 1)]),
    PieceShape([Point(0, 0), Point(0, 1), Point(1, 1), Point(2, 1)]),
    PieceShape([Point(0, 0), Point(1, 0), Point(1, 1), Point(0, 1), Point(0, 2)]),
    PieceShape([Point(0, 0), Point(1, 0), Point(2, 0), Point(0, 1), Point(2, 1)]),
    PieceShape([Point(0, 0), Point(0, 1), Point(0, 2), Point(1, 1)]),
    PieceShape([Point(1, 0), Point(0, 1), Point(1, 1), Point(2, 1)]),
    PieceShape([Point(0, 0), Point(0, 1), Point(1, 0), Point(1, 1), Point(2, 0), Point(2, 1)]),
  ];
}

/// A dealt tray piece: shape + which cube skin (1..4) it renders with.
class TrayPiece {
  TrayPiece({required this.shape, required this.skin, required this.id});
  final PieceShape shape;
  final int skin;
  final String id;
}

class PlacementResult {
  PlacementResult({
    required this.linesCleared,
    required this.cellsPlaced,
    required this.cellsCleared,
  });
  final int linesCleared;
  final int cellsPlaced;
  final int cellsCleared;
}

/// Pure game logic for the 8x8 block-placement board (block-blast style),
/// matching the reference `block-puzzle-master` mechanic required by the TZ.
class BoardEngine {
  BoardEngine() {
    grid = List.generate(boardSize, (_) => List<int?>.filled(boardSize, null));
  }

  final _random = Random();
  late List<List<int?>> grid;

  static const int skinCount = 12;

  List<TrayPiece> dealTray() {
    return List.generate(3, (i) {
      final shape = PieceShape.library[_random.nextInt(PieceShape.library.length)];
      final skin = _random.nextInt(skinCount) + 1;
      return TrayPiece(shape: shape, skin: skin, id: '${DateTime.now().microsecondsSinceEpoch}_$i');
    });
  }

  bool canPlace(PieceShape shape, int row, int col) {
    for (final cell in shape.cells) {
      final r = row + cell.x;
      final c = col + cell.y;
      if (r < 0 || r >= boardSize || c < 0 || c >= boardSize) return false;
      if (grid[r][c] != null) return false;
    }
    return true;
  }

  bool canPlaceAnywhere(PieceShape shape) {
    for (var r = 0; r < boardSize; r++) {
      for (var c = 0; c < boardSize; c++) {
        if (canPlace(shape, r, c)) return true;
      }
    }
    return false;
  }

  bool hasAnyMove(List<TrayPiece> tray) {
    for (final p in tray) {
      if (canPlaceAnywhere(p.shape)) return true;
    }
    return false;
  }

  PlacementResult place(PieceShape shape, int row, int col, int skin) {
    for (final cell in shape.cells) {
      grid[row + cell.x][col + cell.y] = skin;
    }
    final cellsPlaced = shape.cells.length;

    final fullRows = <int>[];
    final fullCols = <int>[];
    for (var r = 0; r < boardSize; r++) {
      if (grid[r].every((v) => v != null)) fullRows.add(r);
    }
    for (var c = 0; c < boardSize; c++) {
      if (List.generate(boardSize, (r) => grid[r][c]).every((v) => v != null)) fullCols.add(c);
    }

    final clearedCells = <Point<int>>{};
    for (final r in fullRows) {
      for (var c = 0; c < boardSize; c++) {
        clearedCells.add(Point(r, c));
      }
    }
    for (final c in fullCols) {
      for (var r = 0; r < boardSize; r++) {
        clearedCells.add(Point(r, c));
      }
    }
    for (final p in clearedCells) {
      grid[p.x][p.y] = null;
    }

    return PlacementResult(
      linesCleared: fullRows.length + fullCols.length,
      cellsPlaced: cellsPlaced,
      cellsCleared: clearedCells.length,
    );
  }

  void reset() {
    grid = List.generate(boardSize, (_) => List<int?>.filled(boardSize, null));
  }
}
