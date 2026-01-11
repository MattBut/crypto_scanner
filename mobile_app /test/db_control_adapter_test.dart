import 'package:crypto_scanner/data/datasources/db_control.dart';
import 'package:crypto_scanner/data/datasources/db_control_adapter.dart';
import 'package:crypto_scanner/data/models/map_coin.dart';
import 'package:crypto_scanner/data/models/tables.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'db_control_adapter_test.mocks.dart';

// Аннотация для генерации мок-классов
@GenerateMocks([DbControl, Logger])
void main() {
  late DbControlAdapter dbControlAdapter;
  late MockDbControl mockDbControl;
  late MockLogger mockLogger;

  // Настройка перед каждым тестом
  setUp(() {
    mockDbControl = MockDbControl();
    mockLogger = MockLogger();
    dbControlAdapter = DbControlAdapter(
      logger: mockLogger,
      dbControl: mockDbControl,
    );
    // Подавление вывода ошибок логгера во время тестов
    when(mockLogger.e(any,
            error: anyNamed('error'), stackTrace: anyNamed('stackTrace')))
        .thenAnswer((_) {});
  });

  // Группа тестов для DbControlAdapter
  group('DbControlAdapter', () {
    // Группа тестов для метода initTables
    group('initTables', () {
      final tables = Tables(tableNames: ['table1', 'table2'], columnNames: []);
      setUp(() {
        when(mockDbControl.findTable(any)).thenAnswer((_) async => false);
      });
      // Тест на успешное создание всех таблиц
      test(
        'should return true when all tables are created successfully',
        () async {
          // Arrange: Настройка мока для успешного создания таблиц
          when(
            mockDbControl.createTable(any, any),
          ).thenAnswer((_) async => true);

          // Act: Вызов метода
          final result = await dbControlAdapter.initTables(tables: tables);

          // Assert: Проверка, что результат true и методы создания таблиц были вызваны
          expect(result, isTrue);
          verify(mockDbControl.createTable('table1', [])).called(1);
          verify(mockDbControl.createTable('table2', [])).called(1);
        },
      );

      // Тест на случай, когда создание одной из таблиц не удалось
      test('should return false when table creation fails', () async {
        // Arrange: Настройка мока для неудачного создания одной из таблиц
        when(
          mockDbControl.createTable('table1', any),
        ).thenAnswer((_) async => true);
        when(
          mockDbControl.createTable('table2', any),
        ).thenAnswer((_) async => false);

        // Act & Assert: Проверка, что результат false
        expect(
          await dbControlAdapter.initTables(tables: tables),
          isFalse,
        );
      });

      // Тест на обработку исключений от DbControl
      test(
        'should log error and rethrow exception when DbControl fails',
        () async {
          // Arrange: Настройка мока для генерации исключения
          final expectedError = Exception('DB connection error');
          when(mockDbControl.createTable(any, any)).thenThrow(expectedError);

          // Act & Assert: Проверка, что метод генерирует исключение и логирует ошибку
          try {
            await dbControlAdapter.initTables(tables: tables);
            fail('should have thrown an exception');
          } catch (e) {
            expect(e, isA<Exception>());
          }

          verify(
            mockLogger.e(
              'devlog_DbControlAdapter_initTables:',
              error: anyNamed('error'),
              stackTrace: anyNamed('stackTrace'),
            ),
          ).called(1);
        },
      );
    });

    // Группа тестов для метода isTableEmpty
    group('isTableEmpty', () {
      // Тест на случай, когда таблица пуста
      test('should return true when table is empty', () async {
        // Arrange: Настройка мока для возврата true
        when(mockDbControl.isTableEmpty(any)).thenAnswer((_) async => true);

        // Act: Вызов метода
        final result = await dbControlAdapter.isTableEmpty(
          tableName: 'test_table',
        );

        // Assert: Проверка, что результат true
        expect(result, isTrue);
        verify(mockDbControl.isTableEmpty('test_table')).called(1);
      });

      // Тест на обработку исключений от DbControl
      test(
        'should log error and rethrow exception when DbControl fails',
        () async {
          // Arrange: Настройка мока для генерации исключения
          final expectedError = Exception('DB connection error');
          when(mockDbControl.isTableEmpty(any)).thenThrow(expectedError);

          // Act & Assert: Проверка, что метод генерирует исключение и логирует ошибку
          expect(
            () async => await dbControlAdapter.isTableEmpty(tableName: 'test'),
            throwsA(isA<Exception>()),
          );

          verify(
            mockLogger.e(
              'devlog_DbControlAdapter_isTableEmpty:',
              error: expectedError,
            ),
          ).called(1);
        },
      );
    });

    // Группа тестов для метода addDbData
    group('addDbData', () {
      setUp(() {
        when(mockDbControl.addTableData(any, any))
            .thenAnswer((_) async => true);
      });
      // Тест на добавление одной записи
      test('should call addTableData for single data', () async {
        const mapCoin = MapCoin(
          symbol: 'BTC',
          coinName: 'Bitcoin',
          currentPrice: 10000.0,
          priceChange24hPcnt: 0.05,
          volume24h: 1000000.0,
          coinLogoURL: '',
          marketCapUSD: 200000000.0,
          marketCapRank: 1,
        );
        when(
          mockDbControl.addTableData(any, any),
        ).thenAnswer((_) async => true);

        await dbControlAdapter.addDbData(tableName: 'coins', mapCoin: mapCoin);

        verify(mockDbControl.addTableData('coins', mapCoin.toMap())).called(1);
      });

      // Тест на обработку исключений от DbControl
      test(
        'should log error and rethrow exception when DbControl fails',
        () async {
          final expectedError = Exception('DB connection error');
          when(mockDbControl.addTableData(any, any)).thenThrow(expectedError);

          expect(
            () async => await dbControlAdapter.addDbData(
              tableName: 'coins',
              mapCoin: MapCoin.empty(),
            ),
            throwsA(isA<Exception>()),
          );

          verify(
            mockLogger.e(
              'devlog_DbControlAdapter_addDbData:',
              error: expectedError,
            ),
          ).called(1);
        },
      );
    });

    // Группа тестов для метода getDbData
    group('getDbData', () {
      setUp(() {
        when(mockDbControl.getTableDataByParam(any, any, any))
            .thenAnswer((_) async => []);
      });
      // Тест на получение всех данных
      test('should call getTableData for all data', () async {
        when(mockDbControl.getTableDataByParam(any, any, any))
            .thenAnswer((_) async => []);

        await dbControlAdapter.getDbData(
          tableName: 'coins',
          where: '',
          whereArgs: [],
        );

        verify(mockDbControl.getTableDataByParam('coins', '', [])).called(1);
      });

      // Тест на получение данных по параметру
      test('should call getTableDataByParam for specific data', () async {
        when(
          mockDbControl.getTableDataByParam(any, any, any),
        ).thenAnswer((_) async => []);

        await dbControlAdapter.getDbData(
          tableName: 'coins',
          where: 'coin = ?',
          whereArgs: ['BTC'],
        );

        verify(
          mockDbControl.getTableDataByParam('coins', 'coin = ?', ['BTC']),
        ).called(1);
      });

      // Тест на обработку исключений от DbControl
      test(
        'should log error and rethrow exception when DbControl fails',
        () async {
          final expectedError = Exception('DB connection error');
          when(mockDbControl.getTableDataByParam(any, any, any))
              .thenThrow(expectedError);

          expect(
            () async => await dbControlAdapter.getDbData(
              tableName: 'coins',
              where: '',
              whereArgs: [],
            ),
            throwsA(isA<Exception>()),
          );

          verify(
            mockLogger.e(
              'devlog_DbControlAdapter_getDbData:',
              error: expectedError,
            ),
          ).called(1);
        },
      );
    });

    // Группа тестов для метода findDbData
    group('findDbData', () {
      // Тест на вызов findTableData
      test('should call findTableData', () async {
        when(
          mockDbControl.findTableData(any, any, any),
        ).thenAnswer((_) async => true);

        await dbControlAdapter.findDbData(
          tableName: 'coins',
          where: 'coin = ?',
          whereArgs: ['BTC'],
        );

        verify(
          mockDbControl.findTableData('coins', 'coin = ?', ['BTC']),
        ).called(1);
      });
      // Тест на обработку исключений от DbControl
      test(
        'should log error and rethrow exception when DbControl fails',
        () async {
          final expectedError = Exception('DB connection error');
          when(
            mockDbControl.findTableData(any, any, any),
          ).thenThrow(expectedError);

          expect(
            () async => await dbControlAdapter.findDbData(
              tableName: 'coins',
              where: 'id=?',
              whereArgs: [1],
            ),
            throwsA(isA<Exception>()),
          );

          verify(
            mockLogger.e(
              'devlog_DbControlAdapter_findDbData:',
              error: expectedError,
            ),
          ).called(1);
        },
      );
    });

    // Группа тестов для метода updateDbData
    group('updateDbData', () {
      // Тест на вызов updateTableData
      test('should call updateTableData', () async {
        when(
          mockDbControl.updateTableData(any, any, any, any),
        ).thenAnswer((_) async => true);

        await dbControlAdapter.updateDbData(
          tableName: 'coins',
          tableData: {'coinName': 'Bitcoin_new'},
          where: 'coin = ?',
          whereArgs: ['BTC'],
        );

        verify(
          mockDbControl.updateTableData(
            'coins',
            {'coinName': 'Bitcoin_new'},
            'coin = ?',
            ['BTC'],
          ),
        ).called(1);
      });

      // Тест на обработку исключений от DbControl
      test(
        'should log error and rethrow exception when DbControl fails',
        () async {
          final expectedError = Exception('DB connection error');
          when(
            mockDbControl.updateTableData(any, any, any, any),
          ).thenThrow(expectedError);

          expect(
            () async => await dbControlAdapter.updateDbData(
              tableName: 'coins',
              tableData: {},
              where: 'id=?',
              whereArgs: [1],
            ),
            throwsA(isA<Exception>()),
          );

          verify(
            mockLogger.e(
              'devlog_DbControlAdapter_updateDbData:',
              error: expectedError,
            ),
          ).called(1);
        },
      );
    });

    // Группа тестов для метода deleteDbData
    group('deleteDbData', () {
      // Тест на вызов deleteTableData
      test('should call deleteTableData', () async {
        when(
          mockDbControl.deleteTableData(any, any, any),
        ).thenAnswer((_) async => true);

        await dbControlAdapter.deleteDbData(
          tableName: 'coins',
          where: 'coin = ?',
          whereArgs: ['BTC'],
        );

        verify(
          mockDbControl.deleteTableData('coins', 'coin = ?', ['BTC']),
        ).called(1);
      });

      // Тест на обработку исключений от DbControl
      test(
        'should log error and rethrow exception when DbControl fails',
        () async {
          final expectedError = Exception('DB connection error');
          when(
            mockDbControl.deleteTableData(any, any, any),
          ).thenThrow(expectedError);

          expect(
            () async => await dbControlAdapter.deleteDbData(
              tableName: 'coins',
              where: 'id=?',
              whereArgs: [1],
            ),
            throwsA(isA<Exception>()),
          );

          verify(
            mockLogger.e(
              'devlog_DbControlAdapter_deleteDbData:',
              error: expectedError,
            ),
          ).called(1);
        },
      );
    });

    // Группа тестов для метода clearTableData
    group('clearTableData', () {
      // Тест на успешную очистку таблицы
      test('should return true on successful table clearing', () async {
        when(mockDbControl.clearTableData(any)).thenAnswer((_) async => true);

        final result = await dbControlAdapter.clearTableData(
          tableName: 'test_table',
        );

        expect(result, isTrue);
        verify(mockDbControl.clearTableData('test_table')).called(1);
      });

      // Тест на обработку исключений от DbControl
      test(
        'should log error and rethrow exception when DbControl fails',
        () async {
          final expectedError = Exception('DB connection error');
          when(mockDbControl.clearTableData(any)).thenThrow(expectedError);

          expect(
            () async =>
                await dbControlAdapter.clearTableData(tableName: 'test'),
            throwsA(isA<Exception>()),
          );

          verify(
            mockLogger.e(
              'devlog_DbControlAdapter_clearTableData:',
              error: expectedError,
            ),
          ).called(1);
        },
      );
    });
  });
}
