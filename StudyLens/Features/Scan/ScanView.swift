import SwiftUI
import VisionKit
import PhotosUI
import UniformTypeIdentifiers

struct ScanView: View {

    @State private var viewModel: ScanViewModel
    @State private var showCamera = false
    @State private var showPDFImporter = false
    @State private var photoItem: PhotosPickerItem?
    @State private var subject = ""

    init(dependencies: AppDependencies) {
        _viewModel = State(initialValue: ScanViewModel(
            ocrService: dependencies.ocrService,
            aiService: dependencies.aiService,
            deckRepository: dependencies.deckRepository,
            scanSessionRepository: dependencies.scanSessionRepository,
            analytics: dependencies.analytics
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                content
                if viewModel.isScanning {
                    LoadingOverlay(message: "Reading your notes…")
                } else if viewModel.isGenerating {
                    LoadingOverlay(message: "Generating flashcards…")
                }
            }
            .navigationTitle("Scan Notes")
            .sheet(isPresented: $showCamera) {
                DocumentCameraView { image in
                    Task { await viewModel.scanDocument(image: image) }
                }
                .ignoresSafeArea()
            }
            .navigationDestination(isPresented: bindingForReview) {
                ReviewGeneratedCardsView(viewModel: viewModel)
            }
            .fileImporter(
                isPresented: $showPDFImporter,
                allowedContentTypes: [.pdf]
            ) { result in
                if case .success(let url) = result {
                    Task { await viewModel.importPDF(from: url) }
                }
            }
            .alert(
                "Something went wrong",
                isPresented: .init(
                    get: { viewModel.error != nil },
                    set: { if !$0 { viewModel.error = nil } }
                ),
                presenting: viewModel.error
            ) { _ in
                Button("OK", role: .cancel) {}
            } message: { error in
                Text(error.errorDescription ?? "Unknown error")
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.extractedText.isEmpty {
            emptyState
        } else {
            extractedState
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.viewfinder")
                .font(.system(size: 64))
                .foregroundStyle(Color.accentPrimary)
            Text("Scan your handwritten notes and let AI turn them into flashcards.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            PrimaryButton(title: "Scan Notes", systemImage: "camera.fill") {
                showCamera = true
            }
            .padding(.horizontal, 32)

            Button {
                showPDFImporter = true
            } label: {
                Label("Import PDF from Files", systemImage: "doc.fill")
                    .font(.subheadline)
            }

            PhotosPicker(selection: $photoItem, matching: .images) {
                Label("Import from Photos", systemImage: "photo.on.rectangle")
                    .font(.subheadline)
            }
            .onChange(of: photoItem) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await viewModel.scanDocument(image: image)
                    }
                    photoItem = nil
                }
            }
        }
    }

    private var extractedState: some View {
        ScrollView {
            VStack(spacing: 16) {
                ScanPreviewCard(image: viewModel.scannedImage, text: viewModel.extractedText)

                TextField("Subject (e.g. Biology)", text: $subject)
                    .textFieldStyle(.roundedBorder)

                PrimaryButton(
                    title: "Generate Flashcards",
                    systemImage: "sparkles",
                    isDisabled: subject.trimmingCharacters(in: .whitespaces).isEmpty
                ) {
                    Task { await viewModel.generateFlashcards(subject: subject) }
                }

                Button("Scan Again", role: .destructive) {
                    viewModel.reset()
                    showCamera = true
                }
                .font(.subheadline)
            }
            .padding()
        }
    }

    private var bindingForReview: Binding<Bool> {
        .init(
            get: { !viewModel.generatedDrafts.isEmpty },
            set: { if !$0 { viewModel.generatedDrafts = [] } }
        )
    }
}

struct DocumentCameraView: UIViewControllerRepresentable {

    let onScan: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan, dismiss: { dismiss() })
    }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        private let onScan: (UIImage) -> Void
        private let dismiss: () -> Void

        init(onScan: @escaping (UIImage) -> Void, dismiss: @escaping () -> Void) {
            self.onScan = onScan
            self.dismiss = dismiss
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            // MVP scope: process the first scanned page.
            if scan.pageCount > 0 {
                onScan(scan.imageOfPage(at: 0))
            }
            dismiss()
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            dismiss()
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            dismiss()
        }
    }
}
