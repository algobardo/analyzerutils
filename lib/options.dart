library dart_annotation_levels.options;

import 'dart:convert';
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
  bool allowNonPackageFolderName;

  String get package {
    if (_package == null)
      _package = loadYaml(
          new File(pubspec).readAsStringSync())["name"];

    if (!allowNonPackageFolderName && _package != path.basename(projectDirectory)) throw new Exception(
        "Package directory (${path.basename(projectDirectory)}) has not the same name as package (${_package})");
    return _package;
  }

  SemanticCommandOptions.args(this.projectDirectory, this.entryFile, this.inline, [this.allowNonPackageFolderName = false]) {
    if(projectDirectory == null || entryFile == null)
      throw new UsageException("Options 'dir' and 'entry' are mandatory", "--dir <directory> --entry <entry>");
  }

  static void createOptions(ArgParser a) {
    a.addOption('benchmark', help: "Benchmark name");
    a.addOption('dir', help: "Project directory");
    a.addOption('entry', help: "Project entry point", allowMultiple: true);
    a.addFlag('inline', help: "Inline packages", defaultsTo: false);
  }

  SemanticCommandOptions.parse(ArgResults opts, [ bool desugar = false ]) {
    if (opts["benchmark"] != null) {
      Map projects = JSON.decode(new File("./benchmarks/projects.json").readAsStringSync());
      Map project = projects[opts["benchmark"]];
      this.projectDirectory = "benchmarks/${desugar ? "original" : "desugared"}/${project["package"]}";
      this.entryFile = [project["entry"]];
    }
    if (opts["dir"] != null)
      this.projectDirectory = opts["dir"];
    if (opts["entry"] != null && opts["entry"].isNotEmpty)
      this.entryFile = opts["entry"];
    this.inline = opts["inline"];
    if(projectDirectory == null || entryFile == null)
      throw new UsageException("Options 'dir' and 'entry' are mandatory", "--dir <directory> --entry <entry>");
  }

}

class DesugarCommandOptions extends SemanticCommandOptions {

  String destination;
  bool ignoreCache;
  bool push = true; //TODO: See if this can be enabled by default considering the casa machines

  DesugarCommandOptions.args(this.destination, this.ignoreCache, ArgResults o) : super.parse(o, true);

  static void createOptions(ArgParser a) {
    SemanticCommandOptions.createOptions(a);
    a.addOption('dest', help: "Destination Folder", defaultsTo: "benchmarks/desugared");
    a.addFlag('ignore-cache', help: "Ignore github cache branch", defaultsTo: true);
  }

  DesugarCommandOptions.parse(ArgResults opts) : this.args(opts["dest"], opts["ignore-cache"], opts);

}


class SyntacticCommandOptions {

  String projectDirectory;

  SyntacticCommandOptions.args({this.projectDirectory});

  static void createOptions(ArgParser a) {
    a.addOption('dir', help: "Project directory");
  }


  SyntacticCommandOptions.parse(ArgResults opts) : this.args(projectDirectory: opts["dir"]);

}
