import UIKit
import ImageIO

/// Фото хранятся файлами (не в БД), сжимаются до 1600px, миниатюры декодируются через ImageIO и кэшируются.
enum ImageStore {
    private static let cache: NSCache<NSString, UIImage> = {
        let c = NSCache<NSString, UIImage>()
        c.countLimit = 60
        return c
    }()

    static let dir: URL = {
        let u = URL.documentsDirectory.appending(path: "Photos", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
        return u
    }()

    private static func thumb(_ src: CGImageSource, maxPixel: Int) -> CGImage? {
        let opts: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel
        ]
        return CGImageSourceCreateThumbnailAtIndex(src, 0, opts as CFDictionary)
    }

    static func save(_ data: Data) -> String? {
        guard let src = CGImageSourceCreateWithData(data as CFData, nil),
              let cg = thumb(src, maxPixel: 1600),
              let jpeg = UIImage(cgImage: cg).jpegData(compressionQuality: 0.82) else { return nil }
        let name = UUID().uuidString + ".jpg"
        do {
            try jpeg.write(to: dir.appending(path: name), options: .atomic)
            return name
        } catch { return nil }
    }

    static func load(_ name: String, maxPixel: Int) async -> UIImage? {
        let key = "\(name)#\(maxPixel)" as NSString
        if let hit = cache.object(forKey: key) { return hit }
        let url = dir.appending(path: name)
        let img: UIImage? = await Task.detached(priority: .utility) {
            guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
                  let cg = ImageStore.thumb(src, maxPixel: maxPixel) else { return nil }
            return UIImage(cgImage: cg)
        }.value
        if let img { cache.setObject(img, forKey: key) }
        return img
    }

    static func delete(_ name: String) {
        try? FileManager.default.removeItem(at: dir.appending(path: name))
    }
}
