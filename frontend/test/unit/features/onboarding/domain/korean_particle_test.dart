import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/features/onboarding/domain/korean_particle.dart';

void main() {
  test('withCopulaParticle_endsWithVowel_appendsYa', () {
    expect(withCopulaParticle('티티'), '티티야');
  });

  test('withCopulaParticle_endsWithBatchim_appendsIya', () {
    expect(withCopulaParticle('민준'), '민준이야');
  });

  test('withSubjectParticle_endsWithVowel_appendsGa', () {
    expect(withSubjectParticle('티티'), '티티가');
  });

  test('withSubjectParticle_endsWithBatchim_appendsI', () {
    expect(withSubjectParticle('민준'), '민준이');
  });

  test('withCopulaParticle_endsWithLatinLetter_treatedAsNoBatchim', () {
    expect(withCopulaParticle('Mina'), 'Mina야');
  });

  test('withSubjectParticle_endsWithDigit_treatedAsNoBatchim', () {
    expect(withSubjectParticle('Tom2'), 'Tom2가');
  });

  test('emptyText_throwsArgumentError', () {
    expect(() => withCopulaParticle(''), throwsArgumentError);
    expect(() => withSubjectParticle(''), throwsArgumentError);
  });
}
