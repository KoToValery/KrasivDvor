import '../../../models/models.dart';

/// Engine for analyzing plant compatibility based on various characteristics
class CompatibilityEngine {
  /// Analyze compatibility between two plants
  CompatibilityResult analyzeCompatibility(Plant plant1, Plant plant2) {
    final scores = <CompatibilityFactor, double>{};
    final reasons = <String>[];
    
    // Light requirement compatibility (Requirements 3.1)
    final lightScore = _analyzeLightCompatibility(plant1, plant2);
    scores[CompatibilityFactor.light] = lightScore.score;
    if (lightScore.reason != null) reasons.add(lightScore.reason!);
    
    // Water requirement compatibility (Requirements 3.2)
    final waterScore = _analyzeWaterCompatibility(plant1, plant2);
    scores[CompatibilityFactor.water] = waterScore.score;
    if (waterScore.reason != null) reasons.add(waterScore.reason!);
    
    // Color harmony analysis (Requirements 3.3)
    final colorScore = _analyzeColorHarmony(plant1, plant2);
    scores[CompatibilityFactor.color] = colorScore.score;
    if (colorScore.reason != null) reasons.add(colorScore.reason!);
    
    // Height level compatibility (Requirements 3.3)
    final heightScore = _analyzeHeightCompatibility(plant1, plant2);
    scores[CompatibilityFactor.height] = heightScore.score;
    if (heightScore.reason != null) reasons.add(heightScore.reason!);
    
    // Seasonal variety analysis (Requirements 3.3)
    final seasonalScore = _analyzeSeasonalVariety(plant1, plant2);
    scores[CompatibilityFactor.seasonal] = seasonalScore.score;
    if (seasonalScore.reason != null) reasons.add(seasonalScore.reason!);
    
    // Soil compatibility
    final soilScore = _analyzeSoilCompatibility(plant1, plant2);
    scores[CompatibilityFactor.soil] = soilScore.score;
    if (soilScore.reason != null) reasons.add(soilScore.reason!);
    
    // Growth rate compatibility
    final growthScore = _analyzeGrowthRateCompatibility(plant1, plant2);
    scores[CompatibilityFactor.growth] = growthScore.score;
    if (growthScore.reason != null) reasons.add(growthScore.reason!);
    
    // Calculate overall compatibility score
    final overallScore = _calculateOverallScore(scores);
    final compatibilityLevel = _determineCompatibilityLevel(overallScore);
    
    return CompatibilityResult(
      plant1Id: plant1.id,
      plant2Id: plant2.id,
      overallScore: overallScore,
      compatibilityLevel: compatibilityLevel,
      factorScores: scores,
      reasons: reasons,
    );
  }
  
  /// Find compatible plants for a given plant from a list of candidates
  List<CompatibilityResult> findCompatiblePlants(
    Plant targetPlant, 
    List<Plant> candidatePlants, {
    double minCompatibilityScore = 0.6,
    int? maxResults,
  }) {
    final results = <CompatibilityResult>[];
    
    for (final candidate in candidatePlants) {
      if (candidate.id == targetPlant.id) continue; // Skip self
      
      final compatibility = analyzeCompatibility(targetPlant, candidate);
      if (compatibility.overallScore >= minCompatibilityScore) {
        results.add(compatibility);
      }
    }
    
    // Sort by compatibility score (highest first)
    results.sort((a, b) => b.overallScore.compareTo(a.overallScore));
    
    // Limit results if specified
    if (maxResults != null && results.length > maxResults) {
      return results.take(maxResults).toList();
    }
    
    return results;
  }
  
  /// Get plants that are highly compatible with multiple plants (good for group plantings)
  List<Plant> findGroupCompatiblePlants(
    List<Plant> existingPlants,
    List<Plant> candidatePlants, {
    double minAverageScore = 0.7,
  }) {
    final compatiblePlants = <Plant>[];
    
    for (final candidate in candidatePlants) {
      if (existingPlants.any((p) => p.id == candidate.id)) continue;
      
      final scores = <double>[];
      for (final existing in existingPlants) {
        final compatibility = analyzeCompatibility(existing, candidate);
        scores.add(compatibility.overallScore);
      }
      
      if (scores.isNotEmpty) {
        final averageScore = scores.reduce((a, b) => a + b) / scores.length;
        if (averageScore >= minAverageScore) {
          compatiblePlants.add(candidate);
        }
      }
    }
    
    return compatiblePlants;
  }
  
  /// Analyze plant combinations for garden design
  PlantCombinationAnalysis analyzePlantCombination(List<Plant> plants) {
    if (plants.length < 2) {
      return PlantCombinationAnalysis(
        plants: plants,
        overallHarmony: 1.0,
        strengths: ['Single plant - no compatibility issues'],
        weaknesses: [],
        suggestions: ['Consider adding complementary plants'],
      );
    }
    
    final compatibilityResults = <CompatibilityResult>[];
    final strengths = <String>[];
    final weaknesses = <String>[];
    final suggestions = <String>[];
    
    // Analyze all plant pairs
    for (int i = 0; i < plants.length; i++) {
      for (int j = i + 1; j < plants.length; j++) {
        final result = analyzeCompatibility(plants[i], plants[j]);
        compatibilityResults.add(result);
      }
    }
    
    // Calculate overall harmony
    final averageScore = compatibilityResults.isEmpty 
        ? 1.0 
        : compatibilityResults.map((r) => r.overallScore).reduce((a, b) => a + b) / compatibilityResults.length;
    
    // Analyze strengths and weaknesses
    _analyzeCombinationStrengthsAndWeaknesses(
      plants, 
      compatibilityResults, 
      strengths, 
      weaknesses, 
      suggestions
    );
    
    return PlantCombinationAnalysis(
      plants: plants,
      overallHarmony: averageScore,
      strengths: strengths,
      weaknesses: weaknesses,
      suggestions: suggestions,
    );
  }
  
  // Private helper methods
  
  _FactorScore _analyzeLightCompatibility(Plant plant1, Plant plant2) {
    final light1 = plant1.characteristics.lightRequirement;
    final light2 = plant2.characteristics.lightRequirement;
    
    // Define light requirement compatibility matrix
    const compatibilityMatrix = {
      LightRequirement.fullSun: {
        LightRequirement.fullSun: 1.0,
        LightRequirement.partialSun: 0.8,
        LightRequirement.partialShade: 0.3,
        LightRequirement.fullShade: 0.0,
      },
      LightRequirement.partialSun: {
        LightRequirement.fullSun: 0.8,
        LightRequirement.partialSun: 1.0,
        LightRequirement.partialShade: 0.7,
        LightRequirement.fullShade: 0.2,
      },
      LightRequirement.partialShade: {
        LightRequirement.fullSun: 0.3,
        LightRequirement.partialSun: 0.7,
        LightRequirement.partialShade: 1.0,
        LightRequirement.fullShade: 0.8,
      },
      LightRequirement.fullShade: {
        LightRequirement.fullSun: 0.0,
        LightRequirement.partialSun: 0.2,
        LightRequirement.partialShade: 0.8,
        LightRequirement.fullShade: 1.0,
      },
    };
    
    final score = compatibilityMatrix[light1]?[light2] ?? 0.0;
    String? reason;
    
    if (score >= 0.8) {
      reason = 'Отлична съвместимост по светлинни изисквания';
    } else if (score >= 0.5) {
      reason = 'Добра съвместимост по светлинни изисквания';
    } else if (score > 0.0) {
      reason = 'Частична съвместимост по светлинни изисквания';
    } else {
      reason = 'Несъвместими светлинни изисквания';
    }
    
    return _FactorScore(score, reason);
  }
  
  _FactorScore _analyzeWaterCompatibility(Plant plant1, Plant plant2) {
    final water1 = plant1.characteristics.waterRequirement;
    final water2 = plant2.characteristics.waterRequirement;
    
    // Water requirement compatibility
    const compatibilityMatrix = {
      WaterRequirement.low: {
        WaterRequirement.low: 1.0,
        WaterRequirement.moderate: 0.6,
        WaterRequirement.high: 0.2,
      },
      WaterRequirement.moderate: {
        WaterRequirement.low: 0.6,
        WaterRequirement.moderate: 1.0,
        WaterRequirement.high: 0.7,
      },
      WaterRequirement.high: {
        WaterRequirement.low: 0.2,
        WaterRequirement.moderate: 0.7,
        WaterRequirement.high: 1.0,
      },
    };
    
    final score = compatibilityMatrix[water1]?[water2] ?? 0.0;
    String? reason;
    
    if (score >= 0.8) {
      reason = 'Отлична съвместимост по водни изисквания';
    } else if (score >= 0.5) {
      reason = 'Добра съвместимост по водни изисквания';
    } else {
      reason = 'Различни водни изисквания - може да се наложи зониране';
    }
    
    return _FactorScore(score, reason);
  }
  
  _FactorScore _analyzeColorHarmony(Plant plant1, Plant plant2) {
    // For now, we'll use a simplified color harmony analysis
    // In a real implementation, this would analyze actual flower/foliage colors
    
    // Check if plants bloom in same seasons for color coordination
    final plant1Seasons = plant1.specifications.bloomSeason;
    final plant2Seasons = plant2.specifications.bloomSeason;
    
    final hasOverlappingSeasons = plant1Seasons.any((season) => plant2Seasons.contains(season));
    
    double score = 0.7; // Base score for color harmony
    String? reason;
    
    if (hasOverlappingSeasons) {
      score = 0.8; // Higher score if they bloom together
      reason = 'Растенията цъфтят в същия сезон - възможност за цветова хармония';
    } else {
      reason = 'Растенията цъфтят в различни сезони - продължително цъфтене';
    }
    
    return _FactorScore(score, reason);
  }
  
  _FactorScore _analyzeHeightCompatibility(Plant plant1, Plant plant2) {
    final height1 = plant1.specifications.maxHeightCm;
    final height2 = plant2.specifications.maxWidthCm;
    
    final heightDifference = (height1 - height2).abs();
    final maxHeight = height1 > height2 ? height1 : height2;
    
    double score;
    String? reason;
    
    if (heightDifference < maxHeight * 0.3) {
      // Similar heights - good for uniform plantings
      score = 0.8;
      reason = 'Подобни височини - подходящи за еднородни насаждения';
    } else if (heightDifference < maxHeight * 0.7) {
      // Moderate height difference - good for layered plantings
      score = 0.9;
      reason = 'Добра разлика във височините - създава слоести композиции';
    } else {
      // Large height difference - can work but needs careful planning
      score = 0.6;
      reason = 'Голяма разлика във височините - изисква внимателно планиране';
    }
    
    return _FactorScore(score, reason);
  }
  
  _FactorScore _analyzeSeasonalVariety(Plant plant1, Plant plant2) {
    final seasons1 = plant1.specifications.bloomSeason;
    final seasons2 = plant2.specifications.bloomSeason;
    
    final allSeasons = {...seasons1, ...seasons2};
    final overlappingSeasons = seasons1.where((s) => seasons2.contains(s)).length;
    
    double score;
    String? reason;
    
    if (allSeasons.length >= 3) {
      // Good seasonal coverage
      score = 0.9;
      reason = 'Отлично сезонно разнообразие - интерес през повечето сезони';
    } else if (allSeasons.length == 2) {
      score = 0.7;
      reason = 'Добро сезонно разнообразие';
    } else if (overlappingSeasons > 0) {
      score = 0.6;
      reason = 'Цъфтят в същия сезон - концентриран интерес';
    } else {
      score = 0.5;
      reason = 'Ограничено сезонно разнообразие';
    }
    
    return _FactorScore(score, reason);
  }
  
  _FactorScore _analyzeSoilCompatibility(Plant plant1, Plant plant2) {
    final soil1 = plant1.characteristics.preferredSoil;
    final soil2 = plant2.characteristics.preferredSoil;
    
    double score;
    String? reason;
    
    if (soil1 == soil2) {
      score = 1.0;
      reason = 'Идентични почвени изисквания';
    } else {
      // Some soil types are more compatible than others
      const compatibleSoils = {
        SoilType.loam: [SoilType.clay, SoilType.sand],
        SoilType.clay: [SoilType.loam],
        SoilType.sand: [SoilType.loam],
        SoilType.chalk: [SoilType.loam],
        SoilType.peat: [],
      };
      
      final compatible = compatibleSoils[soil1]?.contains(soil2) ?? false;
      
      if (compatible) {
        score = 0.7;
        reason = 'Съвместими почвени изисквания';
      } else {
        score = 0.4;
        reason = 'Различни почвени изисквания - може да се наложи подобряване на почвата';
      }
    }
    
    return _FactorScore(score, reason);
  }
  
  _FactorScore _analyzeGrowthRateCompatibility(Plant plant1, Plant plant2) {
    final growth1 = plant1.specifications.growthRate;
    final growth2 = plant2.specifications.growthRate;
    
    double score;
    String? reason;
    
    if (growth1 == growth2) {
      score = 0.9;
      reason = 'Еднакъв темп на растеж - лесно поддържане';
    } else {
      final growthRates = [GrowthRate.slow, GrowthRate.moderate, GrowthRate.fast];
      final diff = (growthRates.indexOf(growth1) - growthRates.indexOf(growth2)).abs();
      
      if (diff == 1) {
        score = 0.7;
        reason = 'Подобен темп на растеж';
      } else {
        score = 0.5;
        reason = 'Различен темп на растеж - може да се наложи различна грижа';
      }
    }
    
    return _FactorScore(score, reason);
  }
  
  double _calculateOverallScore(Map<CompatibilityFactor, double> scores) {
    if (scores.isEmpty) return 0.0;
    
    // Weighted average - some factors are more important than others
    const weights = {
      CompatibilityFactor.light: 0.25,
      CompatibilityFactor.water: 0.25,
      CompatibilityFactor.soil: 0.15,
      CompatibilityFactor.height: 0.15,
      CompatibilityFactor.color: 0.10,
      CompatibilityFactor.seasonal: 0.05,
      CompatibilityFactor.growth: 0.05,
    };
    
    double weightedSum = 0.0;
    double totalWeight = 0.0;
    
    scores.forEach((factor, score) {
      final weight = weights[factor] ?? 0.0;
      weightedSum += score * weight;
      totalWeight += weight;
    });
    
    return totalWeight > 0 ? weightedSum / totalWeight : 0.0;
  }
  
  CompatibilityLevel _determineCompatibilityLevel(double score) {
    if (score >= 0.8) return CompatibilityLevel.excellent;
    if (score >= 0.6) return CompatibilityLevel.good;
    if (score >= 0.4) return CompatibilityLevel.fair;
    return CompatibilityLevel.poor;
  }
  
  void _analyzeCombinationStrengthsAndWeaknesses(
    List<Plant> plants,
    List<CompatibilityResult> results,
    List<String> strengths,
    List<String> weaknesses,
    List<String> suggestions,
  ) {
    // Analyze light requirements
    final lightRequirements = plants.map((p) => p.characteristics.lightRequirement).toSet();
    if (lightRequirements.length == 1) {
      strengths.add('Еднакви светлинни изисквания - лесно позициониране');
    } else if (lightRequirements.length > 2) {
      weaknesses.add('Твърде различни светлинни изисквания');
      suggestions.add('Разделете растенията по зони според светлинните изисквания');
    }
    
    // Analyze water requirements
    final waterRequirements = plants.map((p) => p.characteristics.waterRequirement).toSet();
    if (waterRequirements.length == 1) {
      strengths.add('Еднакви водни изисквания - лесно поливане');
    } else if (waterRequirements.length > 2) {
      weaknesses.add('Твърде различни водни изисквания');
      suggestions.add('Групирайте растенията според водните им нужди');
    }
    
    // Analyze height variety
    final heights = plants.map((p) => p.specifications.maxHeightCm).toList()..sort();
    if (heights.length > 1) {
      final heightRange = heights.last - heights.first;
      if (heightRange > 100) {
        strengths.add('Добро разнообразие във височините - създава слоести композиции');
      }
    }
    
    // Analyze seasonal interest
    final allBloomSeasons = plants.expand((p) => p.specifications.bloomSeason).toSet();
    if (allBloomSeasons.length >= 3) {
      strengths.add('Отлично сезонно разнообразие - интерес през повечето сезони');
    } else if (allBloomSeasons.length <= 1) {
      weaknesses.add('Ограничено сезонно разнообразие');
      suggestions.add('Добавете растения, които цъфтят в други сезони');
    }
    
    // Check for low compatibility pairs
    final lowCompatibilityPairs = results.where((r) => r.overallScore < 0.5).length;
    if (lowCompatibilityPairs > 0) {
      weaknesses.add('$lowCompatibilityPairs двойки растения с ниска съвместимост');
      suggestions.add('Преразгледайте избора на растения или ги разделете в различни зони');
    }
  }
}

/// Result of compatibility analysis between two plants
class CompatibilityResult {
  final String plant1Id;
  final String plant2Id;
  final double overallScore;
  final CompatibilityLevel compatibilityLevel;
  final Map<CompatibilityFactor, double> factorScores;
  final List<String> reasons;
  
  CompatibilityResult({
    required this.plant1Id,
    required this.plant2Id,
    required this.overallScore,
    required this.compatibilityLevel,
    required this.factorScores,
    required this.reasons,
  });
}

/// Analysis of a plant combination for garden design
class PlantCombinationAnalysis {
  final List<Plant> plants;
  final double overallHarmony;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> suggestions;
  
  PlantCombinationAnalysis({
    required this.plants,
    required this.overallHarmony,
    required this.strengths,
    required this.weaknesses,
    required this.suggestions,
  });
}

/// Factors considered in compatibility analysis
enum CompatibilityFactor {
  light,
  water,
  soil,
  height,
  color,
  seasonal,
  growth,
}

/// Levels of plant compatibility
enum CompatibilityLevel {
  excellent,
  good,
  fair,
  poor,
}

/// Internal class for factor scoring
class _FactorScore {
  final double score;
  final String? reason;
  
  _FactorScore(this.score, this.reason);
}