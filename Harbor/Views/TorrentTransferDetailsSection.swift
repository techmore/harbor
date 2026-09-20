import SwiftUI

struct TorrentTransferDetailsSection: View {
    let item: DownloadItem
    let center: DownloadCenter

    @State private var torrentStatus: TorrentStatusSnapshot?
    @State private var loadErrorMessage: String?

    var body: some View {
        DownloadDetailSection(title: "Torrent Details") {
            VStack(alignment: .leading, spacing: 12) {
                if let torrentStatus {
                    LabeledContent("Connected Seeders") {
                        Text(torrentStatus.connectedSeeders?.formatted() ?? "—")
                            .monospacedDigit()
                    }

                    if torrentStatus.files.isEmpty {
                        Text("No torrent files are reported yet.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    } else {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(torrentStatus.files.enumerated()), id: \.element.id) { index, file in
                                if index > 0 {
                                    Divider()
                                }
                                TorrentFileProgressRow(file: file)
                            }
                        }
                    }

                    Text("Per-file piece availability is unavailable.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if loadErrorMessage == nil {
                    ProgressView("Loading torrent details…")
                        .controlSize(.small)
                }

                if let loadErrorMessage {
                    Text(loadErrorMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .task(id: item.backendIdentifier) {
            torrentStatus = nil
            loadErrorMessage = nil
            await refreshTorrentStatus()

            while Task.isCancelled == false {
                do {
                    try await Task.sleep(for: .seconds(2))
                } catch {
                    return
                }
                await refreshTorrentStatus()
            }
        }
    }

    @MainActor
    private func refreshTorrentStatus() async {
        do {
            torrentStatus = try await center.torrentStatus(for: item.id)
            loadErrorMessage = nil
        } catch {
            loadErrorMessage = error.localizedDescription
        }
    }
}

private struct TorrentFileProgressRow: View {
    let file: TorrentFileTransferStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(file.path)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(file.path)
                Spacer(minLength: 4)
                if file.isSelected {
                    Text("\(Int(file.progress * 100))%")
                        .monospacedDigit()
                } else {
                    Text("Not Selected")
                        .foregroundStyle(.secondary)
                }
            }

            ProgressView(value: file.isSelected ? file.progress : 0, total: 1)
                .progressViewStyle(.linear)
                .tint(file.isSelected ? nil : .secondary)

            HStack {
                Text("\(DownloadFormatting.byteString(file.completedLength)) of \(DownloadFormatting.byteString(file.length))")
                    .monospacedDigit()
                Spacer(minLength: 0)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 9)
    }
}
