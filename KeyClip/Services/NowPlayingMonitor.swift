//
//  NowPlayingMonitor.swift
//  KeyClip
//

import AppKit
import Combine

struct NowPlayingTrack: Equatable {
    let title: String
    let artist: String?
    let artwork: NSImage?
    let isPlaying: Bool
    /// Total track length, when the player reports one (radio/live streams
    /// often don't).
    let duration: TimeInterval?
    /// Elapsed playback position as of `elapsedCapturedAt`, not "right now"
    /// — the adapter only pushes an update when something actually changes,
    /// not once a second, so a live position has to be extrapolated locally
    /// (see `NowPlayingBar.currentElapsed`).
    let elapsedTime: TimeInterval?
    let elapsedCapturedAt: Date
    let bundleIdentifier: String?
}

/// Reads and controls the system-wide "Now Playing" media session (Music,
/// Spotify, Safari/Chrome tabs, etc.) via Apple's private MediaRemote
/// framework. Since macOS 15.4, `mediaremoted` denies MediaRemote access to
/// any process whose bundle identifier doesn't start with `com.apple.`, so a
/// regular app calling the framework directly (even via `dlopen`) gets
/// nothing back. `KeyClip/Vendor/MediaRemoteAdapter/` (BSD-3-Clause,
/// github.com/ungive/mediaremote-adapter) works around this by shelling out
/// to `/usr/bin/perl`, which macOS itself reports with bundle identifier
/// `com.apple.perl5` and is therefore still entitled — the perl script
/// dynamically loads the bundled helper framework (not linked against
/// KeyClip itself, only passed as a path argument) and prints now-playing
/// JSON to stdout. This exposes only the same info the system's own Control
/// Center "Now Playing" widget already shows.
@MainActor
final class NowPlayingMonitor: ObservableObject {
    static let shared = NowPlayingMonitor()

    @Published private(set) var track: NowPlayingTrack?

    private var streamProcess: Process?
    private var stdoutBuffer = Data()

    private enum Command: Int {
        case togglePlayPause = 2
        case nextTrack = 4
        case previousTrack = 5
    }

    private init() {}

    func start() {
        guard streamProcess == nil else { return }
        guard let script = Self.scriptURL, let framework = Self.frameworkURL else { return }

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/perl")
        task.arguments = [script.path, framework.path, "stream", "--no-diff"]

        let outPipe = Pipe()
        task.standardOutput = outPipe
        task.standardError = Pipe() // discard; the script logs expected non-fatal noise here
        outPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let self else { return }
            Task { @MainActor in
                self.consume(data)
            }
        }

        do {
            try task.run()
            streamProcess = task
        } catch {
            streamProcess = nil
        }
    }

    func togglePlayPause() { send(.togglePlayPause) }
    func next() { send(.nextTrack) }
    func previous() { send(.previousTrack) }

    /// Jumps to an absolute position in the current track. The adapter
    /// takes the position in microseconds, not seconds.
    func seek(to seconds: TimeInterval) {
        guard let script = Self.scriptURL, let framework = Self.frameworkURL else { return }
        let micros = Int((max(seconds, 0) * 1_000_000).rounded())
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/perl")
        task.arguments = [script.path, framework.path, "seek", String(micros)]
        task.standardOutput = Pipe()
        task.standardError = Pipe()
        try? task.run()
    }

    /// Brings the app currently playing `track` to the front — clicking the
    /// artwork jumps to whatever's actually playing it (Music, Spotify, a
    /// browser tab's app, etc.), same way clicking a Clipboard/Snippets row
    /// hands focus back to an app. Deliberately `NSWorkspace.openApplication`
    /// rather than `NSRunningApplication.activate(options:)` — the latter is
    /// unreliable called from a background/accessory (`LSUIElement`) process
    /// like KeyClip: it can mark the target as "active" without actually
    /// raising its windows, since it doesn't go through Launch Services as a
    /// user-initiated open request. `openApplication` handles both the
    /// already-running case (just raises it) and the rare race where the
    /// source app quit between the last stream update and this click (relaunches it).
    func openSource() {
        guard let bundleIdentifier = track?.bundleIdentifier,
              let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else { return }
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }

    private func send(_ command: Command) {
        guard let script = Self.scriptURL, let framework = Self.frameworkURL else { return }
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/perl")
        task.arguments = [script.path, framework.path, "send", String(command.rawValue)]
        task.standardOutput = Pipe()
        task.standardError = Pipe()
        try? task.run()
    }

    private func consume(_ data: Data) {
        stdoutBuffer.append(data)
        while let newlineRange = stdoutBuffer.range(of: Data([0x0A])) {
            let lineData = stdoutBuffer.subdata(in: stdoutBuffer.startIndex..<newlineRange.lowerBound)
            stdoutBuffer.removeSubrange(stdoutBuffer.startIndex..<newlineRange.upperBound)
            handle(line: lineData)
        }
    }

    private func handle(line: Data) {
        guard !line.isEmpty,
              let object = try? JSONSerialization.jsonObject(with: line) as? [String: Any],
              let payload = object["payload"] as? [String: Any] else { return }
        guard let title = payload["title"] as? String else {
            track = nil
            return
        }
        let isPlaying = payload["playing"] as? Bool ?? false
        let artist = payload["artist"] as? String
        let duration = payload["duration"] as? Double
        let elapsedTime = payload["elapsedTime"] as? Double
        let bundleIdentifier = payload["bundleIdentifier"] as? String
        var artwork: NSImage?
        if let base64 = payload["artworkData"] as? String, let data = Data(base64Encoded: base64) {
            artwork = NSImage(data: data)
        } else if let previous = track, previous.title == title {
            // Artwork occasionally drops out of a single update for the same
            // track (e.g. right after a seek) — reuse the last known image
            // rather than flashing the placeholder.
            artwork = previous.artwork
        }
        track = NowPlayingTrack(
            title: title, artist: artist, artwork: artwork, isPlaying: isPlaying,
            duration: duration, elapsedTime: elapsedTime, elapsedCapturedAt: Date(),
            bundleIdentifier: bundleIdentifier
        )
    }

    private static var frameworkURL: URL? { findBundleResource("MediaRemoteAdapter.framework") }
    private static var scriptURL: URL? { findBundleResource("mediaremote-adapter.pl") }

    /// Searches the whole Resources tree rather than assuming a fixed path,
    /// since where `KeyClip/Vendor/MediaRemoteAdapter/`'s contents land
    /// inside the built `.app` depends on how Xcode's file-system-synchronized
    /// group flattens/preserves that subfolder — not worth hardcoding and
    /// re-breaking on every Xcode version change.
    private static func findBundleResource(_ name: String) -> URL? {
        guard let resourceURL = Bundle.main.resourceURL else { return nil }
        guard let enumerator = FileManager.default.enumerator(at: resourceURL, includingPropertiesForKeys: nil) else { return nil }
        for case let url as URL in enumerator where url.lastPathComponent == name {
            return url
        }
        return nil
    }
}
