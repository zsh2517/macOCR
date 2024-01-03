import Foundation

func captureRegion(destination: URL, rect: String?) -> URL {
    let destinationPath = destination.path as String
    
    let task = Process()
    task.launchPath = "/usr/sbin/screencapture"
    task.arguments = rect != nil ? ["-R" + rect!, "-x", "-r", destinationPath] : ["-i", "-r", destinationPath]
    task.launch()
    task.waitUntilExit()
    
    return destination
}
