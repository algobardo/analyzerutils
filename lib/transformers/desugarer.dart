part of analyzerutils.transformers;

class DesugaringVisitor extends IncrementalAstCloner implements ProgramVisitor {
  HashSet<CompilationUnitElement> inlined = new HashSet();

  AstNode _cloneNode(AstNode node) {
    if (node == null) {
      return null;
    }

    return node.accept(this) as AstNode;
  }

  List _cloneNodeList(NodeList nodes) {
    List clonedNodes = new List();
    for (AstNode node in nodes) {
      clonedNodes.add(_cloneNode(node));
    }
    return clonedNodes;
  }

  Token _mapToken(Token oldToken) {
    return oldToken;
  }

  DesugaringVisitor() : super(null, null, new IdentityTokenMap());

  @override
  CompilationUnit visitCompilationUnit(CompilationUnit node, [handleParts = false]) {
    List<PartDirective> partDirectives =
    node.directives.where((Directive directive) => directive is PartDirective);

    List<PartOfDirective> partOfDirectives =
    node.directives.where((Directive directive) => directive is PartOfDirective);

    if(partOfDirectives.isNotEmpty && !handleParts) return null;

    if (partDirectives.isNotEmpty) {
      List<CompilationUnit> imported = node.directives
          .where((Directive d) => d is PartDirective)
          .map((PartDirective d) =>
          visitCompilationUnit(d.uriElement.computeNode(), true));

      inlined.addAll(imported.map((CompilationUnit cu) =>  cu.element));

      CompilationUnit copy = new CompilationUnit(
          _mapToken(node.beginToken),
          _cloneNode(node.scriptTag),
          _cloneNodeList(node.directives.where((Directive directive) => directive is! PartDirective).toList()),
          _cloneNodeList(imported.fold(node.declarations, (List<Declaration> acc, CompilationUnit cu) =>
          acc..addAll(cu.declarations))),
          _mapToken(node.endToken));
      copy.lineInfo = node.lineInfo;
      copy.element = node.element;
      return copy;

    }

    CompilationUnit copy = new CompilationUnit(
        _mapToken(node.beginToken),
        _cloneNode(node.scriptTag),
        _cloneNodeList(node.directives),
        _cloneNodeList(node.declarations),
        _mapToken(node.endToken));
    copy.lineInfo = node.lineInfo;
    copy.element = node.element;

    return copy;
  }

  void transformationFinished() {

  }

  bool shouldTransform(cu, String originalPath) => true;
}
