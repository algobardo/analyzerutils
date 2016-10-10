library dart_annotations.utils;

import "dart:collection";
import "dart:io";

import 'package:path/path.dart' as path;

String cmdrun(String cmd, String wd) {
  var split = cmd.split(" ");
  var p = Process.runSync(
      split[0],
      split.length == 1 ? [] : split.getRange(1, split.length).toList(),
      environment: Platform.environment,
      workingDirectory: wd,
      includeParentEnvironment: true,
      runInShell: true);
  if (p.exitCode != 0) throw new Exception("Failed $cmd in $wd \n    - stdout ${p.stdout}\n    - stderr ${p.stderr}");
  return p.stdout.toString();
}

ProcessResult pubget(String dir, [bool fail = true]) {
  print(" - Executing cmd: (cd $dir; pub get)");

  Stopwatch watch = new Stopwatch()..start();
  ProcessResult res = Process.runSync("pub", <String>["get"], workingDirectory: dir, runInShell: true, environment: Platform.environment);
  watch.stop();

  print("   ... finished in ${watch.elapsedMilliseconds}ms\n");

  if (fail && res.exitCode != 0) throw new Exception("Failed pub get in directory $dir");
  return res;
}

ProcessResult pubbuild(String dir, [bool fail = true]) {
  ProcessResult res = Process.runSync("pub", <String>["build"], workingDirectory: dir, runInShell: true, environment: Platform.environment);
  if (fail && res.exitCode != 0) throw new Exception("Failed pub build in directory $dir");
  return res;
}

class DirectoryUtils {
  static bool isBadFolder(String pathString) {

    File fullPath = new File(path.normalize(path.absolute(pathString)));
    File solvedPath = new File(path.normalize(path.absolute(fullPath.resolveSymbolicLinksSync())));

    bool simlink = fullPath.path != solvedPath.path;

    bool hidded = path.basename(pathString).startsWith(".") && path.basename(pathString).length > 1;

    return hidded || simlink;
  }

  static void recursiveFolderCopySync(String path1, String path2, [Set<String> avoid = null]) {
    Directory dir1 = new Directory(path1);
    if (!dir1.existsSync()) {
      throw new Exception(
          'Source directory "${dir1.path}" does not exist, nothing to copy'
      );
    }
    Directory dir2 = new Directory(path2);
    if (!dir2.existsSync()) {
      dir2.createSync(recursive: true);
    }
    dir1.listSync().forEach((element) {
      if (!isBadFolder(element.path) && (avoid == null || !avoid.contains(element.absolute.path))) {
        String elementPath = element.path;
        String newPath = path.join(dir2.path, path.basename(elementPath));
        if (element is File) {
          File newFile = new File(newPath);
          newFile.writeAsBytesSync(element.readAsBytesSync());
        }
        else if (element is Directory) {
          recursiveFolderCopySync(element.path, newPath, avoid);
        }
        else {
          throw new Exception('File is neither File nor Directory. HOW?!');
        }
      }
    });
  }

  static Set<File> recursiveFolderListSync(String path1, [Set<String> avoid = null]) {
    Directory dir1 = new Directory(path1);
    if (!dir1.existsSync()) {
      throw new Exception(
          'Source directory "${dir1.path}" does not exist, nothing to copy'
      );
    }

    Iterable<Set<File>> sub = dir1.listSync().map((element) {
      if (isBadFolder(element.path) || (avoid != null && avoid.contains(element.absolute.path))) return new HashSet();
      if (element is File) {
        return new HashSet.from([element]);
      }
      else if (element is Directory) {
        return recursiveFolderListSync(element.path, avoid);
      }
      else {
        throw new Exception('File is neither File nor Directory. HOW?!');
      }
    });
    return sub.isEmpty ? new Set() : sub.reduce((Set<File> a, Set<File> b) => new HashSet()..addAll(a)..addAll(b));
  }


}