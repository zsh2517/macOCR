import ArgumentParser
import Foundation

struct CLIArgs {
    struct ocr: ParsableArguments {

        @Flag(name: [.customShort("c"), .long], help: "[C]apture screenshot.")
        var capture: Bool = false

        @Flag(name: [.customShort("s"), .long], help: "Read [s]tdin binary data.")
        var stdin: Bool = false

        @Option(name: [.customShort("i")], help: "Path to [i]nput image.", completion: CompletionKind.file(extensions: ["gif", "png", "jpg", "webp", "tiff"]))
        var input: String?


    }
}
