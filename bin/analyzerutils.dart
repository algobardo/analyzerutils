library analyzerutil;

import 'package:analyzerutils/commands/cloner-stats.dart';
import 'package:analyzerutils/commands/desugar.dart';
import 'package:args/command_runner.dart';

void main(List<String> args) {
  new CommandRunner("analyzerutils", "Dynamic analysis framework for Dart")
    ..addCommand(new SyntacticWorker())
    ..addCommand(new SemanticWorker())
    ..addCommand(new DesugarWorker())
    ..run(args);
}

