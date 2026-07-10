import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kaibigan_loan/src/app_routes.dart';
import 'package:kaibigan_loan/src/core/json/json.dart';
import 'package:kaibigan_loan/src/core/network/api_client.dart';
import 'package:kaibigan_loan/src/core/network/api_config.dart';
import 'package:kaibigan_loan/src/core/network/api_response.dart';
import 'package:kaibigan_loan/src/core/session/product_detail_cache.dart';
import 'package:kaibigan_loan/src/core/session/session_store.dart';
import 'package:kaibigan_loan/src/modules/certification/certification_upload_page.dart';
import 'package:kaibigan_loan/src/modules/certification/widgets/certification_prompt_banner.dart';
import 'package:kaibigan_loan/src/theme/app_colors.dart';
import 'package:kaibigan_loan/src/utils/app_toast.dart';

void main() {
  late SessionStore sessionStore;
  late _FakeToastPresenter toastPresenter;

  setUp(() {
    Get.testMode = true;
    sessionStore = SessionStore.memory();
    toastPresenter = _FakeToastPresenter();
    Get.put<SessionStore>(sessionStore);
    AppToast.presenter = toastPresenter;
  });

  tearDown(() {
    AppToast.presenter = const EasyLoadingToastPresenter();
    Get.reset();
  });

  testWidgets('renders upload page from design assets', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await sessionStore.saveProductDetailCache(
      ProductDetailCache.fromJson({
        'metallurgists': {
          'aimless': 'Upload the clear PRC front from cached detail.',
        },
      }),
    );

    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: '/',
        getPages: [
          GetPage(name: '/', page: () => const SizedBox()),
          GetPage(
            name: AppRoutes.certificationUpload,
            page: () => const CertificationUploadPage(),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    Get.toNamed<void>(
      AppRoutes.certificationUpload,
      arguments: {'geobotanists': 'product-1', 'cardType': 'PRC'},
    );
    await tester.pumpAndSettle();

    expect(find.text('Identity verification'), findsOneWidget);
    expect(find.byType(CertificationPromptBanner), findsOneWidget);
    expect(
      find.text('Upload the clear PRC front from cached detail.'),
      findsOneWidget,
    );
    expect(find.text('Submit'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('falls back to default prompt when product detail cache is empty', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const GetMaterialApp(home: CertificationUploadPage()),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'A clear ID photo is the key to lightning-fast approval. Please upload ID front.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('submit opens upload method sheet and confirms selected method', (
    tester,
  ) async {
    CertificationUploadMethod? selectedMethod;
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      GetMaterialApp(
        home: CertificationUploadPage(
          onUploadMethodSelected: (method) => selectedMethod = method,
          imagePicker: _FakeImagePicker(),
          imageCompressor: _FakeImageCompressor(compressedPath: ''),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(find.text('Photo album'), findsOneWidget);
    expect(find.text('Photograph'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    final barrier = tester
        .widgetList<ModalBarrier>(find.byType(ModalBarrier))
        .last;
    expect(barrier.color, AppColors.uploadMethodBarrier);
    expect(barrier.color?.a, closeTo(0.6, 0.001));
    expect(
      tester
          .widget<DecoratedBox>(
            find.descendant(
              of: find.byKey(const Key('certificationUploadPhotoAlbumOption')),
              matching: find.byType(DecoratedBox),
            ),
          )
          .decoration,
      isA<BoxDecoration>().having(
        (decoration) => decoration.color,
        'color',
        isNull,
      ),
    );

    await tester.tap(find.text('Photograph'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(selectedMethod, CertificationUploadMethod.camera);
    expect(find.text('Photograph'), findsNothing);

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<DecoratedBox>(
            find.descendant(
              of: find.byKey(const Key('certificationUploadPhotographOption')),
              matching: find.byType(DecoratedBox),
            ),
          )
          .decoration,
      isA<BoxDecoration>().having(
        (decoration) => decoration.color,
        'color',
        isNull,
      ),
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(selectedMethod, CertificationUploadMethod.camera);
    expect(find.text('Cancel'), findsNothing);
  });

  testWidgets('camera selection compresses and uploads picked image', (
    tester,
  ) async {
    final apiClient = _FakeApiClient();
    final imagePicker = _FakeImagePicker(cameraPath: '/tmp/camera-id.jpg');
    final compressor = _FakeImageCompressor(
      compressedPath: '/tmp/compressed-id.jpg',
    );
    Get.put<ApiClient>(apiClient);

    await _pumpUploadPage(
      tester,
      imagePicker: imagePicker,
      imageCompressor: compressor,
      arguments: {'geobotanists': 'product-1', 'cardType': 'PRC'},
    );

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Photograph'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(imagePicker.calls, ['camera']);
    expect(compressor.paths, ['/tmp/camera-id.jpg']);
    expect(apiClient.uploads, [
      _UploadRequest(
        commensurate: '11',
        gams: '2',
        filePath: '/tmp/compressed-id.jpg',
        fileField: 'attach',
        heirship: 'PRC',
      ),
    ]);
    expect(Get.currentRoute, AppRoutes.certificationIdentitySubmit);
    expect(Get.arguments, containsPair('geobotanists', 'product-1'));
    expect(Get.arguments, containsPair('cardType', 'PRC'));
    expect(
      Get.arguments,
      containsPair('recognizedInfo', {
        'unwits': 'NAVEEN TOM VARGHESE',
        'overmanaged': '623099344111',
        'asthmas': '23/11/1993',
        'bloomeries': 'https://example.test/id-front.png',
      }),
    );
    expect(
      (Get.arguments as Map)['scene3StartTimeSeconds'],
      isA<int>().having((value) => value, 'positive', greaterThan(0)),
    );
    expect(find.byKey(const Key('identitySubmitPage')), findsOneWidget);
    expect(toastPresenter.loadingMessages, [null]);
    expect(toastPresenter.dismissCount, 1);
  });

  testWidgets('photo album selection compresses and uploads picked image', (
    tester,
  ) async {
    final apiClient = _FakeApiClient();
    final imagePicker = _FakeImagePicker(galleryPath: '/tmp/gallery-id.jpg');
    final compressor = _FakeImageCompressor(
      compressedPath: '/tmp/compressed-gallery-id.jpg',
    );
    Get.put<ApiClient>(apiClient);

    await _pumpUploadPage(
      tester,
      imagePicker: imagePicker,
      imageCompressor: compressor,
      arguments: {'geobotanists': 'product-2', 'cardType': 'SSS'},
    );

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Photo album'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(imagePicker.calls, ['gallery']);
    expect(compressor.paths, ['/tmp/gallery-id.jpg']);
    expect(apiClient.uploads.single.gams, '1');
    expect(apiClient.uploads.single.heirship, 'SSS');
    expect(apiClient.uploads.single.filePath, '/tmp/compressed-gallery-id.jpg');
  });
}

Future<void> _pumpUploadPage(
  WidgetTester tester, {
  required CertificationUploadImagePicker imagePicker,
  required CertificationUploadImageCompressor imageCompressor,
  required Object arguments,
}) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    GetMaterialApp(
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const SizedBox()),
        GetPage(
          name: AppRoutes.certificationUpload,
          page: () => CertificationUploadPage(
            imagePicker: imagePicker,
            imageCompressor: imageCompressor,
          ),
        ),
        GetPage(
          name: AppRoutes.certificationIdentitySubmit,
          page: () => const SizedBox(key: Key('identitySubmitPage')),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
  Get.toNamed<void>(AppRoutes.certificationUpload, arguments: arguments);
  await tester.pumpAndSettle();
}

class _FakeImagePicker implements CertificationUploadImagePicker {
  _FakeImagePicker({this.cameraPath, this.galleryPath});

  final String? cameraPath;
  final String? galleryPath;
  final calls = <String>[];

  @override
  Future<String?> pickFromCamera() async {
    calls.add('camera');
    return cameraPath;
  }

  @override
  Future<String?> pickFromGallery() async {
    calls.add('gallery');
    return galleryPath;
  }
}

class _FakeImageCompressor implements CertificationUploadImageCompressor {
  _FakeImageCompressor({required this.compressedPath});

  final String compressedPath;
  final paths = <String>[];

  @override
  Future<String?> compressToLimit(String filePath) async {
    paths.add(filePath);
    return compressedPath;
  }
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(ApiConfig(), dio: Dio());

  final uploads = <_UploadRequest>[];

  @override
  Future<ApiResponse> uploadImage({
    required String commensurate,
    required String gams,
    required String filePath,
    required String fileField,
    String? heirship,
    String? scolloped,
    String? arrests,
    String? clevises,
    String? intemperances,
  }) async {
    uploads.add(
      _UploadRequest(
        commensurate: commensurate,
        gams: gams,
        filePath: filePath,
        fileField: fileField,
        heirship: heirship,
      ),
    );
    return ApiResponse(
      code: 0,
      message: 'Upload success',
      states: Json({
        'unwits': 'NAVEEN TOM VARGHESE',
        'overmanaged': '623099344111',
        'asthmas': '23/11/1993',
        'bloomeries': 'https://example.test/id-front.png',
      }),
    );
  }
}

class _UploadRequest {
  const _UploadRequest({
    required this.commensurate,
    required this.gams,
    required this.filePath,
    required this.fileField,
    required this.heirship,
  });

  final String commensurate;
  final String gams;
  final String filePath;
  final String fileField;
  final String? heirship;

  @override
  bool operator ==(Object other) {
    return other is _UploadRequest &&
        other.commensurate == commensurate &&
        other.gams == gams &&
        other.filePath == filePath &&
        other.fileField == fileField &&
        other.heirship == heirship;
  }

  @override
  int get hashCode =>
      Object.hash(commensurate, gams, filePath, fileField, heirship);
}

class _FakeToastPresenter implements ToastPresenter {
  final loadingMessages = <String?>[];
  final messages = <String>[];
  int dismissCount = 0;

  @override
  Future<void> show(String message, {required bool isError}) async {
    if (isError) {
      dismissCount += 1;
    }
    messages.add(message);
  }

  @override
  Future<void> showLoading(String? message) async {
    loadingMessages.add(message);
  }

  @override
  Future<void> dismissLoading() async {
    dismissCount += 1;
  }
}
