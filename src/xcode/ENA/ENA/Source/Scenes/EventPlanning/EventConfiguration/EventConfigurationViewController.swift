//
// 🦠 Corona-Warn-App
//

import UIKit

class EventConfigurationViewController: UIViewController, ENANavigationControllerWithFooterChild {

	// MARK: - Init

	init(
		viewModel: EventConfigurationViewModel,
		onDismiss: @escaping () -> Void
	) {
		self.viewModel = viewModel
		self.onDismiss = onDismiss

		super.init(nibName: nil, bundle: nil)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - Overrides

	override func viewDidLoad() {
		super.viewDidLoad()

		view.backgroundColor = .enaColor(for: .background)

		navigationItem.title = AppStrings.EventPlanning.Configuration.title

		navigationItem.rightBarButtonItem = CloseBarButtonItem { [weak self] in
			self?.onDismiss()
		}

		navigationController?.navigationBar.prefersLargeTitles = true

		footerView?.primaryButton?.accessibilityIdentifier = AccessibilityIdentifiers.ExposureSubmission.primaryButton
	}

	override var navigationItem: UINavigationItem {
		navigationFooterItem
	}

	// MARK: - Protocol ENANavigationControllerWithFooterChild

	func navigationController(_ navigationController: ENANavigationControllerWithFooter, didTapPrimaryButton button: UIButton) {
		navigationFooterItem.isPrimaryButtonLoading = true
		navigationFooterItem.isPrimaryButtonEnabled = false

		viewModel.save { [weak self] success in
			self?.navigationFooterItem.isPrimaryButtonLoading = false
			self?.navigationFooterItem.isPrimaryButtonEnabled = true

			if success {
				self?.onDismiss()
			}
		}
	}


	// MARK: - Private

	private let viewModel: EventConfigurationViewModel

	private let onDismiss: () -> Void

	private lazy var navigationFooterItem: ENANavigationFooterItem = {
		let item = ENANavigationFooterItem()

		item.primaryButtonTitle = AppStrings.EventPlanning.Configuration.primaryButtonTitle
		item.isPrimaryButtonEnabled = true

		item.isSecondaryButtonHidden = true

		return item
	}()

}
