import ArgumentParser
import Foundation
import Cocoa
import Combine
import Vision

import func Darwin.fputs
import var Darwin.stderr

struct OCRResult: Codable {
    let id: String
    let text: String
    let position: Position
    
    struct Position: Codable {
        let left: Int
        let top: Int
        let width: Int
        let height: Int
    }
}

class OCRApp {

    var cancellables = Set<AnyCancellable>()

    func run() {
        let args = CLIArgs.ocr.parseOrExit()
        let image: CGImage?
        switch (args.input, args.stdin, args.capture, args.rectangle) {
        case (.some(let path), false, false, .none):
            image = imageFromURL(path.pathAsURL)
        case (.none, true, false, .none):
            image = imageFromStdIn()
        case (.none, false, true, .some(let rect)):
            let tempURL = URL(fileURLWithPath: "/tmp/ocr-\(UUID().uuidString).png")
            image = imageFromURL(captureRegion(destination: tempURL, rect: rect))
            try? FileManager.default.removeItem(at: tempURL)
        case (.none, false, true, .none):
            let tempURL = URL(fileURLWithPath: "/tmp/ocr-\(UUID().uuidString).png")
            image = imageFromURL(captureRegion(destination: tempURL, rect: nil))
            try? FileManager.default.removeItem(at: tempURL)
        default:
            CLIArgs.ocr.exit(withError: ArgumentParser.ValidationError("Input not properly specified."))
        }
        guard let image = image
        else {
            fputs("Error: neither a valid image path as --input arg nor valid image data via stdin were found.", stderr)
            exit(EXIT_FAILURE)
        }
        detectText(in: image, language: args.language, outputFormat: args.output, mode: args.mode)
            .sink(receiveCompletion: {
                    switch $0 {
                    case .finished:
                        exit(EXIT_SUCCESS)
                    case .failure(let error):
                        fputs(error.localizedDescription, stderr)
                        exit(EXIT_FAILURE)
                    }
                }, receiveValue: { result in
                    if let result = result {
                        print(result)
                    } else {
                        fputs(OCRError.noTextFound.localizedDescription, stderr)
                        exit(EXIT_FAILURE)
                    }
            })
            .store(in: &cancellables)
    }

    func detectText(in image: CGImage, language: String, outputFormat: String, mode: String) -> AnyPublisher<String?, Error> {
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

                    if outputFormat == "json" {
                        // JSON 输出格式
                        var results: [OCRResult] = []
                        
                        for (index, observation) in observations.enumerated() {
                            guard let recognizedText = observation.topCandidates(1).first else { continue }
                            
                            // 获取整个文本的边界框
                            let boundingBox = observation.boundingBox
                            
                            // 转换坐标系 (Vision 使用 (0,0) 在左下角，我们转换为左上角)
                            let imageHeight = Double(image.height)
                            let imageWidth = Double(image.width)
                            
                            let left = boundingBox.origin.x * imageWidth
                            let top = (1.0 - boundingBox.origin.y - boundingBox.size.height) * imageHeight
                            let width = boundingBox.size.width * imageWidth
                            let height = boundingBox.size.height * imageHeight
                            
                            let result = OCRResult(
                                id: String(index + 1),
                                text: recognizedText.string,
                                position: OCRResult.Position(
                                    left: Int(left.rounded()),
                                    top: Int(top.rounded()),
                                    width: Int(width.rounded()),
                                    height: Int(height.rounded())
                                )
                            )
                            results.append(result)
                        }
                        
                        do {
                            let jsonData = try JSONEncoder().encode(results)
                            let jsonString = String(data: jsonData, encoding: .utf8) ?? "[]"
                            compl(.success(jsonString))
                        } catch {
                            compl(.failure(error))
                        }
                    } else {
                        // 文本输出格式
                        let text = observations.compactMap {
                            $0.topCandidates(1).first?.string
                        }.joined(separator: " ")
                        compl(.success(text))
                    }
                }
                
                // 设置识别级别 (macOS 15.0+ 支持新 API，较旧版本使用兼容方法)
                if #available(macOS 15.0, *) {
                    // 使用新的 API
                    if language == "auto" {
                        request.automaticallyDetectsLanguage = true
                    } else {
                        request.automaticallyDetectsLanguage = false
                        if #available(macOS 11.0, *) {
                            var recognitionLanguages = ["en-US"]
                            recognitionLanguages.insert(language, at: 0)
                            request.recognitionLanguages = recognitionLanguages
                        }
                    }
                    
                    // 设置识别模式
                    request.recognitionLevel = mode == "accurate" ? .accurate : .fast
                } else {
                    // 兼容较旧版本 (macOS 11-14)
                    if #available(macOS 11.0, *), language != "auto" {
                        var recognitionLanguages = ["en-US"]
                        recognitionLanguages.insert(language, at: 0)
                        request.recognitionLanguages = recognitionLanguages
                    }
                    // 对于旧版本，language == "auto" 时不设置 recognitionLanguages
                    
                    // 旧版本的识别级别设置
                    if #available(macOS 11.0, *) {
                        request.recognitionLevel = mode == "accurate" ? .accurate : .fast
                    }
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
