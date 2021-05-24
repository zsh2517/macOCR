import Foundation

enum OCRError: String, Error {
    case noTextFound = "No text was found"
    case noImagePassed = "No image was passed. Run `ocr --help` for usage information."
}
