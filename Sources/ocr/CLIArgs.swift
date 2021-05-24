import ArgumentParser
import Foundation

struct CLIArgs {
    struct ocr: ParsableArguments {

        @Flag(name: [.customShort("c"), .long], help: "Capture screenshot.")
        var capture: Bool = false

        @Flag(name: [.customShort("s"), .long], help: "Read stdin binary data.")
        var stdin: Bool = false

        @Option(name: [.customShort("i")], help: "Path to input image.", completion: CompletionKind.file(extensions: ["gif", "png", "jpg", "webp", "tiff"]))
        var input: String?


    }
}
