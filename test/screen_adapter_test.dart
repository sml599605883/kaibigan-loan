import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_loan/src/utils/screen_adapter.dart';

void main() {
  testWidgets('keeps design values on 375 by 812 canvas', (tester) async {
    late ScreenAdapter adapter;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(375, 812)),
          child: Builder(
            builder: (context) {
              adapter = ScreenAdapter.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(adapter.w(20), 20);
    expect(adapter.h(24), 24);
    expect(adapter.r(8), 8);
    expect(adapter.sp(16), 16);
    expect(
      adapter.edgeInsetsFromLTRB(20, 24, 20, 132),
      const EdgeInsets.fromLTRB(20, 24, 20, 132),
    );
  });

  testWidgets('scales design values from 375 by 812 canvas', (tester) async {
    late ScreenAdapter adapter;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(750, 1624)),
          child: Builder(
            builder: (context) {
              adapter = ScreenAdapter.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(adapter.w(20), 40);
    expect(adapter.h(24), 48);
    expect(adapter.r(8), 16);
    expect(adapter.sp(16), 32);
    expect(adapter.size(35, 30), const Size(70, 60));
  });

  testWidgets('supports concise context and num extensions', (tester) async {
    late BuildContext capturedContext;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(750, 1624)),
          child: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(capturedContext.screen.w(20), 40);
    expect(20.wOf(capturedContext), 40);
    expect(24.hOf(capturedContext), 48);
    expect(8.rOf(capturedContext), 16);
    expect(16.spOf(capturedContext), 32);
    expect(
      20.insetsOnlyOf(capturedContext, top: 24, bottom: 132),
      const EdgeInsets.only(left: 40, top: 48, bottom: 264),
    );
  });

  testWidgets('supports initialized context-free num extensions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(750, 1624)),
          child: Builder(
            builder: (context) {
              ScreenAdapter.init(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(20.w, 40);
    expect(24.h, 48);
    expect(8.r, 16);
    expect(16.sp, 32);
    expect(
      20.insetsOnly(top: 24, bottom: 132),
      const EdgeInsets.only(left: 40, top: 48, bottom: 264),
    );
  });
}
