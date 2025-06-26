class LevelConfig {
  final int stage;
  final int level;
  final int targetResult;
  final List<String> initialNumbers;
  final String operation; // '+', '-', '*', '/'
  final String equation; // "? + ? = 3" atau "? - ? = 1"
  final int timeLimit; // dalam detik
  final int maxBubbles; // maksimal bubble yang bisa ditambah
  
  const LevelConfig({
    required this.stage,
    required this.level,
    required this.targetResult,
    this.initialNumbers = const [],
    this.operation = '+',
    required this.equation,
    this.timeLimit = 60,
    this.maxBubbles = 10,
  });
  
  // Helper method untuk mendapatkan symbol operasi yang sesuai untuk tampilan
  String get displayOperation {
    switch (operation) {
      case '+': return '+';
      case '-': return '-';
      case '*': return '×';
      case '/': return '÷';
      default: return '+';
    }
  }
  
  // Helper method untuk validasi jawaban
  bool validateAnswer(int left, int right) {
    switch (operation) {
      case '+':
        return left + right == targetResult;
      case '-':
        return left - right == targetResult;
      case '*':
        return left * right == targetResult;
      case '/':
        return right != 0 && left / right == targetResult;
      default:
        return false;
    }
  }
}