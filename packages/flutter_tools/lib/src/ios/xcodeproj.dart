// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../artifacts.dart';
import '../base/file_system.dart';
import '../base/process.dart';
import '../build_info.dart';
import '../cache.dart';
import '../globals.dart';

final RegExp _settingExpr = new RegExp(r'(\w+)\s*=\s*(\S+)');
final RegExp _varExpr = new RegExp(r'\$\((.*)\)');

void updateXcodeGeneratedProperties(String projectPath, BuildMode mode, String target) {
  final StringBuffer localsBuffer = new StringBuffer();

  localsBuffer.writeln('// This is a generated file; do not edit or check into version control.');

  final String flutterRoot = fs.path.normalize(Cache.flutterRoot);
  localsBuffer.writeln('FLUTTER_ROOT=$flutterRoot');

  // This holds because requiresProjectRoot is true for this command
  localsBuffer.writeln('FLUTTER_APPLICATION_PATH=${fs.path.normalize(projectPath)}');

  // Relative to FLUTTER_APPLICATION_PATH, which is [Directory.current].
  localsBuffer.writeln('FLUTTER_TARGET=$target');

  // The runtime mode for the current build.
  localsBuffer.writeln('FLUTTER_BUILD_MODE=${getModeName(mode)}');

  // The build outputs directory, relative to FLUTTER_APPLICATION_PATH.
  localsBuffer.writeln('FLUTTER_BUILD_DIR=${getBuildDirectory()}');

  localsBuffer.writeln('SYMROOT=\${SOURCE_ROOT}/../${getIosBuildDirectory()}');

  final String flutterFrameworkDir = fs.path.normalize(fs.path.dirname(artifacts.getArtifactPath(Artifact.flutterFramework, TargetPlatform.ios, mode)));
  localsBuffer.writeln('FLUTTER_FRAMEWORK_DIR=$flutterFrameworkDir');

  if (artifacts is LocalEngineArtifacts) {
    final LocalEngineArtifacts localEngineArtifacts = artifacts;
    localsBuffer.writeln('LOCAL_ENGINE=${localEngineArtifacts.engineOutPath}');
  }

  final File localsFile = fs.file(fs.path.join(projectPath, 'ios', 'Flutter', 'Generated.xcconfig'));
  localsFile.createSync(recursive: true);
  localsFile.writeAsStringSync(localsBuffer.toString());
}

Map<String, String> getXcodeBuildSettings(String xcodeProjPath, String target) {
  final String absProjPath = fs.path.absolute(xcodeProjPath);
  final String out = runCheckedSync(<String>[
    '/usr/bin/xcodebuild', '-project', absProjPath, '-target', target, '-showBuildSettings'
  ]);
  final Map<String, String> settings = <String, String>{};
  for (String line in out.split('\n').where(_settingExpr.hasMatch)) {
    final Match match = _settingExpr.firstMatch(line);
    settings[match[1]] = match[2];
  }
  return settings;
}


/// Substitutes variables in [str] with their values from the specified Xcode
/// project and target.
String substituteXcodeVariables(String str, String xcodeProjPath, String target) {
  final Iterable<Match> matches = _varExpr.allMatches(str);
  if (matches.isEmpty)
    return str;

  final Map<String, String> settings = getXcodeBuildSettings(xcodeProjPath, target);
  return str.replaceAllMapped(_varExpr, (Match m) => settings[m[1]] ?? m[0]);
}
