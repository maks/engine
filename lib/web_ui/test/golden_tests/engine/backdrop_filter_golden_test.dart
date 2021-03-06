// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:html' as html;

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/ui.dart';
import 'package:ui/src/engine.dart';

import 'package:web_engine_tester/golden_tester.dart';

final Rect region = Rect.fromLTWH(0, 0, 500, 500);

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() async {
  setUp(() async {
    debugShowClipLayers = true;
    SurfaceSceneBuilder.debugForgetFrameScene();
    for (html.Node scene in html.document.querySelectorAll('flt-scene')) {
      scene.remove();
    }

    await webOnlyInitializePlatform();
    webOnlyFontCollection.debugRegisterTestFonts();
    await webOnlyFontCollection.ensureFontsLoaded();
  });

  // The black circle on the left should not be blurred since it is outside
  // the clip boundary around backdrop filter. However there should be only
  // one red dot since the other one should be blurred by filter.
  test('Background should only blur at ancestor clip boundary', () async {
    final SurfaceSceneBuilder builder = SurfaceSceneBuilder();
    final Picture backgroundPicture = _drawBackground();
    builder.addPicture(Offset.zero, backgroundPicture);

    builder.pushClipRect(
      const Rect.fromLTRB(10, 10, 300, 300),
    );
    final Picture circles1 = _drawTestPictureWithCircles(30, 30);
    builder.addPicture(Offset.zero, circles1);

    builder.pushClipRect(
      const Rect.fromLTRB(60, 10, 300, 300),
    );
    builder.pushBackdropFilter(ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
      oldLayer: null);
    final Picture circles2 = _drawTestPictureWithCircles(90, 30);
    builder.addPicture(Offset.zero, circles2);
    builder.pop();
    builder.pop();
    builder.pop();

    html.document.body.append(builder
        .build()
        .webOnlyRootElement);

    await matchGoldenFile('backdrop_filter_clip.png', region: region);
  });

  test('Background should only blur at ancestor clip boundary after move', () async {
    final SurfaceSceneBuilder builder = SurfaceSceneBuilder();
    final Picture backgroundPicture = _drawBackground();
    builder.addPicture(Offset.zero, backgroundPicture);
    ClipRectEngineLayer clipEngineLayer = builder.pushClipRect(
      const Rect.fromLTRB(10, 10, 300, 300),
    );
    final Picture circles1 = _drawTestPictureWithCircles(30, 30);
    builder.addPicture(Offset.zero, circles1);
    ClipRectEngineLayer clipEngineLayer2 = builder.pushClipRect(
      const Rect.fromLTRB(60, 10, 300, 300),
    );
    BackdropFilterEngineLayer oldBackdropFilterLayer =
        builder.pushBackdropFilter(ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        oldLayer: null);
    final Picture circles2 = _drawTestPictureWithCircles(90, 30);
    builder.addPicture(Offset.zero, circles2);
    builder.pop();
    builder.pop();
    builder.pop();
    builder.build();

    // Now reparent filter layer in next scene.
    final SurfaceSceneBuilder builder2 = SurfaceSceneBuilder();
    builder2.addPicture(Offset.zero, backgroundPicture);
    builder2.pushClipRect(
      const Rect.fromLTRB(10, 10, 300, 300),
      oldLayer: clipEngineLayer
    );
    builder2.addPicture(Offset.zero, circles1);
    builder2.pushClipRect(
      const Rect.fromLTRB(10, 75, 300, 300),
      oldLayer: clipEngineLayer2
    );
    builder2.pushBackdropFilter(ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        oldLayer: oldBackdropFilterLayer);
    builder2.addPicture(Offset.zero, circles2);
    builder2.pop();
    builder2.pop();
    builder2.pop();

    html.document.body.append(builder2
        .build()
        .webOnlyRootElement);

    await matchGoldenFile('backdrop_filter_clip_moved.png', region: region);
  });
}

Picture _drawTestPictureWithCircles(double offsetX, double offsetY) {
  final EnginePictureRecorder recorder = PictureRecorder();
  final RecordingCanvas canvas =
  recorder.beginRecording(const Rect.fromLTRB(0, 0, 400, 400));
  canvas.drawCircle(
      Offset(offsetX + 10, offsetY + 10), 10, Paint()..style = PaintingStyle.fill);
  canvas.drawCircle(
      Offset(offsetX + 60, offsetY + 10),
      10,
      Paint()
        ..style = PaintingStyle.fill
        ..color = const Color.fromRGBO(255, 0, 0, 1));
  canvas.drawCircle(
      Offset(offsetX + 10, offsetY + 60),
      10,
      Paint()
        ..style = PaintingStyle.fill
        ..color = const Color.fromRGBO(0, 255, 0, 1));
  canvas.drawCircle(
      Offset(offsetX + 60, offsetY + 60),
      10,
      Paint()
        ..style = PaintingStyle.fill
        ..color = const Color.fromRGBO(0, 0, 255, 1));
  return recorder.endRecording();
}

Picture _drawBackground() {
  final EnginePictureRecorder recorder = PictureRecorder();
  final RecordingCanvas canvas =
  recorder.beginRecording(const Rect.fromLTRB(0, 0, 400, 400));
  canvas.drawRect(
      Rect.fromLTWH(8, 8, 400.0 - 16, 400.0 - 16),
      Paint()
        ..style = PaintingStyle.fill
        ..color = Color(0xFFE0FFE0)
      );
  return recorder.endRecording();
}
