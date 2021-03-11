////
// 🦠 Corona-Warn-App
//

import Foundation

// ELS errors are a subset of PPAC errors. Let's keep this simple for now
typealias ELSError = PPACError

enum LogError: Error {
	case couldNotReadLogfile(_ message: String? = nil)
}