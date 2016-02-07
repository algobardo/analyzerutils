library dart_annotation_levels.options;

import 'dart:io';

import 'package:args/args.dart';
import 'package:args/src/usage_exception.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

class GlobalOptions {
  static String outDirectory = "./out";
}

class SemanticCommandOptions {

  String projectDirectory;
  String _package;
  String get pubspec => path.join(projectDirectory, "pubspec.yaml");

  List<String> entryFile;
  bool inline;

  String get package {
    if (_package == null)
      _package = loadYaml(
          new File(pubspec).readAsStringSync())["name"];

    if (_package != path.basename(projectDirectory)) throw new Exception(
        "Package directory (${path.basename(projectDirectory)}) has not the same name as package (${_package})");
    return _package;
  }

  SemanticCommandOptions.args(this.projectDirectory, this.entryFile, this.inline);

  static void createOptions(ArgParser a) {
    a.addOption('dir', help: "Project directory");
    a.addOption('entry', help: "Project entry point", allowMultiple: true);
    a.addFlag('inline', help: "Inline packages", defaultsTo: true);
  }


  factory SemanticCommandOptions.parse(ArgResults opts) {
    if(opts["dir"] == null || opts["entry"] == null)
      throw new UsageException("Options 'dir' and 'entry' are mandatory", "--dir <directory> --entry <entry>");
    return new SemanticCommandOptions.args(
        opts["dir"],
        opts["entry"],
        opts["inline"]
    );
  }

}

class DesugarCommandOptions extends SemanticCommandOptions {

  String destination;
  bool ignoreCache;
  bool push = true; //TODO: See if this can be enabled by default considering the casa machines

  DesugarCommandOptions.args(projectDirectory, entryFile, inline, this.destination, this.ignoreCache) : super.args(projectDirectory, entryFile, inline);

  static void createOptions(ArgParser a) {
    SemanticCommandOptions.createOptions(a);
    a.addOption('dest', help: "Destination Folder");
    a.addFlag('ignore-cache', help: "Ignore github cache branch", defaultsTo: true);
  }


  factory DesugarCommandOptions.parse(ArgResults opts) {
    SemanticCommandOptions sup = new SemanticCommandOptions.parse(opts);
    return new DesugarCommandOptions.args(
        sup.projectDirectory,
        sup.entryFile,
        sup.inline,
        opts["dest"],
        opts["ignore-cache"]
    );
  }

}


class SyntacticCommandOptions {

  String projectDirectory;

  SyntacticCommandOptions.args({this.projectDirectory});

  static void createOptions(ArgParser a) {
    a.addOption('dir', help: "Project directory");
  }


  factory SyntacticCommandOptions.parse(ArgResults opts) {
    return new SyntacticCommandOptions.args(
        projectDirectory: opts["dir"]
    );
  }

}
