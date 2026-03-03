import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/calculator_engine.dart';

void main() {
  group('CalculatorEngine', () {
    test('pipCalculator computes pip value in quote and account currency', () {
      final PipValueResult result = CalculatorEngine.pipCalculator(
        lotSize: 100000,
        pipSize: 0.0001,
        quoteToAccountRate: 1,
      );

      expect(result.pipValueInQuote, closeTo(10, 0.000001));
      expect(result.pipValueInAccount, closeTo(10, 0.000001));
    });

    test('positionSizeCalculator computes risk and units', () {
      final PositionSizeResult result = CalculatorEngine.positionSizeCalculator(
        accountSize: 10000,
        riskPercent: 1,
        entryPrice: 1.25,
        stopLoss: 1.245,
        takeProfit: 1.26,
      );

      expect(result.riskAmount, closeTo(100, 0.000001));
      expect(result.positionUnits, closeTo(20000, 0.000001));
      expect(result.riskRewardRatio, closeTo(2, 0.000001));
      expect(result.potentialProfit, closeTo(200, 0.000001));
    });

    test('forexRebateCalculator computes total rebate', () {
      final double rebate = CalculatorEngine.forexRebateCalculator(
        tradedLots: 5.5,
        rebatePerLot: 2,
      );

      expect(rebate, closeTo(11, 0.000001));
    });

    test('profitCalculator computes long trade result', () {
      final ProfitResult result = CalculatorEngine.profitCalculator(
        entryPrice: 1.2,
        exitPrice: 1.22,
        units: 1000,
      );

      expect(result.priceDifference, closeTo(0.02, 0.000001));
      expect(result.grossProfit, closeTo(20, 0.000001));
    });

    test('compoundProfitCalculator computes compounding growth', () {
      final CompoundProfitResult result = CalculatorEngine.compoundProfitCalculator(
        principal: 1000,
        returnRatePercent: 10,
        periods: 2,
        contributionPerPeriod: 100,
      );

      expect(result.finalBalance, closeTo(1420, 0.000001));
      expect(result.totalContributions, closeTo(1200, 0.000001));
      expect(result.totalProfit, closeTo(220, 0.000001));
    });

    test('drawdownCalculator computes drawdown and recovery', () {
      final DrawdownResult result = CalculatorEngine.drawdownCalculator(
        peakBalance: 10000,
        troughBalance: 7500,
      );

      expect(result.drawdownAmount, closeTo(2500, 0.000001));
      expect(result.drawdownPercent, closeTo(25, 0.000001));
      expect(result.recoveryPercent, closeTo(33.333333, 0.001));
    });

    test('riskOfRuinCalculator returns bounded probability', () {
      final double risk = CalculatorEngine.riskOfRuinCalculator(
        winRatePercent: 55,
        winLossRatio: 1.5,
        riskPerTradePercent: 1,
        ruinThresholdPercent: 50,
      );

      expect(risk, greaterThanOrEqualTo(0));
      expect(risk, lessThanOrEqualTo(1));
      expect(risk, lessThan(0.5));
    });

    test('pivotPointsCalculator computes classic levels', () {
      final PivotPointsResult result = CalculatorEngine.pivotPointsCalculator(
        high: 110,
        low: 100,
        close: 105,
      );

      expect(result.pp, closeTo(105, 0.000001));
      expect(result.r1, closeTo(110, 0.000001));
      expect(result.s1, closeTo(100, 0.000001));
      expect(result.r2, closeTo(115, 0.000001));
      expect(result.s2, closeTo(95, 0.000001));
      expect(result.r3, closeTo(120, 0.000001));
      expect(result.s3, closeTo(90, 0.000001));
    });

    test('fibonacciRetracementCalculator computes standard levels', () {
      final Map<double, double> levels = CalculatorEngine.fibonacciRetracementCalculator(
        high: 2,
        low: 1,
      );

      expect(levels[0.0], closeTo(2, 0.000001));
      expect(levels[0.5], closeTo(1.5, 0.000001));
      expect(levels[1.0], closeTo(1, 0.000001));
    });

    test('forexMarginCalculator computes notional and margin', () {
      final MarginResult result = CalculatorEngine.forexMarginCalculator(
        lots: 1,
        contractSize: 100000,
        leverage: 100,
        marketPrice: 1.2,
      );

      expect(result.notionalValue, closeTo(120000, 0.000001));
      expect(result.requiredMargin, closeTo(1200, 0.000001));
    });

    test('cryptoExchangeFeesCalculator computes fees and net', () {
      final FeeResult result = CalculatorEngine.cryptoExchangeFeesCalculator(
        tradeValue: 1000,
        feePercent: 0.1,
        networkFee: 2,
      );

      expect(result.tradingFee, closeTo(1, 0.000001));
      expect(result.totalFees, closeTo(3, 0.000001));
      expect(result.netAmount, closeTo(997, 0.000001));
    });

    test('converterCalculator computes gross, fee and net conversion', () {
      final ConversionResult result = CalculatorEngine.converterCalculator(
        amount: 100,
        rate: 56,
        feePercent: 1,
      );

      expect(result.grossConverted, closeTo(5600, 0.000001));
      expect(result.feeAmount, closeTo(56, 0.000001));
      expect(result.netConverted, closeTo(5544, 0.000001));
    });

    test('positionSizeCalculator throws on invalid stop distance', () {
      expect(
        () => CalculatorEngine.positionSizeCalculator(
          accountSize: 10000,
          riskPercent: 1,
          entryPrice: 1.2,
          stopLoss: 1.2,
          takeProfit: 1.25,
        ),
        throwsArgumentError,
      );
    });
  });
}
