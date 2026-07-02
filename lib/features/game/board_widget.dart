import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../domain/board_engine.dart';
import 'tile_widget.dart';

class DragPieceData {
  DragPieceData(this.trayIndex, this.piece);
  final int trayIndex;
  final TrayPiece piece;
}

/// The 8x8 placement board. Accepts pieces dragged in from [PieceTray] via a
/// [DragTarget], converting the raw drag offset into a board cell and
/// showing a live ghost preview (green = valid, red = invalid).
class BoardWidget extends StatefulWidget {
  const BoardWidget({
    super.key,
    required this.grid,
    required this.boardSizePx,
    required this.canPlace,
    required this.onDrop,
  });

  final List<List<int?>> grid;
  final double boardSizePx;
  final bool Function(TrayPiece piece, int row, int col) canPlace;
  final void Function(int trayIndex, int row, int col) onDrop;

  /// Exposed so callers (e.g. the piece tray) can size their own cells to
  /// match the board's real cell size exactly. Figma: 358px frame with an
  /// 8x8 grid of edge-to-edge 42.96px cells starting ~7.16px in.
  static const double framePadding = 7.16;

  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget> {
  static const double _framePadding = BoardWidget.framePadding;

  final GlobalKey _boardKey = GlobalKey();
  int? _hoverRow;
  int? _hoverCol;
  TrayPiece? _hoverPiece;

  // The grid itself only occupies the area inside the frame's padding, so
  // the cell size must be computed from that inner size — using the raw
  // [boardSizePx] here (as before) drifted further out of sync with the
  // real `GridView` cells on every column/row, which is why the drag
  // ghost/targets looked increasingly detached from the actual grid.
  double get _innerSize => widget.boardSizePx - _framePadding * 2;
  double get _cell => _innerSize / boardSize;

  (int, int)? _cellFromGlobal(Offset globalPos, TrayPiece piece) {
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    // `box` is the outer (padded) frame, so subtract the frame padding to
    // land in the same coordinate space as the grid cells / ghost overlay.
    final local = box.globalToLocal(globalPos) - const Offset(_framePadding, _framePadding);
    // `globalPos` is the raw pointer position (see pointerDragAnchorStrategy
    // in PieceTray), and the dragged piece is rendered centered on that same
    // point, so treat it as the piece's center when deriving its top-left.
    final pw = piece.shape.width * _cell;
    final ph = piece.shape.height * _cell;
    final topLeft = Offset(local.dx - pw / 2, local.dy - ph / 2);
    final col = (topLeft.dx / _cell).round();
    final row = (topLeft.dy / _cell).round();
    return (row, col);
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<DragPieceData>(
      onMove: (details) {
        final cell = _cellFromGlobal(details.offset, details.data.piece);
        if (cell == null) return;
        setState(() {
          _hoverRow = cell.$1;
          _hoverCol = cell.$2;
          _hoverPiece = details.data.piece;
        });
      },
      onLeave: (_) {
        setState(() {
          _hoverRow = null;
          _hoverCol = null;
          _hoverPiece = null;
        });
      },
      onAcceptWithDetails: (details) {
        final cell = _cellFromGlobal(details.offset, details.data.piece);
        setState(() {
          _hoverRow = null;
          _hoverCol = null;
          _hoverPiece = null;
        });
        if (cell == null) return;
        if (widget.canPlace(details.data.piece, cell.$1, cell.$2)) {
          widget.onDrop(details.data.trayIndex, cell.$1, cell.$2);
        }
      },
      builder: (context, candidate, rejected) {
        return Container(
          key: _boardKey,
          width: widget.boardSizePx,
          height: widget.boardSizePx,
          padding: const EdgeInsets.all(_framePadding),
          decoration: BoxDecoration(
            color: AppColors.boardFrame,
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [
              BoxShadow(color: Color(0x40452305), blurRadius: 5, offset: Offset(0, 4)),
            ],
          ),
          child: RepaintBoundary(
            child: Stack(
              children: [
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: boardSize * boardSize,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: boardSize),
                  itemBuilder: (context, index) {
                    final r = index ~/ boardSize;
                    final c = index % boardSize;
                    return GameTile(key: ValueKey('cell_${r}_$c'), skin: widget.grid[r][c], size: _cell);
                  },
                ),
                if (_hoverPiece != null && _hoverRow != null && _hoverCol != null)
                  ..._buildGhost(_hoverPiece!, _hoverRow!, _hoverCol!),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildGhost(TrayPiece piece, int row, int col) {
    final valid = widget.canPlace(piece, row, col);
    return piece.shape.cells.map((cellOffset) {
      final r = row + cellOffset.x;
      final c = col + cellOffset.y;
      if (r < 0 || r >= boardSize || c < 0 || c >= boardSize) return const SizedBox.shrink();
      return Positioned(
        left: c * _cell,
        top: r * _cell,
        width: _cell,
        height: _cell,
        child: Container(
          margin: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            color: (valid ? AppColors.success : AppColors.danger).withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: valid ? AppColors.success : AppColors.danger, width: 2),
          ),
        ),
      );
    }).toList();
  }
}
