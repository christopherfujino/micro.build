import 'source_code.dart';

enum TokenType {
  // keywords

  /// Keyword "target".
  target,

  // brackets
  openParen,
  closeParen,

  openSquareBracket,
  closeSquareBracket,

  openCurlyBracket,
  closeCurlyBracket,

  // String-like tokens
  identifier,
  stringLiteral,

  // misc
  comma,
  semicolon,
  hash, // #
}

class Token {
  Token({
    required this.type,
    required this.line,
    required this.char,
  });

  final TokenType type;
  final int line;
  final int char;

  @override
  String toString() => '[$line, $char] ${type.name}';
}

class StringToken extends Token {
  StringToken({
    required super.type,
    required this.value,
    required super.line,
    required super.char,
  });

  /// The contents of this string, excluding quotes.
  final String value;

  @override
  String toString() => '${super.toString()}: "$value"';
}

class Scanner {
  Scanner._(this.source);

  factory Scanner.fromSourceCode(SourceCode sourceCode) {
    return Scanner._(sourceCode.text);
  }

  final String source;
  final List<Token> _tokenList = <Token>[];

  int _index = 0;
  int _line = 1;
  int _lastNewlineIndex = 0;
  int get _char => _index - _lastNewlineIndex + 1;

  // TODO figure out unicode
  Future<List<Token>> scan() async {
    while (_index < source.length) {
      if (_scanWhitespace()) {
        continue;
      }

      if (_scanKeyword()) {
        continue;
      }

      // handle brackets (parens, square, and curly)
      if (_scanBracket()) {
        continue;
      }

      if (_scanString()) {
        continue;
      }

      // handle named identifiers--must run after [_scanKeyword()],
      // [_scanString()]
      if (_scanIdentifier()) {
        continue;
      }

      if (_scanMisc()) {
        continue;
      }

      _index += 1;
    }
    return _tokenList;
  }

  static const List<String> kKeywords = <String>[
    'target',
  ];

  bool _scanKeyword() {
    // TODO this can be faster, use linear search, not [.startsWith()]
    final String rest = source.substring(_index);
    for (final String keyword in kKeywords) {
      if (rest.startsWith(keyword)) {
        _index += keyword.length;
        _tokenList.add(
          Token(
            type: TokenType.target,
            line: _line,
            char: _char,
          ),
        );
        return true;
      }
    }
    return false;
  }

  // TODO: handle escapes?
  static final RegExp kStringPattern = RegExp(r'"(.*)"');

  bool _scanString() {
    // TODO this can be faster
    final String rest = source.substring(_index);
    final Match? match = kStringPattern.matchAsPrefix(rest);
    if (match != null) {
      // increment index including quotes
      _index += match.group(0)!.length;
      _tokenList.add(
        StringToken(
          type: TokenType.stringLiteral,
          // store the sub-group, excluding quotes
          value: match.group(1)!,
          line: _line,
          char: _char,
        ),
      );
      return true;
    }
    return false;
  }

  static final RegExp kIdentifierPattern = RegExp(r'[a-zA-Z0-9_-]+');

  bool _scanIdentifier() {
    // TODO this can be faster
    final String rest = source.substring(_index);
    final Match? match = kIdentifierPattern.matchAsPrefix(rest);
    if (match != null) {
      final String stringMatch = match.group(0)!;
      _index += stringMatch.length;
      _tokenList.add(
        StringToken(
          type: TokenType.identifier,
          value: stringMatch,
          line: _line,
          char: _char,
        ),
      );
      return true;
    }
    return false;
  }

  bool _scanWhitespace() {
    switch (source[_index]) {
      case ' ':
      case '\t':
      case '\r':
        _index += 1;
        return true;
      case '\n':
        _lastNewlineIndex = _index;
        _line += 1;
        _index += 1;
        return true;
      default:
        return false;
    }
  }

  bool _scanBracket() {
    switch (source[_index]) {
      case '{':
        _index += 1;
        _tokenList.add(
          Token(
            type: TokenType.openCurlyBracket,
            line: _line,
            char: _char,
          ),
        );
        return true;
      case '}':
        _index += 1;
        _tokenList.add(
          Token(
            type: TokenType.closeCurlyBracket,
            line: _line,
            char: _char,
          ),
        );
        return true;
      case '[':
        _index += 1;
        _tokenList.add(
          Token(
            type: TokenType.openSquareBracket,
            line: _line,
            char: _char,
          ),
        );
        return true;
      case ']':
        _index += 1;
        _tokenList.add(
          Token(
            type: TokenType.closeSquareBracket,
            line: _line,
            char: _char,
          ),
        );
        return true;
      case '(':
        _index += 1;
        _tokenList.add(
          Token(
            type: TokenType.openParen,
            line: _line,
            char: _char,
          ),
        );
        return true;
      case ')':
        _index += 1;
        _tokenList.add(
          Token(
            type: TokenType.closeParen,
            line: _line,
            char: _char,
          ),
        );
        return true;
      default:
        return false;
    }
  }

  bool _scanMisc() {
    switch (source[_index]) {
      case ',':
        _index += 1;
        _tokenList.add(
          Token(
            type: TokenType.comma,
            line: _line,
            char: _char,
          ),
        );
        return true;
      case ';':
        _index += 1;
        _tokenList.add(
          Token(
            type: TokenType.semicolon,
            line: _line,
            char: _char,
          ),
        );
        return true;
      case '#':
        // eat all text until end of line
        while (source[_index] != '\n') {
          _index += 1;
        }
        // does the parser need a comment token?
        return true;
    }

    return false;
  }
}
