// test/get_data_integration_test.dart

import 'package:crypto_scanner/core/service_locator.dart';
import 'package:crypto_scanner/data/datasources/get_api_data.dart';
import 'package:crypto_scanner/data/models/coin.dart';
import 'package:crypto_scanner/data/models/coins.dart';
import 'package:crypto_scanner/data/models/kline.dart';
import 'package:crypto_scanner/data/models/klines.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Группа интеграционных тестов для GetApiData, требующих сетевого подключения
  group('GetData Integration Tests (Requires Network)', () {
    GetApiData? getData;

    // Настройка перед всеми тестами в группе
    setUpAll(() async {
      // Инициализация service locator для доступа к зависимостям
      await setupLocator();
      // Получение экземпляра GetApiData из service locator
      getData = getIt<GetApiData>();
    });

    // Тест 1: Проверка получения списка всех монет
    test('getCoins() fetches real data and returns non-empty Coins', () async {
      // Вызов метода для получения данных о монетах
      final result = await getData!.getCoins();

      // Проверки на корректность полученных данных
      expect(result, isNotNull, reason: 'Результат не должен быть null');
      expect(result, isA<Coins>(), reason: 'Результат должен быть типа Coins');
      expect(
        result!.coins.isNotEmpty,
        isTrue,
        reason: 'Список монет (coins) не должен быть пустым.',
      );
      expect(
        result.coins.first,
        isA<Coin>(),
        reason: 'Элементы списка должны быть типа Coin',
      );
      expect(
        result.coins.first.coinName,
        isNotNull,
        reason: 'Имя монеты не должно быть null',
      );
    });

    // Тест 2: Проверка получения исторических данных (Klines) для конкретной монеты
    test(
      'getKlines() fetches real data with parameters and returns non-empty Klines',
      () async {
        // Определение параметров для запроса
        const testSymbol = 'BTCUSDT';
        const testInterval = 60;
        const testLimit = 10;

        // Вызов метода для получения Klines
        final result = await getData!.getKlines(
          symbol: testSymbol,
          interval: testInterval,
          limit: testLimit,
        );

        // Проверки на корректность полученных данных
        expect(result, isNotNull, reason: 'Результат не должен быть null');
        expect(result, isA<Klines>(),
            reason: 'Результат должен быть типа Klines');
        expect(
          result!.kLines.isNotEmpty,
          isTrue,
          reason: 'Список Klines не должен быть пустым.',
        );

        // Проверка первого элемента в списке Klines
        final firstKline = result.kLines.first;
        expect(firstKline, isA<Kline>());
        expect(
          firstKline.time,
          isNotNull,
          reason: 'Время в Kline не должно быть null',
        );
      },
    );
  });
}
