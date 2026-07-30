import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kaibigan_loan/src/app_routes.dart';
import 'package:kaibigan_loan/src/assets/app_assets.dart';
import 'package:kaibigan_loan/src/core/client/client_bridge.dart';
import 'package:kaibigan_loan/src/core/json/json.dart';
import 'package:kaibigan_loan/src/core/network/api_client.dart';
import 'package:kaibigan_loan/src/core/network/api_config.dart';
import 'package:kaibigan_loan/src/core/network/api_exception.dart';
import 'package:kaibigan_loan/src/core/network/api_response.dart';
import 'package:kaibigan_loan/src/core/report/report_cache.dart';
import 'package:kaibigan_loan/src/core/report/report_manager.dart';
import 'package:kaibigan_loan/src/core/report/report_models.dart';
import 'package:kaibigan_loan/src/core/report/report_native_bridge.dart';
import 'package:kaibigan_loan/src/core/report/report_network.dart';
import 'package:kaibigan_loan/src/core/session/product_detail_cache.dart';
import 'package:kaibigan_loan/src/core/session/session_store.dart';
import 'package:kaibigan_loan/src/modules/certification/certification_face_page.dart';
import 'package:kaibigan_loan/src/modules/certification/widgets/certification_prompt_banner.dart';
import 'package:kaibigan_loan/src/utils/app_toast.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  late SessionStore sessionStore;
  late _FakeApiClient apiClient;
  late _FakeToastPresenter toastPresenter;
  late _RecordingReportManager reportManager;

  setUp(() {
    Get.testMode = true;
    sessionStore = SessionStore.memory();
    apiClient = _FakeApiClient();
    toastPresenter = _FakeToastPresenter();
    reportManager = _RecordingReportManager();
    Get.put<SessionStore>(sessionStore);
    Get.put<ApiClient>(apiClient);
    Get.put<ReportManager>(reportManager);
    AppToast.presenter = toastPresenter;
  });

  tearDown(() {
    AppToast.presenter = const EasyLoadingToastPresenter();
    Get.reset();
  });

  testWidgets('renders face verification design and cached prompt', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await sessionStore.saveProductDetailCache(
      ProductDetailCache.fromJson({
        'metallurgists': {
          'periodontal': 'Keep your face centered for live verification.',
        },
      }),
    );

    await tester.pumpWidget(
      const GetMaterialApp(home: CertificationFacePage()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Identity verification'), findsOneWidget);
    expect(find.byType(CertificationPromptBanner), findsOneWidget);
    expect(
      find.text('Keep your face centered for live verification.'),
      findsOneWidget,
    );
    expect(
      find.image(const AssetImage(AppAssets.certificationFaceGuide)),
      findsOneWidget,
    );
    expect(find.text('Submit'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('submit runs TrustDecision liveness and uploads face image', (
    tester,
  ) async {
    final livenessCalls = <String>[];
    apiClient.faceTokenStates = {
      'dwarfishly': '200',
      'thatches': 'td-license',
      'clevises': '7',
    };
    await _pumpFacePage(tester, arguments: {'geobotanists': 'product-face-1'});

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(apiClient.tokenRequests, [
      _FaceTokenRequest(dodgy: 'ORDER001', commensurate: '0'),
    ]);
    expect(livenessCalls, isEmpty);
    expect(toastPresenter.loadingMessages, [null]);
    expect(toastPresenter.dismissCount, 1);
  });

  testWidgets('submit runs injected TrustDecision liveness and uploads face', (
    tester,
  ) async {
    final livenessCalls = <String>[];
    apiClient.faceTokenStates = {
      'dwarfishly': '200',
      'thatches': 'td-license',
      'clevises': '7',
    };
    apiClient.productDetailStates = {
      'grinner': {'unconfusing': 'Penalization'},
      'sensitized': {'cabdrivers': 'ORDER001'},
    };
    await _pumpFacePage(
      tester,
      arguments: {'geobotanists': 'route-face-product'},
      cachedProductId: 'cached-face-product',
      cachedOrderNo: 'ORDER001',
      showTrustDecisionLiveness: (license) async {
        livenessCalls.add(license);
        return const TrustDecisionLivenessResult(
          success: true,
          code: 0,
          message: 'ok',
          image: 'ZmFjZQ==',
          sequenceId: 'seq-1',
          livenessId: 'live-1',
          raw: <String, dynamic>{},
        );
      },
      faceImageFilePathBuilder: (imageBase64) async {
        expect(imageBase64, 'ZmFjZQ==');
        return '/tmp/face.jpg';
      },
    );

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(livenessCalls, ['td-license']);
    expect(apiClient.tokenRequests, [
      _FaceTokenRequest(dodgy: 'ORDER001', commensurate: '0'),
    ]);
    expect(apiClient.uploads, [
      _UploadRequest(
        commensurate: '10',
        gams: '1',
        filePath: '/tmp/face.jpg',
        fileField: 'attach',
        heirship: null,
        scolloped: 'live-1',
        arrests: 'td-license',
        clevises: '7',
        intemperances: null,
      ),
    ]);
    expect(toastPresenter.loadingMessages, [null, null, null]);
    expect(toastPresenter.dismissCount, 3);
    expect(toastPresenter.messages, isEmpty);
    expect(apiClient.productDetailIds, ['cached-face-product']);
    expect(reportManager.faceReports, hasLength(1));
    expect(reportManager.faceReports.single.livenessId, 'live-1');
    expect(reportManager.faceReports.single.requestId, 'seq-1');
    expect(reportManager.faceReports.single.resultCode, '0');
    expect(reportManager.faceReports.single.resultMessage, 'ok');
  });

  testWidgets('shows liveness error and skips upload when native fails', (
    tester,
  ) async {
    apiClient.faceTokenStates = {
      'dwarfishly': '200',
      'thatches': 'td-license',
      'clevises': '7',
    };
    await _pumpFacePage(
      tester,
      arguments: {'geobotanists': 'ORDER002'},
      showTrustDecisionLiveness: (_) async => const TrustDecisionLivenessResult(
        success: false,
        code: -1,
        message: 'liveness failed',
        image: '',
        sequenceId: '',
        livenessId: '',
        raw: <String, dynamic>{},
      ),
    );

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(apiClient.uploads, isEmpty);
    expect(toastPresenter.errors, ['liveness failed']);
    expect(reportManager.faceReports, hasLength(1));
    expect(reportManager.faceReports.single.livenessId, '');
    expect(reportManager.faceReports.single.requestId, '');
    expect(reportManager.faceReports.single.resultCode, '-1');
    expect(reportManager.faceReports.single.resultMessage, 'liveness failed');
  });

  testWidgets('shows API error when face token request fails', (tester) async {
    apiClient.error = ApiBusinessException('face failed');

    await _pumpFacePage(tester, arguments: {'geobotanists': 'product-face-2'});

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(toastPresenter.dismissCount, 1);
    expect(toastPresenter.errors, ['face failed']);
  });

  testWidgets('camera denial opens settings without requesting face token', (
    tester,
  ) async {
    var openedSettings = false;
    await _pumpFacePage(
      tester,
      arguments: {'geobotanists': 'product-face-denied'},
      requestCameraPermission: () async => PermissionStatus.denied,
      openAppSettingsPage: () async {
        openedSettings = true;
        return true;
      },
    );

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(apiClient.tokenRequests, isEmpty);
    expect(find.byType(CupertinoAlertDialog), findsOneWidget);
    expect(find.text('Enable Your Camera'), findsOneWidget);
    expect(
      find.text(
        'ID document scanning and selfie require camera access. Please enable it in your device Settings to continue.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Enable Camera'));
    await tester.pumpAndSettle();

    expect(openedSettings, isTrue);
  });
}

Future<void> _pumpFacePage(
  WidgetTester tester, {
  required Object arguments,
  String? cachedProductId,
  String? cachedOrderNo,
  CameraPermissionRequester? requestCameraPermission,
  AppSettingsOpener? openAppSettingsPage,
  TrustDecisionLivenessLauncher? showTrustDecisionLiveness,
  FaceImageFilePathBuilder? faceImageFilePathBuilder,
}) async {
  final argumentProductId = arguments is Map
      ? arguments['geobotanists']?.toString().trim() ?? ''
      : '';
  final productId = cachedProductId ?? argumentProductId;
  if (productId.isNotEmpty) {
    await SessionStore.instance.saveProductDetailCache(
      ProductDetailCache(
        amount: '',
        productid: productId,
        orderNo: cachedOrderNo ?? 'ORDER001',
        orderId: '',
        term: '',
        termType: '',
        note: const <String, dynamic>{},
        nextStep: const <String, dynamic>{},
      ),
    );
  }
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
          name: AppRoutes.certificationFace,
          page: () => CertificationFacePage(
            requestCameraPermission:
                requestCameraPermission ?? () async => PermissionStatus.granted,
            openAppSettingsPage: openAppSettingsPage,
            showTrustDecisionLiveness: showTrustDecisionLiveness,
            faceImageFilePathBuilder: faceImageFilePathBuilder,
          ),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
  Get.toNamed<void>(AppRoutes.certificationFace, arguments: arguments);
  await tester.pumpAndSettle();
}

class _RecordingReportManager extends ReportManager {
  _RecordingReportManager()
    : super(
        cache: _FakeReportCache(),
        nativeBridge: _FakeReportNativeBridge(),
        network: _FakeReportNetwork(),
      );

  final faceReports = <FaceReportPayload>[];

  @override
  Future<void> reportFaceResult(FaceReportPayload payload) async {
    faceReports.add(payload);
  }
}

class _FakeReportCache implements ReportCache {
  @override
  Future<void> clearSessionReportState() async {}
  @override
  Future<String> getAttributionLastStatus() async => '';
  @override
  Future<String> getLastMarketSignature() async => '';
  @override
  Future<String> getLastPushToken() async => '';
  @override
  Future<int> getLoginAt() async => 0;
  @override
  Future<ReportLocation?> getLocation() async => null;
  @override
  Future<bool> isAttributionInitialized() async => false;
  @override
  Future<bool> isLoggedIn() async => false;
  @override
  Future<bool> markAppOpened() async => false;
  @override
  Future<void> saveLocation(ReportLocation location) async {}
  @override
  Future<void> setAttributionInitialized(bool value) async {}
  @override
  Future<void> setAttributionLastStatus(String value) async {}
  @override
  Future<void> setLastMarketSignature(String signature) async {}
  @override
  Future<void> setLastPushToken(String token) async {}
  @override
  Future<void> setLoginAt(int millis) async {}
}

class _FakeReportNativeBridge implements ReportNativeBridge {
  @override
  Future<NativeDeviceSnapshot> getDeviceSnapshot() async =>
      const NativeDeviceSnapshot();
  @override
  Future<ReportLocation?> getLocation() async => null;
  @override
  Future<String> getPushToken() async => '';
  @override
  Future<String> getTrackingStatus() async => '';
  @override
  Future<void> initializeAttribution(String token) async {}
  @override
  Stream<Json> nativeEvents() => const Stream<Json>.empty();
  @override
  Future<String> requestNotificationPermission() async => '';
  @override
  Future<String> requestTrackingPermission() async => '';
}

class _FakeReportNetwork implements ReportNetwork {
  @override
  Future<void> reportContacts(String encryptedPayload) async {}
  @override
  Future<void> reportDeviceInfo(String encryptedPayload) async {}
  @override
  Future<void> reportFaceResult(FaceReportPayload payload) async {}
  @override
  Future<Json> reportGoogleMarket({
    required String idfv,
    required String idfa,
  }) async => Json(null);
  @override
  Future<void> reportLocation(ReportLocation location) async {}
  @override
  Future<void> reportPushToken(String token) async {}
  @override
  Future<void> reportRiskBehavior(Map<String, dynamic> payload) async {}
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(ApiConfig(), dio: Dio());

  final tokenRequests = <_FaceTokenRequest>[];
  final uploads = <_UploadRequest>[];
  final productDetailIds = <String>[];
  Object? error;
  Map<String, dynamic> faceTokenStates = const {};
  Map<String, dynamic>? productDetailStates;

  @override
  Future<ApiResponse> getFaceToken({
    required String dodgy,
    required String commensurate,
  }) async {
    tokenRequests.add(
      _FaceTokenRequest(dodgy: dodgy, commensurate: commensurate),
    );
    final requestError = error;
    if (requestError != null) {
      throw requestError;
    }
    return ApiResponse(
      code: 0,
      message: 'face token ready',
      states: Json(faceTokenStates),
    );
  }

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
        scolloped: scolloped,
        arrests: arrests,
        clevises: clevises,
        intemperances: intemperances,
      ),
    );
    return ApiResponse(code: 0, message: 'Upload success', states: Json(null));
  }

  @override
  Future<ApiResponse> productDetail({required String geobotanists}) async {
    productDetailIds.add(geobotanists);
    return ApiResponse(
      code: 0,
      message: 'success',
      states: Json(productDetailStates ?? <String, dynamic>{}),
    );
  }
}

class _FaceTokenRequest {
  const _FaceTokenRequest({required this.dodgy, required this.commensurate});

  final String dodgy;
  final String commensurate;

  @override
  bool operator ==(Object other) {
    return other is _FaceTokenRequest &&
        other.dodgy == dodgy &&
        other.commensurate == commensurate;
  }

  @override
  int get hashCode => Object.hash(dodgy, commensurate);
}

class _UploadRequest {
  const _UploadRequest({
    required this.commensurate,
    required this.gams,
    required this.filePath,
    required this.fileField,
    required this.heirship,
    required this.scolloped,
    required this.arrests,
    required this.clevises,
    required this.intemperances,
  });

  final String commensurate;
  final String gams;
  final String filePath;
  final String fileField;
  final String? heirship;
  final String? scolloped;
  final String? arrests;
  final String? clevises;
  final String? intemperances;

  @override
  bool operator ==(Object other) {
    return other is _UploadRequest &&
        other.commensurate == commensurate &&
        other.gams == gams &&
        other.filePath == filePath &&
        other.fileField == fileField &&
        other.heirship == heirship &&
        other.scolloped == scolloped &&
        other.arrests == arrests &&
        other.clevises == clevises &&
        other.intemperances == intemperances;
  }

  @override
  int get hashCode => Object.hash(
    commensurate,
    gams,
    filePath,
    fileField,
    heirship,
    scolloped,
    arrests,
    clevises,
    intemperances,
  );
}

class _FakeToastPresenter implements ToastPresenter {
  final loadingMessages = <String?>[];
  final messages = <String>[];
  final errors = <String>[];
  int dismissCount = 0;

  @override
  Future<void> show(String message, {required bool isError}) async {
    if (isError) {
      dismissCount++;
      errors.add(message);
    } else {
      messages.add(message);
    }
  }

  @override
  Future<void> showLoading(String? message) async {
    loadingMessages.add(message);
  }

  @override
  Future<void> dismissLoading() async {
    dismissCount++;
  }
}
