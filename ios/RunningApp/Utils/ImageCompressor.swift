import UIKit
import Photos

// MARK: - 图片压缩工具类
class ImageCompressor {

    static let shared = ImageCompressor()

    private init() {}

    // MARK: - 压缩配置
    struct CompressConfig {
        var maxWidth: CGFloat = 1080           // 最大宽度
        var maxHeight: CGFloat = 1920          // 最大高度
        var quality: CGFloat = 0.85            // 压缩质量 0-1
        var maxSize: Int = 1024 * 1024        // 最大文件大小（字节）
        var keepExif: Bool = false            // 是否保留EXIF信息

        static let `default` = CompressConfig()
    }

    // MARK: - 压缩图片

    /// 压缩UIImage
    func compress(image: UIImage, config: CompressConfig = .default) async -> Data? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                guard var data = self.compressImage(image, config: config) else {
                    continuation.resume(returning: nil)
                    return
                }

                // 如果超过最大尺寸，降低质量
                var quality = config.quality
                while data.count > config.maxSize && quality > 0.1 {
                    quality -= 0.1
                    var modifiedConfig = config
                    modifiedConfig.quality = quality

                    if let newData = self.compressImage(image, config: modifiedConfig) {
                        data = newData
                    } else {
                        break
                    }
                }

                Logger.d("Image compressed: \(data.count) bytes, quality: \(quality)")
                continuation.resume(returning: data)
            }
        }
    }

    /// 压缩图片并保存到文件
    func compressToFile(image: UIImage, config: CompressConfig = .default) async -> URL? {
        guard let data = await compress(image: image, config: config) else {
            return nil
        }

        return await saveToTempFile(data: data)
    }

    /// 批量压缩图片
    func compressBatch(images: [UIImage], config: CompressConfig = .default) async -> [Data] {
        var results: [Data] = []

        for image in images {
            if let data = await compress(image: image, config: config) {
                results.append(data)
            }
        }

        return results
    }

    /// 从URL加载并压缩图片
    func compressFromURL(_ url: URL, config: CompressConfig = .default) async -> Data? {
        guard let image = UIImage(contentsOfFile: url.path) else {
            return nil
        }

        return await compress(image: image, config: config)
    }

    /// 从PHAsset加载并压缩图片
    func compressFromAsset(_ asset: PHAsset, config: CompressConfig = .default) async -> Data? {
        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.isSynchronous = false
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .exact

            let targetSize = CGSize(width: config.maxWidth, height: config.maxHeight)

            PHImageManager.default().requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                guard let image = image else {
                    continuation.resume(returning: nil)
                    return
                }

                Task {
                    let data = await self.compress(image: image, config: config)
                    continuation.resume(returning: data)
                }
            }
        }
    }

    // MARK: - 私有方法

    /// 压缩图片核心方法
    private func compressImage(_ image: UIImage, config: CompressConfig) -> Data? {
        // 调整大小
        let resizedImage = resize(image: image, maxWidth: config.maxWidth, maxHeight: config.maxHeight)

        // 转换为JPEG数据
        return resizedImage.jpegData(compressionQuality: config.quality)
    }

    /// 调整图片大小
    private func resize(image: UIImage, maxWidth: CGFloat, maxHeight: CGFloat) -> UIImage {
        let width = image.size.width
        let height = image.size.height

        // 如果图片尺寸已经小于目标尺寸，直接返回
        if width <= maxWidth && height <= maxHeight {
            return image
        }

        // 计算缩放比例
        let scale = min(maxWidth / width, maxHeight / height)
        let newSize = CGSize(width: width * scale, height: height * scale)

        // 使用UIGraphicsImageRenderer进行高质量缩放
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }

        return resizedImage
    }

    /// 保存到临时文件
    private func saveToTempFile(data: Data) async -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "compressed_\(UUID().uuidString).jpg"
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            Logger.e("Save to temp file failed", error: error)
            return nil
        }
    }

    // MARK: - 图片信息

    /// 获取图片信息
    func getImageInfo(_ image: UIImage) -> ImageInfo {
        return ImageInfo(
            width: Int(image.size.width),
            height: Int(image.size.height),
            scale: image.scale
        )
    }

    /// 获取图片文件大小
    func getImageDataSize(_ image: UIImage, quality: CGFloat = 1.0) -> Int? {
        return image.jpegData(compressionQuality: quality)?.count
    }

    struct ImageInfo {
        let width: Int
        let height: Int
        let scale: CGFloat
    }
}

// MARK: - UIImage扩展
extension UIImage {

    /// 快速压缩
    func compress(maxWidth: CGFloat = 1080, quality: CGFloat = 0.85) async -> Data? {
        var config = ImageCompressor.CompressConfig()
        config.maxWidth = maxWidth
        config.maxHeight = maxWidth * (size.height / size.width)
        config.quality = quality

        return await ImageCompressor.shared.compress(image: self, config: config)
    }

    /// 调整大小
    func resize(to targetSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    /// 保持宽高比缩放
    func scaleToFit(maxWidth: CGFloat, maxHeight: CGFloat) -> UIImage {
        let width = size.width
        let height = size.height

        if width <= maxWidth && height <= maxHeight {
            return self
        }

        let scale = min(maxWidth / width, maxHeight / height)
        let newSize = CGSize(width: width * scale, height: height * scale)

        return resize(to: newSize)
    }

    /// 裁剪为正方形
    func cropToSquare() -> UIImage? {
        let size = self.size
        let minDimension = min(size.width, size.height)
        let x = (size.width - minDimension) / 2
        let y = (size.height - minDimension) / 2
        let cropRect = CGRect(x: x, y: y, width: minDimension, height: minDimension)

        guard let cgImage = self.cgImage?.cropping(to: cropRect) else {
            return nil
        }

        return UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
    }

    /// 旋转图片
    func rotate(degrees: CGFloat) -> UIImage? {
        let radians = degrees * .pi / 180

        var newSize = CGRect(origin: .zero, size: size)
            .applying(CGAffineTransform(rotationAngle: radians))
            .size

        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { context in
            context.cgContext.translateBy(x: newSize.width / 2, y: newSize.height / 2)
            context.cgContext.rotate(by: radians)
            self.draw(in: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height))
        }
    }

    /// 修正图片方向
    func fixOrientation() -> UIImage {
        if imageOrientation == .up {
            return self
        }

        var transform = CGAffineTransform.identity

        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: .pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: .pi / 2)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: -.pi / 2)
        default:
            break
        }

        switch imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        default:
            break
        }

        guard let cgImage = cgImage,
              let colorSpace = cgImage.colorSpace,
              let context = CGContext(
                data: nil,
                width: Int(size.width),
                height: Int(size.height),
                bitsPerComponent: cgImage.bitsPerComponent,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: cgImage.bitmapInfo.rawValue
              ) else {
            return self
        }

        context.concatenate(transform)

        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }

        guard let newCGImage = context.makeImage() else {
            return self
        }

        return UIImage(cgImage: newCGImage)
    }
}
