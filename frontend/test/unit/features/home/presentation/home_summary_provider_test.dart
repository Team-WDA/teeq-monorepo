import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/features/home/domain/home_summary.dart';
import 'package:teeq/features/home/presentation/home_summary_provider.dart';
import 'package:teeq/features/home/data/home_repository_impl.dart';

import '../../../../support/fake_home_repository.dart';

const _summary = HomeSummary(
  characterName: '티큐',
  personalityTags: ['다정한', '차분한', '든든한'],
  greeting: '안녕',
);

(ProviderContainer, FakeHomeRepository) _setUp() {
  final repository = FakeHomeRepository(summary: _summary);
  final container = ProviderContainer(
    overrides: [homeRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  return (container, repository);
}

void main() {
  test('homeSummary_fetchesOncePerMemberId', () async {
    final (container, repository) = _setUp();
    container.listen(homeSummaryProvider('a'), (_, _) {});

    expect(await container.read(homeSummaryProvider('a').future), _summary);
    await container.read(homeSummaryProvider('a').future);

    expect(repository.fetchCount, 1);
  });

  test('homeSummary_keepsSeparateInstancesPerMemberId', () async {
    final (container, repository) = _setUp();
    container.listen(homeSummaryProvider('a'), (_, _) {});
    container.listen(homeSummaryProvider('b'), (_, _) {});

    await container.read(homeSummaryProvider('a').future);
    await container.read(homeSummaryProvider('b').future);

    expect(repository.fetchCount, 2);
  });

  test('homeSummary_refetchesWhenInvalidated', () async {
    final (container, repository) = _setUp();
    container.listen(homeSummaryProvider('a'), (_, _) {});
    await container.read(homeSummaryProvider('a').future);

    container.invalidate(homeSummaryProvider);
    await container.read(homeSummaryProvider('a').future);

    expect(repository.fetchCount, 2);
  });
}
