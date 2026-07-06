import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_loan/src/utils/app_toast.dart';

void main() {
  late _FakeToastPresenter presenter;

  setUp(() {
    presenter = _FakeToastPresenter();
    AppToast.presenter = presenter;
  });

  tearDown(() {
    AppToast.presenter = const EasyLoadingToastPresenter();
  });

  test('show delegates a normal toast message', () async {
    await AppToast.show('Saved');

    expect(presenter.message, 'Saved');
    expect(presenter.isError, isFalse);
  });

  test('error delegates an error toast message', () async {
    await AppToast.error('Request failed');

    expect(presenter.message, 'Request failed');
    expect(presenter.isError, isTrue);
  });

  test('showLoading delegates the loading message', () async {
    await AppToast.showLoading('Loading');

    expect(presenter.loadingMessage, 'Loading');
  });

  test('dismissLoading delegates loading dismissal', () async {
    await AppToast.dismissLoading();

    expect(presenter.dismissedLoading, isTrue);
  });
}

class _FakeToastPresenter implements ToastPresenter {
  String? message;
  bool? isError;
  String? loadingMessage;
  bool dismissedLoading = false;

  @override
  Future<void> show(String message, {required bool isError}) async {
    this.message = message;
    this.isError = isError;
  }

  @override
  Future<void> showLoading(String? message) async {
    loadingMessage = message;
  }

  @override
  Future<void> dismissLoading() async {
    dismissedLoading = true;
  }
}
