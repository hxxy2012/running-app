import Foundation

// MARK: - 数据备份和恢复工具
class BackupHelper {

    static let shared = BackupHelper()

    private init() {}

    // 备份目录
    private let backupDirectory: URL = {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsURL.appendingPathComponent("Backups", isDirectory: true)
    }()

    // MARK: - 备份数据

    /// 备份所有数据
    func backupAllData() async -> Result<URL, Error> {
        do {
            // 确保备份目录存在
            try createBackupDirectoryIfNeeded()

            // 创建备份文件
            let backupURL = createBackupFileURL()

            // 收集所有数据
            let dataDict = await collectAllData()

            // 创建备份包
            let backupData = try await createBackupPackage(data: dataDict)

            // 写入文件
            try backupData.write(to: backupURL)

            Logger.d("Backup created: \(backupURL.path)")
            return .success(backupURL)
        } catch {
            Logger.e("Backup failed", error: error)
            return .failure(error)
        }
    }

    /// 收集所有数据
    private func collectAllData() async -> [String: Any] {
        var dataDict: [String: Any] = [:]

        // 收集跑步记录
        dataDict["runningRecords"] = []

        // 收集成就
        dataDict["achievements"] = []

        // 收集训练计划
        dataDict["trainingPlans"] = []

        // 添加版本信息
        dataDict["version"] = 1

        Logger.d("Data collected")
        return dataDict
    }

    /// 创建备份包
    private func createBackupPackage(data: [String: Any]) async throws -> Data {
        var backupDict: [String: Any] = [:]

        // 添加数据
        backupDict["data"] = data

        // 添加偏好设置
        backupDict["preferences"] = exportPreferences()

        // 添加元数据
        backupDict["metadata"] = createMetadata()

        // 转换为JSON
        let jsonData = try JSONSerialization.data(withJSONObject: backupDict, options: .prettyPrinted)
        return jsonData
    }

    /// 导出偏好设置
    private func exportPreferences() -> [String: Any] {
        let defaults = UserDefaults.standard
        return defaults.dictionaryRepresentation()
    }

    /// 创建元数据
    private func createMetadata() -> [String: Any] {
        let deviceHelper = DeviceHelper.shared
        return [
            "appVersion": deviceHelper.appVersion,
            "backupTime": Date().timeIntervalSince1970,
            "deviceModel": deviceHelper.deviceTypeName,
            "systemVersion": deviceHelper.systemVersion
        ]
    }

    /// 创建备份文件URL
    private func createBackupFileURL() -> URL {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        let fileName = "backup_\(timestamp).json"
        return backupDirectory.appendingPathComponent(fileName)
    }

    /// 创建备份目录
    private func createBackupDirectoryIfNeeded() throws {
        if !FileManager.default.fileExists(atPath: backupDirectory.path) {
            try FileManager.default.createDirectory(
                at: backupDirectory,
                withIntermediateDirectories: true
            )
        }
    }

    // MARK: - 恢复数据

    /// 从备份文件恢复数据
    func restoreFromBackup(_ backupURL: URL) async -> Result<Void, Error> {
        do {
            // 读取备份文件
            let data = try Data(contentsOf: backupURL)
            let backupDict = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            guard let backupDict = backupDict else {
                throw NSError(domain: "BackupHelper", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Invalid backup file format"
                ])
            }

            // 恢复数据
            if let dataDict = backupDict["data"] as? [String: Any] {
                await restoreData(dataDict)
            }

            // 恢复偏好设置
            if let prefsDict = backupDict["preferences"] as? [String: Any] {
                restorePreferences(prefsDict)
            }

            Logger.d("Restore completed")
            return .success(())
        } catch {
            Logger.e("Restore failed", error: error)
            return .failure(error)
        }
    }

    /// 恢复数据
    private func restoreData(_ dataDict: [String: Any]) async {
        // 这里应该将数据写入数据库
        Logger.d("Data restored")
    }

    /// 恢复偏好设置
    private func restorePreferences(_ prefsDict: [String: Any]) {
        let defaults = UserDefaults.standard

        prefsDict.forEach { key, value in
            defaults.set(value, forKey: key)
        }

        defaults.synchronize()
        Logger.d("Preferences restored")
    }

    // MARK: - 导出数据

    /// 导出跑步数据为CSV
    func exportRunningDataToCsv() async -> Result<URL, Error> {
        do {
            let exportURL = createExportFileURL(name: "running_data", extension: "csv")

            // CSV头部
            var csv = "日期,距离(km),时长(秒),配速(min/km),卡路里,平均心率\n"

            // 这里应该从数据库读取数据
            // 示例数据
            csv += "2025-11-17,5.2,1800,5.77,300,145\n"

            // 写入文件
            try csv.write(to: exportURL, atomically: true, encoding: .utf8)

            Logger.d("CSV exported: \(exportURL.path)")
            return .success(exportURL)
        } catch {
            Logger.e("Export CSV failed", error: error)
            return .failure(error)
        }
    }

    /// 导出跑步数据为JSON
    func exportRunningDataToJson() async -> Result<URL, Error> {
        do {
            let exportURL = createExportFileURL(name: "running_data", extension: "json")
            let dataDict = await collectAllData()

            let jsonData = try JSONSerialization.data(withJSONObject: dataDict, options: .prettyPrinted)
            try jsonData.write(to: exportURL)

            Logger.d("JSON exported: \(exportURL.path)")
            return .success(exportURL)
        } catch {
            Logger.e("Export JSON failed", error: error)
            return .failure(error)
        }
    }

    /// 创建导出文件URL
    private func createExportFileURL(name: String, extension: String) -> URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let exportDirectory = documentsURL.appendingPathComponent("Exports", isDirectory: true)

        // 创建导出目录
        try? FileManager.default.createDirectory(at: exportDirectory, withIntermediateDirectories: true)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        let fileName = "\(name)_\(timestamp).\(`extension`)"

        return exportDirectory.appendingPathComponent(fileName)
    }

    // MARK: - 备份管理

    /// 获取所有备份文件
    func getAllBackups() -> [URL] {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: backupDirectory,
                includingPropertiesForKeys: [.creationDateKey],
                options: .skipsHiddenFiles
            )

            return fileURLs
                .filter { $0.pathExtension == "json" && $0.lastPathComponent.hasPrefix("backup_") }
                .sorted { url1, url2 in
                    let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                    let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                    return date1 > date2
                }
        } catch {
            Logger.e("Get backups failed", error: error)
            return []
        }
    }

    /// 删除备份文件
    func deleteBackup(_ backupURL: URL) -> Bool {
        do {
            try FileManager.default.removeItem(at: backupURL)
            Logger.d("Backup deleted: \(backupURL.path)")
            return true
        } catch {
            Logger.e("Delete backup failed", error: error)
            return false
        }
    }

    /// 清理旧备份（保留最近N个）
    func cleanOldBackups(keepCount: Int = 5) {
        let backups = getAllBackups()
        if backups.count > keepCount {
            let toDelete = backups.dropFirst(keepCount)
            toDelete.forEach { _ = deleteBackup($0) }
            Logger.d("Cleaned \(toDelete.count) old backups")
        }
    }

    /// 获取备份文件大小
    func getBackupSize(_ backupURL: URL) -> Int64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: backupURL.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }

    /// 获取备份文件信息
    func getBackupInfo(_ backupURL: URL) -> [String: String] {
        let size = getBackupSize(backupURL)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        let creationDate: Date
        if let resourceValues = try? backupURL.resourceValues(forKeys: [.creationDateKey]),
           let date = resourceValues.creationDate {
            creationDate = date
        } else {
            creationDate = Date()
        }

        return [
            "name": backupURL.lastPathComponent,
            "size": FormatUtils.shared.formatFileSize(size),
            "date": dateFormatter.string(from: creationDate)
        ]
    }
}

// MARK: - 便捷扩展

extension BackupHelper {

    /// 快速备份
    func quickBackup() async -> URL? {
        let result = await backupAllData()
        switch result {
        case .success(let url):
            return url
        case .failure:
            return nil
        }
    }

    /// 快速恢复
    func quickRestore(from url: URL) async -> Bool {
        let result = await restoreFromBackup(url)
        switch result {
        case .success:
            return true
        case .failure:
            return false
        }
    }
}
