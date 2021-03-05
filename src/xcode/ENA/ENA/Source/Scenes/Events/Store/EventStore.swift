////
// 🦠 Corona-Warn-App
//

import UIKit
import OpenCombine
import FMDB

class EventStore: EventStoring, EventProviding {

	static let encryptionKeyKey = "EventStoreEncryptionKey"

	// MARK: - Init

	init?(
		databaseQueue: FMDatabaseQueue,
		schema: SchemaProtocol,
		key: String,
		migrator: SerialMigratorProtocol
		) {
		self.databaseQueue = databaseQueue
		self.key = key
		self.schema = schema
		self.migrator = migrator

		guard case .success = openAndSetup() else {
			return nil
		}

		guard case .success = cleanup() else {
			return nil
		}

		registerToDidBecomeActiveNotification()
	}

	// MARK: - Protocol EventStoring

	// swiftlint:disable function_parameter_count
	func createEvent(
		id: String,
		type: Int,
		description: String,
		address: String,
		start: Date,
		end: Date,
		defaultCheckInLengthInMinutes: Int,
		signature: String
	) -> EventStoring.VoidResult {

		var result: EventStoring.VoidResult?

		databaseQueue.inDatabase { database in
			Log.info("[EventStore] Add Event.", log: .localData)

			let sql = """
				INSERT INTO Event (
					id,
					type,
					description,
					address,
					start,
					end,
					defaultCheckInLengthInMinutes,
					signature
				)
				VALUES (
					:id,
					:type,
					SUBSTR(:description, 1, \(maxTextLength)),
					SUBSTR(:address, 1, \(maxTextLength)),
					:start,
					:end,
					:defaultCheckInLengthInMinutes,
					:signature
				);
			"""
			let parameters: [String: Any] = [
				"id": id,
				"type": type,
				"description": description,
				"address": address,
				"start": Int(start.timeIntervalSince1970),
				"end": Int(end.timeIntervalSince1970),
				"defaultCheckInLengthInMinutes": defaultCheckInLengthInMinutes,
				"signature": signature
			]
			guard database.executeUpdate(sql, withParameterDictionary: parameters) else {
				logLastErrorCode(from: database)
				result = .failure(dbError(from: database))
				return
			}

			let updateEventsDaysResult = updateEvents(with: database)
			guard case .success = updateEventsDaysResult else {
				logLastErrorCode(from: database)
				result = .failure(dbError(from: database))
				return
			}

			result = .success(())
		}

		guard let _result = result else {
			fatalError("[EventStore] Result should not be nil.")
		}

		return _result
	}

	func deleteEvent(id: String) -> EventStoring.VoidResult {
		var result: EventStoring.VoidResult?

		databaseQueue.inDatabase { database in
			Log.info("[EventStore] Remove Event with id: \(id).", log: .localData)

			let sql = """
				DELETE FROM Event
				WHERE id = ?;
			"""

			do {
				try database.executeUpdate(sql, values: [id])
			} catch {
				logLastErrorCode(from: database)
				result = .failure(dbError(from: database))
				return
			}

			let updateEventsDaysResult = updateEvents(with: database)
			guard case .success = updateEventsDaysResult else {
				logLastErrorCode(from: database)
				result = .failure(dbError(from: database))
				return
			}

			result = .success(())
		}

		guard let _result = result else {
			fatalError("[ContactDiaryStore] Result should not be nil.")
		}

		return _result
	}

	// swiftlint:disable function_parameter_count
	func createCheckin(
		eventId: String,
		eventType: Int,
		eventDescription: String,
		eventAddress: String,
		eventStart: Date,
		eventEnd: Date,
		eventSignature: String,
		checkinStart: Date,
		checkinEnd: Date) -> EventStoring.IdResult {

		var result: EventStoring.VoidResult?

		databaseQueue.inDatabase { database in
			Log.info("[EventStore] Add Event.", log: .localData)

			let sql = """
				INSERT INTO Event (
					eventId,
					eventType,
					eventDescription,
					eventAddress,
					eventStart,
					eventEnd,
					eventDefaultCheckInLengthInMinutes,
					eventSignature,
					checkinStart,
					checkinEnd
				)
				VALUES (
					:eventId,
					:eventType,
					SUBSTR(:eventDescription, 1, \(maxTextLength))
					SUBSTR(:eventAddress, 1, \(maxTextLength)),
					:eventStart,
					:eventEnd,
					:eventDefaultCheckInLengthInMinutes,
					:eventSignature,
					:checkinStart,
					:checkinEnd
				);
			"""
			let parameters: [String: Any] = [
				"eventId": eventId,
				"eventType": eventType,
				"eventDescription": eventDescription,
				"eventAddress": eventAddress,
				"eventStart": Int(eventStart.timeIntervalSince1970),
				"eventEnd": Int(eventEnd.timeIntervalSince1970),
				"eventDefaultCheckInLengthInMinutes": eventDefaultCheckInLengthInMinutes,
				"eventSignature": eventSignature,
				"checkinStart": Int(checkinStart.timeIntervalSince1970),
				"checkinEnd": Int(checkinEnd.timeIntervalSince1970),
			]
			guard database.executeUpdate(sql, withParameterDictionary: parameters) else {
				logLastErrorCode(from: database)
				result = .failure(dbError(from: database))
				return
			}

			let updateEventsDaysResult = updateEvents(with: database)
			guard case .success = updateEventsDaysResult else {
				logLastErrorCode(from: database)
				result = .failure(dbError(from: database))
				return
			}

			result = .success(())
		}

		guard let _result = result else {
			fatalError("[EventStore] Result should not be nil.")
		}

		return _result
	}

	func deleteCheckin(id: Int) -> EventStoring.VoidResult {

		// TODO AFS

		return .success(())
	}

	func updateCheckin(id: Int, end: Date) -> EventStoring.VoidResult {

		// TODO AFS

		return .success(())
	}

	// MARK: - Protocol EventProviding

	var eventsPublisher = CurrentValueSubject<[Event], Never>([])

	var checkingPublisher = CurrentValueSubject<[Checkin], Never>([])

	// MARK: - Private

	private let databaseQueue: FMDatabaseQueue
	private let key: String
	private let schema: SchemaProtocol
	private let migrator: SerialMigratorProtocol
	private let maxTextLength = 150

	private func openAndSetup() -> EventStoring.VoidResult {
		var errorResult: EventStoring.VoidResult?
		var userVersion: UInt32 = 0

		databaseQueue.inDatabase { database in
			Log.info("[EventStore] Open and setup database.", log: .localData)
			let dbHandle = OpaquePointer(database.sqliteHandle)
			guard CWASQLite.sqlite3_key(dbHandle, key, Int32(key.count)) == SQLITE_OK else {
				Log.error("[EventStore] Unable to set Key for encryption.", log: .localData)
				errorResult = .failure(dbError(from: database))
				return
			}

			guard database.open() else {
				Log.error("[EventStore] Database could not be opened", log: .localData)
				errorResult = .failure(dbError(from: database))
				return
			}

			userVersion = database.userVersion

			let sql = """
				PRAGMA locking_mode=EXCLUSIVE;
				PRAGMA auto_vacuum=2;
				PRAGMA journal_mode=WAL;
			"""
			guard database.executeStatements(sql) else {
				logLastErrorCode(from: database)
				errorResult = .failure(dbError(from: database))
				return
			}
		}

		if let _errorResult = errorResult {
			return _errorResult
		}

		// if version is zero then this means this is a fresh database "i.e no previous app was installed"
		// then we create the latest schema
		if userVersion == 0 {
			let schemaCreateResult = schema.create()
			if case let .failure(error) = schemaCreateResult {
				return .failure(.database(error))
			}
		} else {
			migrate()
		}

		return .success(())
	}

	private func migrate() {
		do {
			try migrator.migrate()
		} catch {
			_ = MigrationError.general(description: error.localizedDescription)
		}
	}

	private func registerToDidBecomeActiveNotification() {
		NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActiveNotification), name: UIApplication.didBecomeActiveNotification, object: nil)
	}

	@objc
	private func didBecomeActiveNotification(_ notification: Notification) {
		cleanup()
	}

	@discardableResult
	private func cleanup() -> EventStoring.VoidResult {
		var result: EventStoring.VoidResult = .success(())

		databaseQueue.inDatabase { database in
			Log.info("[EventStore] Cleanup old entries.", log: .localData)

			// TODO: AFS

//			guard database.beginExclusiveTransaction() else {
//				logLastErrorCode(from: database)
//				result = .failure(dbError(from: database))
//				return
//			}
//
//			let sqlContactPersonEncounter = """
//				DELETE FROM ContactPersonEncounter
//				WHERE date < date('\(todayDateString)','-\(dataRetentionPeriodInDays - 1) days')
//			"""
//
//			let sqlLocationVisit = """
//				DELETE FROM LocationVisit
//				WHERE date < date('\(todayDateString)','-\(dataRetentionPeriodInDays - 1) days')
//			"""
//
//			do {
//				try database.executeUpdate(sqlContactPersonEncounter, values: nil)
//				try database.executeUpdate(sqlLocationVisit, values: nil)
//			} catch {
//				logLastErrorCode(from: database)
//				result = .failure(dbError(from: database))
//				return
//			}
//
//			guard database.commit() else {
//				logLastErrorCode(from: database)
//				result = .failure(dbError(from: database))
//				return
//			}
//
//			let updateDiaryDaysResult = updateDiaryDays(with: database)
//			guard case .success = updateDiaryDaysResult else {
//				logLastErrorCode(from: database)
//				result = .failure(dbError(from: database))
//				return
//			}
		}

		return result
	}

	@discardableResult
	private func updateEvents(with database: FMDatabase) -> EventStore.VoidResult {
		// TODO AFS

		return .success(())
	}

	@discardableResult
	private func updateCheckins(with database: FMDatabase) -> EventStore.VoidResult {
		// TODO AFS

		return .success(())
	}
}

// MARK: Creation

extension EventStore {

	static func make(url: URL? = nil) -> EventStore {
		let storeURL: URL

		if let url = url {
			storeURL = url
		} else {
			storeURL = EventStore.storeURL
		}

		Log.info("[EventStore] Trying to create event store...", log: .localData)

		if let store = EventStore(url: storeURL) {
			Log.info("[EventStore] Successfully created event store", log: .localData)
			return store
		}

		Log.info("[EventStore] Failed to create event store. Try to rescue it...", log: .localData)

		// The database could not be created – To the rescue!
		// Remove the database file and try to init the store a second time.
		do {
			try FileManager.default.removeItem(at: storeURL)
		} catch {
			Log.error("Could not remove item at \(EventStore.storeDirectoryURL)", log: .localData, error: error)
			assertionFailure()
		}

		if let secondTryStore = EventStore(url: storeURL) {
			Log.info("[EventStore] Successfully rescued event store", log: .localData)
			return secondTryStore
		} else {
			Log.info("[EventStore] Failed to rescue event store.", log: .localData)
			fatalError("[EventStore] Could not create event store after second try.")
		}
	}

	private static var storeURL: URL {
		storeDirectoryURL
			.appendingPathComponent("EventStore")
			.appendingPathExtension("sqlite")
	}

	private static var storeDirectoryURL: URL {
		let fileManager = FileManager.default

		guard let storeDirectoryURL = try? fileManager
				.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
				.appendingPathComponent("EventStore") else {
			fatalError("[EventStore] Could not create folder.")
		}

		if !fileManager.fileExists(atPath: storeDirectoryURL.path) {
			do {
				try fileManager.createDirectory(atPath: storeDirectoryURL.path, withIntermediateDirectories: true, attributes: nil)
			} catch {
				Log.error("Could not create directory at \(storeDirectoryURL)", log: .localData, error: error)
				assertionFailure()
			}
		}
		return storeDirectoryURL
	}

	private static var encryptionKey: String {
		guard let keychain = try? KeychainHelper() else {
			fatalError("[EventStore] Failed to create KeychainHelper for event store.")
		}

		let key: String
		if let keyData = keychain.loadFromKeychain(key: EventStore.encryptionKeyKey) {
			key = String(decoding: keyData, as: UTF8.self)
		} else {
			do {
				key = try keychain.generateEventDatabaseKey()
			} catch {
				fatalError("[EventStore] Failed to create key for event store.")
			}
		}

		return key
	}

	private func logLastErrorCode(from database: FMDatabase) {
		Log.error("[EventStore] (\(database.lastErrorCode())) \(database.lastErrorMessage())", log: .localData)
	}

	private func dbError(from database: FMDatabase) -> EventStoringError {
		let dbError = SQLiteErrorCode(rawValue: database.lastErrorCode()) ?? SQLiteErrorCode.unknown
		return .database(dbError)
	}
}

extension EventStore {
	convenience init?(url: URL) {

		guard let databaseQueue = FMDatabaseQueue(path: url.path) else {
			Log.error("[EventStore] Failed to create FMDatabaseQueue.", log: .localData)
			return nil
		}

		let latestDBVersion = 1
		let schema = EventStoreSchemaV1(
			databaseQueue: databaseQueue
		)

		let migrations: [Migration] = []
		let migrator = SerialDatabaseQueueMigrator(
			queue: databaseQueue,
			latestVersion: latestDBVersion,
			migrations: migrations
		)

		self.init(
			databaseQueue: databaseQueue,
			schema: schema,
			key: EventStore.encryptionKey,
			migrator: migrator
		)
	}
}
