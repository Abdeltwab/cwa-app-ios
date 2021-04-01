////
// 🦠 Corona-Warn-App
//

// This implementation is based on the following technical specification.
// For more details please see: https://github.com/corona-warn-app/cwa-app-tech-spec/blob/e87ef2851c91141573d5714fd24485219280543e/docs/spec/event-registration-client.md

import FMDB

class DeleteTraceTimeIntervalMatchQuery: StoreQueryProtocol {

	// MARK: - Init

	init(id: Int) {
		self.id = id
	}

	// MARK: - Protocol StoreQueryProtocol

	func execute(in database: FMDatabase) -> Bool {
		let sql = """
			DELETE FROM TraceTimeIntervalMatch
			WHERE id = ?;
		"""

		do {
			try database.executeUpdate(sql, values: [id])
			return true
		} catch {
			return false
		}
	}

	// MARK: - Private

	private let id: Int

}
