import 'dart:io';

import 'package:crypto_scanner/core/service_locator.dart';
import 'package:crypto_scanner/data/datasources/db_control.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // 1. Инициализация GetIt (для доступа к Logger)
  setupLocator();

  // 2. Инициализация для десктоп/тестирования (sqflite_common_ffi)
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final testDbName =
      'db_control_test_suite_${DateTime.now().millisecondsSinceEpoch}.db';
  late DbControl dbControl;

  const testTableName = 'TestAssets';
  const initialColumns = ['symbol', 'price'];
  const initialData = {'symbol': 'BTC', 'price': '60000.00'};

  // Создание и очистка БД перед каждым тестом (автоматическое удаление старого файла БД)
  setUp(() async {
    dbControl = DbControl(dbName: testDbName, logger: getIt<Logger>());
    await dbControl.initDb(isTest: true);
  });

  // Удаление файла БД после каждого теста
  tearDown(() async {
    await dbControl.closeDb();
    final dbPath = path.join(Directory.current.path, testDbName);
    if (File(dbPath).existsSync()) {
      await databaseFactory.deleteDatabase(dbPath);
    }
  });

  // Группа интеграционных тестов для DbControl
  group('DbControl: Full Integration Tests', () {
    // Тесты управления таблицей (создание, поиск, переименование, удаление)
    test('1. Table Management (Create, Find, Rename, Delete)', () async {
      // Создание таблицы
      await dbControl.createTable(testTableName, initialColumns);
      var allTables = await dbControl.getTableNames();
      // Проверка, что таблица создана и присутствует в списке таблиц
      expect(allTables, contains(testTableName));
      expect(
        allTables,
        contains('description'),
        reason: 'Initial table from _initTabs',
      );

      // Переименование таблицы
      const newTableName = 'RenamedAssets';
      var isRenamed = await dbControl.renameTable(testTableName, newTableName);
      expect(isRenamed, isTrue, reason: 'Таблица должна быть переименована');
      expect(await dbControl.findTable(newTableName), isTrue);
      expect(await dbControl.findTable(testTableName), isFalse);

      // Попытка переименовать несуществующую таблицу
      var renameNull = await dbControl.renameTable('NonExistent', 'NewName');
      expect(
        renameNull,
        isNull,
        reason: 'Для несуществующей таблицы должен быть null',
      );

      // Удаление таблицы
      var isDeleted = await dbControl.deleteTable(newTableName);
      expect(isDeleted, isTrue, reason: 'Таблица должна быть удалена');
      expect(await dbControl.findTable(newTableName), isFalse);

      // Повторное создание таблицы
      const newTableNameForCreation = 'NewCreation';
      expect(
        await dbControl.findTable(newTableNameForCreation),
        isFalse,
        reason: 'Таблица NewCreation не должна существовать до создания',
      );
      var isCreated = await dbControl.createTable(newTableNameForCreation, [
        'col1',
      ]);
      expect(isCreated, isTrue, reason: 'Новая таблица должна быть создана');
      expect(await dbControl.findTable(newTableNameForCreation), isTrue);

      // Попытка создать уже существующую таблицу
      var isCreatedAgain = await dbControl.createTable(
        newTableNameForCreation,
        ['col1'],
      );
      expect(
        isCreatedAgain,
        isTrue,
        reason: 'Повторное создание существующей таблицы должно вернуть true',
      );
    });

    // Тесты управления колонками (создание, поиск, переименование, удаление)
    test('2. Column Management (Create, Find, Rename, Delete)', () async {
      await dbControl.createTable(testTableName, initialColumns);
      // Получение всех имен колонок
      var columnNames = await dbControl.getColumnNames(testTableName);
      expect(
          columnNames,
          [
            '_id',
            ...initialColumns,
          ],
          reason: 'Все колонки должны быть возвращены');

      // Поиск колонки
      expect(await dbControl.findColumn(testTableName, 'symbol'), isTrue);
      expect(
        await dbControl.findColumn(testTableName, 'non_existent'),
        isFalse,
      );
      expect(
        await dbControl.findColumn('non_table', 'symbol'),
        isNull,
        reason: 'Нет таблицы, return null',
      );

      // Создание колонки
      const newColumn = 'volume';
      var isColCreated = await dbControl.createColumn(testTableName, newColumn);
      expect(isColCreated, isTrue, reason: 'Новая колонка должна быть создана');
      expect(await dbControl.findColumn(testTableName, newColumn), isTrue);

      // Переименование колонки
      const renamedCol = 'market_cap';
      var isColRenamed = await dbControl.renameColumn(
        testTableName,
        newColumn,
        renamedCol,
      );
      expect(isColRenamed, isTrue, reason: 'Колонка должна быть переименована');
      expect(await dbControl.findColumn(testTableName, renamedCol), isTrue);
      expect(await dbControl.findColumn(testTableName, newColumn), isFalse);
    });

    // Тесты удаления колонки со сложной логикой сохранения данных
    test('3. Data Integrity During Column Deletion', () async {
      // 1. Добавляем тестовые данные (ETH)
      await dbControl.addTableData(testTableName, {
        'symbol': 'ETH',
        'price': '3000.00',
      });

      // 2. Создаем и заполняем колонку, которую будем удалять
      await dbControl.createColumn(testTableName, 'to_delete');
      await dbControl.updateTableData(
        testTableName,
        {'to_delete': 'TEMP_DATA'},
        'symbol = ?',
        ['ETH'],
      );

      // 3. Удаляем колонку 'to_delete'
      var isColDeleted = await dbControl.deleteColumn(
        testTableName,
        'to_delete',
      );
      expect(isColDeleted, isTrue, reason: 'Колонка должна быть удалена');

      // 4. Проверка: остальные данные сохранились
      var finalData = await dbControl.getTableData(testTableName);
      expect(finalData, isNotNull);
      expect(finalData!.length, 1);
      // Проверка: исходная колонка 'price' не удалена, и данные целы
      expect(
        finalData.first['price'],
        '3000.00',
        reason: 'Данные должны быть сохранены',
      );
      // Проверка: удаленная колонка отсутствует
      expect(finalData.first.containsKey('to_delete'), isFalse);

      // 5. Финальная проверка
      var finalCheck = await dbControl.getTableData(testTableName);
      expect(
        finalCheck!.length,
        1,
        reason:
            'Таблица должна содержать одну запись (ETH), которая удалится в tearDown',
      );
    });

    // Тесты CRUD данных (Insert, Update, Delete, Query)
    test('4. Data CRUD Operations', () async {
      await dbControl.createTable(testTableName, initialColumns);
      await dbControl.clearTableData(testTableName);
      //Добавление данных (Insert)
      var isAdded = await dbControl.addTableData(testTableName, initialData);
      expect(isAdded, isTrue, reason: 'Данные должны быть добавлены');

      //Получение данных (Select All)
      var retrievedData = await dbControl.getTableData(testTableName);
      expect(retrievedData, isNotNull);
      expect(retrievedData!.length, 1);
      expect(retrievedData.first['symbol'], 'BTC');

      //Обновление данных
      const updateData = {'price': '65000.00'};
      var isUpdated = await dbControl.updateTableData(
        testTableName,
        updateData,
        'symbol = ?',
        ['BTC'],
      );
      expect(isUpdated, isTrue, reason: 'Данные должны быть обновлены');

      //Поиск данных (проверка обновления)
      var isFound = await dbControl.findTableData(testTableName, 'price = ?', [
        '65000.00',
      ]);
      expect(isFound, isTrue, reason: 'Обновленные данные должны быть найдены');
      var isNotFound = await dbControl.findTableData(
        testTableName,
        'price = ?',
        ['60000.00'],
      );
      expect(
        isNotFound,
        isFalse,
        reason: 'Старые данные не должны быть найдены',
      );

      //Удаление данных
      var isDeleted = await dbControl.deleteTableData(
        testTableName,
        'symbol = ?',
        ['BTC'],
      );
      expect(isDeleted, isTrue, reason: 'Данные должны быть удалены');

      //Проверка удаления
      var finalData = await dbControl.getTableData(testTableName);
      expect(finalData, isNotNull);
      expect(finalData!.isEmpty, isTrue);
    });

    // Тест массовой вставки данных через Batch
    test('4A. Data Batch Operations', () async {
      await dbControl.createTable(testTableName, initialColumns);
      await dbControl.clearTableData(testTableName);
      const nonExistentTable = 'NON_EXISTENT_BATCH';
      final List<Map<String, dynamic>> batchData = [
        {'symbol': 'SOL', 'price': '100.00'},
        {'symbol': 'MATIC', 'price': '0.80'},
        {'symbol': 'AVAX', 'price': '40.00'},
      ];

      // 1. Вставка данных в существующую таблицу
      var isAdded = await dbControl.addMultipleTableData(
        testTableName,
        batchData,
      );
      expect(
        isAdded,
        isTrue,
        reason: 'Batch-данные должны быть успешно добавлены',
      );

      // 2. Проверка количества вставленных строк
      var retrievedData = await dbControl.getTableData(testTableName);
      expect(retrievedData, isNotNull);
      expect(
        retrievedData!.length,
        3,
        reason: 'Должно быть ровно 3 записи после Batch-вставки',
      );
      expect(retrievedData.map((e) => e['symbol']), contains('MATIC'));

      // 3. Проверка возврата null для несуществующей таблицы
      var batchNull = await dbControl.addMultipleTableData(
        nonExistentTable,
        batchData,
      );
      expect(
        batchNull,
        isNull,
        reason: 'Для несуществующей таблицы должен возвращаться null',
      );

      // 4. Очистка (данные удаляются в tearDown)
      var isDeleted = await dbControl.deleteTableData(
        testTableName,
        'symbol = ? OR symbol = ? OR symbol = ?',
        ['SOL', 'MATIC', 'AVAX'],
      );
      expect(
        isDeleted,
        isTrue,
        reason: 'Данные, добавленные Batch, должны быть удалены',
      );

      // Проверка очистки
      var finalCheck = await dbControl.getTableData(testTableName);
      expect(finalCheck!.isEmpty, isTrue);
    });

    // Тест на корректность возврата null (перенумерован в 5)
    test('5. Null Return for Non-Existent Tables', () async {
      const nonExistentTable = 'NON_EXISTENT';

      // CRUD методы
      expect(
        await dbControl.addTableData(nonExistentTable, initialData),
        isNull,
      );
      expect(await dbControl.getTableData(nonExistentTable), isNull);
      expect(
        await dbControl.deleteTableData(nonExistentTable, '1', ['1']),
        isNull,
      );

      // Методы схемы
      expect(await dbControl.renameTable(nonExistentTable, 'New'), isNull);
      expect(await dbControl.findColumn(nonExistentTable, 'col'), isNull);
      expect(await dbControl.getColumnNames(nonExistentTable), isNull);

      // Проверка метода Batch
      expect(
        await dbControl.addMultipleTableData(nonExistentTable, [{}]),
        isNull,
        reason:
            'addMultipleTableData должен возвращать null для несуществующей таблицы',
      );
    });

    // Тест прочих операций с БД
    test('6. Other DB Operations', () async {
      await dbControl.createTable(testTableName, initialColumns);
      await dbControl.clearTableData(testTableName);
      // Тест optimizeDb
      var isOptimized = await dbControl.optimizeDb();
      expect(
        isOptimized,
        isTrue,
        reason: 'База данных должна быть оптимизирована',
      );

      // Тест getTableDataByParam
      await dbControl.addTableData(testTableName, initialData);
      var retrievedData = await dbControl.getTableDataByParam(
        testTableName,
        'symbol = ?',
        ['BTC'],
      );
      expect(retrievedData, isNotNull);
      expect(retrievedData!.length, 1);
      expect(retrievedData.first['symbol'], 'BTC');
    });
  });
}
