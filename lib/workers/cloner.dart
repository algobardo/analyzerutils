part of analyzerutils.workers;

bool FORMAT_STYLE = true;
bool DEBUG = false;

class CloneResult extends WorkResult {
  String destination;
  ProgramVisitor transformer;
  ProgramInfo originalProgram;

  CloneResult(this.originalProgram, this.destination, this.transformer);
}

/**
 * A worker that clone a program into a destination, while performing a transformation
 * This transformer removes any dependency, by importing the packages directly by absolute path
 */
class TransformCloneWorker implements ProgramWorker {

  File destination;
  Iterable<ProgramVisitor> transformer;
  bool inline;

  TransformCloneWorker(this.destination, this.transformer, this.inline);

  TransformCloneWorker.single(destination, transformer, inline) : this(destination, [transformer], inline);

  WorkResult apply(ProgramInfo p) {
    // We clone the folder first

    if(path.isWithin(p.programRoot.absolute.path, destination.absolute.path))
      throw new Exception("Cloning path inside project root: ${destination.absolute.path}");

    //Cloning the folder is only needed because of resources
    DirectoryUtils.recursiveFolderCopySync(p.programRoot.absolute.path, destination.absolute.path);

    // And then we clone on top;
    new Cloner(destination, transformer, p, inline);
    transformer.forEach((ProgramVisitor v) => v.transformationFinished());
    return new CloneResult(p, destination.absolute.path, transformer.last);
  }
}

class Cloner {

  File destination;
  Iterable<ProgramVisitor> transformer;
  ProgramInfo p;
  bool inline;
  HashSet<String> inlined = new HashSet();

  final DartFormatter df = new DartFormatter(pageWidth: -1);

  Cloner.single(destination, ProgramVisitor transformer, p, inline) : this(destination, [transformer], p, inline);

  Cloner(this.destination, this.transformer, this.p, this.inline) {
    cloneRec(p.entryLibrary, new HashSet());
  }


  bool isPackage(String pth) => path.isWithin(path.join(p.programRoot.path, "packages"), pth);

  String getSourcePath(CompilationUnitElement l) => l.source.uriKind == UriKind.DART_URI ? null : p.transform
      .getFile(p.resolver.getSourceAssetId(l))
      .absolute.path;

  String importMapper(CompilationUnitElement l, [String relativeTo = null, bool forImport = false]) {
    String ret;

    String origPath = getSourcePath(l);

    if(origPath == null) return null;

    if(!isPackage(origPath) && forImport)
      return l.uri;

    File orig = new File(origPath);

    String dest = destination.absolute.path;
    String dirPattern = p.programRoot.absolute.path;
    if(isPackage(orig.path)) {
      if (inline) {
        dirPattern = path.absolute(path.join(dirPattern, "packages"));
        dest = path.absolute(path.join(dest, "lib/src/inlined/"));
      }
      else {
        return l.uri;
      }
    }

    ret = orig.path.replaceFirst(dirPattern, dest);

    if(relativeTo != null) {
      return path.relative(ret, from: path.dirname(relativeTo));
    }
    else
      return path.absolute(ret);
  }

  cloneRec(LibraryElement lib, HashSet<LibraryElement> visitedLibraries) {
    if (visitedLibraries.contains(lib)) return;
    cloneLibrary(lib);
    visitedLibraries.add(lib);
    lib.importedLibraries.forEach((LibraryElement il) {
      cloneRec(il, visitedLibraries);
    });
    lib.exportedLibraries.forEach((LibraryElement il) {
      cloneRec(il, visitedLibraries);
    });
  }

  cloneLibrary(LibraryElement lib) {
    lib.units.forEach((CompilationUnitElement unit) => cloneUnit(unit));
  }

  cloneUnit(CompilationUnitElement cu) {
    CompilationUnit node = cu.computeNode();
    if (!cu.source.isInSystemLibrary && (inline || !isPackage(getSourcePath(cu)))) {
      if(DEBUG)
        print("Handling ${getSourcePath(cu)}");
      CompilationUnit clone = node.accept(new ImportReplacerVisitor(this));
      CompilationUnit instrument = clone;
      transformer.forEach((ProgramVisitor pv) {
        if (instrument != null) {
          pv.transforming(cu, getSourcePath(cu));
          instrument = instrument.accept(pv);
        }
      });

      if (instrument == null) return;

      String dest = importMapper(cu);
      File destFile = new File(dest);
      destFile.createSync(recursive: true);
      String source = "";
      if(FORMAT_STYLE) {
        Stopwatch s = new Stopwatch()..start();
        source = df.format(instrument.toSource());
        s.stop();
        if(DEBUG)
          print("Formatting ${clone.element} took ${s.elapsedMilliseconds}");
      } else
        source = instrument.toSource();
      destFile.writeAsStringSync(source);
    }
    else {
      //Only invoke it, for stats ?
      //node.accept(transformer);
    }
  }

}

class ImportReplacerVisitor extends IncrementalAstCloner  {

  Cloner c;

  ImportReplacerVisitor(this.c) : super(null, null, new IdentityTokenMap());

  ImportDirective visitImportDirective(ImportDirective node) {
    String myPosition = c.importMapper(node.element.unit.element);
    String newPosition = c.importMapper(node.uriElement.unit.element, myPosition, true);
    ImportDirective clone = super.visitImportDirective(node);
    if(newPosition != null)
      clone.uri = AstFactory.string2(newPosition);
    return clone;
  }

  ExportDirective visitExportDirective(ExportDirective node) {
    String myPosition = c.importMapper(node.element.unit.element);
    String newPosition = c.importMapper(node.uriElement.unit.element, myPosition, true);

    ExportDirective clone = super.visitExportDirective(node);
    if(newPosition != null)
      clone.uri = AstFactory.string2(newPosition);
    return clone;
  }


}