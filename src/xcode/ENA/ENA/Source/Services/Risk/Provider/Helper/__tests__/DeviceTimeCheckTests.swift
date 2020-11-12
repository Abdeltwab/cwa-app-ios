//
// Corona-Warn-App
//
// SAP SE and all other contributors
// copyright owners license this file to you under the Apache
// License, Version 2.0 (the "License"); you may not use this
// file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.
//

import XCTest
@testable import ENA

final class DeviceTimeCheckTest: XCTestCase {

	func test_WHEN_CorrectDeviceTime_THEN_DeviceTimeIsCorrectIsSavedToStore() {
		let fakeStore = MockTestStore()
		fakeStore.appConfig = makeAppConfig(killSwitchIsOn: false)

		let serverTime = Date()
		let deviceTime = Date()

		let deviceTimeCheck = DeviceTimeCheck(store: fakeStore)
		deviceTimeCheck.updateDeviceTimeFlags(
			serverTime: serverTime,
			deviceTime: deviceTime
		)

		XCTAssertTrue(fakeStore.isDeviceTimeCorrect)
		XCTAssertFalse(fakeStore.wasDeviceTimeErrorShown)
	}

	func test_WHEN_DeviceTimeIs2HoursInThePast_THEN_DeviceTimeIsCorrectIsSavedToStore() {
		let fakeStore = MockTestStore()
		fakeStore.appConfig = makeAppConfig(killSwitchIsOn: false)
		let twoHourIntevall: Double = 2 * 60 * 60

		let serverTime = Date()
		let deviceTime = serverTime.addingTimeInterval(-twoHourIntevall)

		let deviceTimeCheck = DeviceTimeCheck(store: fakeStore)
		deviceTimeCheck.updateDeviceTimeFlags(
			serverTime: serverTime,
			deviceTime: deviceTime
		)

		XCTAssertTrue(fakeStore.isDeviceTimeCorrect)
		XCTAssertFalse(fakeStore.wasDeviceTimeErrorShown)
	}

	func test_WHEN_DeviceTimeIsOn2HoursInTheFuture_THEN_DeviceTimeIsCorrectIsSavedToStore() {
		let fakeStore = MockTestStore()
		fakeStore.appConfig = makeAppConfig(killSwitchIsOn: false)
		let twoHourIntevall: Double = 2 * 60 * 60

		let serverTime = Date()
		let deviceTime = serverTime.addingTimeInterval(twoHourIntevall)

		let deviceTimeCheck = DeviceTimeCheck(store: fakeStore)
		deviceTimeCheck.updateDeviceTimeFlags(
			serverTime: serverTime,
			deviceTime: deviceTime
		)

		XCTAssertTrue(fakeStore.isDeviceTimeCorrect)
		XCTAssertFalse(fakeStore.wasDeviceTimeErrorShown)
	}

	func test_WHEN_DeviceTimeMoreThen2HoursInThePast_THEN_DeviceTimeIsNOTCorrectIsSavedToStore() {
		let fakeStore = MockTestStore()
		fakeStore.appConfig = makeAppConfig(killSwitchIsOn: false)
		let twoHourOneSecondIntevall: Double = 2 * 60 * 60 + 1

		let serverTime = Date()
		let deviceTime = serverTime.addingTimeInterval(-twoHourOneSecondIntevall)

		let deviceTimeCheck = DeviceTimeCheck(store: fakeStore)
		deviceTimeCheck.updateDeviceTimeFlags(
			serverTime: serverTime,
			deviceTime: deviceTime
		)

		XCTAssertFalse(fakeStore.isDeviceTimeCorrect)
		XCTAssertFalse(fakeStore.wasDeviceTimeErrorShown)
	}

	func test_WHEN_DeviceTimeMoreThen2HoursInTheFuture_THEN_DeviceTimeIsNOTCorrectIsSavedToStore() {
		let fakeStore = MockTestStore()
		fakeStore.appConfig = makeAppConfig(killSwitchIsOn: false)
		let twoHourOneSecondIntevall: Double = 2 * 60 * 60 + 1

		let serverTime = Date()
		let deviceTime = serverTime.addingTimeInterval(twoHourOneSecondIntevall)

		let deviceTimeCheck = DeviceTimeCheck(store: fakeStore)
		deviceTimeCheck.updateDeviceTimeFlags(
			serverTime: serverTime,
			deviceTime: deviceTime
		)

		XCTAssertFalse(fakeStore.isDeviceTimeCorrect)
		XCTAssertFalse(fakeStore.wasDeviceTimeErrorShown)
	}

	func test_WHEN_DeviceTimeMoreThen2HoursInTheFuture_AND_KillSwitchIsActive_THEN_DeviceTimeIsCorrectIsSavedToStore() {
		let fakeStore = MockTestStore()
		fakeStore.appConfig = makeAppConfig(killSwitchIsOn: true)

		let serverTime = Date()
		guard let deviceTime = Calendar.current.date(byAdding: .minute, value: 121, to: serverTime) else {
			XCTFail("Could not create date.")
			return
		}

		let deviceTimeCheck = DeviceTimeCheck(store: fakeStore)
		deviceTimeCheck.updateDeviceTimeFlags(
			serverTime: serverTime,
			deviceTime: deviceTime
		)

		XCTAssertTrue(fakeStore.isDeviceTimeCorrect)
		XCTAssertFalse(fakeStore.wasDeviceTimeErrorShown)
	}

	func test_WHEN_ResetDeviceTimeFlagsToDefault_THEN_DeviceTimeIsCorrectIsSavedToStore() {
		let fakeStore = MockTestStore()
		fakeStore.isDeviceTimeCorrect = false
		fakeStore.wasDeviceTimeErrorShown = true

		let deviceTimeCheck = DeviceTimeCheck(store: fakeStore)
		deviceTimeCheck.resetDeviceTimeFlags()

		XCTAssertTrue(fakeStore.isDeviceTimeCorrect)
		XCTAssertFalse(fakeStore.wasDeviceTimeErrorShown)
	}

	private func makeAppConfig(killSwitchIsOn: Bool) -> SAP_Internal_V2_ApplicationConfigurationIOS {
		var killSwitchFeature = SAP_Internal_V2_AppFeature()
		killSwitchFeature.label = "disable-device-time-check"
		killSwitchFeature.value = killSwitchIsOn ? 1 : 0

		var fakeAppFeatures = SAP_Internal_V2_AppFeatures()
		fakeAppFeatures.appFeatures = [killSwitchFeature]

		var fakeAppConfig = SAP_Internal_V2_ApplicationConfigurationIOS()
		fakeAppConfig.appFeatures = fakeAppFeatures

		return fakeAppConfig
	}
}
