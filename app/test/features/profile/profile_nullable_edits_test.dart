import 'package:flutter_test/flutter_test.dart';
import '../../support/qa_profile_fixtures.dart';

void main() {
  test(
    'omitted draft fields persist while explicit null clears optional edits',
    () {
      final original = qaProfileDraft().copyWith(
        heightCm: 175,
        education: 'Graduate',
        profession: 'Architect',
        incomeRange: 'Saved',
        country: 'India',
        regionState: 'Maharashtra',
        city: 'Thane',
        instagramHandle: 'qa_member',
        additionalInfo: 'Saved information',
        petPreference: 'Dogs',
        dietPreference: 'Vegetarian',
        workoutFrequency: 'Weekly',
        dietType: 'Balanced',
        sleepSchedule: 'Early bird',
        travelStyle: 'Planned',
        politicalComfortRange: 'Open',
        religion: 'Saved religion',
        motherTongue: 'Hindi',
      );
      final unrelated = original.copyWith(bio: 'A different biography');
      expect(unrelated.country, 'India');
      expect(unrelated.heightCm, 175);
      expect(unrelated.motherTongue, 'Hindi');
      final cleared = original.copyWith(
        heightCm: null,
        education: null,
        profession: null,
        incomeRange: null,
        country: null,
        regionState: null,
        city: null,
        instagramHandle: null,
        additionalInfo: null,
        petPreference: null,
        dietPreference: null,
        workoutFrequency: null,
        dietType: null,
        sleepSchedule: null,
        travelStyle: null,
        politicalComfortRange: null,
        religion: null,
        motherTongue: null,
      );
      expect([
        cleared.heightCm,
        cleared.education,
        cleared.profession,
        cleared.incomeRange,
        cleared.country,
        cleared.regionState,
        cleared.city,
        cleared.instagramHandle,
        cleared.additionalInfo,
        cleared.petPreference,
        cleared.dietPreference,
        cleared.workoutFrequency,
        cleared.dietType,
        cleared.sleepSchedule,
        cleared.travelStyle,
        cleared.politicalComfortRange,
        cleared.religion,
        cleared.motherTongue,
      ], everyElement(isNull));
      expect(cleared.bio, original.bio);
      expect(cleared.seekingGenders, original.seekingGenders);
    },
  );
}
