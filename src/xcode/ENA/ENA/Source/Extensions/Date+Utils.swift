//
// 🦠 Corona-Warn-App
//

import Foundation

extension Date {

	var hoursSinceNow: Double {
		self.timeIntervalSinceNow / 60 / 60
	}
	
	var unixTimestampInHours: Int {
		return Int(self.timeIntervalSince1970 / 3600)
	}
}
