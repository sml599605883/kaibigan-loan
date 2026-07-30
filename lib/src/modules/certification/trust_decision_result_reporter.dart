import '../../core/client/client_bridge.dart';
import '../../core/report/report_manager.dart';
import '../../core/report/report_models.dart';

Future<void> reportTrustDecisionResult(
  TrustDecisionLivenessResult result,
) async {
  await ReportManager.instance.reportFaceResult(
    FaceReportPayload(
      livenessId: result.livenessId,
      requestId: result.sequenceId,
      resultCode: result.code.toString(),
      resultMessage: result.message,
    ),
  );
}
