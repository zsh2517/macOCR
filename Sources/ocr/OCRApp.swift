import ArgumentParser
import Foundation
import Cocoa
import Combine
import Vision

import func Darwin.fputs
import var Darwin.stderr

class OCRApp {

    var cancellables = Set<AnyCancellable>()

    func run() {
        let args = CLIArgs.ocr.parseOrExit()
        let image: CGImage?
        switch (args.input, args.stdin, args.capture) {
        case (.some(let path), false, false):
            image = imageFromURL(path.pathAsURL)
        case (.none, true, false):
            image = imageFromStdIn()
        case (.none, false, true):
            let tempURL = URL(fileURLWithPath: "/tmp/ocr-\(UUID().uuidString).png")
            image = imageFromURL(captureRegion(destination: tempURL))
            try? FileManager.default.removeItem(at: tempURL)
        default:
            CLIArgs.ocr.exit(withError: ArgumentParser.ValidationError("Input not properly specified."))
        }
        guard let image = image
        else {
            fputs("Error: neither a valid image path as --input arg nor valid image data via stdin were found.", stderr)
            exit(EXIT_FAILURE)
        }
        detectText(in: image)
            .sink(receiveCompletion: {
                    switch $0 {
                    case .finished:
                        exit(EXIT_SUCCESS)
                    case .failure(let error):
                        fputs(error.localizedDescription, stderr)
                        exit(EXIT_FAILURE)
                    }
                }, receiveValue: {
                    if let text = $0 {
                        print(text)
                    } else {
                        fputs(OCRError.noTextFound.localizedDescription, stderr)
                        exit(EXIT_FAILURE)
                    }
            })
            .store(in: &cancellables)
    }

    func detectText(in image: CGImage) -> AnyPublisher<String?, Error> {
        Deferred<Future<String?, Error>> {
            Future<String?, Error> { compl in
                let requestHandler = VNImageRequestHandler(cgImage: image)
                let request = VNRecognizeTextRequest { request, error in
                    if let error = error {
                        compl(Result { throw error } )
                        return
                    }
                    guard let observations = request.results as? [VNRecognizedTextObservation]
                    else {
                        compl(Result { throw OCRError.noTextFound } )
                        return
                    }

                    compl(Result {
                        observations.compactMap {
                            $0.topCandidates(1).first?.string
                        }.joined(separator: " ")
                    })
                }
                try? requestHandler.perform([request])
            }
        }.eraseToAnyPublisher()
    }

    func imageFromStdIn() -> CGImage? {
        let file = FileHandle.standardInput
        let data = file.readDataToEndOfFile()
        guard let image = NSImage(data: data)
        else { return nil }
        var imageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        return image.cgImage(forProposedRect: &imageRect, context: nil, hints: nil)
    }


    func imageFromURL(_ inputURL: URL) -> CGImage? {
        if let ciImage = CIImage(contentsOf: inputURL),
           let cgImage = CIContext(options: nil)
            .createCGImage(ciImage, from: ciImage.extent) {
            return cgImage
        }
        return nil
    }

}

extension String {
    var pathAsURL: URL {
        let inputPath: String
        if self.hasPrefix("/") {
            inputPath = self
        } else {
            let cwd = FileManager.default.currentDirectoryPath
            inputPath = "\(cwd)/\(self)"
        }
        return URL(fileURLWithPath: inputPath)
    }
}
