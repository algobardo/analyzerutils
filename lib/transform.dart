library transform;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:barback/barback.dart';
import 'package:source_span/source_span.dart';

import 'options.dart';

class BinTransformImpl implements Transform {
  final SemanticCommandOptions options;

  @override
  final Asset primaryInput;

  @override
  TransformLogger get logger =>
      new TransformLogger((AssetId asset, LogLevel level, String message, SourceSpan span) => print(message));

  BinTransformImpl(this.options, this.primaryInput);

  File getFile(AssetId id) {
    File f;
    if (id.package == options.package)
      f = new File("${options.projectDirectory}/${id.path}");
    else
      f = new File("${options.projectDirectory}/packages/${id.package}/${id.path.substring(4)}");
    // substring to remove "lib/"
    if (!f.existsSync()) throw new Exception("Failed to retrieve $id in $f -- package:${id.package} path:${id.path} during the analysis");
    return f;
  }

  @override
  Future<Asset> getInput(AssetId id) => throw new Exception("Unsupported");

  @override
  Future<String> readInputAsString(AssetId id, { Encoding encoding: UTF8 }) =>
      getFile(id).readAsString(encoding: encoding);

  @override
  Stream<List<int>> readInput(AssetId id) => throw new Exception("Unsupported");

  @override
  Future<bool> hasInput(AssetId id) => throw new Exception("Unsupported");

  @override
  void addOutput(Asset output) => throw new Exception("Unsupported");

  @override
  void consumePrimary() => throw new Exception("Unsupported");
}
