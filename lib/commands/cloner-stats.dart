library analyzerutils.commands.cloner;

import "dart:io";
import "dart:math";

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzerutils/transformers/transformers.dart';
import 'package:analyzerutils/workers/workers.dart';
import 'package:args/command_runner.dart';
import 'package:dart_style/src/dart_formatter.dart';
import 'package:path/path.dart' as path;

import '../analyzer.dart';
import '../options.dart';
import '../program.dart';
import '../utils.dart';

void runProgram(String name, String folder, String entry) {
  print("Running $name");
  ProcessResult result = Process.runSync(
  //"dart", ["--enable_asserts=false", "--enable_type_checks=true", "--trace_type_checks=true", entry],
      "/Users/mezzetti/Archivi/Lavori/Programs/dart-sdk-original/sdk/xcodebuild/ReleaseX64/dart" , ["--enable_asserts=false", "--enable_type_checks=true", "--trace_type_checks=true", "--ignore_patch_signature_mismatch", entry],
      environment: Platform.environment,
      workingDirectory: folder,
      includeParentEnvironment: true,
      runInShell: true);

  //result.then((ProcessResult result) {
  if (result.exitCode != 0) {
    print(result.stdout);
    print(result.stderr);
    throw new Exception("Test $folder $entry failed");
  }

  RegExp exp = new RegExp(r"TypeCheck");
  String err = result.stderr.toString();
  int tpc = exp.allMatches(err).length;
  print("$name \t $tpc");
  //});
}


class SemanticWorker extends Command {

  final name = "semantic";
  final description = "Semantic worker";

  SemanticWorker() {
    // [argParser] is automatically created by the parent class.
    SemanticCommandOptions.createOptions(argParser);
  }

  // [run] may also return a Future.
  void run() {
    SemanticCommandOptions opts;
    try {
      opts = new SemanticCommandOptions.parse(this.argResults);
    }
    catch (e) {
      throw new UsageException("invalid semantic command", this.usage);
    }
    semanticStripper(opts);
  }


  /**
   * This part tries to instantiate a full analyser environment, so
   * that we can use any information we want from it, including package uri resolution.
   */
  void semanticStripper(SemanticCommandOptions options) {
    List<ProgramWorker> phases = createPhases(options);

    List<WorkResult> workersResults = new List();

    AnalyserUtils.resolve(options).then((ProgramInfo p) {
      phases.forEach((ProgramWorker pw) {
        var result = pw.apply(p);
        workersResults.add(result);
      });
      p.release();

      for (WorkResult wr in workersResults) {
        if (wr is CloneResult) {
          StripperVisitor v = (wr.transformer as StripperVisitor);
          String name = "${v.annotationLevel} \t ${v.seed}";
          runProgram(name, wr.destination, options.entryFile.first);
        }
      }
    });
  }


  List<ProgramWorker> createPhases(SemanticCommandOptions options) {
    List<ProgramWorker> l = new List();
    Random r = new Random();
    int seed = r.nextInt(4294967296);
    for (int i = 0; i <= 10; i++) {
      StripperVisitor stripper = new StripperVisitor((0.1 * i), seed);
      Directory clonePath = new Directory(path.join(
          GlobalOptions.outDirectory, path.basename(options.projectDirectory), "level-${i}-${seed}"));
      clonePath.createSync(recursive: true);
      l.add(new TransformCloneWorker.single(new File(clonePath.path), stripper, options.inline));
    }
    return l;
  }

}


class SyntacticWorker extends Command {


  final name = "synth";
  final description = "Syntactical worker";

  SyntacticWorker() {
    SyntacticCommandOptions.createOptions(argParser);
  }

  // [run] may also return a Future.
  void run() {
    SyntacticCommandOptions opts;
    try {
      opts = new SyntacticCommandOptions.parse(this.argResults);
    }
    catch(e) {
      throw new UsageException("invalid semantic command", this.usage);
    }
    syntacticStripper(opts);
  }

  void syntacticStripper(SyntacticCommandOptions args) {
    print("Syntactic stripper working on ${args.projectDirectory}");
    if(!new Directory(args.projectDirectory).existsSync()) throw new Exception("Directory ${args.projectDirectory} does not exist");
    Set<File> files = DirectoryUtils.recursiveFolderListSync(args.projectDirectory);
    print("Listed ${files.length} files");
    Iterable<File> dartFiles = files.where((File f) => path.extension(f.path) == ".dart");
    final DartFormatter df = new DartFormatter(pageWidth: -1);

    for (File f in dartFiles) {
      print("Writing $f");
      StripperVisitor stripper = new StripperVisitor(0.0, 0);
      CompilationUnit cu = AnalyserUtils.parse(f.readAsStringSync());
      CompilationUnit stripped = cu.accept(stripper);

      f.writeAsStringSync(df.format(stripped.toSource()));
    }
  }
}
