library analyzerutils.program;


import "dart:io";

import 'package:analyzer/src/generated/element.dart';
import 'package:code_transformers/resolver.dart';

import 'transform.dart';


class ProgramInfo {
  final Resolver resolver;
  final LibraryElement entryLibrary;
  final BinTransformImpl transform;
  final File programRoot;

  ProgramInfo(this.resolver, this.entryLibrary, this.transform, this.programRoot);

  void release() {
    resolver.release();
  }
}

abstract class WorkResult {

}

abstract class ProgramWorker {

  WorkResult apply(ProgramInfo p);

}