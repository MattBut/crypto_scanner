import 'package:crypto_scanner/data/datasources/api_data_adapter.dart';
import 'package:crypto_scanner/data/datasources/db_control_adapter.dart';
import 'package:crypto_scanner/data/mappers/data_convertor.dart';
import 'package:crypto_scanner/data/models/coin.dart';
import 'package:crypto_scanner/data/models/coins.dart';
import 'package:crypto_scanner/data/models/db_schema.dart';
import 'package:crypto_scanner/data/models/kline.dart';
import 'package:crypto_scanner/data/models/klines.dart';
import 'package:crypto_scanner/data/models/map_coin.dart';
import 'package:crypto_scanner/data/models/map_coins.dart';
import 'package:crypto_scanner/data/models/map_kline.dart';
import 'package:crypto_scanner/data/models/map_klines.dart';
import 'package:crypto_scanner/data/repositories/coin_repository_impl.dart';
import 'package:crypto_scanner/domain/entities/coin_entity.dart';
import 'package:crypto_scanner/domain/entities/coins_entity.dart';
import 'package:crypto_scanner/domain/entities/data_field.dart';
import 'package:crypto_scanner/domain/entities/work_space.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'coin_repository_impl_test.mocks.dart';

// Аннотация для генерации мок-классов
@GenerateMocks([
  ApiDataAdapter,
  DataConvertor,
  Logger,
  DbSchema,
  DbControlAdapter,
])
main() {
  late CoinRepositoryImpl repository;
  late MockApiDataAdapter mockApiDataAdapter;
  late MockDbControlAdapter mockDbControlAdapter;
  late MockDataConvertor mockDataConvertor;
  late MockLogger mockLogger;
  late MockDbSchema mockDbSchema;

  // Тестовые данные
  const tTableName = 'all_coins';
  const tWorkSpace = WorkSpace.allCoins;
  const tSymbol = 'BTCUSDT';
  const tCoin = Coin(symbol: tSymbol);
  const tCoins = Coins(coins: [tCoin]);
  const tMapCoin = MapCoin(symbol: tSymbol);
  const tMapCoins = MapCoins(coins: [tMapCoin]);
  const tCoinEntity = CoinEntity(symbol: tSymbol);
  const tCoinsEntity = CoinsEntity(coins: [tCoinEntity]);

  const tColumnName = 'symbol';

  // Настройка перед каждым тестом
  setUp(() {
    mockApiDataAdapter = MockApiDataAdapter();
    mockDbControlAdapter = MockDbControlAdapter();
    mockDataConvertor = MockDataConvertor();
    mockLogger = MockLogger();
    mockDbSchema = MockDbSchema();

    // Инициализация репозитория с моками
    repository = CoinRepositoryImpl(
      apiDataAdapter: mockApiDataAdapter,
      dbControlAdapter: mockDbControlAdapter,
      dataConvertor: mockDataConvertor,
      logger: mockLogger,
      dbSchema: mockDbSchema,
    );

    // Настройка моков
    when(mockLogger.e(any, error: anyNamed('error'))).thenAnswer((_) {});
    when(
      mockDataConvertor.fromWorkSpaceToTableName(
        workSpace: anyNamed('workSpace'),
      ),
    ).thenReturn(tTableName);
    when(mockDataConvertor.fromCoinsToMapCoins(any)).thenReturn(tMapCoins);
    when(
      mockDbControlAdapter.isTableEmpty(tableName: anyNamed('tableName')),
    ).thenAnswer((_) async => false);
    when(
      mockDbControlAdapter.getDbMultipleData(tableName: anyNamed('tableName')),
    ).thenAnswer((_) async => tMapCoins);
    when(
      mockDbControlAdapter.addMultipleDbData(
        tableName: anyNamed('tableName'),
        mapCoins: anyNamed('mapCoins'),
      ),
    ).thenAnswer((_) async => true);
    when(mockDbSchema.getColumnName(any)).thenReturn(tColumnName);
    when(
      mockDbControlAdapter.updateMultipleDbData(
        tableName: anyNamed('tableName'),
        tableData: anyNamed('tableData'),
        updateWhereFieldIs: anyNamed('updateWhereFieldIs'),
      ),
    ).thenAnswer((_) async => true);
    when(
      mockDbControlAdapter.updateDbData(
        tableName: anyNamed('tableName'),
        tableData: anyNamed('tableData'),
        where: anyNamed('where'),
        whereArgs: anyNamed('whereArgs'),
      ),
    ).thenAnswer((_) async => true);
  });

  // Группа тестов для метода clearTableData
  group('clearTableData', () {
    // Тест на успешную очистку таблицы
    test('should return true when table clearing is successful', () async {
      // Arrange
      when(
        mockDbControlAdapter.clearTableData(tableName: anyNamed('tableName')),
      ).thenAnswer((_) async => true);
      // Act
      final result = await repository.clearSpaceData(workSpace: tWorkSpace);
      // Assert
      expect(result, true);
      verify(mockDbControlAdapter.clearTableData(tableName: tTableName));
    });

    // Тест на неудачную очистку таблицы
    test('should return false when table clearing fails', () async {
      // Arrange
      when(
        mockDbControlAdapter.clearTableData(tableName: anyNamed('tableName')),
      ).thenAnswer((_) async => false);
      // Act
      final result = await repository.clearSpaceData(workSpace: tWorkSpace);
      // Assert
      expect(result, false);
      verify(mockDbControlAdapter.clearTableData(tableName: tTableName));
    });

    // Тест на обработку исключений
    test(
      'should rethrow and log error when db adapter throws an exception',
      () async {
        // Arrange
        final tException = Exception('DB Error');
        when(
          mockDbControlAdapter.clearTableData(tableName: anyNamed('tableName')),
        ).thenThrow(tException);
        // Act & Assert
        expect(
          () => repository.clearSpaceData(workSpace: tWorkSpace),
          throwsA(isA<Exception>()),
        );
        verify(
          mockLogger.e(
            'devlog_CoinRepositoryImpl_clearTableData:',
            error: tException,
          ),
        ).called(1);
      },
    );
  });

  // Группа тестов для метода isTableEmpty
  group('isTableEmpty', () {
    // Тест на случай, когда таблица пуста
    test('should return true when table is empty', () async {
      // Arrange
      when(
        mockDbControlAdapter.isTableEmpty(tableName: anyNamed('tableName')),
      ).thenAnswer((_) async => true);
      // Act
      final result = await repository.isSpaceEmpty(workSpace: tWorkSpace);
      // Assert
      expect(result, true);
      verify(mockDbControlAdapter.isTableEmpty(tableName: tTableName));
    });

    // Тест на случай, когда таблица не пуста
    test('should return false when table is not empty', () async {
      // Arrange
      when(
        mockDbControlAdapter.isTableEmpty(tableName: anyNamed('tableName')),
      ).thenAnswer((_) async => false);
      // Act
      final result = await repository.isSpaceEmpty(workSpace: tWorkSpace);
      // Assert
      expect(result, false);
      verify(mockDbControlAdapter.isTableEmpty(tableName: tTableName));
    });

    // Тест на обработку исключений
    test(
      'should rethrow and log error when db adapter throws an exception',
      () async {
        // Arrange
        final tException = Exception('DB Error');
        when(
          mockDbControlAdapter.isTableEmpty(tableName: anyNamed('tableName')),
        ).thenThrow(tException);
        // Act & Assert
        expect(
          () => repository.isSpaceEmpty(workSpace: tWorkSpace),
          throwsA(isA<Exception>()),
        );
        verify(
          mockLogger.e(
            'devlog_CoinRepositoryImpl_isTableEmpty:',
            error: tException,
          ),
        ).called(1);
      },
    );
  });

  // Группа тестов для метода initTables
  group('initTables', () {
    // Тест на успешную инициализацию таблиц
    test(
      'should return true when table initialization is successful',
      () async {
        // Arrange
        when(
          mockDbControlAdapter.initTables(tables: anyNamed('tables')),
        ).thenAnswer((_) async => true);
        // Act
        final result = await repository.initSpaces();
        // Assert
        expect(result, true);
        verify(mockDbControlAdapter.initTables(tables: anyNamed('tables')));
      },
    );

    // Тест на обработку исключений
    test(
      'should rethrow and log error when db adapter throws an exception',
      () async {
        // Arrange
        final tException = Exception('DB Init Error');
        when(
          mockDbControlAdapter.initTables(tables: anyNamed('tables')),
        ).thenThrow(tException);
        // Act & Assert
        expect(() => repository.initSpaces(), throwsA(isA<Exception>()));
        verify(
          mockLogger.e(
            'devlog_CoinRepositoryImpl_initTables:',
            error: tException,
          ),
        ).called(1);
      },
    );
  });

  // Группа тестов для метода findCoinFromApi
  group('findCoinFromApi', () {
    // Тест на успешный поиск монеты
    test('should return true when coin is found', () async {
      // Arrange
      when(mockApiDataAdapter.getAllCoins()).thenAnswer((_) async => tCoins);
      // Act
      final result = await repository.findCoinFromApi(symbol: tSymbol);
      // Assert
      expect(result, true);
      verify(mockApiDataAdapter.getAllCoins());
    });

    // Тест на случай, когда монета не найдена
    test('should return false when coin is not found', () async {
      // Arrange
      when(
        mockApiDataAdapter.getAllCoins(),
      ).thenAnswer((_) async => const Coins(coins: []));
      // Act
      final result = await repository.findCoinFromApi(symbol: tSymbol);
      // Assert
      expect(result, false);
      verify(mockApiDataAdapter.getAllCoins());
    });

    // Тест на случай, когда API возвращает null
    test('should return null when api returns null', () async {
      // Arrange
      when(mockApiDataAdapter.getAllCoins()).thenAnswer((_) async => null);
      // Act
      final result = await repository.findCoinFromApi(symbol: tSymbol);
      // Assert
      expect(result, isNull);
      verify(mockApiDataAdapter.getAllCoins());
    });

    // Тест на обработку исключений
    test('should rethrow and log error when api throws an exception', () async {
      // Arrange
      final tException = Exception('API Error');
      when(mockApiDataAdapter.getAllCoins()).thenThrow(tException);
      // Act & Assert
      expect(
        () => repository.findCoinFromApi(symbol: tSymbol),
        throwsA(isA<Exception>()),
      );
      verify(
        mockLogger.e(
          'devlog_CoinRepositoryImpl_findCoinFromApi:',
          error: tException,
        ),
      ).called(1);
    });
  });

  // Группа тестов для метода getCoinFromApi
  group('getCoinFromApi', () {
    // Тест на успешное получение монеты
    test('should return coin entity when api call is successful', () async {
      // Arrange
      when(mockApiDataAdapter.getAllCoins()).thenAnswer((_) async => tCoins);
      when(mockDataConvertor.fromCoinToCoinEntity(any)).thenReturn(tCoinEntity);
      // Act
      final result = await repository.getCoinFromApi(symbol: tSymbol);
      // Assert
      expect(result, tCoinEntity);
      verify(mockApiDataAdapter.getAllCoins());
      verify(mockDataConvertor.fromCoinToCoinEntity(tCoin));
    });

    // Тест на случай, когда API возвращает null
    test('should return null when api returns null', () async {
      // Arrange
      when(mockApiDataAdapter.getAllCoins()).thenAnswer((_) async => null);
      // Act
      final result = await repository.getCoinFromApi(symbol: tSymbol);
      // Assert
      expect(result, isNull);
      verify(mockApiDataAdapter.getAllCoins());
      verifyZeroInteractions(mockDataConvertor);
    });

    // Тест на случай, когда монета не найдена
    test('should return null when coin is not found', () async {
      // Arrange
      when(mockApiDataAdapter.getAllCoins()).thenAnswer((_) async => tCoins);
      when(
        mockDataConvertor.fromCoinToCoinEntity(any),
      ).thenReturn(CoinEntity.empty()); // Simulate not found
      // Act
      final result = await repository.getCoinFromApi(symbol: 'NONEXISTENT');
      // Assert
      expect(result, isNull);
    });

    // Тест на обработку исключений
    test('should rethrow and log error when api throws an exception', () async {
      // Arrange
      final tException = Exception('API Error');
      when(mockApiDataAdapter.getAllCoins()).thenThrow(tException);
      // Act & Assert
      expect(
        () => repository.getCoinFromApi(symbol: tSymbol),
        throwsA(isA<Exception>()),
      );
      verify(
        mockLogger.e(
          'devlog_CoinRepositoryImpl_getCoinFromApi:',
          error: tException,
        ),
      ).called(1);
    });
  });

  // Группа тестов для метода getCoinsFromApi
  group('getCoinsFromApi', () {
    // Тест на успешное получение списка монет
    test('should return coins entity when api call is successful', () async {
      // Arrange
      when(mockApiDataAdapter.getAllCoins()).thenAnswer((_) async => tCoins);
      when(
        mockDataConvertor.fromCoinsToCoinsEntity(any),
      ).thenReturn(tCoinsEntity);
      // Act
      final result = await repository.getCoinsFromApi();
      // Assert
      expect(result, tCoinsEntity);
      verify(mockApiDataAdapter.getAllCoins());
      verify(mockDataConvertor.fromCoinsToCoinsEntity(tCoins));
      verifyNoMoreInteractions(mockApiDataAdapter);
      verifyNoMoreInteractions(mockDataConvertor);
    });

    // Тест на случай, когда API возвращает null
    test('should return empty coins entity when api returns null', () async {
      // Arrange
      when(mockApiDataAdapter.getAllCoins()).thenAnswer((_) async => null);
      when(
        mockDataConvertor.fromCoinsToCoinsEntity(any),
      ).thenReturn(const CoinsEntity(coins: []));
      // Act
      final result = await repository.getCoinsFromApi();
      // Assert
      expect(result, isA<CoinsEntity>());
      expect(result?.coins.isEmpty, true);
      verify(mockApiDataAdapter.getAllCoins());
      verify(
        mockDataConvertor.fromCoinsToCoinsEntity(
          argThat(predicate<Coins>((c) => c.coins.isEmpty)),
        ),
      );
    });

    // Тест на обработку исключений
    test('should rethrow and log error when api throws an exception', () async {
      // Arrange
      final tException = Exception('API Error');
      when(mockApiDataAdapter.getAllCoins()).thenThrow(tException);
      // Act & Assert
      expect(() => repository.getCoinsFromApi(), throwsA(isA<Exception>()));
      verify(
        mockLogger.e(
          'devlog_CoinRepositoryImpl_getCoinsFromApi:',
          error: tException,
        ),
      ).called(1);
    });
  });

  // Группа тестов для метода updateDbCoinsFromApi
  group('updateDbCoinsFromApi', () {
    // Тест на обновление всех монет
    test('should update all coins', () async {
      // arrange
      const tCoin2 = Coin(symbol: 'ETHUSDT');
      const tCoins2 = Coins(coins: [tCoin, tCoin2]);
      const tMapCoin2 = MapCoin(symbol: 'ETHUSDT');
      const tMapCoins2 = MapCoins(coins: [tMapCoin, tMapCoin2]);
      when(mockDataConvertor.fromCoinsToMapCoins(any)).thenReturn(tMapCoins2);
      when(mockApiDataAdapter.getAllCoins()).thenAnswer((_) async => tCoins2);
      when(
        mockDbControlAdapter.updateMultipleDbData(
          tableName: anyNamed('tableName'),
          tableData: anyNamed('tableData'),
          updateWhereFieldIs: anyNamed('updateWhereFieldIs'),
        ),
      ).thenAnswer((_) async => true);

      // act
      final result = await repository.updateSpaceCoinsFromApi(
        workSpace: tWorkSpace,
      );

      // assert
      expect(result, isTrue);
      verify(mockApiDataAdapter.getAllCoins()).called(1);
      verify(
        mockDbControlAdapter.updateMultipleDbData(
          tableName: tTableName,
          tableData: tMapCoins2.toMap(),
          updateWhereFieldIs: 'symbol',
        ),
      ).called(1);
    });

    // Тест на случай, когда API возвращает null
    test('should return null if api returns null', () async {
      // arrange
      when(mockApiDataAdapter.getAllCoins()).thenAnswer((_) async => null);
      // act
      final result = await repository.updateSpaceCoinsFromApi(
        workSpace: tWorkSpace,
      );
      // assert
      expect(result, isNull);
    });

    // Тест на обработку исключений
    test('should rethrow and log error when api throws an exception', () async {
      // arrange
      final tException = Exception('API Error');
      when(mockApiDataAdapter.getAllCoins()).thenThrow(tException);
      // act & assert
      expect(
        () => repository.updateSpaceCoinsFromApi(workSpace: tWorkSpace),
        throwsA(isA<Exception>()),
      );
      verify(
        mockLogger.e(
          'devlog_CoinRepositoryImpl_updateSpaceCoinsFromApi:',
          error: tException,
        ),
      ).called(1);
    });
  });

  // Группа тестов для метода updateDbCoin
  group('updateDbCoin', () {
    // Тест на случай, когда монета не найдена в БД
    test('should return false if coin is not found in db', () async {
      // arrange
      when(
        mockDbControlAdapter.findDbData(
          tableName: anyNamed('tableName'),
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        ),
      ).thenAnswer((_) async => false);
      // act
      final result = await repository.updateSpaceCoin(
        workSpace: tWorkSpace,
        coinEntity: tCoinEntity,
      );
      // assert
      expect(result, isNull);
      verify(
        mockDbControlAdapter.findDbData(
          tableName: tTableName,
          where: 'symbol=?',
          whereArgs: [tSymbol],
        ),
      );
      verifyNoMoreInteractions(mockDbControlAdapter);
    });

    // Тест на успешное обновление монеты
    test(
      'should return true if coin is updated successfully (no klines)',
      () async {
        // arrange
        when(
          mockDbControlAdapter.findDbData(
            tableName: anyNamed('tableName'),
            where: anyNamed('where'),
            whereArgs: anyNamed('whereArgs'),
          ),
        ).thenAnswer((_) async => true);
        when(
          mockDataConvertor.fromCoinEntityToMapCoin(any),
        ).thenReturn(tMapCoin);
        when(
          mockDbControlAdapter.updateDbData(
            tableName: anyNamed('tableName'),
            tableData: anyNamed('tableData'),
            where: anyNamed('where'),
            whereArgs: anyNamed('whereArgs'),
          ),
        ).thenAnswer((_) async => true);
        // act
        final result = await repository.updateSpaceCoin(
          workSpace: tWorkSpace,
          coinEntity: tCoinEntity,
        );
        // assert
        expect(result, true);
        verify(
          mockDbControlAdapter.updateDbData(
            tableName: tTableName,
            tableData: tMapCoin.toMap(),
            where: 'symbol=?',
            whereArgs: [tSymbol],
          ),
        );
        verifyNever(
          mockApiDataAdapter.getCoinKlines(
            symbol: anyNamed('symbol'),
            interval: anyNamed('interval'),
            limit: anyNamed('limit'),
          ),
        );
      },
    );

    // Тест на обработку исключений
    test('should rethrow and log error when db throws an exception', () async {
      // arrange
      final tException = Exception('DB Error');
      when(
        mockDbControlAdapter.findDbData(
          tableName: anyNamed('tableName'),
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        ),
      ).thenThrow(tException);
      // act & assert
      expect(
        () => repository.updateSpaceCoin(
          workSpace: tWorkSpace,
          coinEntity: tCoinEntity,
        ),
        throwsA(isA<Exception>()),
      );
      verify(
        mockLogger.e(
          'devlog_CoinRepositoryImpl_updateDbCoin:',
          error: tException,
        ),
      ).called(1);
    });
  });

  // Группа тестов для метода deleteCoinFromDb
  group('deleteCoinFromDb', () {
    // Тест на успешное удаление монеты
    test('should return true when coin is deleted successfully', () async {
      // arrange
      when(
        mockDbControlAdapter.deleteDbData(
          tableName: anyNamed('tableName'),
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        ),
      ).thenAnswer((_) async => true);
      // act
      final result = await repository.deleteCoinFromSpace(
        workSpace: tWorkSpace,
        symbol: tSymbol,
      );
      // assert
      expect(result, true);
      verify(
        mockDbControlAdapter.deleteDbData(
          tableName: tTableName,
          where: 'symbol=?',
          whereArgs: [tSymbol],
        ),
      );
    });

    // Тест на неудачное удаление монеты
    test('should return false when coin deletion fails', () async {
      // arrange
      when(
        mockDbControlAdapter.deleteDbData(
          tableName: anyNamed('tableName'),
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        ),
      ).thenAnswer((_) async => false);
      // act
      final result = await repository.deleteCoinFromSpace(
        workSpace: tWorkSpace,
        symbol: tSymbol,
      );
      // assert
      expect(result, false);
    });

    // Тест на случай, когда БД возвращает null
    test('should return null when db call returns null', () async {
      // arrange
      when(
        mockDbControlAdapter.deleteDbData(
          tableName: anyNamed('tableName'),
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        ),
      ).thenAnswer((_) async => null);
      // act
      final result = await repository.deleteCoinFromSpace(
        workSpace: tWorkSpace,
        symbol: tSymbol,
      );
      // assert
      expect(result, isNull);
    });

    // Тест на обработку исключений
    test('should rethrow and log error when db throws an exception', () async {
      // arrange
      final tException = Exception('DB Error');
      when(
        mockDbControlAdapter.deleteDbData(
          tableName: anyNamed('tableName'),
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        ),
      ).thenThrow(tException);
      // act & assert
      expect(
        () => repository.deleteCoinFromSpace(
          workSpace: tWorkSpace,
          symbol: tSymbol,
        ),
        throwsA(isA<Exception>()),
      );
      verify(
        mockLogger.e(
          'devlog_CoinRepositoryImpl_deleteCoinFromDb:',
          error: tException,
        ),
      ).called(1);
    });
  });

  // Группа тестов для метода findCoinFromDb
  group('findCoinFromDb', () {
    // Тест на успешный поиск монеты
    test('should return true when coin is found in db', () async {
      // arrange
      when(
        mockDbControlAdapter.findDbData(
          tableName: anyNamed('tableName'),
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        ),
      ).thenAnswer((_) async => true);
      // act
      final result = await repository.findCoinFromSpace(
        workSpace: tWorkSpace,
        symbol: tSymbol,
      );
      // assert
      expect(result, true);
      verify(
        mockDbControlAdapter.findDbData(
          tableName: tTableName,
          where: 'symbol=?',
          whereArgs: [tSymbol],
        ),
      );
    });

    // Тест на случай, когда монета не найдена
    test('should return false when coin is not found in db', () async {
      // arrange
      when(
        mockDbControlAdapter.findDbData(
          tableName: anyNamed('tableName'),
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        ),
      ).thenAnswer((_) async => false);
      // act
      final result = await repository.findCoinFromSpace(
        workSpace: tWorkSpace,
        symbol: tSymbol,
      );
      // assert
      expect(result, false);
    });

    // Тест на случай, когда БД возвращает null
    test('should return null when db call returns null', () async {
      // arrange
      when(
        mockDbControlAdapter.findDbData(
          tableName: anyNamed('tableName'),
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        ),
      ).thenAnswer((_) async => null);
      // act
      final result = await repository.findCoinFromSpace(
        workSpace: tWorkSpace,
        symbol: tSymbol,
      );
      // assert
      expect(result, isNull);
    });

    // Тест на обработку исключений
    test('should rethrow and log error when db throws an exception', () async {
      // arrange
      final tException = Exception('DB Error');
      when(
        mockDbControlAdapter.findDbData(
          tableName: anyNamed('tableName'),
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        ),
      ).thenThrow(tException);
      // act & assert
      expect(
        () => repository.findCoinFromSpace(
          workSpace: tWorkSpace,
          symbol: tSymbol,
        ),
        throwsA(isA<Exception>()),
      );
      verify(
        mockLogger.e(
          'devlog_CoinRepositoryImpl_findCoinFromDb:',
          error: tException,
        ),
      ).called(1);
    });
  });

  // Группа тестов для метода getCoinFromDb
  group('getCoinFromDb', () {
    // Тест на успешное получение монеты
    test('should return coin entity when db call is successful', () async {
      // arrange
      when(
        mockDbControlAdapter.getDbData(
          tableName: anyNamed('tableName'),
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        ),
      ).thenAnswer((_) async => tMapCoins);
      when(
        mockDataConvertor.fromMapCoinsToCoinsEntity(any),
      ).thenReturn(tCoinsEntity);
      // act
      final result = await repository.getCoinFromSpace(
        workSpace: tWorkSpace,
        symbol: tSymbol,
      );
      // assert
      expect(result, tCoinEntity);
      verify(
        mockDbControlAdapter.getDbData(
          tableName: tTableName,
          where: 'symbol=?',
          whereArgs: [tSymbol],
        ),
      );
      verify(mockDataConvertor.fromMapCoinsToCoinsEntity(tMapCoins));
    });

    // Тест на случай, когда БД возвращает null
    test('should return null when db returns null', () async {
      // arrange
      when(
        mockDbControlAdapter.getDbData(
          tableName: anyNamed('tableName'),
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        ),
      ).thenAnswer((_) async => null);
      when(
        mockDataConvertor.fromMapCoinsToCoinsEntity(any),
      ).thenReturn(const CoinsEntity(coins: []));
      // act
      final result = await repository.getCoinFromSpace(
        workSpace: tWorkSpace,
        symbol: tSymbol,
      );
      // assert
      expect(result, isNull);
    });

    // Тест на случай, когда монета не найдена
    test('should return null when coin is not found in db', () async {
      // arrange
      when(
        mockDbControlAdapter.getDbData(
          tableName: anyNamed('tableName'),
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        ),
      ).thenAnswer((_) async => tMapCoins); // Returns a list
      when(
        mockDataConvertor.fromMapCoinsToCoinsEntity(any),
      ).thenReturn(
          const CoinsEntity(coins: [tCoinEntity])); // The list has the coin
      // act
      final result = await repository.getCoinFromSpace(
        workSpace: tWorkSpace,
        symbol: 'NONEXISTENT',
      ); // But we search for another
      // assert
      expect(result, isNull);
    });

    // Тест на обработку исключений
    test('should rethrow and log error when db throws an exception', () async {
      // arrange
      final tException = Exception('DB Error');
      when(
        mockDbControlAdapter.getDbData(
          tableName: anyNamed('tableName'),
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        ),
      ).thenThrow(tException);
      // act & assert
      expect(
        () =>
            repository.getCoinFromSpace(workSpace: tWorkSpace, symbol: tSymbol),
        throwsA(isA<Exception>()),
      );
      verify(
        mockLogger.e(
          'devlog_CoinRepositoryImpl_getCoinFromDb:',
          error: tException,
        ),
      ).called(1);
    });
  });

  // Группа тестов для метода getCoinsFromDb
  group('getCoinsFromDb', () {
    // Тест на успешное получение списка монет
    test('should return coins entity when db call is successful', () async {
      // arrange
      when(
        mockDbControlAdapter.getDbMultipleData(
          tableName: anyNamed('tableName'),
        ),
      ).thenAnswer((_) async => tMapCoins);
      when(
        mockDataConvertor.fromMapCoinsToCoinsEntity(any),
      ).thenReturn(tCoinsEntity);
      // act
      final result = await repository.getCoinsFromSpace(workSpace: tWorkSpace);
      // assert
      expect(result, tCoinsEntity);
      verify(mockDbControlAdapter.getDbMultipleData(tableName: tTableName));
      verify(mockDataConvertor.fromMapCoinsToCoinsEntity(tMapCoins));
    });

    // Тест на случай, когда БД возвращает null
    test('should return null when db returns null', () async {
      // arrange
      when(
        mockDbControlAdapter.getDbMultipleData(
          tableName: anyNamed('tableName'),
        ),
      ).thenAnswer((_) async => null);
      when(
        mockDataConvertor.fromMapCoinsToCoinsEntity(any),
      ).thenReturn(const CoinsEntity(coins: []));
      // act
      final result = await repository.getCoinsFromSpace(workSpace: tWorkSpace);
      // assert
      expect(result, isNull);
    });

    // Тест на случай, когда БД возвращает пустой список
    test('should return null when db returns empty coins', () async {
      // arrange
      when(
        mockDbControlAdapter.getDbMultipleData(
          tableName: anyNamed('tableName'),
        ),
      ).thenAnswer((_) async => const MapCoins(coins: []));
      when(
        mockDataConvertor.fromMapCoinsToCoinsEntity(any),
      ).thenReturn(const CoinsEntity(coins: []));
      // act
      final result = await repository.getCoinsFromSpace(workSpace: tWorkSpace);
      // assert
      expect(result, isNull);
    });
  });

  // Группа тестов для метода addDbCoin
  group('addDbCoin', () {
    // Тест на добавление монеты, если ее нет в БД
    test('should add coin to db if it does not exist', () async {
      // arrange
      when(
        mockDbControlAdapter.findDbData(
          tableName: anyNamed('tableName'),
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        ),
      ).thenAnswer((_) async => false);
      when(mockDataConvertor.fromCoinEntityToMapCoin(any)).thenReturn(tMapCoin);
      when(
        mockDbControlAdapter.addDbData(
          tableName: anyNamed('tableName'),
          mapCoin: anyNamed('mapCoin'),
        ),
      ).thenAnswer((_) async => true);
      // act
      final result = await repository.addSpaceCoin(
        workSpace: tWorkSpace,
        coinEntity: tCoinEntity,
      );
      // assert
      expect(result, true);
      verify(
        mockDbControlAdapter.findDbData(
          tableName: tTableName,
          where: 'symbol=?',
          whereArgs: [tSymbol],
        ),
      );
      verify(
        mockDbControlAdapter.addDbData(
          tableName: tTableName,
          mapCoin: tMapCoin,
        ),
      );
    });

    // Тест на случай, когда монета уже существует в БД
    test('should return null if coin already exists in db', () async {
      // arrange
      when(
        mockDbControlAdapter.findDbData(
          tableName: anyNamed('tableName'),
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        ),
      ).thenAnswer((_) async => true);
      // act
      final result = await repository.addSpaceCoin(
        workSpace: tWorkSpace,
        coinEntity: tCoinEntity,
      );
      // assert
      expect(result, isNull);
      verify(
        mockDbControlAdapter.findDbData(
          tableName: tTableName,
          where: 'symbol=?',
          whereArgs: [tSymbol],
        ),
      );
      verifyNoMoreInteractions(mockDbControlAdapter);
    });

    // Тест на случай, когда findDbData возвращает null
    test('should return null if findDbData returns null', () async {
      // arrange
      when(
        mockDbControlAdapter.findDbData(
          tableName: anyNamed('tableName'),
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        ),
      ).thenAnswer((_) async => null);
      // act
      final result = await repository.addSpaceCoin(
        workSpace: tWorkSpace,
        coinEntity: tCoinEntity,
      );
      // assert
      expect(result, isNull);
    });
  });

  // Группа тестов для метода addDbCoinsFromApi
  group('addDbCoinsFromApi', () {
    // Тест на случай, когда таблица не пуста
    test(
      'should return null and not add coins when table is not empty and isAllCoins is true',
      () async {
        // arrange
        when(
          mockDbControlAdapter.isTableEmpty(tableName: anyNamed('tableName')),
        ).thenAnswer((_) async => false);
        // Add stub for the API call that now happens before the check
        when(mockApiDataAdapter.getAllCoins()).thenAnswer((_) async => tCoins);

        // act
        final result = await repository.addSpaceCoinsFromApi(
          workSpace: tWorkSpace,
        );
        // assert
        expect(result, isNull);
        verify(mockDbControlAdapter.isTableEmpty(tableName: tTableName));
        // Verify getAllCoins was called, but no further DB interactions happened
        verify(mockApiDataAdapter.getAllCoins());
        verifyNoMoreInteractions(mockDbControlAdapter);
      },
    );

    // Тест на добавление всех монет, когда таблица пуста
    test(
      'should add all coins when table is empty and isAllCoins is true',
      () async {
        // arrange
        when(
          mockDbControlAdapter.isTableEmpty(tableName: anyNamed('tableName')),
        ).thenAnswer((_) async => true);
        when(mockApiDataAdapter.getAllCoins()).thenAnswer((_) async => tCoins);
        when(mockDataConvertor.fromCoinsToMapCoins(any)).thenReturn(tMapCoins);
        when(
          mockDbControlAdapter.addMultipleDbData(
            tableName: anyNamed('tableName'),
            mapCoins: anyNamed('mapCoins'),
          ),
        ).thenAnswer((_) async => true);
        // act
        final result = await repository.addSpaceCoinsFromApi(
          workSpace: tWorkSpace,
        );
        // assert
        expect(result, true);
        verify(mockDbControlAdapter.isTableEmpty(tableName: tTableName));
        verify(mockApiDataAdapter.getAllCoins());
        verify(mockDataConvertor.fromCoinsToMapCoins(tCoins));
        verify(
          mockDbControlAdapter.addMultipleDbData(
            tableName: tTableName,
            mapCoins: tMapCoins,
          ),
        );
      },
    );
  });

  // Группа тестов для метода updateKlinesFromApi
  group('updateKlinesFromApi', () {
    const tInterval = 60;
    const tLimit = 10;
    const tRequestDelay = 200;
    final tKlines = Klines(
      symbol: tSymbol,
      kLines: [Kline(open: 1)],
      kLineInterval: tInterval,
      kLineAmount: 1,
    );
    const tMapKlines = MapKlines(
      symbol: tSymbol,
      kLines: [MapKline(open: 1)],
      kLineInterval: tInterval,
      kLineAmount: 1,
    );

    // Тест на успешное обновление klines
    test(
      'should update klines in db when coin exists and api returns klines',
      () async {
        // arrange
        when(
          mockDbControlAdapter.findDbData(
            tableName: anyNamed('tableName'),
            where: anyNamed('where'),
            whereArgs: anyNamed('whereArgs'),
          ),
        ).thenAnswer((_) async => true);
        when(
          mockApiDataAdapter.getCoinKlines(
            symbol: anyNamed('symbol'),
            interval: anyNamed('interval'),
            limit: anyNamed('limit'),
          ),
        ).thenAnswer((_) async => tKlines);
        when(
          mockDataConvertor.fromKlinesToMapKlines(any),
        ).thenReturn(tMapKlines);
        when(
          mockDbControlAdapter.updateDbData(
            tableName: anyNamed('tableName'),
            tableData: anyNamed('tableData'),
            where: anyNamed('where'),
            whereArgs: anyNamed('whereArgs'),
          ),
        ).thenAnswer((_) async => true);

        // act
        final result = await repository.updateKlinesFromApi(
          workSpace: tWorkSpace,
          symbol: tSymbol,
          interval: tInterval,
          limit: tLimit,
          requestDelay: tRequestDelay,
        );

        // assert
        expect(result, true);
        verify(
          mockDataConvertor.fromWorkSpaceToTableName(workSpace: tWorkSpace),
        );
        verify(
          mockDbControlAdapter.findDbData(
            tableName: tTableName,
            where: 'symbol=?',
            whereArgs: [tSymbol],
          ),
        );
        await untilCalled(
          mockApiDataAdapter.getCoinKlines(
            symbol: tSymbol,
            interval: tInterval,
            limit: tLimit,
          ),
        );
        verify(
          mockApiDataAdapter.getCoinKlines(
            symbol: tSymbol,
            interval: tInterval,
            limit: tLimit,
          ),
        );
        verify(mockDataConvertor.fromKlinesToMapKlines(tKlines));
        verify(
          mockDbControlAdapter.updateDbData(
            tableName: tTableName,
            tableData: tMapKlines.toMap(),
            where: 'symbol=?',
            whereArgs: [tSymbol],
          ),
        );
        verifyNoMoreInteractions(mockApiDataAdapter);
        verifyNoMoreInteractions(mockDbControlAdapter);
        verifyNoMoreInteractions(mockDataConvertor);
      },
    );

    // Тест на случай, когда интервал null
    test('should return null if interval is null', () async {
      // act
      final result = await repository.updateKlinesFromApi(
        workSpace: tWorkSpace,
        symbol: tSymbol,
        interval: null,
        limit: tLimit,
        requestDelay: tRequestDelay,
      );
      // assert
      expect(result, isNull);
      verifyZeroInteractions(mockApiDataAdapter);
      verifyZeroInteractions(mockDbControlAdapter);
    });

    // Тест на случай, когда монета не найдена в БД
    test('should return null if coin is not found in db', () async {
      // arrange
      when(
        mockDbControlAdapter.findDbData(
          tableName: anyNamed('tableName'),
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        ),
      ).thenAnswer((_) async => false);
      // act
      final result = await repository.updateKlinesFromApi(
        workSpace: tWorkSpace,
        symbol: tSymbol,
        interval: tInterval,
        limit: tLimit,
        requestDelay: tRequestDelay,
      );
      // assert
      expect(result, isNull);
      verify(
        mockDbControlAdapter.findDbData(
          tableName: tTableName,
          where: 'symbol=?',
          whereArgs: [tSymbol],
        ),
      );
      verifyNoMoreInteractions(mockDbControlAdapter);
      verifyZeroInteractions(mockApiDataAdapter);
    });

    // Тест на случай, когда API возвращает пустой список klines
    test('should return null if api returns empty klines', () async {
      // arrange
      when(
        mockDbControlAdapter.findDbData(
          tableName: anyNamed('tableName'),
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        ),
      ).thenAnswer((_) async => true);
      when(
        mockApiDataAdapter.getCoinKlines(
          symbol: anyNamed('symbol'),
          interval: anyNamed('interval'),
          limit: anyNamed('limit'),
        ),
      ).thenAnswer(
        (_) async => const Klines(
          symbol: tSymbol,
          kLines: [],
          kLineInterval: tInterval,
          kLineAmount: 0,
        ),
      );
      // act
      final result = await repository.updateKlinesFromApi(
        workSpace: tWorkSpace,
        symbol: tSymbol,
        interval: tInterval,
        limit: tLimit,
        requestDelay: tRequestDelay,
      );
      // assert
      expect(result, isNull);
      verify(
        mockDbControlAdapter.findDbData(
          tableName: tTableName,
          where: 'symbol=?',
          whereArgs: [tSymbol],
        ),
      );
      await untilCalled(
        mockApiDataAdapter.getCoinKlines(
          symbol: tSymbol,
          interval: tInterval,
          limit: tLimit,
        ),
      );
      verify(
        mockApiDataAdapter.getCoinKlines(
          symbol: tSymbol,
          interval: tInterval,
          limit: tLimit,
        ),
      );
      verifyNoMoreInteractions(mockDbControlAdapter);
      verifyNoMoreInteractions(mockApiDataAdapter);
    });

    // Тест на обработку исключений
    test('should rethrow and log error when db throws an exception', () async {
      // arrange
      final tException = Exception('DB Error');
      when(
        mockDbControlAdapter.findDbData(
          tableName: anyNamed('tableName'),
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        ),
      ).thenThrow(tException);
      // act & assert
      expect(
        () => repository.updateKlinesFromApi(
          workSpace: tWorkSpace,
          symbol: tSymbol,
          interval: tInterval,
          limit: tLimit,
          requestDelay: tRequestDelay,
        ),
        throwsA(isA<Exception>()),
      );
      verify(
        mockLogger.e(
          'devlog_CoinRepositoryImpl_updateKlinesFromApi:',
          error: tException,
        ),
      ).called(1);
    });
  });
  // Группа тестов для метода updateDbField
  group('updateDbField', () {
    // Тест на успешное обновление поля
    test('should return true when db update is successful', () async {
      when(mockDbSchema.getColumnName('isWhatched')).thenReturn('isWhatched');
      when(
        mockDbControlAdapter.updateDbData(
          tableName: anyNamed('tableName'),
          tableData: anyNamed('tableData'),
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        ),
      ).thenAnswer((_) async => true);
      // act
      final result = await repository.updateSpaceField(
        workSpace: tWorkSpace,
        dataField: const DataField(symbol: tSymbol, isWhatched: true),
      );
      // assert
      expect(result, true);
      verify(mockDataConvertor.fromWorkSpaceToTableName(workSpace: tWorkSpace));
      verify(mockDbSchema.getColumnName('isWhatched'));
      verify(
        mockDbControlAdapter.updateDbData(
          tableName: tTableName,
          tableData: {'isWhatched': 'true'},
          where: 'symbol=?',
          whereArgs: [tSymbol],
        ),
      );
    });

    // Тест на случай, когда имя таблицы null
    test('should return null when table name is null', () async {
      // arrange
      when(
        mockDataConvertor.fromWorkSpaceToTableName(
          workSpace: anyNamed('workSpace'),
        ),
      ).thenReturn(null);
      // act
      final result = await repository.updateSpaceField(
        workSpace: tWorkSpace,
        dataField: const DataField(symbol: tSymbol, isWhatched: true),
      );
      // assert
      expect(result, isNull);
      verify(mockDataConvertor.fromWorkSpaceToTableName(workSpace: tWorkSpace));
      verifyZeroInteractions(mockDbSchema);
      verifyZeroInteractions(mockDbControlAdapter);
    });

    // Тест на случай, когда имя колонки null
    test('should return null when column name is null', () async {
      // arrange
      // To make dataField.getField() return null, set symbol to null
      const dataFieldWithNullSymbol = DataField(symbol: null, isWhatched: true);
      // act
      final result = await repository.updateSpaceField(
        workSpace: tWorkSpace,
        dataField: dataFieldWithNullSymbol,
      );
      // assert
      expect(result, isNull);
      verify(mockDataConvertor.fromWorkSpaceToTableName(workSpace: tWorkSpace));
      verifyZeroInteractions(mockDbSchema);
      verifyZeroInteractions(mockDbControlAdapter);
    });

    // Тест на случай, когда схема БД возвращает null для имени колонки
    test(
      'should return null when db schema returns null for column name',
      () async {
        when(mockDbSchema.getColumnName('isWhatched')).thenReturn(null);
        // act
        final result = await repository.updateSpaceField(
          workSpace: tWorkSpace,
          dataField: const DataField(symbol: tSymbol, isWhatched: true),
        );
        // assert
        expect(result, isNull);
        verify(
          mockDataConvertor.fromWorkSpaceToTableName(workSpace: tWorkSpace),
        );
        verify(mockDbSchema.getColumnName('isWhatched'));
        verifyZeroInteractions(mockDbControlAdapter);
      },
    );

    // Тест на неудачное обновление БД
    test('should return false when db update fails', () async {
      // arrange
      when(mockDbSchema.getColumnName('isWhatched')).thenReturn('isWhatched');
      when(
        mockDbControlAdapter.updateDbData(
          tableName: anyNamed('tableName'),
          tableData: anyNamed('tableData'),
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        ),
      ).thenAnswer((_) async => false);
      // act
      final result = await repository.updateSpaceField(
        workSpace: tWorkSpace,
        dataField: const DataField(symbol: tSymbol, isWhatched: true),
      );
      // assert
      expect(result, false);
      verify(
        mockDbControlAdapter.updateDbData(
          tableName: tTableName,
          tableData: {'isWhatched': 'true'},
          where: 'symbol=?',
          whereArgs: [tSymbol],
        ),
      );
    });

    // Тест на случай, когда обновление БД возвращает null
    test('should return null when db update returns null', () async {
      // arrange
      when(mockDbSchema.getColumnName('isWhatched')).thenReturn('isWhatched');
      when(
        mockDbControlAdapter.updateDbData(
          tableName: anyNamed('tableName'),
          tableData: anyNamed('tableData'),
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        ),
      ).thenAnswer((_) async => null);
      // act
      final result = await repository.updateSpaceField(
        workSpace: tWorkSpace,
        dataField: const DataField(symbol: tSymbol, isWhatched: true),
      );
      // assert
      expect(result, isNull);
      verify(
        mockDbControlAdapter.updateDbData(
          tableName: tTableName,
          tableData: {'isWhatched': 'true'},
          where: 'symbol=?',
          whereArgs: [tSymbol],
        ),
      );
    });

    // Тест на обработку исключений
    test('should rethrow and log error when db throws an exception', () async {
      // arrange
      final tException = Exception('DB Error');
      when(
        mockDataConvertor.fromFieldToColumnName(field: anyNamed('field')),
      ).thenReturn(tColumnName);
      when(mockDbSchema.getColumnName(any)).thenReturn(tColumnName);
      when(
        mockDbControlAdapter.updateDbData(
          tableName: anyNamed('tableName'),
          tableData: anyNamed('tableData'),
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        ),
      ).thenThrow(tException);
      // act & assert
      expect(
        () => repository.updateSpaceField(
          workSpace: tWorkSpace,
          dataField: const DataField(symbol: tSymbol, isWhatched: true),
        ),
        throwsA(isA<Exception>()),
      );
      verify(
        mockLogger.e(
          'devlog_CoinRepositoryImpl_updateDbField:',
          error: tException,
        ),
      ).called(1);
    });
  });
}
