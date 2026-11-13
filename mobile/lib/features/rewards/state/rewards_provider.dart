import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/state/auth_provider.dart';
import '../data/reward_repository.dart';
import '../models/reward_model.dart';

final rewardRepositoryProvider = Provider<RewardRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return RewardRepository(client);
});

class RewardsNotifier extends AsyncNotifier<List<RewardModel>> {
  @override
  Future<List<RewardModel>> build() async {
    return _fetch();
  }

  Future<List<RewardModel>> _fetch() async {
    final repo = ref.read(rewardRepositoryProvider);
    return await repo.getRewards();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
  }

  Future<void> claim(String rewardId) async {
    final repo = ref.read(rewardRepositoryProvider);
    await repo.claimReward(rewardId);
    await refresh();
  }
}

final rewardsNotifierProvider = AsyncNotifierProvider<RewardsNotifier, List<RewardModel>>(() {
  return RewardsNotifier();
});
