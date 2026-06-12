import SwiftUI
import UIKit

struct ScanPreviewCard: View {
    let image: UIImage?
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Text("Extracted text")
                .font(.statLabel)
                .foregroundStyle(.secondary)

            Text(text)
                .font(.footnote)
                .lineLimit(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
