import SwiftUI

struct SubjectBadge: View {
    let subject: String
    let colorHex: String

    var body: some View {
        Text(subject)
            .font(.badge)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(hex: colorHex).opacity(0.15))
            .foregroundStyle(Color(hex: colorHex))
            .clipShape(Capsule())
    }
}

#Preview {
    HStack {
        SubjectBadge(subject: "Biology", colorHex: "#16A34A")
        SubjectBadge(subject: "History", colorHex: "#D97706")
    }
    .padding()
}
