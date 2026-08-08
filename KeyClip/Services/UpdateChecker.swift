//
//  UpdateChecker.swift
//  KeyClip
//

import Foundation

struct ReleaseInfo: Equatable {
    let version: String
    let url: URL
}

enum UpdateCheckResult: Equatable {
    case upToDate
    case updateAvailable(ReleaseInfo)
    case failed
}

/// Queries GitHub's Releases API for the latest published release and
/// compares it to the running app's version — a manual/on-demand check, not
/// an auto-updater. No signing keys or extra dependencies: this is
/// unsandboxed, so plain `URLSession` needs no special entitlement either.
enum UpdateChecker {
    private static let repo = "shinji-kasai/KeyClip"

    static func currentVersion() -> String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }

    static func checkForUpdate() async -> UpdateCheckResult {
        guard let url = URL(string: "https://api.github.com/repos/\(repo)/releases/latest") else {
            return .failed
        }
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
            let remoteVersion = release.tag_name.trimmingCharacters(in: CharacterSet(charactersIn: "v"))
            guard let releaseURL = URL(string: release.html_url) else { return .failed }

            if isVersion(remoteVersion, newerThan: currentVersion()) {
                return .updateAvailable(ReleaseInfo(version: remoteVersion, url: releaseURL))
            }
            return .upToDate
        } catch {
            return .failed
        }
    }

    private struct GitHubRelease: Decodable {
        let tag_name: String
        let html_url: String
    }

    private static func isVersion(_ lhs: String, newerThan rhs: String) -> Bool {
        let lhsParts = lhs.split(separator: ".").compactMap { Int($0) }
        let rhsParts = rhs.split(separator: ".").compactMap { Int($0) }
        for i in 0..<max(lhsParts.count, rhsParts.count) {
            let l = i < lhsParts.count ? lhsParts[i] : 0
            let r = i < rhsParts.count ? rhsParts[i] : 0
            if l != r { return l > r }
        }
        return false
    }
}
