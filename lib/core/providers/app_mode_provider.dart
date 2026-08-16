import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppMode { renting, hosting }

final appModeProvider = StateProvider<AppMode>((ref) => AppMode.renting);
