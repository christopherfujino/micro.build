import 'scanner.dart';
import 'source_code.dart';

class Config {
  const Config(this.declarations);

  final List declarations;
}

class Parser {
  Parser({
    required this.tokenList,
    required this.source,
  });

  final List<Token> tokenList;
  final SourceCode source;

  int _index = 0;
  Token? get _currentToken {
    if (_index >= tokenList.length) {
      return null;
    }
    return tokenList[_index];
  }

  Future<Config> parse() async {
    final List declarations = [];
    Declaration? currentDeclaration = _parseDeclaration();
    while (currentDeclaration != null) {
      declarations.add(currentDeclaration);
      currentDeclaration = _parseDeclaration();
    }

    return Config(declarations);
  }

  Declaration? _parseDeclaration() {
    final Token? currentToken = _currentToken;
    if (currentToken == null) {
      return null;
    }
    if (currentToken.type == TokenType.target) {
      return _parseTargetDeclaration();
    }
    _throwParseError(
      currentToken,
      'Unknown declaration type ${currentToken.type.name}',
    );
  }

  Never _throwParseError(Token token, String message) {
    throw ParseError(
      '\n${source.getDebugMessage(token.line, token.char)}\n'
      'Parse error: $message [${token.line}, ${token.char}]\n',
    );
  }

  /// Parse a [TargetDeclaration].
  ///
  /// target_declaration ::= "target", identifier, "{", statement*, "}"
  TargetDeclaration? _parseTargetDeclaration() {
    _consume(TokenType.target);
    final StringToken name = _consume(TokenType.identifier) as StringToken;

    _consume(TokenType.openCurlyBracket);
    final List<Statement> statements = <Statement>[];
    Statement? statement = _parseStatement();
    while (statement != null) {
      statements.add(statement);
      statement = _parseStatement();
    }

    return TargetDeclaration(
      name: name.value,
      statements: statements,
    );
  }

  Statement? _parseStatement() {
    Statement? statement = _parseBareStatement();
    if (statement != null) {
      return statement;
    }

    return null;
  }

  // bare_statement ::= expression, ";"
  BareStatement? _parseBareStatement() {
    final Expression? expression = _parseExpression();
    if (expression == null) {
      return null;
    }
    if (_currentToken!.type != TokenType.semicolon) {
      throw ParseError('Parse error: at ${_currentToken}');
    }
    return BareStatement(expression: expression);
  }

  // Expressions

  Expression? _parseExpression() {
    Expression? expression = _parseCallExpression();
    if (expression != null) {
      return expression;
    }

    return null;
  }

  // call_expression ::= identifier, "(", expression?, ")"
  CallExpression? _parseCallExpression() {
    final StringToken? name = _consume(TokenType.identifier) as StringToken?;
    if (name == null) {
      return null;
    }
  }

  /// Consume and return the next token iff it matches [type].
  ///
  /// Throws [Exception] if the type is not correct.
  Token? _consume(TokenType type) {
    // coerce type as this should only be called if you know what's there.
    final Token? consumedToken = _currentToken;
    if (consumedToken == null || consumedToken.type != type) {
      return null;
    }
    _index += 1;
    return consumedToken;
  }
}

abstract class Declaration {
  Declaration({
    required this.name,
  });

  final String name;
}

class TargetDeclaration extends Declaration {
  TargetDeclaration({
    required super.name,
    required this.statements,
  });

  final Iterable<Statement> statements;
}

abstract class Statement {}

class BareStatement extends Statement {
  BareStatement({required this.expression});

  final Expression expression;
}

abstract class Expression {}

class CallExpression extends Expression {}

class ParseError implements Exception {
  const ParseError(this.message);

  final String message;

  @override
  String toString() => message;
}
