import SwiftUI

struct ResultPreview: View {
    let image: UIImage

    var body: some View {
        GeometryReader { proxy in
            ScrollView([.vertical, .horizontal]) {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.medium)
                    .scaledToFit()
                    .frame(width: min(proxy.size.width, image.size.width))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.separator), lineWidth: 0.5)
                    }
            }
        }
        .frame(minHeight: 420)
    }
}
