import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/features/profile/providers/profile_setup_provider.dart';
import '../../support/qa_profile_fixtures.dart';

class _Draft extends ProfileSetupNotifier {
  @override
  Future<ProfileDraft> build() async => qaProfileDraft();
}

void main() {
  test(
    'real preference notifier exposes failed persistence and supports retry',
    () async {
      var reject = true;
      var writes = 0;
      final dio = Dio(BaseOptions(baseUrl: 'https://test.invalid'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            writes++;
            if (reject) {
              h.reject(
                DioException(
                  requestOptions: o,
                  response: Response<dynamic>(
                    requestOptions: o,
                    statusCode: 503,
                  ),
                ),
              );
              return;
            }
            h.resolve(
              Response<dynamic>(
                requestOptions: o,
                statusCode: 200,
                data: {'draft': o.data},
              ),
            );
          },
        ),
      );
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(dio),
          profileSetupNotifierProvider.overrideWith(_Draft.new),
        ],
      );
      addTearDown(container.dispose);
      final listener = container.listen(
        profileSetupNotifierProvider,
        (_, _) {},
      );
      addTearDown(listener.close);
      final draft = await container.read(profileSetupNotifierProvider.future);
      final notifier = container.read(profileSetupNotifierProvider.notifier);
      Future<void> save() => notifier.savePreferences(
        seekingGenders: draft.seekingGenders,
        minAgeYears: draft.minAgeYears,
        maxAgeYears: draft.maxAgeYears,
        maxDistanceKm: draft.maxDistanceKm,
        educationFilter: draft.educationFilter,
        seriousOnly: draft.seriousOnly,
        verifiedOnly: draft.verifiedOnly,
        country: draft.country,
        regionState: draft.regionState,
        city: draft.city,
        instagramHandle: draft.instagramHandle,
        hobbies: draft.hobbies,
        favoriteBooks: draft.favoriteBooks,
        favoriteNovels: draft.favoriteNovels,
        favoriteSongs: draft.favoriteSongs,
        extraCurriculars: draft.extraCurriculars,
        additionalInfo: draft.additionalInfo,
        intentTags: draft.intentTags,
        languageTags: draft.languageTags,
        petPreference: draft.petPreference,
        dietPreference: draft.dietPreference,
        workoutFrequency: draft.workoutFrequency,
        dietType: draft.dietType,
        sleepSchedule: draft.sleepSchedule,
        travelStyle: draft.travelStyle,
        politicalComfortRange: draft.politicalComfortRange,
        dealBreakerTags: draft.dealBreakerTags,
        motherTongue: draft.motherTongue,
        hookupOnly: draft.hookupOnly,
      );
      await expectLater(save(), throwsA(isA<DioException>()));
      expect(writes, 1);
      reject = false;
      await save();
      expect(writes, 2);
    },
  );
}
