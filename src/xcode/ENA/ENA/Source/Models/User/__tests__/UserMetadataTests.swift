////
// 🦠 Corona-Warn-App
//

@testable import ENA
import XCTest

class UserMetadataTests: XCTestCase {

	func testUserMetadata_ageBelow29() throws {
		let store = MockTestStore()
		store.userMetadata = UserMetadata(
			federalState: "Baden-Württemberg",
			// Rhein-Neckar-Kreis
			administrativeUnit: 11008226,
			ageGroup: .ageBelow29
		)
		XCTAssertEqual(store.userMetadata?.federalState, "Baden-Württemberg")
		XCTAssertEqual(store.userMetadata?.administrativeUnit, 11008226)
		XCTAssertEqual(store.userMetadata?.ageGroup, .ageBelow29)
	}
	
	func testUserMetadata_ageBetween30And59() throws {
		let store = MockTestStore()
		store.userMetadata = UserMetadata(
			federalState: "Baden-Württemberg",
			// Heidelberg
			administrativeUnit: 11008221,
			ageGroup: .ageBetween30And59
		)
		XCTAssertEqual(store.userMetadata?.federalState, "Baden-Württemberg")
		XCTAssertEqual(store.userMetadata?.administrativeUnit, 11008221)
		XCTAssertEqual(store.userMetadata?.ageGroup, .ageBetween30And59)
	}
	
	func testUserMetadata_age60OrAbove() throws {
		let store = MockTestStore()
		store.userMetadata = UserMetadata(
			federalState: "Baden-Württemberg",
			// Mannheim
			administrativeUnit: 11008222,
			ageGroup: .age60OrAbove
		)
		XCTAssertEqual(store.userMetadata?.federalState, "Baden-Württemberg")
		XCTAssertEqual(store.userMetadata?.administrativeUnit, 11008222)
		XCTAssertEqual(store.userMetadata?.ageGroup, .age60OrAbove)
	}

}
