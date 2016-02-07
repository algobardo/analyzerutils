library analyzerutils.commands.desugar;

import "dart:io";

import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzerutils/transformers/transformers.dart';
import 'package:analyzerutils/workers/workers.dart';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as path;

import '../analyzer.dart';
import '../options.dart';
import '../program.dart';
import '../utils.dart';


class DesugarWorker extends Command {

  final name = "desugar";
  final description = "Desugarer worker";

  DesugarWorker() {
    // [argParser] is automatically created by the parent class.
    DesugarCommandOptions.createOptions(argParser);
  }

  // [run] may also return a Future.
  void run() {
    DesugarCommandOptions opts;
    try {
      opts = new DesugarCommandOptions.parse(this.argResults);
    }
    catch (e) {
      throw new UsageException("invalid desugar command\n${this.usage}", this.usage);
    }
    desugar(opts);
  }


  String getSourcePath(CompilationUnitElement l, ProgramInfo p) => l.source.uriKind == UriKind.DART_URI ? null : p.transform
      .getFile(p.resolver.getSourceAssetId(l))
      .absolute.path;

  void desugar(DesugarCommandOptions options) {
    Directory clonePath = new Directory(path.join(
        options.destination, path.basename(options.projectDirectory)));

    String currentrev;
    bool cached = false;
    if(!options.ignoreCache) {
      currentrev = cmdrun("git log --pretty=format:'%h' -n 1", options.projectDirectory).trim().replaceAll("'", "").replaceAll(
          "\"", "");
      print("Original revision is: $currentrev");
      try {
        cmdrun("git ls-remote --exit-code . origin/${currentrev}_desugared", options.projectDirectory);
        cached = true;
        print("Found git-cached version");
      }
      catch (e) {}
    }


    // We always need to have a .git repository on the desugared version
    DirectoryUtils.recursiveFolderCopySync(path.join(options.projectDirectory, ".git"), path.join(clonePath.path, ".git"));
    if(!options.ignoreCache && (cached && !options.inline)) { // Cashing inlining not supported, because this would require to add files ("git add..") to the git repository
      //We clone the original folder
      DirectoryUtils.recursiveFolderCopySync(options.projectDirectory, clonePath.path);
      cmdrun("git checkout -f ${currentrev}_desugared", clonePath.path);
    }
    else {
      clonePath.createSync(recursive: true);
      DesugaringVisitor desugar = new DesugaringVisitor();
      ProgramVisitor deawait = new DeawaiterVisitor();

      ProgramWorker pw = new TransformCloneWorker(new File(clonePath.path), [desugar, deawait], options.inline);
      AnalyserUtils.resolve(options).then((ProgramInfo prog) {

        pw.apply(prog);

        // Remove spurious files
        if(!options.inline) {
          for(CompilationUnitElement cu in desugar.inlined) {
            String p = getSourcePath(cu, prog);
            String rp = path.relative(p, from: options.projectDirectory);
            String newPath = path.absolute(path.join(clonePath.path, rp));
            print("Removing $newPath because inlined");
            new File(newPath).deleteSync();
          }
        }


        prog.release();


        if(!options.ignoreCache && options.push) {
          print("Pushing desugared version to github");
          print("git checkout -b: " + cmdrun("git checkout -b ${currentrev}_desugared", clonePath.path));
          print("git add * : " + cmdrun("git add *", clonePath.path));
          print("git commit -m : " + cmdrun("git commit -m Desugared", clonePath.path));
          print("git status :" + cmdrun("git status", clonePath.path));
          print("git push: " + cmdrun("git push --set-upstream origin ${currentrev}_desugared", clonePath.path));
        }


      });
    }
  }

}

