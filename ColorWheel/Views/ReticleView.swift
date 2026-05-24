import SwiftUI

/// Square reticle drawn at the center of the camera preview, sized to match
/// the sampling region (10% × 10% of the frame).
struct ReticleView: View {
    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height) * 0.10
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(.white, lineWidth: 2)
                .frame(width: side, height: side)
                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                .shadow(color: .black.opacity(0.6), radius: 2)
        }
    }
}
