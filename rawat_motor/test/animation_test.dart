import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rawatin/core/widgets/rawatin_intro_page.dart';
import 'package:rawatin/core/widgets/rawatin_page_transition.dart';

void main() {
  testWidgets('intro menampilkan slogan Rawatin di dua baris lalu selesai', (
    tester,
  ) async {
    var finished = false;
    await tester.pumpWidget(
      MaterialApp(home: RawatinIntroPage(onFinished: () => finished = true)),
    );

    expect(find.text('Kamu yang gas,\nRawatin yang ingat.'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('RAWATIN'), findsNothing);
    await tester.pump(const Duration(milliseconds: 1900));
    expect(find.text('R'), findsOneWidget);
    expect(finished, isFalse);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(finished, isFalse);
    await tester.pump(const Duration(milliseconds: 400));
    expect(finished, isFalse);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();
    expect(finished, isTrue);
  });

  testWidgets('transisi halaman menampilkan konten tujuan', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: RawatinPageTransition(child: Text('Beranda'))),
    );

    expect(find.text('Beranda'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Beranda'), findsOneWidget);
  });
}
