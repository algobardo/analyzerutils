part of analyzerutils.transformers;

class StripperState {
  Map<Type, int> stripped = new HashMap();
  int missing = 0;
  int totals = 0;
  int get kept => nannotations - (stripped.values.isEmpty ? 0 : stripped.values.reduce((x, y) => x + y));
  int get nannotations => totals - missing;
}

class StripperVisitor extends IncrementalAstCloner implements ProgramVisitor {

  final StripperState state;
  final double annotationLevel;
  final Random rnd;
  final int seed;
  final bool skipContext;

  StripperVisitor(this.annotationLevel, int seed) :
        this.seed = seed,
        this.rnd = new Random(seed),
        this.state = new StripperState(),
        this.skipContext = false,
        super(null, null, new IdentityTokenMap());

  StripperVisitor._internal(this.state, this.seed, this.rnd, this.skipContext, this.annotationLevel)
      : super(null, null, new IdentityTokenMap());


  StripperVisitor withArgs({state, seed, rnd, skipContext, annotationLevel}) =>
    new StripperVisitor._internal(
      state != null ? state : this.state,
      seed != null ? seed : this.seed,
      rnd != null ? rnd : this.rnd,
      skipContext != null ? skipContext : this.skipContext,
      annotationLevel != null ? annotationLevel : this.annotationLevel
  );

  bool arbitrateStrip(TypeName type, AstNode node) {
    if(skipContext) return false;
    state.totals++;
    bool toStrip = false;

    if(type == null || (type.type != null && type.type.isDynamic)) state.missing++;
    else toStrip = rnd.nextDouble() > annotationLevel;

    if(toStrip) state.stripped[node.runtimeType] = (state.stripped[node.runtimeType] ?? 0) + 1;
    return toStrip;
  }

  static bool isPatched(AstNode node) => false;
      /*(node is MethodDeclaration && (node.externalKeyword != null || (node.body != null && node.body is NativeFunctionBody)))
      ||
      (node is FunctionDeclaration && (node.externalKeyword != null || (node.functionExpression.body != null && node.functionExpression.body is NativeFunctionBody)))
      ||
      (node is ConstructorDeclaration && (node.externalKeyword != null))
      ||
      (node is ClassDeclaration && (node.nativeClause != null))
      ||
      (node.parent is ClassDeclaration && (node.parent as ClassDeclaration).name.toString() == "Object");*/

  StripperVisitor patchedContextVisitor(AstNode node) =>
      isPatched(node) ?
      withArgs(skipContext: true)
      :
      this;

  DeclaredIdentifier visitDeclaredIdentifier(DeclaredIdentifier node) {
    if(skipContext) return super.visitDeclaredIdentifier(node);

    bool toStrip = arbitrateStrip(node.type, node);
    node = super.visitDeclaredIdentifier(node);
    if (toStrip) {
      if (node.keyword == null) {
        node.keyword = new KeywordToken(Keyword.VAR, -1);
      }
      node.type = null;
    }
    return node;
  }


  VariableDeclarationList visitVariableDeclarationList(VariableDeclarationList node) {
    if(skipContext) return super.visitVariableDeclarationList(node);

    bool toStrip = arbitrateStrip(node.type, node);
    node = super.visitVariableDeclarationList(node);
    if (toStrip) {
      if (node.keyword == null) {
        node.keyword = new KeywordToken(Keyword.VAR, -1);
      }
      node.type = null;
    }
    return node;
  }


  FunctionDeclaration visitFunctionDeclaration(FunctionDeclaration node) {
    if(skipContext) return super.visitFunctionDeclaration(node);

    bool toStrip = arbitrateStrip(node.returnType, node);
    if(!isPatched(node)) {
      node = super.visitFunctionDeclaration(node);
      if(toStrip)
        node.returnType = null;
    }
    else {
      node = patchedContextVisitor(node).visitFunctionDeclaration(node);
    }
    return node;
  }


  MethodDeclaration visitMethodDeclaration(MethodDeclaration node) {
    if(skipContext) return super.visitMethodDeclaration(node);

    bool toStrip = arbitrateStrip(node.returnType, node);
    if(!isPatched(node)) {
      node = super.visitMethodDeclaration(node);
      if (toStrip)
        node.returnType = null;
    }
    else {
      node = patchedContextVisitor(node).visitMethodDeclaration(node);
    }
    return node;
  }


/*
  FieldFormalParameter visitFieldFormalParameter(FieldFormalParameter node) {
    bool toStrip = handleType(node.type);
    node = super.visitFieldFormalParameter(node);
    if(toStrip) node.type = null;
    return node;
  }
*/


  InstanceCreationExpression visitInstanceCreationExpression(InstanceCreationExpression node) {
    if(skipContext) return super.visitInstanceCreationExpression(node);

    if(!isPatched(node)) {
      node = super.visitInstanceCreationExpression(node);
      if(node.constructorName.type != null && node.constructorName.type.typeArguments != null && node.constructorName.type.typeArguments.arguments.isNotEmpty) {
        node.constructorName.type.typeArguments = null; //Fixme: arbitrate
      }
    }
    else {
      node = patchedContextVisitor(node).visitInstanceCreationExpression(node);
    }
    return node;
  }

  ConstructorDeclaration visitConstructorDeclaration(ConstructorDeclaration node) {
    if(skipContext) return super.visitConstructorDeclaration(node);

    if(!isPatched(node)) {
      node = super.visitConstructorDeclaration(node);
    }
    else {
      node = patchedContextVisitor(node).visitConstructorDeclaration(node);
    }
    return node;
  }

  SimpleFormalParameter visitSimpleFormalParameter(SimpleFormalParameter node) {
    if(skipContext) return super.visitSimpleFormalParameter(node);

    bool toStrip = arbitrateStrip(node.type, node);
    node = super.visitSimpleFormalParameter(node);
    if(toStrip) node.type = null;
    return node;
  }

  FunctionTypedFormalParameter visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    if(skipContext) return super.visitFunctionTypedFormalParameter(node);

    bool toStrip = arbitrateStrip(node.returnType, node);
    node = super.visitFunctionTypedFormalParameter(node);
    if(toStrip) node.returnType = null;
    return node;
  }

  void printStats() {
    print("Annotations (${(state.kept.toDouble() / state.nannotations)*100}%) overall annotation level: (${(state.kept.toDouble() / state.totals)*100}%) --  stripped: ${state.stripped}, out of ${state.nannotations} annotations, there are ${state.totals} declarations and ${state.missing} missing annotations");
  }

  void transformationFinished() {
    printStats();
  }

  void transforming(cu, String originalPath) {

  }

}
