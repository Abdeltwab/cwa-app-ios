//
// 🦠 Corona-Warn-App
//

import Foundation
import XCTest
@testable import ENA
import OpenCombine

class DiaryEditEntriesViewModelTest: XCTestCase {

	func testContactPersonsStrings() throws {
		let viewModel = DiaryEditEntriesViewModel(entryType: .contactPerson, store: MockDiaryStore())

		XCTAssertEqual(viewModel.title, AppStrings.ContactDiary.EditEntries.ContactPersons.title)
		XCTAssertEqual(viewModel.deleteAllButtonTitle, AppStrings.ContactDiary.EditEntries.ContactPersons.deleteAllButtonTitle)
		XCTAssertEqual(viewModel.alertTitle, AppStrings.ContactDiary.EditEntries.ContactPersons.Alert.title)
		XCTAssertEqual(viewModel.alertMessage, AppStrings.ContactDiary.EditEntries.ContactPersons.Alert.message)
		XCTAssertEqual(viewModel.alertConfirmButtonTitle, AppStrings.ContactDiary.EditEntries.ContactPersons.Alert.confirmButtonTitle)
		XCTAssertEqual(viewModel.alertCancelButtonTitle, AppStrings.ContactDiary.EditEntries.ContactPersons.Alert.cancelButtonTitle)
	}

	func testLocationsStrings() throws {
		let viewModel = DiaryEditEntriesViewModel(entryType: .location, store: MockDiaryStore())

		XCTAssertEqual(viewModel.title, AppStrings.ContactDiary.EditEntries.Locations.title)
		XCTAssertEqual(viewModel.deleteAllButtonTitle, AppStrings.ContactDiary.EditEntries.Locations.deleteAllButtonTitle)
		XCTAssertEqual(viewModel.alertTitle, AppStrings.ContactDiary.EditEntries.Locations.Alert.title)
		XCTAssertEqual(viewModel.alertMessage, AppStrings.ContactDiary.EditEntries.Locations.Alert.message)
		XCTAssertEqual(viewModel.alertConfirmButtonTitle, AppStrings.ContactDiary.EditEntries.Locations.Alert.confirmButtonTitle)
		XCTAssertEqual(viewModel.alertCancelButtonTitle, AppStrings.ContactDiary.EditEntries.Locations.Alert.cancelButtonTitle)
	}

	func testContactPersonsEntriesUpdatedWhenStoreChanges() throws {
		let store = makeMockStore()
		let viewModel = DiaryEditEntriesViewModel(entryType: .contactPerson, store: store)

		let publisherExpectation = expectation(description: "Entries publisher called")
		publisherExpectation.expectedFulfillmentCount = 2

		XCTAssertEqual(viewModel.entries.count, 10)

		var subscriptions = [AnyCancellable]()
		viewModel.$entries.sink { _ in
			publisherExpectation.fulfill()
		}.store(in: &subscriptions)

		store.addContactPerson(name: "Janet Back")

		waitForExpectations(timeout: .medium)

		XCTAssertEqual(viewModel.entries.count, 11)
	}

	func testLocationsEntriesUpdatedWhenStoreChanges() throws {
		let store = makeMockStore()
		let viewModel = DiaryEditEntriesViewModel(entryType: .location, store: store)

		let publisherExpectation = expectation(description: "Entries publisher called")
		publisherExpectation.expectedFulfillmentCount = 2

		XCTAssertEqual(viewModel.entries.count, 2)

		var subscriptions = [AnyCancellable]()
		viewModel.$entries.sink { _ in
			publisherExpectation.fulfill()
		}.store(in: &subscriptions)

		store.addLocation(name: "Zeit für Brot")

		waitForExpectations(timeout: .medium)

		XCTAssertEqual(viewModel.entries.count, 3)
	}

	func testRemoveContactPerson() throws {
		let store = makeMockStore()
		let viewModel = DiaryEditEntriesViewModel(entryType: .contactPerson, store: store)

		let publisherExpectation = expectation(description: "Entries publisher called")
		publisherExpectation.expectedFulfillmentCount = 2

		XCTAssertEqual(viewModel.entries.count, 10)
		XCTAssertEqual(viewModel.entries[0].name, "Andreas Vogel")

		var subscriptions = [AnyCancellable]()
		viewModel.$entries.sink { _ in
			publisherExpectation.fulfill()
		}.store(in: &subscriptions)

		viewModel.removeEntry(at: IndexPath(row: 0, section: 0))

		waitForExpectations(timeout: .medium)

		XCTAssertEqual(viewModel.entries.count, 9)

		let filteredEntries = viewModel.entries.filter { entry in
			if case .contactPerson(let contactPerson) = entry, contactPerson.name == "Andreas Vogel" {
				return true
			}

			return false
		}

		XCTAssertEqual(filteredEntries.count, 0)
	}

	func testRemoveLocation() throws {
		let store = makeMockStore()
		let viewModel = DiaryEditEntriesViewModel(entryType: .location, store: store)

		let publisherExpectation = expectation(description: "Entries publisher called")
		publisherExpectation.expectedFulfillmentCount = 2

		XCTAssertEqual(viewModel.entries.count, 2)
		XCTAssertEqual(viewModel.entries[0].name, "Bakery")

		var subscriptions = [AnyCancellable]()
		viewModel.$entries.sink { _ in
			publisherExpectation.fulfill()
		}.store(in: &subscriptions)

		viewModel.removeEntry(at: IndexPath(row: 0, section: 0))

		waitForExpectations(timeout: .medium)

		XCTAssertEqual(viewModel.entries.count, 1)

		let filteredEntries = viewModel.entries.filter { entry in
			if case .contactPerson(let contactPerson) = entry, contactPerson.name == "Bakery" {
				return true
			}

			return false
		}

		XCTAssertEqual(filteredEntries.count, 0)
	}

	func testRemoveAllContactPersons() throws {
		let store = makeMockStore()
		let viewModel = DiaryEditEntriesViewModel(entryType: .contactPerson, store: store)

		let publisherExpectation = expectation(description: "Entries publisher called")
		publisherExpectation.expectedFulfillmentCount = 2

		XCTAssertEqual(viewModel.entries.count, 10)
		XCTAssertEqual(store.diaryDaysPublisher.value.first?.entries.count, 12)

		var subscriptions = [AnyCancellable]()
		viewModel.$entries.sink { _ in
			publisherExpectation.fulfill()
		}.store(in: &subscriptions)

		viewModel.removeAll()

		waitForExpectations(timeout: .medium)

		XCTAssertEqual(viewModel.entries.count, 0)
		XCTAssertEqual(store.diaryDaysPublisher.value.first?.entries.count, 2)
	}

	func testRemoveAllLocations() throws {
		let store = makeMockStore()
		let viewModel = DiaryEditEntriesViewModel(entryType: .location, store: store)

		let publisherExpectation = expectation(description: "Entries publisher called")
		publisherExpectation.expectedFulfillmentCount = 2

		XCTAssertEqual(viewModel.entries.count, 2)
		XCTAssertEqual(store.diaryDaysPublisher.value.first?.entries.count, 12)

		var subscriptions = [AnyCancellable]()
		viewModel.$entries.sink { _ in
			publisherExpectation.fulfill()
		}.store(in: &subscriptions)

		viewModel.removeAll()

		waitForExpectations(timeout: .medium)

		XCTAssertEqual(viewModel.entries.count, 0)
		XCTAssertEqual(store.diaryDaysPublisher.value.first?.entries.count, 10)
	}

	// MARK: - Private Helpers

	func makeMockStore() -> MockDiaryStore {
		let store = MockDiaryStore()
		store.addContactPerson(name: "Nick Gündling")
		store.addContactPerson(name: "Marcus Scherer")
		store.addContactPerson(name: "Artur Friesen")
		store.addContactPerson(name: "Pascal Brause")
		store.addContactPerson(name: "Kai Teuber")
		store.addContactPerson(name: "Karsten Gahn")
		store.addContactPerson(name: "Carsten Knoblich")
		store.addContactPerson(name: "Andreas Vogel")
		store.addContactPerson(name: "Puneet Mahali")
		store.addContactPerson(name: "Omar Ahmed")
		store.addLocation(name: "Supermarket")
		store.addLocation(name: "Bakery")

		return store
	}
	
}
