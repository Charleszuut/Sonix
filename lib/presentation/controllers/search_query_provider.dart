import 'package:flutter_riverpod/flutter_riverpod.dart';

final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');
