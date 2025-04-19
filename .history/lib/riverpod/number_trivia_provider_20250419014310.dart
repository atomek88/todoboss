import 'dart:isolate';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:dio/dio.dart' as http;
import 'package:todoApp/feature/counter2/models/number_trivia_model.dart';

part 'number_trivia_provider.g.dart';

@riverpod
class NumberTrivia extends _$NumberTrivia {
  @override
  FutureOr<NumberTriviaModel> build() {
    return NumberTriviaModel.fromJson({
      'number': -1,
      'text': '',
      'type': '',
      'found': false,
    });
  }

  Future<void> getRandomNumberTrivia() async {
    state = const AsyncLoading();

    try {
      final response = await Isolate.run(() async {
        return await http.Dio().get(
          'http://numbersapi.com/random',
          options: http.Options(
            headers: {
              'Content-Type': 'application/json',
            },
          ),
        );
      });

      if (response.statusCode != 200) {
        return Future.error({
          'success': false,
          'statusCode': response.statusCode,
          'message': 'Something when wrong, please try again',
        });
      }

      final numberTrivia = response.data as Map<String, dynamic>;

      state = AsyncData(NumberTriviaModel.fromJson(numberTrivia));
    } catch (e) {
      return Future.error({
        'success': false,
        'message': e.toString(),
      });
    }
  }

  Future<void> getConcreteNumberTrivia(
    int number,
  ) async {
    try {
      state = const AsyncLoading();

      final response = await Isolate.run(() async {
        return await http.Dio().get(
          'http://numbersapi.com/$number',
          options: http.Options(
            headers: {
              'Content-Type': 'application/json',
            },
          ),
        );
      });

      if (response.statusCode != 200) {
        return Future.error({
          'success': false,
          'statusCode': response.statusCode,
          'message': 'Something when wrong, please try again',
        });
      }

      final numberTrivia = response.data as Map<String, dynamic>;

      state = AsyncData(NumberTriviaModel.fromJson(numberTrivia));
    } catch (e) {
      return Future.error({
        'success': false,
        'message': e.toString(),
      });
    }
  }
}
