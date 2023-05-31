import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:hooked_bloc/hooked_bloc.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart' as test;

@isTest
void actionBlocTest<B extends BlocActionMixin<Action, State>, State extends Object, Action>(
  String description, {
  FutureOr<void> Function()? setUp,
  required B Function() build,
  State Function()? seed,
  Function(B bloc)? act,
  Duration? wait,
  int skip = 0,
  int skipActions = 0,
  dynamic Function()? expect,
  dynamic Function()? expectActions,
  Function(B bloc)? verify,
  dynamic Function()? errors,
  FutureOr<void> Function()? tearDown,
  dynamic tags,
}) {
  test.test(
    description,
    () {
      final List<Action> blocActions = [];
      late final StreamSubscription<Action> actionsSubscription;

      blocTest<B, State>(
        description,
        setUp: () async {
          blocActions.clear();

          return await setUp?.call();
        },
        build: () {
          final bloc = build();
          actionsSubscription = bloc.actions.skip(skipActions).listen(blocActions.add);

          return bloc;
        },
        seed: seed,
        act: act,
        wait: wait,
        skip: skip,
        expect: expect,
        verify: (bloc) async {
          await actionsSubscription.cancel();
          await verify?.call(bloc);

          if (expectActions != null) {
            final dynamic expectedActions = expectActions();

            final shallowEquality = '$blocActions' == '$expectedActions';

            try {
              test.expect(blocActions, test.wrapMatcher(expectedActions));
            } on test.TestFailure catch (e) {
              if (shallowEquality || expectedActions is! List<Action>) rethrow;

              final diff = 'expected: $expectedActions, actual: $blocActions';
              final message = '${e.message}\n$diff';

              throw test.TestFailure(message);
            }
          }
        },
        errors: errors,
        tearDown: tearDown,
      );
    },
    tags: tags,
  );
}
