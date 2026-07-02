import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Renders a single grid/piece cube using the cube skins exported from
/// Figma (`cube02`..`cube05`). Skin `0`/`null` renders as an empty cell.
class GameTile extends StatelessWidget {
  const GameTile({super.key, required this.skin, this.size = 40, this.ghost = false});

  final int? skin;
  final double size;
  final bool ghost;

  static const _assets = {
    1: 'assets/images/tile_cube_01.png',
    2: 'assets/images/tile_cube_02.png',
    3: 'assets/images/tile_cube_03.png',
    4: 'assets/images/tile_cube_04.png',
    5: 'assets/images/tile_cube_05.png',
    6: 'assets/images/tile_cube_06.png',
    7: 'assets/images/tile_cube_07.png',
    8: 'assets/images/tile_cube_08.png',
    9: 'assets/images/tile_cube_09.png',
    10: 'assets/images/tile_cube_10.png',
    11: 'assets/images/tile_cube_11.png',
    12: 'assets/images/tile_cube_12.png',
  };

  @override
  Widget build(BuildContext context) {
    if (skin == null) {
      // Figma cells are edge-to-edge (42.96px pitch == 42.96px cell size);
      // only the 1px border creates the grid lines, no gap between cells.
      return Container(
        decoration: BoxDecoration(
          color: AppColors.boardCell,
          border: Border.all(color: AppColors.boardCellBorder, width: 0.75),
        ),
      );
    }
    final asset = _assets[skin] ?? _assets[1]!;
    return Opacity(
      opacity: ghost ? 0.55 : 1,
      child: Container(
        margin: const EdgeInsets.all(0.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          boxShadow: ghost
              ? null
              : const [BoxShadow(color: Colors.black38, blurRadius: 2, offset: Offset(0, 1))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Image.asset(asset, fit: BoxFit.cover),
        ),
      ),
    );
  }
}
