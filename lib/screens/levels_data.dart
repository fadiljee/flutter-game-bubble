import 'level_config.dart'; // Perbaikan: import yang benar

class LevelsData {
  static const Map<String, LevelConfig> levels = {
    // Stage 1 - Basic Addition
    '1-1': LevelConfig(
      stage: 1, level: 1, targetResult: 3,
      equation: "? + ? = 3", timeLimit: 90,
    ),
    '1-2': LevelConfig(
      stage: 1, level: 2, targetResult: 5,
      equation: "? + ? = 5", timeLimit: 80,
    ),
    '1-3': LevelConfig(
      stage: 1, level: 3, targetResult: 7,
      equation: "? + ? = 7", timeLimit: 70,
    ),
    '1-4': LevelConfig(
      stage: 1, level: 4, targetResult: 10,
      equation: "? + ? = 10", timeLimit: 70,
    ),
    '1-5': LevelConfig(
      stage: 1, level: 5, targetResult: 12,
      equation: "? + ? = 12", timeLimit: 60,
    ),
    '1-6': LevelConfig(
      stage: 1, level: 6, targetResult: 15,
      equation: "? + ? = 15", timeLimit: 60,
    ),
    '1-7': LevelConfig(
      stage: 1, level: 7, targetResult: 18,
      equation: "? + ? = 18", timeLimit: 50,
    ),
    '1-8': LevelConfig(
      stage: 1, level: 8, targetResult: 20,
      equation: "? + ? = 20", timeLimit: 50,
    ),
    '1-9': LevelConfig(
      stage: 1, level: 9, targetResult: 25,
      equation: "? + ? = 25", timeLimit: 40,
    ),
    '1-10': LevelConfig(
      stage: 1, level: 10, targetResult: 30,
      equation: "? + ? = 30", timeLimit: 40,
    ),
    
    // Stage 2 - Subtraction
    '2-1': LevelConfig(
      stage: 2, level: 1, targetResult: 1,
      operation: '-', equation: "? - ? = 1", timeLimit: 90,
    ),
    '2-2': LevelConfig(
      stage: 2, level: 2, targetResult: 2,
      operation: '-', equation: "? - ? = 2", timeLimit: 80,
    ),
    '2-3': LevelConfig(
      stage: 2, level: 3, targetResult: 5,
      operation: '-', equation: "? - ? = 5", timeLimit: 70,
    ),
    '2-4': LevelConfig(
      stage: 2, level: 4, targetResult: 8,
      operation: '-', equation: "? - ? = 8", timeLimit: 70,
    ),
    '2-5': LevelConfig(
      stage: 2, level: 5, targetResult: 10,
      operation: '-', equation: "? - ? = 10", timeLimit: 60,
    ),
    '2-6': LevelConfig(
      stage: 2, level: 6, targetResult: 12,
      operation: '-', equation: "? - ? = 12", timeLimit: 60,
    ),
    '2-7': LevelConfig(
      stage: 2, level: 7, targetResult: 15,
      operation: '-', equation: "? - ? = 15", timeLimit: 50,
    ),
    '2-8': LevelConfig(
      stage: 2, level: 8, targetResult: 18,
      operation: '-', equation: "? - ? = 18", timeLimit: 50,
    ),
    '2-9': LevelConfig(
      stage: 2, level: 9, targetResult: 20,
      operation: '-', equation: "? - ? = 20", timeLimit: 40,
    ),
    '2-10': LevelConfig(
      stage: 2, level: 10, targetResult: 25,
      operation: '-', equation: "? - ? = 25", timeLimit: 40,
    ),
    
    // Stage 3 - Mixed Operations
    '3-1': LevelConfig(
      stage: 3, level: 1, targetResult: 6,
      operation: '*', equation: "? × ? = 6", timeLimit: 90,
    ),
    '3-2': LevelConfig(
      stage: 3, level: 2, targetResult: 8,
      operation: '*', equation: "? × ? = 8", timeLimit: 80,
    ),
    '3-3': LevelConfig(
      stage: 3, level: 3, targetResult: 12,
      operation: '*', equation: "? × ? = 12", timeLimit: 70,
    ),
    '3-4': LevelConfig(
      stage: 3, level: 4, targetResult: 15,
      operation: '*', equation: "? × ? = 15", timeLimit: 70,
    ),
    '3-5': LevelConfig(
      stage: 3, level: 5, targetResult: 18,
      operation: '*', equation: "? × ? = 18", timeLimit: 60,
    ),
    '3-6': LevelConfig(
      stage: 3, level: 6, targetResult: 20,
      operation: '*', equation: "? × ? = 20", timeLimit: 60,
    ),
    '3-7': LevelConfig(
      stage: 3, level: 7, targetResult: 24,
      operation: '*', equation: "? × ? = 24", timeLimit: 50,
    ),
    '3-8': LevelConfig(
      stage: 3, level: 8, targetResult: 30,
      operation: '*', equation: "? × ? = 30", timeLimit: 50,
    ),
    '3-9': LevelConfig(
      stage: 3, level: 9, targetResult: 36,
      operation: '*', equation: "? × ? = 36", timeLimit: 40,
    ),
    '3-10': LevelConfig(
      stage: 3, level: 10, targetResult: 42,
      operation: '*', equation: "? × ? = 42", timeLimit: 40,
    ),
  };
  
  static LevelConfig? getLevel(int stage, int level) {
    return levels['$stage-$level'];
  }
  
  static List<LevelConfig> getStage(int stage) {
    return levels.values.where((config) => config.stage == stage).toList()
      ..sort((a, b) => a.level.compareTo(b.level));
  }
}