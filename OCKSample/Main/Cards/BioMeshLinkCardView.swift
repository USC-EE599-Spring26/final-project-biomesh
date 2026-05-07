//
//  BioMeshLinkCardView.swift
//  OCKSample
//
//  Created by Ray on 4/13/26.
//

import CareKit
import CareKitEssentials
import CareKitStore
import CareKitUI
import SwiftUI

struct LinkView: View {
    @Environment(\.customStyler) private var style
    @Environment(\.isCardEnabled) private var isCardEnabled

    let event: OCKAnyEvent

    private var destinationURL: URL? {
        if let task = event.task as? OCKTask {
            return task.userInfo?[Constants.linkURL].flatMap(URL.init(string:))
        }
        if let task = event.task as? OCKHealthKitTask {
            return task.userInfo?[Constants.linkURL].flatMap(URL.init(string:))
        }
        return nil
    }

    private var iconName: String {
        event.task.asset ?? "link.circle.fill"
    }

    private var iconColor: Color {
        switch event.task.id {
        case TaskID.hydrationGuide:
            return .cyan
        case TaskID.studyResource:
            return .brown
        default:
            return .accentColor
        }
    }

    private var sourceName: String {
        guard let host = destinationURL?.host() else { return "" }
        return host
            .replacingOccurrences(of: "www.", with: "")
    }

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: iconName)
                        .font(.title2)
                        .foregroundStyle(iconColor)
                        .frame(width: 40, height: 40)
                        .background(iconColor.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.title)
                            .font(.headline)
                        if let instructions = event.task.instructions {
                            Text(instructions)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Divider()

                if let destinationURL {
                    Link(destination: destinationURL) {
                        HStack(spacing: 10) {
                            Image(systemName: "safari.fill")
                            Text("Read Article")
                                .fontWeight(.semibold)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(iconColor.gradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Label(sourceName, systemImage: "globe")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No link configured for this resource.")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(isCardEnabled ? [.all] : [])
        }
        .careKitStyle(style)
        .frame(maxWidth: .infinity)
        .padding(.vertical)
    }
}

#if !os(watchOS)
extension LinkView: EventViewable {
    public init?(
        event: OCKAnyEvent,
        store: any OCKAnyStoreProtocol
    ) {
        self.init(event: event)
    }
}
#endif
