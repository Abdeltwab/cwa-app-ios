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

import ExposureNotification
import Foundation
import UserNotifications
import UIKit

enum ExposureNotificationError: Error {
	case exposureNotificationRequired
	case exposureNotificationAuthorization
	case exposureNotificationUnavailable
	/// Typically occurs when `activate()` is called more than once.
	case apiMisuse
	case unknown(String)
}

enum ExposureDetectionError: Error {
	case isAlreadyRunning
}

struct ExposureManagerState: Equatable {
	// MARK: Creating a State

	init(
		authorized: Bool = false,
		enabled: Bool = false,
		status: ENStatus = .unknown
	) {
		self.authorized = authorized
		self.enabled = enabled
		self.status = status


		#if DEBUG
		if isUITesting {
			self.authorized = true
			self.enabled = true

			switch UserDefaults.standard.integer(forKey: "ENStatus") {
			case ENStatus.active.rawValue:
				self.status = .active
			case ENStatus.disabled.rawValue:
				self.status = .disabled
			case ENStatus.bluetoothOff.rawValue:
				self.status = .bluetoothOff
			case ENStatus.restricted.rawValue:
				self.status = .restricted
			case ENStatus.paused.rawValue:
				self.status = .paused
			case ENStatus.unauthorized.rawValue:
				self.status = .unauthorized
			default :
				self.status = .unknown // 0
			}
		}
		#endif
	}

	// MARK: Properties

	private(set) var authorized: Bool
	private(set) var enabled: Bool
	private(set) var status: ENStatus
	var isGood: Bool { authorized && enabled && status == .active }
}

@objc protocol Manager: NSObjectProtocol {
	static var authorizationStatus: ENAuthorizationStatus { get }
	func detectExposures(configuration: ENExposureConfiguration, diagnosisKeyURLs: [URL], completionHandler: @escaping ENDetectExposuresHandler) -> Progress
	func activate(completionHandler: @escaping ENErrorHandler)
	func invalidate()
	var invalidationHandler: (() -> Void)? { get set }
	@objc dynamic var exposureNotificationEnabled: Bool { get }
	func setExposureNotificationEnabled(_ enabled: Bool, completionHandler: @escaping ENErrorHandler)
	@objc dynamic var exposureNotificationStatus: ENStatus { get }
	func getDiagnosisKeys(completionHandler: @escaping ENGetDiagnosisKeysHandler)
	func getTestDiagnosisKeys(completionHandler: @escaping ENGetDiagnosisKeysHandler)
}

extension ENManager: Manager {}

protocol ExposureManagerLifeCycle {
	typealias CompletionHandler = ((ExposureNotificationError?) -> Void)
	func invalidate(handler:(() -> Void)?)
	func activate(completion: @escaping CompletionHandler)
	func enable(completion: @escaping CompletionHandler)
	func disable(completion: @escaping CompletionHandler)
	func preconditions() -> ExposureManagerState
	func reset(handler: (() -> Void)?)
	func requestUserNotificationsPermissions(completionHandler: @escaping (() -> Void))
}


protocol DiagnosisKeysRetrieval {
	func getTestDiagnosisKeys(completionHandler: @escaping ENGetDiagnosisKeysHandler)
	func accessDiagnosisKeys(completionHandler: @escaping ENGetDiagnosisKeysHandler)
	func preconditions() -> ExposureManagerState
}


protocol ExposureDetector {
	func detectExposures(configuration: ENExposureConfiguration, diagnosisKeyURLs: [URL], completionHandler: @escaping ENDetectExposuresHandler) -> Progress
}

protocol ExposureManagerObserving {
	func resume(observer: ENAExposureManagerObserver)
	func alertForBluetoothOff(completion: @escaping () -> Void) -> UIAlertController?
}


typealias ExposureManager = ExposureManagerLifeCycle &
	DiagnosisKeysRetrieval &
	ExposureDetector & ExposureManagerObserving


protocol ENAExposureManagerObserver: AnyObject {
	func exposureManager(
		_ manager: ENAExposureManager,
		didChangeState newState: ExposureManagerState
	)
}

/// Wrapper for ENManager to avoid code duplication and to abstract error handling
final class ENAExposureManager: NSObject, ExposureManager {

	// MARK: Properties

	private weak var exposureManagerObserver: ENAExposureManagerObserver?
	private var statusObservation: NSKeyValueObservation?
	@objc private var manager: Manager
	private var progress: Progress?

	// MARK: Creating a Manager

	init(
		manager: Manager = ENManager()
	) {
		self.manager = manager
		super.init()
	}

	func resume(observer: ENAExposureManagerObserver) {
		// previsously we had a precondion here. Removed for now to track down a bug.
		guard exposureManagerObserver == nil else {
			return
		}

		exposureManagerObserver = observer

		statusObservation = observe(\.manager.exposureNotificationStatus, options: .new) { [weak self] _, _ in
			guard let self = self else { return }
			DispatchQueue.main.async {
				observer.exposureManager(self, didChangeState: self.preconditions())
			}
		}
	}

	// MARK: Activation

	/// Activates `ENManager`
	/// Needs to be called before `ExposureManager.enable()`
	func activate(completion: @escaping CompletionHandler) {
		manager.activate { activationError in
			if let activationError = activationError {
				Log.error("Failed to activate ENManager: \(activationError.localizedDescription)", log: .api)
				self.handleENError(error: activationError, completion: completion)
				return
			}
			completion(nil)
		}
	}

	// MARK: Enable

	/// Asks user for permission to enable ExposureNotification and enables it, if the user grants permission
	/// Expects the callee to invoke `ExposureManager.activate` prior to this function call
	func enable(completion: @escaping CompletionHandler) {
		changeEnabled(to: true, completion: completion)
	}

	/// Disables the ExposureNotification framework
	/// Expects the callee to invoke `ExposureManager.activate` prior to this function call
	func disable(completion: @escaping CompletionHandler) {
		changeEnabled(to: false, completion: completion)
	}

	private func changeEnabled(to status: Bool, completion: @escaping CompletionHandler) {
		manager.setExposureNotificationEnabled(status) { error in
			if let error = error {
				Log.error("Failed to change ENManager.setExposureNotificationEnabled to \(status): \(error.localizedDescription)", log: .api)
				self.handleENError(error: error, completion: completion)
				return
			}
			completion(nil)
		}
	}


	private func disableIfNeeded(completion:@escaping CompletionHandler) {
		manager.exposureNotificationEnabled ? disable(completion: completion) : completion(nil)
	}


	/// Returns an instance of the OptionSet `Preconditions`
	/// Only if `Preconditions.all()`
	func preconditions() -> ExposureManagerState {
		.init(
			authorized: type(of: manager).authorizationStatus == .authorized,
			enabled: manager.exposureNotificationEnabled,
			status: manager.exposureNotificationStatus
		)
	}

	// MARK: Detect Exposures

	/// Wrapper for `ENManager.detectExposures`
	/// `ExposureManager` needs to be activated and enabled
	func detectExposures(configuration: ENExposureConfiguration, diagnosisKeyURLs: [URL], completionHandler: @escaping ENDetectExposuresHandler) -> Progress {
		// An exposure detection is currently running. Call complete with error and return current progress.
		if let progress = progress, !progress.isCancelled && !progress.isFinished {
			Log.error("ENAExposureManager: Exposure detection is allready running.", log: .riskDetection, error: ExposureDetectionError.isAlreadyRunning)
			completionHandler(nil, ExposureDetectionError.isAlreadyRunning)
			return progress
		}

		Log.info("ENAExposureManager: Start exposure detection.", log: .riskDetection)

		let _progress = manager.detectExposures(configuration: configuration, diagnosisKeyURLs: diagnosisKeyURLs) { [weak self] summary, error in
			guard let self = self else { return }
			Log.info("ENAExposureManager: Completed exposure detection.", log: .riskDetection)

			self.progress = nil
			completionHandler(summary, error)
		}

		progress = _progress

		return _progress
	}

	// MARK: Diagnosis Keys

	func getTestDiagnosisKeys(completionHandler: @escaping ENGetDiagnosisKeysHandler) {
		manager.getTestDiagnosisKeys(completionHandler: completionHandler)
	}

	/// Wrapper for `ENManager.getDiagnosisKeys`
	/// `ExposureManager` needs to be activated and enabled
	func accessDiagnosisKeys(completionHandler: @escaping ENGetDiagnosisKeysHandler) {
		if !manager.exposureNotificationEnabled {
			let error = ENError(.notEnabled)
			Log.error(error.localizedDescription, log: .api)
			completionHandler(nil, error)
			return
		}
		// see: https://github.com/corona-warn-app/cwa-app-ios/issues/169
		manager.getDiagnosisKeys(completionHandler: completionHandler)
	}

	// MARK: Error Handling

	private func handleENError(error: Error, completion: @escaping CompletionHandler) {
		if let error = error as? ENError {
			switch error.code {
			case .notAuthorized:
				completion(ExposureNotificationError.exposureNotificationAuthorization)
			case .notEnabled:
				completion(ExposureNotificationError.exposureNotificationRequired)
			case .restricted:
				completion(ExposureNotificationError.exposureNotificationUnavailable)
			case .apiMisuse:
				completion(ExposureNotificationError.apiMisuse)
			default:
				let errorMsg = "[ExposureManager] Not implemented \(error.localizedDescription)"
				Log.error(errorMsg, log: .api)
				completion(ExposureNotificationError.unknown(error.localizedDescription))
			}
		}
	}

	// MARK: Invalidate


	/// Invalidate the EnManager with completion handler
	func invalidate(handler: (() -> Void)?) {
		manager.invalidationHandler = handler
		manager.invalidate()
	}


	/// Reset the ExposureManager
	func reset(handler: (() -> Void)?) {
		statusObservation?.invalidate()
		disableIfNeeded { _ in
			self.exposureManagerObserver = nil
			self.invalidate {
				self.manager = ENManager()
				handler?()
			}
		}
	}


	// MARK: Memory

	deinit {
		manager.invalidate()
	}

	// MARK: User Notifications

	func requestUserNotificationsPermissions(completionHandler: @escaping (() -> Void)) {
		let options: UNAuthorizationOptions = [.alert, .sound, .badge]
		let notificationCenter = UNUserNotificationCenter.current()
		notificationCenter.requestAuthorization(options: options) { _, error in
			if let error = error {
				// handle error
				Log.error("Notification authorization request error: \(error.localizedDescription)", log: .api)
			}
			DispatchQueue.main.async {
				completionHandler()
			}
		}
	}

}

// MARK: Pretty print (Only for debugging)

extension ENStatus: CustomDebugStringConvertible {
	public var debugDescription: String {
		switch self {
		case .unknown:
			return "unknown"
		case .active:
			return "active"
		case .disabled:
			return "disabled"
		case .bluetoothOff:
			return "bluetoothOff"
		case .restricted:
			return "restricted"
		default:
			return "not handled"
		}
	}
}

extension ENAuthorizationStatus: CustomDebugStringConvertible {
	public var debugDescription: String {
		switch self {
		case .unknown:
			return "unknown"
		case .restricted:
			return "restricted"
		case .authorized:
			return "authorized"
		case .notAuthorized:
			return "not authorized"
		default:
			return "not handled"
		}
	}
}

extension ENAExposureManager {

	func alertForBluetoothOff(completion: @escaping () -> Void) -> UIAlertController? {
		if ENManager.authorizationStatus == .authorized && self.manager.exposureNotificationStatus == .bluetoothOff {
			let alert = UIAlertController(
				title: AppStrings.Common.alertTitleBluetoothOff,
				message: AppStrings.Common.alertDescriptionBluetoothOff,
				preferredStyle: .alert
			)
			let completionHandler: (UIAlertAction, @escaping () -> Void) -> Void = { action, completion in
				switch action.style {
				case .default:
					guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
						return
					}
					if UIApplication.shared.canOpenURL(settingsUrl) {
						UIApplication.shared.open(settingsUrl, completionHandler: nil)
					}
				case .cancel, .destructive:
					completion()
				@unknown default:
					fatalError("Not all cases of actions covered when handling the bluetooth")
				}
			}
			alert.addAction(UIAlertAction(title: AppStrings.Common.alertActionOpenSettings, style: .default, handler: { action in completionHandler(action, completion) }))
			alert.addAction(UIAlertAction(title: AppStrings.Common.alertActionLater, style: .cancel, handler: { action in completionHandler(action, completion) }))
			return alert
		}
		return nil
	}
}
