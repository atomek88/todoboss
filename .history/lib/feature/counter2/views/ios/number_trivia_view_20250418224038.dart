import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_counter_app/models/number_trivia_model.dart';
import 'package:riverpod_counter_app/riverpod/number_trivia_provider.dart';

class NumberTriviaView extends ConsumerStatefulWidget {
  const NumberTriviaView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _NumberTriviaViewState();
}

class _NumberTriviaViewState extends ConsumerState<NumberTriviaView> {
  late TextEditingController inputNumberController;

  @override
  void initState() {
    super.initState();

    inputNumberController = TextEditingController();
  }

  @override
  void dispose() {
    inputNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<NumberTriviaModel> numberTrivia =
        ref.watch(numberTriviaProvider);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Number Trivia App'),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: numberTrivia.when(
            skipLoadingOnRefresh: false,
            data: (numberTrivia) => successWidget(numberTrivia, ref),
            error: (error, stackTrace) => errorWidget(error),
            loading: () => loadingWidget(),
          ),
        ),
      ),
    );
  }

  Widget successWidget(NumberTriviaModel numberTrivia, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Builder(builder: (context) {
              if (numberTrivia.number == -1) {
                return const Text(
                  'Please enter a number',
                  style: TextStyle(fontSize: 28),
                );
              }

              return Text(
                numberTrivia.number.toString(),
                style: const TextStyle(fontSize: 50),
              );
            }),
            const SizedBox(height: 20.0),
            Text(
              numberTrivia.text,
              style: const TextStyle(fontSize: 25),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20.0),
            CupertinoTextField(
              controller: inputNumberController,
              keyboardType: TextInputType.number,
              clearButtonMode: OverlayVisibilityMode.editing,
              // border
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.inactiveGray,
                    width: 0.0,
                  ),
                ),
              ),
              placeholder: 'Enter a number',
            ),
            const SizedBox(height: 20.0),
            CupertinoButton.filled(
              onPressed: () {
                if (inputNumberController.text.isEmpty) {
                  showCupertinoDialog(
                    context: context,
                    builder: (context) => CupertinoAlertDialog(
                      title: const Text('Error'),
                      content: const Text('Please enter a number'),
                      actions: [
                        CupertinoButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                  return;
                }

                ref
                    .read(numberTriviaProvider.notifier)
                    .getConcreteNumberTrivia(
                      int.parse(inputNumberController.text),
                    )
                    .then((value) {
                  inputNumberController.clear();
                  FocusScope.of(context).unfocus();
                });
              },
              child: const Text('Get concrete number'),
            ),
            const SizedBox(height: 20.0),
            CupertinoButton.filled(
              onPressed: () {
                ref.read(numberTriviaProvider.notifier).getRandomNumberTrivia();
              },
              child: const Text('Get random number'),
            ),
          ],
        ),
      ),
    );
  }

  Widget errorWidget(Object error) {
    Map<String, dynamic> errorMap = error as Map<String, dynamic>;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            errorMap['statusCode'].toString(),
            style: const TextStyle(fontSize: 50),
          ),
          const SizedBox(height: 20.0),
          Text(errorMap['message']),
        ],
      ),
    );
  }

  Widget loadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CupertinoActivityIndicator(),
          SizedBox(height: 10),
          Text('Loading'),
        ],
      ),
    );
  }
}
