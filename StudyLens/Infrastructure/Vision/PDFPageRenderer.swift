import PDFKit
import UIKit

/// Renders a PDF page to a UIImage so it can flow through the same OCR
/// pipeline as a camera scan (Phase 2: "PDF import — scan from Files").
enum PDFPageRenderer {

    /// Renders the first page at 2x scale for OCR accuracy.
    /// MVP scope mirrors the camera flow: one page per import.
    static func firstPageImage(from url: URL, scale: CGFloat = 2.0) -> UIImage? {
        guard let document = PDFDocument(url: url),
              let page = document.page(at: 0) else { return nil }

        let bounds = page.bounds(for: .mediaBox)
        guard bounds.width > 0, bounds.height > 0 else { return nil }
        let size = CGSize(width: bounds.width * scale, height: bounds.height * scale)

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            // PDF coordinate space is bottom-up; flip before drawing.
            context.cgContext.translateBy(x: 0, y: size.height)
            context.cgContext.scaleBy(x: scale, y: -scale)
            page.draw(with: .mediaBox, to: context.cgContext)
        }
    }
}
