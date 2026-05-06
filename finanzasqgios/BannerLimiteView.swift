import SwiftUI

struct BannerLimiteView: View {
    let mensaje  : String
    var onUpgrade: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "crown.fill")
                .foregroundColor(Color(hex: "#FFD700"))
            Text(mensaje)
                .font(Font.caption2)
                .foregroundColor(.textoPrincipal)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button(action: onUpgrade) {
                Text("Premium 👑")
                    .font(Font.caption2.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: "#FF9800"))
                    .cornerRadius(6)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(10)
        .background(
            LinearGradient(
                colors: [Color(hex: "#1A1200"), Color(hex: "#2A1A00")],
                startPoint: .leading, endPoint: .trailing)
        )
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(hex: "#FFD700").opacity(0.4), lineWidth: 1)
        )
    }
}
