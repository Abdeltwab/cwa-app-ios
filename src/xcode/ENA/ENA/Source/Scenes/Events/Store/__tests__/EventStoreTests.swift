////
// 🦠 Corona-Warn-App
//

import XCTest
import FMDB
import OpenCombine
@testable import ENA

// swiftlint:disable:next type_body_length
class EventStoreTests: XCTestCase {

	var subscriptions = Set<AnyCancellable>()

	func test_When_createTraceLocation_Then_TraceLocationWasCreated_And_PublisherWasUpdated() {
		let store = makeStore(with: makeDatabaseQueue())
		let startDate = Date()
		let endDate = Date()

		let traceLocation = TraceLocation(
			guid: "SomeGUID",
			version: 1,
			type: .type2,
			description: "Some description",
			address: "Some address",
			startDate: startDate,
			endDate: endDate,
			defaultCheckInLengthInMinutes: 1,
			signature: "Some signature"
		)

		let sinkExpectation = expectation(description: "Sink is called once.")
		sinkExpectation.expectedFulfillmentCount = 1

		store.traceLocationsPublisher
			.dropFirst()
			.sink { traceLocations in
				XCTAssertEqual(traceLocations.count, 1)

				let traceLocation = traceLocations[0]
				XCTAssertEqual(traceLocation.guid, "SomeGUID")
				XCTAssertEqual(traceLocation.version, 1)
				XCTAssertEqual(traceLocation.type, .type2)
				XCTAssertEqual(traceLocation.description, "Some description")
				XCTAssertEqual(traceLocation.address, "Some address")
				XCTAssertEqual(traceLocation.defaultCheckInLengthInMinutes, 1)
				XCTAssertEqual(traceLocation.signature, "Some signature")

				guard let startDate2 = traceLocation.startDate else {
					XCTFail("Nil for startDate2 not expected.")
					return
				}
				guard let endDate2 = traceLocation.endDate else {
					XCTFail("Nil for endDate2 not expected.")
					return
				}
				XCTAssertEqual(Int(startDate2.timeIntervalSince1970), Int(startDate.timeIntervalSince1970))
				XCTAssertEqual(Int(endDate2.timeIntervalSince1970), Int(endDate.timeIntervalSince1970))

				sinkExpectation.fulfill()
			}
			.store(in: &subscriptions)

		store.createTraceLocation(traceLocation)

		waitForExpectations(timeout: .medium)
	}

	func test_When_createTraceLocationWilNilDates_Then_TraceLocationWasCreated_And_PublisherWasUpdated() {
		let store = makeStore(with: makeDatabaseQueue())

		let traceLocation = TraceLocation(
			guid: "SomeGUID",
			version: 1,
			type: .type2,
			description: "Some description",
			address: "Some address",
			startDate: nil,
			endDate: nil,
			defaultCheckInLengthInMinutes: nil,
			signature: "Some signature"
		)

		let sinkExpectation = expectation(description: "Sink is called once.")
		sinkExpectation.expectedFulfillmentCount = 1

		store.traceLocationsPublisher
			.dropFirst()
			.sink { traceLocations in
				XCTAssertEqual(traceLocations.count, 1)

				let traceLocation = traceLocations[0]
				XCTAssertEqual(traceLocation.guid, "SomeGUID")
				XCTAssertEqual(traceLocation.version, 1)
				XCTAssertEqual(traceLocation.type, .type2)
				XCTAssertEqual(traceLocation.description, "Some description")
				XCTAssertEqual(traceLocation.address, "Some address")
				XCTAssertEqual(traceLocation.signature, "Some signature")
				XCTAssertNil(traceLocation.defaultCheckInLengthInMinutes)
				XCTAssertNil(traceLocation.startDate)
				XCTAssertNil(traceLocation.endDate)

				sinkExpectation.fulfill()
			}
			.store(in: &subscriptions)

		store.createTraceLocation(traceLocation)

		waitForExpectations(timeout: .medium)
	}

	func test_When_deleteTraceLocation_Then_TraceLocationWasDeleted_And_PublisherWasUpdated() {
		let store = makeStore(with: makeDatabaseQueue())

		let traceLocation = makeTraceLocation(guid: "SomeGUID")

		store.createTraceLocation(traceLocation)

		let sinkExpectation = expectation(description: "Sink is called once.")
		sinkExpectation.expectedFulfillmentCount = 1

		store.traceLocationsPublisher
			.dropFirst()
			.sink { traceLocations in
				XCTAssertEqual(traceLocations.count, 0)
				sinkExpectation.fulfill()
			}
			.store(in: &subscriptions)

		store.deleteTraceLocation(guid: "SomeGUID")

		waitForExpectations(timeout: .medium)
	}

	func test_When_deleteAllTraceLocation_Then_AllTraceLocationWereDeleted_And_PublisherWasUpdated() {
		let store = makeStore(with: makeDatabaseQueue())

		store.createTraceLocation(makeTraceLocation(guid: "SomeGUID1"))
		store.createTraceLocation(makeTraceLocation(guid: "SomeGUID2"))

		let sinkExpectation = expectation(description: "Sink is called once.")
		sinkExpectation.expectedFulfillmentCount = 1

		store.traceLocationsPublisher
			.dropFirst()
			.sink { traceLocations in
				XCTAssertEqual(traceLocations.count, 0)
				sinkExpectation.fulfill()
			}
			.store(in: &subscriptions)

		store.deleteAllTraceLocations()

		waitForExpectations(timeout: .medium)
	}

	func test_When_createCheckin_Then_CheckinWasCreated_And_PublisherWasUpdated() {
		let store = makeStore(with: makeDatabaseQueue())
		let traceLocationStartDate = Date()
		let traceLocationEndDate = Date()
		let checkinStartDate = Date()
		let checkinEndDate = Date()
		let targetCheckinEndDate = Date()

		let checkin = Checkin(
			id: 1,
			traceLocationGUID: "SomeGUID",
			traceLocationVersion: 1,
			traceLocationType: .type2,
			traceLocationDescription: "Some description",
			traceLocationAddress: "Some address",
			traceLocationStart: traceLocationStartDate,
			traceLocationEnd: traceLocationEndDate,
			traceLocationDefaultCheckInLengthInMinutes: 1,
			traceLocationSignature: "Some signature",
			checkinStartDate: checkinStartDate,
			checkinEndDate: checkinEndDate,
			targetCheckinEndDate: targetCheckinEndDate,
			createJournalEntry: true
		)

		let sinkExpectation = expectation(description: "Sink is called once.")
		sinkExpectation.expectedFulfillmentCount = 1

		store.checkinsPublisher
			.dropFirst()
			.sink { checkins in
				XCTAssertEqual(checkins.count, 1)

				let checkin = checkins[0]
				XCTAssertEqual(checkin.id, 1)
				XCTAssertEqual(checkin.traceLocationGUID, "SomeGUID")
				XCTAssertEqual(checkin.traceLocationVersion, 1)
				XCTAssertEqual(checkin.traceLocationType, .type2)
				XCTAssertEqual(checkin.traceLocationDescription, "Some description")
				XCTAssertEqual(checkin.traceLocationAddress, "Some address")
				XCTAssertEqual(checkin.traceLocationDefaultCheckInLengthInMinutes, 1)
				XCTAssertEqual(checkin.traceLocationSignature, "Some signature")
				XCTAssertEqual(Int(checkin.checkinStartDate.timeIntervalSince1970), Int(checkinStartDate.timeIntervalSince1970))
				XCTAssertTrue(checkin.createJournalEntry)

				guard let traceLocationStartDate2 = checkin.traceLocationStart else {
					XCTFail("Nil for traceLocationStartDate2 not expected.")
					return
				}
				guard let traceLocationEndDate2 = checkin.traceLocationEnd else {
					XCTFail("Nil for traceLocationEndDate2 not expected.")
					return
				}
				guard let checkinEndDate2 = checkin.checkinEndDate else {
					XCTFail("Nil for checkinEndDate not expected.")
					return
				}
				guard let targetCheckinEndDate2 = checkin.targetCheckinEndDate else {
					XCTFail("Nil for targetCheckinEndDate not expected.")
					return
				}

				XCTAssertEqual(Int(traceLocationStartDate2.timeIntervalSince1970), Int(traceLocationStartDate.timeIntervalSince1970))
				XCTAssertEqual(Int(traceLocationEndDate2.timeIntervalSince1970), Int(traceLocationEndDate.timeIntervalSince1970))
				XCTAssertEqual(Int(checkinEndDate2.timeIntervalSince1970), Int(checkinEndDate.timeIntervalSince1970))
				XCTAssertEqual(Int(targetCheckinEndDate2.timeIntervalSince1970), Int(targetCheckinEndDate.timeIntervalSince1970))

				sinkExpectation.fulfill()
			}
			.store(in: &subscriptions)

		store.createCheckin(checkin)

		waitForExpectations(timeout: .medium)
	}

	func test_When_createCheckinWithNilDates_Then_CheckinWasCreated_And_PublisherWasUpdated() {
		let store = makeStore(with: makeDatabaseQueue())
		let checkinStartDate = Date()

		let checkin = Checkin(
			id: 1,
			traceLocationGUID: "SomeGUID",
			traceLocationVersion: 1,
			traceLocationType: .type2,
			traceLocationDescription: "Some description",
			traceLocationAddress: "Some address",
			traceLocationStart: nil,
			traceLocationEnd: nil,
			traceLocationDefaultCheckInLengthInMinutes: nil,
			traceLocationSignature: "Some signature",
			checkinStartDate: checkinStartDate,
			checkinEndDate: nil,
			targetCheckinEndDate: nil,
			createJournalEntry: true
		)

		let sinkExpectation = expectation(description: "Sink is called once.")
		sinkExpectation.expectedFulfillmentCount = 1

		store.checkinsPublisher
			.dropFirst()
			.sink { checkins in
				XCTAssertEqual(checkins.count, 1)

				let checkin = checkins[0]
				XCTAssertEqual(checkin.id, 1)
				XCTAssertEqual(checkin.traceLocationGUID, "SomeGUID")
				XCTAssertEqual(checkin.traceLocationVersion, 1)
				XCTAssertEqual(checkin.traceLocationType, .type2)
				XCTAssertEqual(checkin.traceLocationDescription, "Some description")
				XCTAssertEqual(checkin.traceLocationAddress, "Some address")
				XCTAssertEqual(checkin.traceLocationSignature, "Some signature")
				XCTAssertEqual(Int(checkin.checkinStartDate.timeIntervalSince1970), Int(checkinStartDate.timeIntervalSince1970))
				XCTAssertTrue(checkin.createJournalEntry)
				XCTAssertNil(checkin.traceLocationDefaultCheckInLengthInMinutes)
				XCTAssertNil(checkin.traceLocationStart)
				XCTAssertNil(checkin.traceLocationEnd)
				XCTAssertNil(checkin.checkinEndDate)
				XCTAssertNil(checkin.targetCheckinEndDate)

				sinkExpectation.fulfill()
			}
			.store(in: &subscriptions)

		store.createCheckin(checkin)

		waitForExpectations(timeout: .medium)
	}

	func test_When_deleteCheckin_Then_CheckinWasDeleted_And_PublisherWasUpdated() {
		let store = makeStore(with: makeDatabaseQueue())

		let checkin = makeCheckin(id: 1)
		store.createCheckin(checkin)

		let sinkExpectation = expectation(description: "Sink is called once.")
		sinkExpectation.expectedFulfillmentCount = 1

		store.checkinsPublisher
			.dropFirst()
			.sink { checkins in
				XCTAssertEqual(checkins.count, 0)
				sinkExpectation.fulfill()
			}
			.store(in: &subscriptions)

		store.deleteCheckin(id: 1)

		waitForExpectations(timeout: .medium)
	}

	func test_When_deleteAllCheckins_Then_AllCheckinsWereDeleted_And_PublisherWasUpdated() {
		let store = makeStore(with: makeDatabaseQueue())

		store.createCheckin(makeCheckin(id: 1))
		store.createCheckin(makeCheckin(id: 2))

		let sinkExpectation = expectation(description: "Sink is called once.")
		sinkExpectation.expectedFulfillmentCount = 1

		store.checkinsPublisher
			.dropFirst()
			.sink { checkins in
				XCTAssertEqual(checkins.count, 0)
				sinkExpectation.fulfill()
			}
			.store(in: &subscriptions)

		store.deleteAllCheckins()

		waitForExpectations(timeout: .medium)
	}

	func test_When_updateCheckin_Then_CheckinWereUpdated_And_PublisherWasUpdated() throws {
		let store = makeStore(with: makeDatabaseQueue())

		store.createCheckin(makeCheckin(id: 1))

		let tomorrowDate = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 1, to: Date()))

		let sinkExpectation = expectation(description: "Sink is called once.")
		sinkExpectation.expectedFulfillmentCount = 1

		store.checkinsPublisher
			.dropFirst()
			.sink { checkins in
				XCTAssertEqual(checkins.count, 1)

				let checkin = checkins[0]
				guard let checkinEndDate = checkin.checkinEndDate else {
					XCTFail("Nil for checkinEndDate not expected.")
					return
				}
				XCTAssertEqual(Int(checkinEndDate.timeIntervalSince1970), Int(tomorrowDate.timeIntervalSince1970))
				XCTAssertTrue(checkin.createJournalEntry)

				sinkExpectation.fulfill()
			}
			.store(in: &subscriptions)

		store.updateCheckin(id: 1, endDate: tomorrowDate)

		waitForExpectations(timeout: .medium)
	}

	func test_When_createTraceTimeIntervalMatch_Then_TraceTimeIntervalMatchWasCreated_And_PublisherWasUpdated() {
		let store = makeStore(with: makeDatabaseQueue())

		let traceTimeIntervalMatch = TraceTimeIntervalMatch(
			id: 1,
			checkinId: 2,
			traceWarningPackageId: 3,
			traceLocationGUID: "someGUID",
			transmissionRiskLevel: 5,
			startIntervalNumber: 6,
			endIntervalNumber: 7
		)

		let sinkExpectation = expectation(description: "Sink is called once.")
		sinkExpectation.expectedFulfillmentCount = 1

		store.traceTimeIntervalMatchesPublisher
			.dropFirst()
			.sink { traceTimeIntervalMatches in
				XCTAssertEqual(traceTimeIntervalMatches.count, 1)

				let traceTimeIntervalMatch = traceTimeIntervalMatches[0]
				XCTAssertEqual(traceTimeIntervalMatch.id, 1)
				XCTAssertEqual(traceTimeIntervalMatch.checkinId, 2)
				XCTAssertEqual(traceTimeIntervalMatch.traceWarningPackageId, 3)
				XCTAssertEqual(traceTimeIntervalMatch.traceLocationGUID, "someGUID")
				XCTAssertEqual(traceTimeIntervalMatch.transmissionRiskLevel, 5)
				XCTAssertEqual(traceTimeIntervalMatch.startIntervalNumber, 6)
				XCTAssertEqual(traceTimeIntervalMatch.endIntervalNumber, 7)

				sinkExpectation.fulfill()
			}
			.store(in: &subscriptions)

		store.createTraceTimeIntervalMatch(traceTimeIntervalMatch)

		waitForExpectations(timeout: .medium)
	}

	func test_When_deleteTraceTimeIntervalMatch_Then_TraceTimeIntervalMatchWasDeleted_And_PublisherWasUpdated() {
		let store = makeStore(with: makeDatabaseQueue())
		store.createTraceTimeIntervalMatch(makeTraceTimeIntervalMatch(id: 1))

		let sinkExpectation = expectation(description: "Sink is called once.")
		sinkExpectation.expectedFulfillmentCount = 1

		store.traceTimeIntervalMatchesPublisher
			.dropFirst()
			.sink { traceTimeIntervalMatches in
				XCTAssertEqual(traceTimeIntervalMatches.count, 0)

				sinkExpectation.fulfill()
			}
			.store(in: &subscriptions)

		store.deleteTraceTimeIntervalMatch(id: 1)

		waitForExpectations(timeout: .medium)
	}

	func test_When_createTraceWarningPackageMetadata_Then_TraceWarningPackageMetadataWasCreated_And_PublisherWasUpdated() {
		let store = makeStore(with: makeDatabaseQueue())

		let traceWarningPackageMetadata = TraceWarningPackageMetadata(id: 1, region: "Some Region", eTag: "Some eTag")

		let sinkExpectation = expectation(description: "Sink is called once.")
		sinkExpectation.expectedFulfillmentCount = 1

		store.traceWarningPackageMetadatasPublisher
			.dropFirst()
			.sink { traceWarningPackageMetadatas in
				XCTAssertEqual(traceWarningPackageMetadatas.count, 1)

				let traceWarningPackageMetadata = traceWarningPackageMetadatas[0]
				XCTAssertEqual(traceWarningPackageMetadata.id, 1)
				XCTAssertEqual(traceWarningPackageMetadata.region, "Some Region")
				XCTAssertEqual(traceWarningPackageMetadata.eTag, "Some eTag")

				sinkExpectation.fulfill()
			}
			.store(in: &subscriptions)

		store.createTraceWarningPackageMetadata(traceWarningPackageMetadata)

		waitForExpectations(timeout: .medium)
	}

	func test_When_deleteTraceWarningPackageMetadata_Then_TraceWarningPackageMetadataWasDeleted_And_PublisherWasUpdated() {
		let store = makeStore(with: makeDatabaseQueue())
		store.createTraceWarningPackageMetadata(makeTraceWarningPackageMetadata(id: 1))

		let sinkExpectation = expectation(description: "Sink is called once.")
		sinkExpectation.expectedFulfillmentCount = 1

		store.traceWarningPackageMetadatasPublisher
			.dropFirst()
			.sink { traceWarningPackageMetadatas in
				XCTAssertEqual(traceWarningPackageMetadatas.count, 0)

				sinkExpectation.fulfill()
			}
			.store(in: &subscriptions)

		store.deleteTraceWarningPackageMetadata(id: 1)

		waitForExpectations(timeout: .medium)
	}

	func test_When_StoreIsInitiliazed_Then_OldCheckinAreRemoved() throws {
		let databaseQueue = makeDatabaseQueue()
		let store = makeStore(with: databaseQueue)
		let dataRetentionPeriodInDays = EventStore.dataRetentionPeriodInDays

		let dateOlderThenRetention = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: -dataRetentionPeriodInDays - 1, to: Date()))
		let today = Date()

		// Check if checkins where created.

		let sinkExpectation = expectation(description: "Sink is called once.")
		sinkExpectation.expectedFulfillmentCount = 1
		store.checkinsPublisher.dropFirst(3).sink { checkins in
			XCTAssertEqual(checkins.count, 3)
			sinkExpectation.fulfill()
		}.store(in: &subscriptions)

		// Create different checkins. 2 of them should survive: Nil date and todays date.
		store.createCheckin(makeCheckin(id: 1, checkinEndDate: dateOlderThenRetention))
		store.createCheckin(makeCheckin(id: 2, checkinEndDate: today))
		store.createCheckin(makeCheckin(id: 3, checkinEndDate: nil))

		// At this point cleanup is called internally and old entries are removed.
		let store2 = makeStore(with: databaseQueue)

		let sinkExpectation2 = expectation(description: "Sink is called once.")
		sinkExpectation2.expectedFulfillmentCount = 1
		store2.checkinsPublisher.sink { checkins in
			XCTAssertEqual(checkins.count, 2)
			sinkExpectation2.fulfill()
		}.store(in: &subscriptions)

		waitForExpectations(timeout: .medium)
	}

	func test_When_StoreIsInitiliazed_Then_OldTraceLocationsAreRemoved() throws {
		let databaseQueue = makeDatabaseQueue()
		let store = makeStore(with: databaseQueue)
		let dataRetentionPeriodInDays = EventStore.dataRetentionPeriodInDays

		let dateOlderThenRetention = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: -dataRetentionPeriodInDays - 1, to: Date()))
		let today = Date()

		// Check if TraceLocations where created.

		let sinkExpectation = expectation(description: "Sink is called once.")
		sinkExpectation.expectedFulfillmentCount = 1
		store.traceLocationsPublisher.dropFirst(3).sink { traceLocations in
			XCTAssertEqual(traceLocations.count, 3)
			sinkExpectation.fulfill()
		}.store(in: &subscriptions)

		// Create different traceLocations. 2 of them should survive: 0 date and todays date.
		store.createTraceLocation(makeTraceLocation(guid: "1", endDate: dateOlderThenRetention))
		store.createTraceLocation(makeTraceLocation(guid: "2", endDate: today))
		store.createTraceLocation(makeTraceLocation(guid: "3", endDate: Date(timeIntervalSince1970: 0)))

		// At this point cleanup is called internally and old entries are removed.
		let store2 = makeStore(with: databaseQueue)

		let sinkExpectation2 = expectation(description: "Sink is called once.")
		sinkExpectation2.expectedFulfillmentCount = 1
		store2.traceLocationsPublisher.sink { traceLocations in
			XCTAssertEqual(traceLocations.count, 2)
			sinkExpectation2.fulfill()
		}.store(in: &subscriptions)

		waitForExpectations(timeout: .medium)
	}

	func test_When_StoreIsInitiliazed_Then_OldTraceTimeIntervalMatchesAreRemoved() throws {
		let databaseQueue = makeDatabaseQueue()
		let store = makeStore(with: databaseQueue)
		let dataRetentionPeriodInDays = EventStore.dataRetentionPeriodInDays

		let dateOlderThenRetention = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: -dataRetentionPeriodInDays - 1, to: Date()))
		let today = Date()

		// Check if TraceLocations where created.

		let sinkExpectation = expectation(description: "Sink is called once.")
		sinkExpectation.expectedFulfillmentCount = 1
		store.traceTimeIntervalMatchesPublisher.dropFirst(3).sink { traceTimeIntervalMatches in
			XCTAssertEqual(traceTimeIntervalMatches.count, 3)
			sinkExpectation.fulfill()
		}.store(in: &subscriptions)

		// Create different traceLocations. 1 of them should survive: todays date.
		store.createTraceLocation(makeTraceLocation(guid: "1", endDate: dateOlderThenRetention))
		store.createTraceLocation(makeTraceLocation(guid: "2", endDate: today))
		store.createTraceLocation(makeTraceLocation(guid: "3", endDate: Date(timeIntervalSince1970: 0)))

		store.createTraceTimeIntervalMatch(makeTraceTimeIntervalMatch(id: 1, endIntervalNumber: Int(dateOlderThenRetention.timeIntervalSince1970)))
		store.createTraceTimeIntervalMatch(makeTraceTimeIntervalMatch(id: 2, endIntervalNumber: Int(today.timeIntervalSince1970)))
		store.createTraceTimeIntervalMatch(makeTraceTimeIntervalMatch(id: 3, endIntervalNumber: 0))

		// At this point cleanup is called internally and old entries are removed.
		let store2 = makeStore(with: databaseQueue)

		let sinkExpectation2 = expectation(description: "Sink is called once.")
		sinkExpectation2.expectedFulfillmentCount = 1
		store2.traceTimeIntervalMatchesPublisher.sink { traceTimeIntervalMatches in
			XCTAssertEqual(traceTimeIntervalMatches.count, 1)
			sinkExpectation2.fulfill()
		}.store(in: &subscriptions)

		waitForExpectations(timeout: .medium)
	}

	private func makeDatabaseQueue() -> FMDatabaseQueue {
		guard let databaseQueue = FMDatabaseQueue(path: "file::memory:") else {
			fatalError("Could not create FMDatabaseQueue.")
		}
		return databaseQueue
	}

	private func makeStore(
		with databaseQueue: FMDatabaseQueue,
		dateProvider: DateProviding = DateProvider(),
		schema: StoreSchemaProtocol? = nil,
		migrator: SerialMigratorProtocol? = nil
	) -> EventStore {

		let _schema: StoreSchemaProtocol
		if let schema = schema {
			_schema = schema
		} else {
			_schema = EventStoreSchemaV1(databaseQueue: databaseQueue)
		}

		let _migrator: SerialMigratorProtocol
		if let migrator = migrator {
			_migrator = migrator
		} else {
			_migrator = SerialDatabaseQueueMigrator(queue: databaseQueue, latestVersion: 1, migrations: [])
		}

		guard let store = EventStore(
			databaseQueue: databaseQueue,
			schema: _schema,
			key: "Dummy",
			migrator: _migrator
		) else {
			fatalError("Could not create event store.")
		}

		return store
	}

	private func makeTraceLocation(guid: String, endDate: Date = Date()) -> TraceLocation {
		TraceLocation(
			guid: guid,
			version: 1,
			type: .type2,
			description: "Some description",
			address: "Some address",
			startDate: Date(),
			endDate: endDate,
			defaultCheckInLengthInMinutes: 1,
			signature: "Some signature"
		)
	}

	private func makeCheckin(id: Int, checkinEndDate: Date? = Date()) -> Checkin {
		Checkin(
			id: id,
			traceLocationGUID: "SomeGUID",
			traceLocationVersion: 1,
			traceLocationType: .type2,
			traceLocationDescription: "Some description",
			traceLocationAddress: "Some address",
			traceLocationStart: Date(),
			traceLocationEnd: Date(),
			traceLocationDefaultCheckInLengthInMinutes: 1,
			traceLocationSignature: "Some signature",
			checkinStartDate: Date(),
			checkinEndDate: checkinEndDate,
			targetCheckinEndDate: Date(),
			createJournalEntry: true
		)
	}

	private func makeTraceTimeIntervalMatch(id: Int, endIntervalNumber: Int = 42) -> TraceTimeIntervalMatch {
		TraceTimeIntervalMatch(
			id: id,
			checkinId: 2,
			traceWarningPackageId: 3,
			traceLocationGUID: "someGUID",
			transmissionRiskLevel: 5,
			startIntervalNumber: 6,
			endIntervalNumber: endIntervalNumber
		)
	}

	private func makeTraceWarningPackageMetadata(id: Int) -> TraceWarningPackageMetadata {
		TraceWarningPackageMetadata(id: id, region: "Some Region", eTag: "Some eTag")
	}

	// swiftlint:disable:next type_body_length
}
