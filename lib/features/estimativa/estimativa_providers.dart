import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database_providers.dart';
import 'models/estimativa_model.dart';

final estimativasListProvider = FutureProvider<List<EstimativaModel>>((ref) async {
  final dao = ref.watch(estimativasDaoProvider);
  return dao.watchAll();
});

final estimativaDetailProvider = FutureProvider.family<EstimativaModel?, int>((ref, id) async {
  final dao = ref.watch(estimativasDaoProvider);
  return dao.findById(id);
});
