import Foundation
import UIKit

// MARK: - 缓存管理工具类
class CacheManager {

    static let shared = CacheManager()

    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    private init() {
        // 获取缓存目录
        if let cachesDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            cacheDirectory = cachesDir.appendingPathComponent("RunningApp")

            // 创建缓存目录
            if !fileManager.fileExists(atPath: cacheDirectory.path) {
                try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            }
        } else {
            cacheDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
        }
    }

    // MARK: - 缓存大小

    /// 获取缓存大小（字节）
    func getCacheSize() -> Int64 {
        var size: Int64 = 0

        // App缓存目录
        size += getDirectorySize(at: cacheDirectory)

        // URL缓存
        if let urlCacheSize = URLCache.shared.currentDiskUsage as Int64? {
            size += urlCacheSize
        }

        return size
    }

    /// 获取格式化的缓存大小
    func getFormattedCacheSize() -> String {
        let size = getCacheSize()
        return formatSize(size)
    }

    // MARK: - 清除缓存

    /// 清除所有缓存
    func clearAllCache() async -> Bool {
        var success = true

        // 清除文件缓存
        success = await clearDirectory(at: cacheDirectory) && success

        // 清除URL缓存
        URLCache.shared.removeAllCachedResponses()

        // 清除图片缓存（如果使用了SDWebImage或Kingfisher）
        // ImageCache.default.clearCache()

        Logger.i("Cache cleared successfully")
        return success
    }

    /// 清除图片缓存
    func clearImageCache() async -> Bool {
        let imageDir = cacheDirectory.appendingPathComponent("images")
        return await clearDirectory(at: imageDir)
    }

    /// 清除过期缓存（超过指定天数）
    func clearExpiredCache(days: Int = 7) async -> Int64 {
        let expireDate = Date().addingTimeInterval(-TimeInterval(days * 24 * 60 * 60))
        var deletedSize: Int64 = 0

        func deleteExpiredFiles(at url: URL) {
            guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.contentModificationDateKey]) else {
                return
            }

            for case let fileURL as URL in enumerator {
                do {
                    let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                    if let modificationDate = attributes[.modificationDate] as? Date,
                       modificationDate < expireDate {
                        let fileSize = (attributes[.size] as? Int64) ?? 0
                        try fileManager.removeItem(at: fileURL)
                        deletedSize += fileSize
                    }
                } catch {
                    Logger.e("Failed to delete expired file", error: error)
                }
            }
        }

        deleteExpiredFiles(at: cacheDirectory)

        Logger.i("Deleted expired cache: \(formatSize(deletedSize))")
        return deletedSize
    }

    // MARK: - 目录操作

    /// 获取指定目录的缓存大小
    func getDirectoryCacheSize(dirName: String) -> Int64 {
        let dir = cacheDirectory.appendingPathComponent(dirName)
        return getDirectorySize(at: dir)
    }

    /// 清除指定目录的缓存
    func clearDirectoryCache(dirName: String) async -> Bool {
        let dir = cacheDirectory.appendingPathComponent(dirName)
        return await clearDirectory(at: dir)
    }

    // MARK: - 文件操作

    /// 保存缓存文件
    func saveCache(dirName: String, fileName: String, data: Data) async -> URL? {
        let dir = cacheDirectory.appendingPathComponent(dirName)

        // 创建目录
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }

        let fileURL = dir.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            Logger.e("Save cache failed", error: error)
            return nil
        }
    }

    /// 读取缓存文件
    func readCache(dirName: String, fileName: String) async -> Data? {
        let fileURL = cacheDirectory.appendingPathComponent(dirName).appendingPathComponent(fileName)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            return try Data(contentsOf: fileURL)
        } catch {
            Logger.e("Read cache failed", error: error)
            return nil
        }
    }

    /// 删除缓存文件
    func deleteCache(dirName: String, fileName: String) async -> Bool {
        let fileURL = cacheDirectory.appendingPathComponent(dirName).appendingPathComponent(fileName)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return true
        }

        do {
            try fileManager.removeItem(at: fileURL)
            return true
        } catch {
            Logger.e("Delete cache failed", error: error)
            return false
        }
    }

    /// 缓存是否存在
    func cacheExists(dirName: String, fileName: String) -> Bool {
        let fileURL = cacheDirectory.appendingPathComponent(dirName).appendingPathComponent(fileName)
        return fileManager.fileExists(atPath: fileURL.path)
    }

    /// 获取缓存文件URL
    func getCacheFileURL(dirName: String, fileName: String) -> URL {
        let dir = cacheDirectory.appendingPathComponent(dirName)

        // 创建目录
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }

        return dir.appendingPathComponent(fileName)
    }

    // MARK: - 私有方法

    /// 获取目录大小
    private func getDirectorySize(at url: URL) -> Int64 {
        var size: Int64 = 0

        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }

        for case let fileURL as URL in enumerator {
            do {
                let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                size += (attributes[.size] as? Int64) ?? 0
            } catch {
                continue
            }
        }

        return size
    }

    /// 清空目录
    private func clearDirectory(at url: URL) async -> Bool {
        guard fileManager.fileExists(atPath: url.path) else {
            return true
        }

        do {
            let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            for fileURL in contents {
                try fileManager.removeItem(at: fileURL)
            }
            return true
        } catch {
            Logger.e("Clear directory failed", error: error)
            return false
        }
    }

    /// 格式化文件大小
    private func formatSize(_ size: Int64) -> String {
        let kb: Double = 1024
        let mb = kb * 1024
        let gb = mb * 1024

        let sizeDouble = Double(size)

        if sizeDouble >= gb {
            return String(format: "%.2f GB", sizeDouble / gb)
        } else if sizeDouble >= mb {
            return String(format: "%.2f MB", sizeDouble / mb)
        } else if sizeDouble >= kb {
            return String(format: "%.2f KB", sizeDouble / kb)
        } else {
            return "\(size) B"
        }
    }
}

// MARK: - 缓存键生成器
class CacheKeyGenerator {

    /// 生成图片缓存键
    static func imageKey(url: String) -> String {
        return String(url.hashValue)
    }

    /// 生成API缓存键
    static func apiKey(endpoint: String, params: [String: Any]? = nil) -> String {
        var key = endpoint

        if let params = params {
            let sortedParams = params.sorted { $0.key < $1.key }
            let paramsString = sortedParams.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
            key += "?\(paramsString)"
        }

        return String(key.hashValue)
    }

    /// 生成用户数据缓存键
    static func userDataKey(userId: Int, dataType: String) -> String {
        return "user_\(userId)_\(dataType)"
    }
}

// MARK: - 缓存策略
enum CachePolicy {
    case memory           // 仅内存缓存
    case disk            // 仅磁盘缓存
    case both            // 内存+磁盘缓存
    case none            // 不缓存
}

// MARK: - 内存缓存
class MemoryCache<Value> {

    private let cache = NSCache<NSString, CacheValue<Value>>()
    private let expirationInterval: TimeInterval

    init(countLimit: Int = 100, expirationInterval: TimeInterval = 3600) {
        self.cache.countLimit = countLimit
        self.expirationInterval = expirationInterval
    }

    func set(_ value: Value, forKey key: String) {
        let cacheValue = CacheValue(value: value, expirationDate: Date().addingTimeInterval(expirationInterval))
        cache.setObject(cacheValue, forKey: key as NSString)
    }

    func get(forKey key: String) -> Value? {
        guard let cacheValue = cache.object(forKey: key as NSString) else {
            return nil
        }

        // 检查是否过期
        if cacheValue.expirationDate < Date() {
            cache.removeObject(forKey: key as NSString)
            return nil
        }

        return cacheValue.value
    }

    func remove(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }

    func removeAll() {
        cache.removeAllObjects()
    }

    private class CacheValue<T> {
        let value: T
        let expirationDate: Date

        init(value: T, expirationDate: Date) {
            self.value = value
            self.expirationDate = expirationDate
        }
    }
}
