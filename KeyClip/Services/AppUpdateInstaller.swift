//
//  AppUpdateInstaller.swift
//  KeyClip
//

import AppKit

/// Downloads a release zip, swaps it in for the currently running `.app`,
/// and relaunches. This is the "just trust the download" self-update path:
/// no Sparkle, no EdDSA signature, no appcast — the download is verified
/// only by TLS + GitHub's own platform security, same trust boundary
/// `UpdateChecker` already relies on to fetch the version/URL in the first
/// place. That's an explicit, accepted tradeoff for a personal, ad-hoc-signed
/// app rather than a Sparkle-managed one; it means anyone who can put a file
/// at the release asset URL controls what gets installed, but adds no key
/// management or CI secret to maintain.
@MainActor
enum AppUpdateInstaller {
    enum InstallError: Error {
        case downloadFailed
        case unzipFailed
        case packageNotFound
        case scriptFailed
    }

    /// Downloads `assetURL`, unzips it, writes a small relaunch script that
    /// waits for this process to exit before swapping the new build into
    /// place, launches that script detached, then quits the app so the
    /// script can complete the swap. Only returns if something failed
    /// *before* the point of no return (the app is still running); on
    /// success it never returns because the process has quit.
    static func installAndRelaunch(from assetURL: URL) async throws {
        let (downloadedURL, response) = try await URLSession.shared.download(from: assetURL)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw InstallError.downloadFailed
        }

        let workDir = FileManager.default.temporaryDirectory.appendingPathComponent("KeyClipUpdate-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: workDir, withIntermediateDirectories: true)
        // `download(from:)` leaves the file at a system temp location that
        // gets cleaned up once this function returns — move it into our own
        // working directory first so it survives long enough to unzip.
        let zipURL = workDir.appendingPathComponent("update.zip")
        try FileManager.default.moveItem(at: downloadedURL, to: zipURL)

        try await run("/usr/bin/ditto", ["-x", "-k", zipURL.path, workDir.path], failing: .unzipFailed)

        guard let newAppURL = try FileManager.default.contentsOfDirectory(at: workDir, includingPropertiesForKeys: nil)
            .first(where: { $0.pathExtension == "app" }) else {
            throw InstallError.packageNotFound
        }

        let currentAppPath = Bundle.main.bundlePath
        let scriptURL = workDir.appendingPathComponent("relaunch.sh")
        let script = """
        #!/bin/sh
        OLD_APP=\(shellQuote(currentAppPath))
        NEW_APP=\(shellQuote(newAppURL.path))
        PID=\(ProcessInfo.processInfo.processIdentifier)

        while kill -0 "$PID" 2>/dev/null; do
          sleep 0.2
        done

        rm -rf "$OLD_APP"
        if ! mv "$NEW_APP" "$OLD_APP" 2>/dev/null; then
          ditto "$NEW_APP" "$OLD_APP"
        fi
        xattr -dr com.apple.quarantine "$OLD_APP" 2>/dev/null
        open "$OLD_APP"
        rm -rf \(shellQuote(workDir.path))
        """
        try script.write(to: scriptURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

        let relaunchTask = Process()
        relaunchTask.executableURL = URL(fileURLWithPath: "/bin/sh")
        relaunchTask.arguments = [scriptURL.path]
        do {
            try relaunchTask.run()
        } catch {
            throw InstallError.scriptFailed
        }

        NSApp.terminate(nil)
    }

    private static func run(_ path: String, _ arguments: [String], failing error: InstallError) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let task = Process()
            task.executableURL = URL(fileURLWithPath: path)
            task.arguments = arguments
            task.terminationHandler = { process in
                if process.terminationStatus == 0 {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error)
                }
            }
            do {
                try task.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private static func shellQuote(_ path: String) -> String {
        "'" + path.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
