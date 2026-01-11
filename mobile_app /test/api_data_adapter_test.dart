import 'package:crypto_scanner/data/datasources/api_data_adapter.dart';
import 'package:crypto_scanner/data/datasources/get_api_data.dart';
import 'package:crypto_scanner/data/models/coin.dart';
import 'package:crypto_scanner/data/models/coins.dart';
import 'package:crypto_scanner/data/models/kline.dart';
import 'package:crypto_scanner/data/models/klines.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'api_data_adapter_test.mocks.dart';

// Аннотация для генерации мок-классов
@GenerateMocks([GetApiData, Logger, Dio])
void main() {
  late MockGetApiData mockGetApiData;
  late MockLogger mockLogger;
  late MockDio mockDio;
  late ApiDataAdapter apiDataAdapter;
  final getIt = GetIt.instance;

  // Настройка перед каждым тестом
  setUp(() {
    // Сброс GetIt для изоляции тестов
    getIt.reset();
    // Создание мок-объектов
    mockGetApiData = MockGetApiData();
    mockLogger = MockLogger();
    mockDio = MockDio();

    // Регистрация моков в GetIt
    getIt.registerSingleton<MockGetApiData>(mockGetApiData);
    getIt.registerSingleton<MockLogger>(mockLogger);
    getIt.registerSingleton<MockDio>(mockDio);

    // Создание экземпляра ApiDataAdapter с моками
    apiDataAdapter = ApiDataAdapter(
      logger: mockLogger,
      getApiData: mockGetApiData,
    );

    // Подавление вывода ошибок логгера во время тестов
    when(
      mockLogger.e(
        any,
        error: anyNamed('error'),
        stackTrace: anyNamed('stackTrace'),
      ),
    ).thenAnswer((_) {});
  });

  // Группа тестов для ApiDataAdapter
  group('ApiDataAdapter', () {
    // Группа тестов для метода getAllCoins
    group('getAllCoins', () {
      // Тестовые данные
      const tCoins = Coins(
        coins: [
          Coin(symbol: 'BTC'),
          Coin(symbol: 'ETH'),
        ],
      );

      // Тест на успешное получение данных
      test(
        'should return Coins when the call to GetApiData is successful',
        () async {
          // Arrange: Настройка мока для возврата тестовых данных
          when(mockGetApiData.getCoins()).thenAnswer((_) async => tCoins);
          // Act: Вызов тестируемого метода
          final result = await apiDataAdapter.getAllCoins();
          // Assert: Проверка результата
          expect(result, tCoins);
          verify(mockGetApiData.getCoins());
          verifyNoMoreInteractions(mockGetApiData);
        },
      );

      // Тест на случай, когда GetApiData возвращает null
      test(
        'should return null when the call to GetApiData returns null',
        () async {
          // Arrange: Настройка мока для возврата null
          when(mockGetApiData.getCoins()).thenAnswer((_) async => null);
          // Act: Вызов метода
          final result = await apiDataAdapter.getAllCoins();
          // Assert: Проверка, что результат null
          expect(result, isNull);
        },
      );

      // Тест на случай, когда GetApiData возвращает пустой список
      test(
        'should return null when the call to GetApiData returns empty list',
        () async {
          // Arrange: Настройка мока для возврата пустого списка
          when(
            mockGetApiData.getCoins(),
          ).thenAnswer((_) async => const Coins(coins: []));
          // Act: Вызов метода
          final result = await apiDataAdapter.getAllCoins();
          // Assert: Проверка, что результат null
          expect(result, isNull);
        },
      );

      // Тест на обработку исключений
      test(
        'should rethrow and log error when GetApiData throws an exception',
        () async {
          // Arrange: Настройка мока для генерации исключения
          final tException = Exception('API Error');
          when(mockGetApiData.getCoins()).thenThrow(tException);
          // Act & Assert: Проверка, что метод генерирует исключение и логирует ошибку
          expect(() => apiDataAdapter.getAllCoins(), throwsA(isA<Exception>()));
          verify(
            mockLogger.e(
              'devlog_ApiDataAdapter_getAllCoins:',
              error: tException,
            ),
          ).called(1);
        },
      );
    });

    // Группа тестов для метода getCoinKlines
    group('getCoinKlines', () {
      const tSymbol = 'BTCUSDT';
      const tInterval = 1;
      const tLimit = 100;
      final tKlines = Klines(
        symbol: tSymbol,
        kLines: [Kline(open: 1), Kline(open: 2)],
        kLineInterval: tInterval,
        kLineAmount: tLimit,
      );

      // Тест на успешное получение Klines
      test(
        'should return Klines when the call to GetApiData is successful',
        () async {
          // Arrange: Настройка мока для возврата тестовых данных
          when(
            mockGetApiData.getKlines(
              symbol: tSymbol,
              interval: tInterval,
              limit: tLimit,
            ),
          ).thenAnswer((_) async => tKlines);
          // Act: Вызов метода
          final result = await apiDataAdapter.getCoinKlines(
            symbol: tSymbol,
            interval: tInterval,
            limit: tLimit,
          );
          // Assert: Проверка результата
          expect(result, tKlines);
          verify(
            mockGetApiData.getKlines(
              symbol: tSymbol,
              interval: tInterval,
              limit: tLimit,
            ),
          );
          verifyNoMoreInteractions(mockGetApiData);
        },
      );

      // Тест на обработку неверного интервала
      test('should return null if interval is null or zero', () async {
        // Act: Вызов метода с неверным интервалом
        final resultNull = await apiDataAdapter.getCoinKlines(
          symbol: tSymbol,
          interval: null,
          limit: tLimit,
        );
        final resultZero = await apiDataAdapter.getCoinKlines(
          symbol: tSymbol,
          interval: 0,
          limit: tLimit,
        );
        // Assert: Проверка, что результат null и метод getKlines не вызывался
        expect(resultNull, isNull);
        expect(resultZero, isNull);
        verifyNever(
          mockGetApiData.getKlines(
            symbol: anyNamed('symbol'),
            interval: anyNamed('interval'),
            limit: anyNamed('limit'),
          ),
        );
      });

      // Тест на обработку неверного лимита
      test('should return null if limit is null or zero', () async {
        // Act: Вызов метода с неверным лимитом
        final resultNull = await apiDataAdapter.getCoinKlines(
          symbol: tSymbol,
          interval: tInterval,
          limit: null,
        );
        final resultZero = await apiDataAdapter.getCoinKlines(
          symbol: tSymbol,
          interval: tInterval,
          limit: 0,
        );
        // Assert: Проверка, что результат null и метод getKlines не вызывался
        expect(resultNull, isNull);
        expect(resultZero, isNull);
        verifyNever(
          mockGetApiData.getKlines(
            symbol: anyNamed('symbol'),
            interval: anyNamed('interval'),
            limit: anyNamed('limit'),
          ),
        );
      });

      // Тест на случай, когда GetApiData возвращает null
      test('should return null when GetApiData returns null', () async {
        // Arrange: Настройка мока для возврата null
        when(
          mockGetApiData.getKlines(
            symbol: tSymbol,
            interval: tInterval,
            limit: tLimit,
          ),
        ).thenAnswer((_) async => null);
        // Act: Вызов метода
        final result = await apiDataAdapter.getCoinKlines(
          symbol: tSymbol,
          interval: tInterval,
          limit: tLimit,
        );
        // Assert: Проверка, что результат null
        expect(result, isNull);
      });

      // Тест на случай, когда GetApiData возвращает пустой список
      test('should return null when GetApiData returns empty list', () async {
        // Arrange: Настройка мока для возврата пустого списка
        when(
          mockGetApiData.getKlines(
            symbol: tSymbol,
            interval: tInterval,
            limit: tLimit,
          ),
        ).thenAnswer(
          (_) async => const Klines(
            symbol: tSymbol,
            kLines: [],
            kLineInterval: tInterval,
            kLineAmount: tLimit,
          ),
        );
        // Act: Вызов метода
        final result = await apiDataAdapter.getCoinKlines(
          symbol: tSymbol,
          interval: tInterval,
          limit: tLimit,
        );
        // Assert: Проверка, что результат null
        expect(result, isNull);
      });

      // Тест на обработку исключений
      test(
        'should rethrow and log error when GetApiData throws an exception',
        () async {
          // Arrange: Настройка мока для генерации исключения
          final tException = Exception('API Error');
          when(
            mockGetApiData.getKlines(
              symbol: tSymbol,
              interval: tInterval,
              limit: tLimit,
            ),
          ).thenThrow(tException);
          // Act & Assert: Проверка, что метод генерирует исключение и логирует ошибку
          expect(
            () => apiDataAdapter.getCoinKlines(
              symbol: tSymbol,
              interval: tInterval,
              limit: tLimit,
            ),
            throwsA(isA<Exception>()),
          );
          verify(
            mockLogger.e(
              'devlog_ApiDataAdapter_getCoinKlines:',
              error: tException,
            ),
          ).called(1);
        },
      );
    });
  });
}
