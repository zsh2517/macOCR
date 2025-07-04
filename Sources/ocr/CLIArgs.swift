import ArgumentParser
import Foundation

struct CLIArgs {
    struct ocr: ParsableArguments {

        @Flag(name: [.customShort("c"), .long], help: "Capture screenshot.")
        var capture: Bool = false

        @Option(name: [.customShort("r")], help: "Rectangle to unattendedly capture (-r x,y,w,h), needs --capture.")
        var rectangle: String?

        @Flag(name: [.customShort("s"), .long], help: "Read stdin binary data.")
        var stdin: Bool = false

        @Option(name: [.customShort("i")], help: "Path to input image.", completion: CompletionKind.file(extensions: ["gif", "png", "jpg", "webp", "tiff"]))
        var input: String?

        @Option(name: [.customShort("l"), .long], help: "Recognition language (e.g., en-US, zh-CN, ja-JP, auto). Supports macOS 11+ only.")
        var language: String = "auto"

        @Option(name: [.customShort("o"), .long], help: "Output format: text or json.")
        var output: String = "text"

        @Option(name: [.customShort("m"), .long], help: "Recognition mode: fast or accurate.")
        var mode: String = "fast"
        
        mutating func validate() throws {
            guard output == "text" || output == "json" else {
                throw ValidationError("Output format must be 'text' or 'json'.")
            }
            guard mode == "fast" || mode == "accurate" else {
                throw ValidationError("Mode must be 'fast' or 'accurate'.")
            }
        }

    }
}
