import Foundation
import UIKit

struct ManifestPost: Codable {
    let id: String
    let text: String
    let dateISO8601: String
    let images: [String]
    let location: String?
}

enum PostsStore {
    static func appSupportDir() -> URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
    }

    static func momentsDir() -> URL? {
        guard let base = appSupportDir() else { return nil }
        return base.appendingPathComponent("Moments", isDirectory: true)
    }

    static func manifestURL() -> URL? {
        momentsDir()?.appendingPathComponent("posts.json")
    }

    static func ensureDirs() {
        guard let dir = momentsDir() else { return }
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
    }

    static func loadPosts() -> [Post] {
        ensureDirs()
        guard let url = manifestURL(), let data = try? Data(contentsOf: url) else { return [] }
        let decoder = JSONDecoder()
        guard let items = try? decoder.decode([ManifestPost].self, from: data) else { return [] }
        let fmt = ISO8601DateFormatter()
        var out: [Post] = []
        for it in items {
            let date = fmt.date(from: it.dateISO8601) ?? Date()
            var imgs: [UIImage] = []
            for name in it.images {
                if let fileURL = momentsDir()?.appendingPathComponent(it.id).appendingPathComponent(name),
                   let d = try? Data(contentsOf: fileURL),
                   let img = UIImage(data: d) {
                    imgs.append(img)
                }
            }
            out.append(Post(images: imgs, text: it.text, date: date, location: it.location ?? "未知", manifestId: it.id))
        }
        return out
    }

    static func savePost(text: String, images: [UIImage], date: Date, location: String) -> Post {
        ensureDirs()
        let id = UUID().uuidString
        guard let dir = momentsDir()?.appendingPathComponent(id, isDirectory: true) else {
            return Post(images: images, text: text, date: date, location: location, manifestId: id)
        }
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        var names: [String] = []
        for (idx, img) in images.enumerated() {
            let name = "image_\(idx).jpg"
            let url = dir.appendingPathComponent(name)
            if let data = img.jpegData(compressionQuality: 0.9) {
                try? data.write(to: url, options: .atomic)
                names.append(name)
            } else if let data = img.pngData() {
                try? data.write(to: url, options: .atomic)
                names.append("image_\(idx).png")
            }
        }
        let fmt = ISO8601DateFormatter()
        let entry = ManifestPost(id: id, text: text, dateISO8601: fmt.string(from: date), images: names, location: location)
        var manifest: [ManifestPost] = []
        if let url = manifestURL(), let data = try? Data(contentsOf: url),
           let items = try? JSONDecoder().decode([ManifestPost].self, from: data) {
            manifest = items
        }
        manifest.insert(entry, at: 0)
        if let url = manifestURL() {
            if let data = try? JSONEncoder().encode(manifest) {
                try? data.write(to: url, options: .atomic)
            }
        }
        return Post(images: images, text: text, date: date, location: location, manifestId: id)
    }

    static func deletePost(manifestId: String) {
        ensureDirs()
        // Update manifest
        if let url = manifestURL(),
           let data = try? Data(contentsOf: url),
           let items = try? JSONDecoder().decode([ManifestPost].self, from: data) {
            let filtered = items.filter { $0.id != manifestId }
            if let newData = try? JSONEncoder().encode(filtered) {
                try? newData.write(to: url, options: .atomic)
            }
        }
        // Remove images directory
        if let dir = momentsDir()?.appendingPathComponent(manifestId, isDirectory: true),
           FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.removeItem(at: dir)
        }
    }
}
