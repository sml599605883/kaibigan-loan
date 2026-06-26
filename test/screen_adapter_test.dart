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
}
