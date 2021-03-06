// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void main() {
  testWidgets('Scaffold control test', (WidgetTester tester) async {
    final Key bodyKey = new UniqueKey();
    await tester.pumpWidget(new Scaffold(
      appBar: new AppBar(title: new Text('Title')),
      body: new Container(key: bodyKey)
    ));

    RenderBox bodyBox = tester.renderObject(find.byKey(bodyKey));
    expect(bodyBox.size, equals(const Size(800.0, 544.0)));

    await tester.pumpWidget(new MediaQuery(
      data: const MediaQueryData(padding: const EdgeInsets.only(bottom: 100.0)),
      child: new Scaffold(
        appBar: new AppBar(title: new Text('Title')),
        body: new Container(key: bodyKey)
      )
    ));

    bodyBox = tester.renderObject(find.byKey(bodyKey));
    expect(bodyBox.size, equals(const Size(800.0, 444.0)));

    await tester.pumpWidget(new MediaQuery(
      data: const MediaQueryData(padding: const EdgeInsets.only(bottom: 100.0)),
      child: new Scaffold(
        appBar: new AppBar(title: new Text('Title')),
        body: new Container(key: bodyKey),
        resizeToAvoidBottomPadding: false
      )
    ));

    bodyBox = tester.renderObject(find.byKey(bodyKey));
    expect(bodyBox.size, equals(const Size(800.0, 544.0)));
  });

  testWidgets('Scaffold large bottom padding test', (WidgetTester tester) async {
    final Key bodyKey = new UniqueKey();
    await tester.pumpWidget(new MediaQuery(
      data: new MediaQueryData(
        padding: const EdgeInsets.only(bottom: 700.0),
      ),
      child: new Scaffold(
        body: new Container(key: bodyKey),
      ),
    ));

    final RenderBox bodyBox = tester.renderObject(find.byKey(bodyKey));
    expect(bodyBox.size, equals(const Size(800.0, 0.0)));

    await tester.pumpWidget(new MediaQuery(
      data: new MediaQueryData(
        padding: const EdgeInsets.only(bottom: 500.0),
      ),
      child: new Scaffold(
        body: new Container(key: bodyKey),
      ),
    ));

    expect(bodyBox.size, equals(const Size(800.0, 100.0)));

    await tester.pumpWidget(new MediaQuery(
      data: new MediaQueryData(
        padding: const EdgeInsets.only(bottom: 580.0),
      ),
      child: new Scaffold(
        appBar: new AppBar(
          title: new Text('Title'),
        ),
        body: new Container(key: bodyKey),
      ),
    ));

    expect(bodyBox.size, equals(const Size(800.0, 0.0)));
  });

  testWidgets('Floating action animation', (WidgetTester tester) async {
    await tester.pumpWidget(new Scaffold(
      floatingActionButton: new FloatingActionButton(
        key: const Key('one'),
        onPressed: null,
        child: new Text("1")
      )
    ));

    expect(tester.binding.transientCallbackCount, 0);

    await tester.pumpWidget(new Scaffold(
      floatingActionButton: new FloatingActionButton(
        key: const Key('two'),
        onPressed: null,
        child: new Text("2")
      )
    ));

    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await tester.pumpWidget(new Container());
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pumpWidget(new Scaffold());
    expect(tester.binding.transientCallbackCount, 0);

    await tester.pumpWidget(new Scaffold(
      floatingActionButton: new FloatingActionButton(
        key: const Key('one'),
        onPressed: null,
        child: new Text("1")
      )
    ));

    expect(tester.binding.transientCallbackCount, greaterThan(0));
  });

  testWidgets('Drawer scrolling', (WidgetTester tester) async {
    final Key drawerKey = new UniqueKey();
    const double appBarHeight = 256.0;

    final ScrollController scrollOffset = new ScrollController();

    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          drawer: new Drawer(
            key: drawerKey,
            child: new ListView(
              controller: scrollOffset,
              children: new List<Widget>.generate(10,
                (int index) => new SizedBox(height: 100.0, child: new Text('D$index'))
              )
            )
          ),
          body: new CustomScrollView(
            slivers: <Widget>[
              new SliverAppBar(
                pinned: true,
                expandedHeight: appBarHeight,
                title: new Text('Title'),
                flexibleSpace: new FlexibleSpaceBar(title: new Text('Title')),
              ),
              new SliverPadding(
                padding: const EdgeInsets.only(top: appBarHeight),
                child: new SliverList(
                  delegate: new SliverChildListDelegate(new List<Widget>.generate(
                    10, (int index) => new SizedBox(height: 100.0, child: new Text('B$index')),
                  )),
                ),
              ),
            ],
          ),
        )
      )
    );

    final ScaffoldState state = tester.firstState(find.byType(Scaffold));
    state.openDrawer();

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(scrollOffset.offset, 0.0);

    const double scrollDelta = 80.0;
    await tester.scroll(find.byKey(drawerKey), const Offset(0.0, -scrollDelta));
    await tester.pump();

    expect(scrollOffset.offset, scrollDelta);

    final RenderBox renderBox = tester.renderObject(find.byType(AppBar));
    expect(renderBox.size.height, equals(appBarHeight));
  });

  Widget _buildStatusBarTestApp(TargetPlatform platform) {
    return new MaterialApp(
      theme: new ThemeData(platform: platform),
      home: new MediaQuery(
        data: const MediaQueryData(padding: const EdgeInsets.only(top: 25.0)), // status bar
        child: new Scaffold(
          body: new CustomScrollView(
            primary: true,
            slivers: <Widget>[
              new SliverAppBar(
                title: new Text('Title')
              ),
              new SliverList(
                delegate: new SliverChildListDelegate(new List<Widget>.generate(
                  20, (int index) => new SizedBox(height: 100.0, child: new Text('$index')),
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('Tapping the status bar scrolls to top on iOS', (WidgetTester tester) async {
    await tester.pumpWidget(_buildStatusBarTestApp(TargetPlatform.iOS));
    final ScrollableState scrollable = tester.state(find.byType(Scrollable));
    scrollable.position.jumpTo(500.0);
    expect(scrollable.position.pixels, equals(500.0));
    await tester.tapAt(const Point(100.0, 10.0));
    await tester.pump();
    await tester.pumpUntilNoTransientCallbacks();
    expect(scrollable.position.pixels, equals(0.0));
  });

  testWidgets('Tapping the status bar does not scroll to top on Android', (WidgetTester tester) async {
    await tester.pumpWidget(_buildStatusBarTestApp(TargetPlatform.android));
    final ScrollableState scrollable = tester.state(find.byType(Scrollable));
    scrollable.position.jumpTo(500.0);
    expect(scrollable.position.pixels, equals(500.0));
    await tester.tapAt(const Point(100.0, 10.0));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(scrollable.position.pixels, equals(500.0));
  });

  testWidgets('Bottom sheet cannot overlap app bar', (WidgetTester tester) async {
    final Key sheetKey = new UniqueKey();

    await tester.pumpWidget(
      new MaterialApp(
        theme: new ThemeData(platform: TargetPlatform.android),
        home: new Scaffold(
          appBar: new AppBar(
            title: new Text('Title'),
          ),
          body: new Builder(
            builder: (BuildContext context) {
              return new GestureDetector(
                onTap: () {
                  Scaffold.of(context).showBottomSheet<Null>((BuildContext context) {
                    return new Container(
                      key: sheetKey,
                      color: Colors.blue[500],
                    );
                  });
                },
                child: new Text('X'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('X'));
    await tester.pump(); // start animation
    await tester.pump(const Duration(seconds: 1));

    final RenderBox appBarBox = tester.renderObject(find.byType(AppBar));
    final RenderBox sheetBox = tester.renderObject(find.byKey(sheetKey));

    final Point appBarBottomRight = appBarBox.localToGlobal(appBarBox.size.bottomRight(Point.origin));
    final Point sheetTopRight = sheetBox.localToGlobal(sheetBox.size.topRight(Point.origin));

    expect(appBarBottomRight, equals(sheetTopRight));
  });

  testWidgets('Persistent bottom buttons are persistent', (WidgetTester tester) async {
    bool didPressButton = false;
    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          body: new SingleChildScrollView(
            child: new Container(
              decoration: new BoxDecoration(
                backgroundColor: Colors.amber[500],
              ),
              height: 5000.0,
              child: new Text('body'),
            ),
          ),
          persistentFooterButtons: <Widget>[
            new FlatButton(
              onPressed: () {
                didPressButton = true;
              },
              child: new Text('X'),
            )
          ],
        ),
      ),
    );

    await tester.scroll(find.text('body'), const Offset(0.0, -1000.0));
    expect(didPressButton, isFalse);
    await tester.tap(find.text('X'));
    expect(didPressButton, isTrue);
  });

  group('back arrow', () {
    Future<Null> expectBackIcon(WidgetTester tester, TargetPlatform platform, IconData expectedIcon) async {
      final GlobalKey rootKey = new GlobalKey();
      final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
        '/': (_) => new Container(key: rootKey, child: new Text('Home')),
        '/scaffold': (_) => new Scaffold(
            appBar: new AppBar(),
            body: new Text('Scaffold'),
        )
      };
      await tester.pumpWidget(
        new MaterialApp(theme: new ThemeData(platform: platform), routes: routes)
      );

      Navigator.pushNamed(rootKey.currentContext, '/scaffold');
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final Icon icon = tester.widget(find.byType(Icon));
      expect(icon.icon, expectedIcon);
    }

    testWidgets('Back arrow uses correct default on Android', (WidgetTester tester) async {
      await expectBackIcon(tester, TargetPlatform.android, Icons.arrow_back);
    });

    testWidgets('Back arrow uses correct default on Fuchsia', (WidgetTester tester) async {
      await expectBackIcon(tester, TargetPlatform.fuchsia, Icons.arrow_back);
    });

    testWidgets('Back arrow uses correct default on iOS', (WidgetTester tester) async {
      await expectBackIcon(tester, TargetPlatform.iOS, Icons.arrow_back_ios);
    });
  });

  group('body size', () {
    testWidgets('body size with container', (WidgetTester tester) async {
      final Key testKey = new UniqueKey();
      await tester.pumpWidget(
        new Scaffold(body: new Container(key: testKey))
      );
      expect(tester.element(find.byKey(testKey)).size, const Size(800.0, 600.0));
      expect(tester.renderObject<RenderBox>(find.byKey(testKey)).localToGlobal(Point.origin), const Point(0.0, 0.0));
    });

    testWidgets('body size with sized container', (WidgetTester tester) async {
      final Key testKey = new UniqueKey();
      await tester.pumpWidget(
        new Scaffold(body: new Container(key: testKey, height: 100.0))
      );
      expect(tester.element(find.byKey(testKey)).size, const Size(800.0, 100.0));
      expect(tester.renderObject<RenderBox>(find.byKey(testKey)).localToGlobal(Point.origin), const Point(0.0, 0.0));
    });

    testWidgets('body size with centered container', (WidgetTester tester) async {
      final Key testKey = new UniqueKey();
      await tester.pumpWidget(
        new Scaffold(body: new Center(child: new Container(key: testKey)))
      );
      expect(tester.element(find.byKey(testKey)).size, const Size(800.0, 600.0));
      expect(tester.renderObject<RenderBox>(find.byKey(testKey)).localToGlobal(Point.origin), const Point(0.0, 0.0));
    });

    testWidgets('body size with button', (WidgetTester tester) async {
      final Key testKey = new UniqueKey();
      await tester.pumpWidget(
        new Scaffold(body: new FlatButton(key: testKey, onPressed: () { }, child: new Text('')))
      );
      expect(tester.element(find.byKey(testKey)).size, const Size(88.0, 36.0));
      expect(tester.renderObject<RenderBox>(find.byKey(testKey)).localToGlobal(Point.origin), const Point(0.0, 0.0));
    });
  });
}
