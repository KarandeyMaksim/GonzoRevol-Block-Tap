import 'package:flutter/material.dart';
import '../../domain/board_engine.dart';
import 'board_widget.dart';
import 'tile_widget.dart';

/// The tray of up to 3 draggable pieces below the board.
class PieceTray extends StatelessWidget {
  const PieceTray({super.key, required this.tray, required this.cellSize, this.enabled = true});

  final List<TrayPiece?> tray;
  final double cellSize;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(tray.length, (i) {
        final piece = tray[i];
        if (piece == null) {
          return SizedBox(width: cellSize * 3, height: cellSize * 3);
        }
        final pieceWidget = _PieceShapeWidget(piece: piece, cellSize: cellSize);
        return SizedBox(
          width: cellSize * 3,
          height: cellSize * 3,
          // Small shapes (1-2 cells) must be centered in their slot, not
          // pinned to the top-left corner — otherwise the tray looks like
          // one cramped cluster of tiles instead of 3 evenly-spaced pieces.
          child: Center(
            child: enabled
                ? Draggable<DragPieceData>(
                    data: DragPieceData(i, piece),
                    // Anchor on the raw pointer (not the touched cell) and
                    // center the piece on it, so the piece is grabbed exactly
                    // where your finger is instead of jumping away — this
                    // matches the anchor math BoardWidget uses to compute the
                    // drop target, so the piece and its green placement
                    // preview always agree on where it's going.
                    dragAnchorStrategy: pointerDragAnchorStrategy,
                    feedback: Transform.translate(
                      offset: Offset(-piece.shape.width * cellSize / 2, -piece.shape.height * cellSize / 2),
                      child: Opacity(opacity: 0.95, child: pieceWidget),
                    ),
                    childWhenDragging: Opacity(opacity: 0.25, child: pieceWidget),
                    child: pieceWidget,
                  )
                : Opacity(opacity: 0.5, child: pieceWidget),
          ),
        );
      }),
    );
  }
}

class _PieceShapeWidget extends StatelessWidget {
  const _PieceShapeWidget({required this.piece, required this.cellSize});

  final TrayPiece piece;
  final double cellSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: piece.shape.width * cellSize,
      height: piece.shape.height * cellSize,
      child: Stack(
        children: piece.shape.cells.map((cell) {
          return Positioned(
            left: cell.y * cellSize,
            top: cell.x * cellSize,
            width: cellSize,
            height: cellSize,
            child: GameTile(skin: piece.skin, size: cellSize),
          );
        }).toList(),
      ),
    );
  }
}
