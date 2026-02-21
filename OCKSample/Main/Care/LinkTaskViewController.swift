import UIKit
import CareKit
import CareKitStore
import CareKitUI
import SwiftUI

final class LinkTaskViewController: UIViewController {

    private let instructionsVC: OCKInstructionsTaskViewController
    private let taskTitle: String
    private let taskInstructions: String?
    init(task: OCKTask, query: OCKEventQuery, store: any OCKAnyStoreProtocol) {
        self.instructionsVC = OCKInstructionsTaskViewController(query: query, store: store)
        self.taskTitle = task.title ?? "Resource"
        self.taskInstructions = task.instructions
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.topAnchor.constraint(equalTo: view.topAnchor),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        addChild(instructionsVC)
        stack.addArrangedSubview(instructionsVC.view)
        instructionsVC.didMove(toParent: self)

        let divider = UIView()
        divider.backgroundColor = .separator
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        stack.addArrangedSubview(divider)

        let button = UIButton(type: .system)
        button.setTitle("View Resource", for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.contentHorizontalAlignment = .leading
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        button.addTarget(self, action: #selector(showResource), for: .touchUpInside)
        stack.addArrangedSubview(button)
    }

    @objc private func showResource() {
        let detail = ResourceDetailView(title: taskTitle, content: taskInstructions ?? "")
        let host = UIHostingController(rootView: detail)
        host.modalPresentationStyle = .pageSheet
        present(host, animated: true)
    }
}

private struct ResourceDetailView: View {
    let title: String
    let content: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(content.isEmpty ? "No additional details provided." : content)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
