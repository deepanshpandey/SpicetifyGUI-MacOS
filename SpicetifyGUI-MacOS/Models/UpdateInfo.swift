// UpdateInfo.swift
import Foundation

struct UpdateInfo: Codable {
    let tagName: String
    let name: String
    let htmlUrl: String
    let body: String
    let assets: [Asset]
    let publishedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case htmlUrl = "html_url"
        case body
        case assets
        case publishedAt = "published_at"
    }
    
    struct Asset: Codable {
        let name: String
        let browserDownloadUrl: String
        let size: Int
        
        enum CodingKeys: String, CodingKey {
            case name
            case browserDownloadUrl = "browser_download_url"
            case size
        }
        
        var formattedSize: String {
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = [.useMB, .useKB]
            formatter.countStyle = .file
            return formatter.string(fromByteCount: Int64(size))
        }
    }
    
    var version: String {
        tagName.replacingOccurrences(of: "v", with: "")
    }
    
    var releaseNotes: String {
        body.isEmpty ? "No release notes available." : body
    }
    
    var formattedPublishedDate: String? {
        guard let publishedAt = publishedAt else { return nil }
        
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: publishedAt) else { return nil }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .none
        return displayFormatter.string(from: date)
    }
}

