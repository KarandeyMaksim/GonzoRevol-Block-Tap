import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

/// Single local persistence gateway. The TZ has no backend, so the whole
/// economy (balance, bonuses, spins, cooldowns, settings, payout methods)
/// lives here as JSON in SharedPreferences.
class GameRepository {
  GameRepository(this._prefs);

  static const _key = 'gonzorevol_game_data_v1';

  final SharedPreferences _prefs;

  static Future<GameRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return GameRepository(prefs);
  }

  GameData load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return GameData();
    try {
      return GameData.decode(raw);
    } catch (_) {
      return GameData();
    }
  }

  Future<void> save(GameData data) async {
    await _prefs.setString(_key, data.encode());
  }
}
