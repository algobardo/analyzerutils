library analyzerutils.analyzer.utils;


import "dart:async";
import "dart:io";

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:barback/barback.dart';
import 'package:code_transformers/resolver.dart';

import 'options.dart';
import 'program.dart';
import 'transform.dart';




class ErrorCollector extends AnalysisErrorListener {
  final errors = <AnalysisError>[];

  onError(error) => errors.add(error);
}

class AnalyserUtils {

  static Future<ProgramInfo> resolve(SemanticCommandOptions options) {
    AssetId primaryInputId = new AssetId(options.package, options.entryFile.first);
    Asset primaryInput = new Asset.fromFile(
        primaryInputId, new File("${options.projectDirectory}/${primaryInputId.path}"));
    BinTransformImpl transform = new BinTransformImpl(options, primaryInput);

    AnalysisOptionsImpl resolverOptions = new AnalysisOptionsImpl()
      ..cacheSize = 512 // # of sources to cache ASTs for.
      ..preserveComments = true
      ..analyzeFunctionBodies = true;

    Resolvers resolvers = new Resolvers(dartSdkDirectory, options: resolverOptions);
    return resolvers.get(transform, options.entryFile.map((String s) => new AssetId(options.package, s)).toList()).then((Resolver r) => new ProgramInfo(r, r.getLibrary(primaryInputId), transform, new File(options.projectDirectory)));
  }


  static FunctionDeclaration parseFunctionDeclaration(String source) {
    ErrorCollector errorCollector = new ErrorCollector();

    CharSequenceReader reader = new CharSequenceReader(source);
    Scanner scanner = new Scanner(null, reader, errorCollector);
    Token token = scanner.tokenize();
    Parser parser = new Parser(null, errorCollector);

    if (errorCollector.errors.isNotEmpty) {
      throw errorCollector.errors.first;
    }

    return parser.parseCompilationUnit(token).declarations.first;
  }

  static CompilationUnit parse(String source) {
    ErrorCollector errorCollector = new ErrorCollector();

    CharSequenceReader reader = new CharSequenceReader(source);
    Scanner scanner = new Scanner(null, reader, errorCollector);
    Token token = scanner.tokenize();
    Parser parser = new Parser(null, errorCollector);

    if (errorCollector.errors.isNotEmpty) {
      throw errorCollector.errors.first;
    }

    return parser.parseCompilationUnit(token);
  }
}