//
//  NowPlayingBar.swift
//  KeyClip
//

import SwiftUI

/// Compact "what's playing" strip shown above the tab bar, backed by
/// `NowPlayingMonitor`. Collapses to nothing when no app is reporting a
/// now-playing session, rather than showing an empty/disabled state — most
/// of the time nothing is playing, and a persistent empty bar would just be
/// dead chrome above the tabs.
struct NowPlayingBar: View {
    static let enabledDefaultsKey = "nowPlayingEnabled"

    @EnvironmentObject private var theme: ThemeStore
    @ObservedObject private var monitor = NowPlayingMonitor.shared
    @AppStorage(NowPlayingBar.enabledDefaultsKey) private var isEnabled = true
    @Environment(\.hidePanel) private var hidePanel

    /// Set while the user is actively dragging the scrubber, so the slider
    /// tracks the drag instead of snapping back to the live-extrapolated
    /// position on every `TimelineView` tick.
    @State private var isScrubbing = false
    @State private var scrubTime: TimeInterval = 0

    var body: some View {
        if isEnabled, let track = monitor.track {
            VStack(spacing: 6) {
                HStack(spacing: 10) {
                    Button {
                        hidePanel()
                        monitor.openSource()
                    } label: {
                        artwork(track)
                    }
                    .buttonStyle(.plain)
                    .disabled(track.bundleIdentifier == nil)
                    .help("Jump to the app playing this")
                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.title)
                            .font(.callout.weight(.medium))
                            .foregroundStyle(theme.text)
                            .lineLimit(1)
                        if let artist = track.artist {
                            Text(artist)
                                .font(.caption)
                                .foregroundStyle(theme.text.opacity(0.45))
                                .lineLimit(1)
                        }
                    }
                    Spacer(minLength: 8)
                    controls(track)
                    Button {
                        isEnabled = false
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11))
                    .foregroundStyle(theme.text.opacity(0.5))
                    .help("Hide Now Playing (Settings → Visible Tabs to bring back)")
                }
                if let duration = track.duration {
                    scrubber(track, duration: duration)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(theme.hover)
            .cornerRadius(8)
            .padding(.horizontal, 12)
            .padding(.bottom, 6)
        }
    }

    @ViewBuilder
    private func scrubber(_ track: NowPlayingTrack, duration: TimeInterval) -> some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { context in
            let liveElapsed = currentElapsed(track, at: context.date)
            let displayed = isScrubbing ? scrubTime : liveElapsed
            VStack(spacing: 2) {
                Slider(
                    value: Binding(
                        get: { displayed },
                        set: { scrubTime = $0 }
                    ),
                    in: 0...max(duration, 1),
                    onEditingChanged: { editing in
                        if editing {
                            scrubTime = liveElapsed
                            isScrubbing = true
                        } else {
                            isScrubbing = false
                            monitor.seek(to: scrubTime)
                        }
                    }
                )
                .tint(theme.selected)
                HStack {
                    Text(Self.formatTime(displayed))
                    Spacer()
                    Text(Self.formatTime(duration))
                }
                .font(.caption2)
                .foregroundStyle(theme.text.opacity(0.45))
            }
        }
    }

    /// Extrapolates the live playback position between adapter updates,
    /// which only arrive when something actually changes — not once a
    /// second — so a paused-looking position has to be advanced locally
    /// while playing.
    private func currentElapsed(_ track: NowPlayingTrack, at now: Date) -> TimeInterval {
        guard let elapsedTime = track.elapsedTime else { return 0 }
        guard track.isPlaying else { return elapsedTime }
        let sinceUpdate = now.timeIntervalSince(track.elapsedCapturedAt)
        let projected = elapsedTime + max(sinceUpdate, 0)
        return track.duration.map { min(projected, $0) } ?? projected
    }

    private static func formatTime(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let total = Int(seconds.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    @ViewBuilder
    private func artwork(_ track: NowPlayingTrack) -> some View {
        Group {
            if let artwork = track.artwork {
                Image(nsImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "music.note")
                    .foregroundStyle(theme.text.opacity(0.5))
            }
        }
        .frame(width: 34, height: 34)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func controls(_ track: NowPlayingTrack) -> some View {
        HStack(spacing: 12) {
            Button(action: monitor.previous) {
                Image(systemName: "backward.fill")
            }
            Button(action: monitor.togglePlayPause) {
                Image(systemName: track.isPlaying ? "pause.fill" : "play.fill")
            }
            Button(action: monitor.next) {
                Image(systemName: "forward.fill")
            }
        }
        .buttonStyle(.plain)
        .font(.system(size: 13))
        .foregroundStyle(theme.text)
    }
}
