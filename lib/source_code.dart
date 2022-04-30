class SourceCode {
  SourceCode._(
    this._lines,
  );

  final List<String> _lines;

  /// Get character at [line], [char] coordinate.
  ///
  /// Note that both are 1-indexed.
  String getDebugMessage(int lineIndex, int charIndex) {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln(_lines[lineIndex - 1]);
    final int padding = charIndex == 1 ? 0 : charIndex - 2;
    buffer.write(' ' * padding);
    buffer.writeln('^');
    return buffer.toString();
  }

  factory SourceCode.fromString(String str) {
    return SourceCode._(str.split('\n'));
  }
}
