import 'dart:math';

class PipValueResult {
  const PipValueResult({required this.pipValueInQuote, required this.pipValueInAccount});

  final double pipValueInQuote;
  final double pipValueInAccount;
}

class PositionSizeResult {
  const PositionSizeResult({
    required this.riskAmount,
    required this.positionUnits,
    required this.riskRewardRatio,
    required this.potentialProfit,
  });

  final double riskAmount;
  final double positionUnits;
  final double riskRewardRatio;
  final double potentialProfit;
}

class ProfitResult {
  const ProfitResult({required this.priceDifference, required this.grossProfit});

  final double priceDifference;
  final double grossProfit;
}

class CompoundProfitResult {
  const CompoundProfitResult({
    required this.finalBalance,
    required this.totalContributions,
    required this.totalProfit,
  });

  final double finalBalance;
  final double totalContributions;
  final double totalProfit;
}

class DrawdownResult {
  const DrawdownResult({
    required this.drawdownAmount,
    required this.drawdownPercent,
    required this.recoveryPercent,
  });

  final double drawdownAmount;
  final double drawdownPercent;
  final double recoveryPercent;
}

class PivotPointsResult {
  const PivotPointsResult({
    required this.pp,
    required this.r1,
    required this.r2,
    required this.r3,
    required this.s1,
    required this.s2,
    required this.s3,
  });

  final double pp;
  final double r1;
  final double r2;
  final double r3;
  final double s1;
  final double s2;
  final double s3;
}

class MarginResult {
  const MarginResult({required this.notionalValue, required this.requiredMargin});

  final double notionalValue;
  final double requiredMargin;
}

class FeeResult {
  const FeeResult({
    required this.tradingFee,
    required this.networkFee,
    required this.totalFees,
    required this.netAmount,
  });

  final double tradingFee;
  final double networkFee;
  final double totalFees;
  final double netAmount;
}

class ConversionResult {
  const ConversionResult({
    required this.grossConverted,
    required this.feeAmount,
    required this.netConverted,
  });

  final double grossConverted;
  final double feeAmount;
  final double netConverted;
}

class RiskByPositionResult {
  const RiskByPositionResult({
    required this.riskAmount,
    required this.lotSize,
    required this.units,
  });

  final double riskAmount;
  final double lotSize;
  final double units;
}

class CalculatorEngine {
  static PipValueResult pipCalculator({
    required double lotSize,
    required double pipSize,
    double quoteToAccountRate = 1.0,
  }) {
    _ensurePositive(lotSize, 'lotSize');
    _ensurePositive(pipSize, 'pipSize');
    _ensurePositive(quoteToAccountRate, 'quoteToAccountRate');

    final double pipValueInQuote = pipSize * lotSize;
    final double pipValueInAccount = pipValueInQuote * quoteToAccountRate;

    return PipValueResult(
      pipValueInQuote: pipValueInQuote,
      pipValueInAccount: pipValueInAccount,
    );
  }

  static PositionSizeResult positionSizeCalculator({
    required double accountSize,
    required double riskPercent,
    required double entryPrice,
    required double stopLoss,
    required double takeProfit,
    double valuePerPriceUnit = 1.0,
  }) {
    _ensurePositive(accountSize, 'accountSize');
    _ensureInRange(riskPercent, 'riskPercent', min: 0, max: 100, inclusiveMin: false);
    _ensurePositive(valuePerPriceUnit, 'valuePerPriceUnit');

    final double stopDistance = (entryPrice - stopLoss).abs();
    final double targetDistance = (takeProfit - entryPrice).abs();
    if (stopDistance == 0) {
      throw ArgumentError('entryPrice and stopLoss cannot be equal.');
    }

    final double riskAmount = accountSize * (riskPercent / 100);
    final double positionUnits = riskAmount / (stopDistance * valuePerPriceUnit);
    final double riskRewardRatio = targetDistance / stopDistance;
    final double potentialProfit = riskAmount * riskRewardRatio;

    return PositionSizeResult(
      riskAmount: riskAmount,
      positionUnits: positionUnits,
      riskRewardRatio: riskRewardRatio,
      potentialProfit: potentialProfit,
    );
  }

  static RiskByPositionResult riskByPositionCalculator({
    required double accountBalance,
    required double riskPercent,
    required double stopLossPips,
    required double pipSize,
    required double baseSize, // e.g., 100000 for standard forex lots
  }) {
    _ensurePositive(accountBalance, 'accountBalance');
    _ensureInRange(riskPercent, 'riskPercent', min: 0, max: 100, inclusiveMin: false);
    _ensurePositive(stopLossPips, 'stopLossPips');
    _ensurePositive(pipSize, 'pipSize');
    _ensurePositive(baseSize, 'baseSize');

    // Calculate risk amount
    final double riskAmount = accountBalance * (riskPercent / 100);

    // Calculate pip value per lot for the base size
    final double pipValuePerLot = pipSize * baseSize;

    // Calculate lot size needed for the desired risk
    final double lotSize = riskAmount / (stopLossPips * pipValuePerLot);

    // Calculate total units
    final double units = lotSize * baseSize;

    return RiskByPositionResult(
      riskAmount: riskAmount,
      lotSize: lotSize,
      units: units,
    );
  }

  static double forexRebateCalculator({
    required double tradedLots,
    required double rebatePerLot,
  }) {
    _ensureNonNegative(tradedLots, 'tradedLots');
    _ensureNonNegative(rebatePerLot, 'rebatePerLot');
    return tradedLots * rebatePerLot;
  }

  static ProfitResult profitCalculator({
    required double entryPrice,
    required double exitPrice,
    required double units,
    bool isLong = true,
    double pointValue = 1.0,
  }) {
    _ensurePositive(units, 'units');
    _ensurePositive(pointValue, 'pointValue');

    final double rawDifference = isLong ? (exitPrice - entryPrice) : (entryPrice - exitPrice);
    final double grossProfit = rawDifference * units * pointValue;

    return ProfitResult(priceDifference: rawDifference, grossProfit: grossProfit);
  }

  static CompoundProfitResult compoundProfitCalculator({
    required double principal,
    required double returnRatePercent,
    required int periods,
    double contributionPerPeriod = 0,
  }) {
    _ensureNonNegative(principal, 'principal');
    _ensureNonNegative(periods.toDouble(), 'periods');
    _ensureNonNegative(contributionPerPeriod, 'contributionPerPeriod');

    final double rate = returnRatePercent / 100;
    final double compoundFactor = pow(1 + rate, periods).toDouble();

    final double principalGrowth = principal * compoundFactor;
    final double contributionsGrowth;

    if (periods == 0) {
      contributionsGrowth = 0;
    } else if (rate == 0) {
      contributionsGrowth = contributionPerPeriod * periods;
    } else {
      contributionsGrowth = contributionPerPeriod * ((compoundFactor - 1) / rate);
    }

    final double finalBalance = principalGrowth + contributionsGrowth;
    final double totalContributions = principal + (contributionPerPeriod * periods);
    final double totalProfit = finalBalance - totalContributions;

    return CompoundProfitResult(
      finalBalance: finalBalance,
      totalContributions: totalContributions,
      totalProfit: totalProfit,
    );
  }

  static DrawdownResult drawdownCalculator({
    required double peakBalance,
    required double troughBalance,
  }) {
    _ensurePositive(peakBalance, 'peakBalance');
    _ensureNonNegative(troughBalance, 'troughBalance');
    if (troughBalance > peakBalance) {
      throw ArgumentError('troughBalance cannot exceed peakBalance.');
    }

    final double drawdownAmount = peakBalance - troughBalance;
    final double drawdownPercent = (drawdownAmount / peakBalance) * 100;
    final double drawdownDecimal = drawdownPercent / 100;
    final double recoveryPercent =
        drawdownDecimal >= 1 ? double.infinity : (drawdownDecimal / (1 - drawdownDecimal)) * 100;

    return DrawdownResult(
      drawdownAmount: drawdownAmount,
      drawdownPercent: drawdownPercent,
      recoveryPercent: recoveryPercent,
    );
  }

  static double riskOfRuinCalculator({
    required double winRatePercent,
    required double winLossRatio,
    required double riskPerTradePercent,
    double ruinThresholdPercent = 50,
  }) {
    _ensureInRange(winRatePercent, 'winRatePercent', min: 0, max: 100);
    _ensurePositive(winLossRatio, 'winLossRatio');
    _ensureInRange(riskPerTradePercent, 'riskPerTradePercent', min: 0, max: 100, inclusiveMin: false);
    _ensureInRange(ruinThresholdPercent, 'ruinThresholdPercent', min: 0, max: 100, inclusiveMin: false);

    final double p = winRatePercent / 100;
    final double q = 1 - p;
    final double effectiveWinProbability = (p * winLossRatio) / ((p * winLossRatio) + q);
    final double effectiveLossProbability = 1 - effectiveWinProbability;

    if (effectiveWinProbability <= effectiveLossProbability) {
      return 1;
    }

    final double riskPerTrade = riskPerTradePercent / 100;
    final double threshold = ruinThresholdPercent / 100;

    final double tradesToRuin = log(1 - threshold) / log(1 - riskPerTrade);
    final double lossWinRatio = effectiveLossProbability / effectiveWinProbability;

    return pow(lossWinRatio, tradesToRuin).toDouble().clamp(0, 1);
  }

  static PivotPointsResult pivotPointsCalculator({
    required double high,
    required double low,
    required double close,
  }) {
    if (low > high) {
      throw ArgumentError('low cannot be greater than high.');
    }

    final double pp = (high + low + close) / 3;
    final double r1 = (2 * pp) - low;
    final double s1 = (2 * pp) - high;
    final double r2 = pp + (high - low);
    final double s2 = pp - (high - low);
    final double r3 = high + (2 * (pp - low));
    final double s3 = low - (2 * (high - pp));

    return PivotPointsResult(pp: pp, r1: r1, r2: r2, r3: r3, s1: s1, s2: s2, s3: s3);
  }

  static Map<double, double> fibonacciRetracementCalculator({
    required double high,
    required double low,
    bool fromHighToLow = true,
  }) {
    if (low > high) {
      throw ArgumentError('low cannot be greater than high.');
    }

    final Map<double, double> levels = <double, double>{};
    const List<double> ratios = <double>[0.0, 0.236, 0.382, 0.5, 0.618, 0.786, 1.0];

    final double range = high - low;
    for (final double ratio in ratios) {
      levels[ratio] = fromHighToLow ? high - (range * ratio) : low + (range * ratio);
    }

    return levels;
  }

  static MarginResult forexMarginCalculator({
    required double lots,
    required double contractSize,
    required double leverage,
    required double marketPrice,
  }) {
    _ensurePositive(lots, 'lots');
    _ensurePositive(contractSize, 'contractSize');
    _ensurePositive(leverage, 'leverage');
    _ensurePositive(marketPrice, 'marketPrice');

    final double notionalValue = lots * contractSize * marketPrice;
    final double requiredMargin = notionalValue / leverage;

    return MarginResult(notionalValue: notionalValue, requiredMargin: requiredMargin);
  }

  static FeeResult cryptoExchangeFeesCalculator({
    required double tradeValue,
    required double feePercent,
    double networkFee = 0,
  }) {
    _ensureNonNegative(tradeValue, 'tradeValue');
    _ensureNonNegative(feePercent, 'feePercent');
    _ensureNonNegative(networkFee, 'networkFee');

    final double tradingFee = tradeValue * (feePercent / 100);
    final double totalFees = tradingFee + networkFee;
    final double netAmount = tradeValue - totalFees;

    return FeeResult(
      tradingFee: tradingFee,
      networkFee: networkFee,
      totalFees: totalFees,
      netAmount: netAmount,
    );
  }

  static ConversionResult converterCalculator({
    required double amount,
    required double rate,
    double feePercent = 0,
  }) {
    _ensureNonNegative(amount, 'amount');
    _ensurePositive(rate, 'rate');
    _ensureNonNegative(feePercent, 'feePercent');

    final double grossConverted = amount * rate;
    final double feeAmount = grossConverted * (feePercent / 100);
    final double netConverted = grossConverted - feeAmount;

    return ConversionResult(
      grossConverted: grossConverted,
      feeAmount: feeAmount,
      netConverted: netConverted,
    );
  }

  static void _ensurePositive(double value, String name) {
    if (value <= 0) {
      throw ArgumentError('$name must be greater than 0.');
    }
  }

  static void _ensureNonNegative(double value, String name) {
    if (value < 0) {
      throw ArgumentError('$name must be non-negative.');
    }
  }

  static void _ensureInRange(
    double value,
    String name, {
    required double min,
    required double max,
    bool inclusiveMin = true,
    bool inclusiveMax = true,
  }) {
    final bool minValid = inclusiveMin ? value >= min : value > min;
    final bool maxValid = inclusiveMax ? value <= max : value < max;
    if (!minValid || !maxValid) {
      throw ArgumentError('$name must be in range $min to $max.');
    }
  }
}
