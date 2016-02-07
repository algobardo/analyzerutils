library analyzerutils.transformers;

import "dart:collection";
import "dart:math";

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/utilities_collection.dart';
import 'package:async_await/src/xform.dart';

import '../analyzer.dart';

part 'deawaiter.dart';
part 'desugarer.dart';
part 'stripper.dart';


class IdentityTokenMap extends TokenMap {

  IdentityTokenMap();

  Token get(Token key) => key;

  void put(Token key, Token value) => throw new Exception("Unsupported");
}

abstract class ProgramVisitor extends Object with AstVisitor<AstNode> {

  void transforming(CompilationUnitElement cu, String originalPath);

  void transformationFinished();
}