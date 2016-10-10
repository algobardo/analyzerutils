part of analyzerutils.transformers;

class DeawaiterVisitor extends RecursiveAstVisitor implements ProgramVisitor {

  @override
  CompilationUnit visitCompilationUnit(CompilationUnit node) {
    return AnalyserUtils.parse(ourCompile(node.toString()));
  }


  String ourCompile(String source) {
    var unit = AnalyserUtils.parse(source);

    var worklistBuilder = new WorklistBuilder();
    worklistBuilder.visit(unit);
    var transform = new AsyncTransformer();
    int position = 0;
    StringBuffer sb = new StringBuffer();
    for (var item in worklistBuilder.worklist) {
      sb.write(source.substring(position, item.position));
      sb.write(transform.visit(item.sourceBody));
      position = item.sourceBody.end;
    }
    sb.write(source.substring(position));
    return sb.toString();
  }

  void transformationFinished() {

  }

  bool shouldTransform(cu, String originalPath) => true;
}
