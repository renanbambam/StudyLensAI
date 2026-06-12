import Foundation

/// Typed errors for every feature. Views render `errorDescription` directly.
enum StudyLensError: LocalizedError, Equatable {
    case cameraUnavailable
    case ocrFailed
    case pdfImportFailed
    case emptyScan
    case missingAPIKey
    case networkFailure(statusCode: Int)
    case invalidAIResponse
    case keychainFailure(status: Int32)
    case persistenceFailure(String)

    var errorDescription: String? {
        switch self {
        case .cameraUnavailable:
            "The camera is not available on this device."
        case .ocrFailed:
            "Could not read text from the scanned image. Try better lighting or a flatter page."
        case .pdfImportFailed:
            "Could not read that PDF. Make sure the file opens correctly in Files."
        case .emptyScan:
            "No text was detected in the scan."
        case .missingAPIKey:
            "No Claude API key configured. Add one in Settings."
        case .networkFailure(let statusCode):
            "The AI service request failed (HTTP \(statusCode)). Check your connection and try again."
        case .invalidAIResponse:
            "The AI returned an unexpected response. Try generating again."
        case .keychainFailure(let status):
            "Secure storage error (\(status))."
        case .persistenceFailure(let detail):
            "Could not save your data: \(detail)"
        }
    }
}
