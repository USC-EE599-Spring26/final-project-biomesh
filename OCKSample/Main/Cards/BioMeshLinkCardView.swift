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

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                InformationHeaderView(
                    title: Text(event.title),
                    information: event.detailText,
                    event: event
                )

                Divider()

                if let destinationURL {
                    Link(destination: destinationURL) {
                        HStack(spacing: 10) {
                            Image(systemName: "safari")
                            Text("Open Resource")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Text(destinationURL.absoluteString)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
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
