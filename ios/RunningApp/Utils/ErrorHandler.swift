import Foundation
import Alamofire

// MARK: - 错误处理工具类
class ErrorHandler {

    /// 获取用户友好的错误消息
    static func getErrorMessage(_ error: Error) -> String {
        // NetworkError
        if let networkError = error as? NetworkError {
            return networkError.errorDescription ?? "网络错误"
        }

        // AFError (Alamofire错误)
        if let afError = error as? AFError {
            switch afError {
            case .sessionTaskFailed(let error):
                return handleURLError(error)
            case .responseValidationFailed(let reason):
                return handleValidationError(reason)
            case .responseSerializationFailed(let reason):
                return handleSerializationError(reason)
            default:
                return "网络请求失败"
            }
        }

        // URLError
        if let urlError = error as? URLError {
            return handleURLError(urlError)
        }

        // 其他错误
        return error.localizedDescription
    }

    /// 处理URL错误
    private static func handleURLError(_ error: Error) -> String {
        guard let urlError = error as? URLError else {
            return error.localizedDescription
        }

        switch urlError.code {
        case .notConnectedToInternet:
            return "网络连接失败，请检查网络设置"
        case .timedOut:
            return "网络请求超时，请稍后重试"
        case .cannotFindHost, .cannotConnectToHost:
            return "无法连接到服务器"
        case .networkConnectionLost:
            return "网络连接已断开"
        case .dnsLookupFailed:
            return "DNS解析失败"
        case .badServerResponse:
            return "服务器响应异常"
        case .userCancelledAuthentication, .userAuthenticationRequired:
            return "需要身份验证"
        default:
            return "网络异常：\(urlError.code.rawValue)"
        }
    }

    /// 处理验证错误
    private static func handleValidationError(_ reason: AFError.ResponseValidationFailureReason) -> String {
        switch reason {
        case .unacceptableStatusCode(let code):
            return getHTTPErrorMessage(code)
        default:
            return "响应验证失败"
        }
    }

    /// 处理序列化错误
    private static func handleSerializationError(_ reason: AFError.ResponseSerializationFailureReason) -> String {
        switch reason {
        case .decodingFailed:
            return "数据解析失败"
        case .inputDataNilOrZeroLength:
            return "服务器返回数据为空"
        default:
            return "数据处理失败"
        }
    }

    /// 获取HTTP状态码对应的错误消息
    private static func getHTTPErrorMessage(_ statusCode: Int) -> String {
        switch statusCode {
        case 400:
            return "请求参数错误"
        case 401:
            return "未授权，请重新登录"
        case 403:
            return "禁止访问"
        case 404:
            return "请求的资源不存在"
        case 408:
            return "请求超时，请稍后重试"
        case 429:
            return "请求过于频繁，请稍后再试"
        case 500:
            return "服务器内部错误"
        case 502:
            return "网关错误"
        case 503:
            return "服务暂时不可用，请稍后重试"
        case 504:
            return "网关超时"
        default:
            if (400...499).contains(statusCode) {
                return "客户端错误：\(statusCode)"
            } else if (500...599).contains(statusCode) {
                return "服务器错误：\(statusCode)"
            } else {
                return "网络错误：\(statusCode)"
            }
        }
    }

    /// 根据错误类型获取建议操作
    static func getSuggestion(_ error: Error) -> String? {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return "请确认已连接到互联网"
            case .timedOut:
                return "网络较慢，建议切换到更稳定的网络"
            default:
                return nil
            }
        }

        if let afError = error as? AFError,
           case .responseValidationFailed(let reason) = afError,
           case .unacceptableStatusCode(let code) = reason {
            switch code {
            case 401:
                return "请重新登录"
            case 429:
                return "请等待一段时间后再试"
            case 500...599:
                return "服务器繁忙，请稍后再试"
            default:
                return nil
            }
        }

        return nil
    }

    /// 判断是否为网络问题
    static func isNetworkError(_ error: Error) -> Bool {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotFindHost, .cannotConnectToHost:
                return true
            default:
                return false
            }
        }
        return false
    }

    /// 判断是否为服务器错误
    static func isServerError(_ error: Error) -> Bool {
        if let afError = error as? AFError,
           case .responseValidationFailed(let reason) = afError,
           case .unacceptableStatusCode(let code) = reason {
            return (500...599).contains(code)
        }
        return false
    }

    /// 判断是否需要重新登录
    static func needsReLogin(_ error: Error) -> Bool {
        if let afError = error as? AFError,
           case .responseValidationFailed(let reason) = afError,
           case .unacceptableStatusCode(let code) = reason {
            return code == 401
        }
        return false
    }

    /// 判断错误是否可重试
    static func isRetryable(_ error: Error) -> Bool {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut, .networkConnectionLost:
                return true
            default:
                return false
            }
        }

        if let afError = error as? AFError,
           case .responseValidationFailed(let reason) = afError,
           case .unacceptableStatusCode(let code) = reason {
            switch code {
            case 408, 429, 500, 502, 503, 504:
                return true
            default:
                return false
            }
        }

        return false
    }
}

// MARK: - 扩展NetworkError
extension NetworkError {
    /// 从Error创建NetworkError
    static func from(_ error: Error) -> NetworkError {
        if let networkError = error as? NetworkError {
            return networkError
        }

        if let afError = error as? AFError,
           case .responseSerializationFailed = afError {
            return .decodingError
        }

        return .apiError(ErrorHandler.getErrorMessage(error))
    }
}

// MARK: - Error扩展
extension Error {
    /// 转换为用户友好的错误消息
    var userFriendlyMessage: String {
        return ErrorHandler.getErrorMessage(self)
    }

    /// 获取建议操作
    var suggestion: String? {
        return ErrorHandler.getSuggestion(self)
    }

    /// 是否为网络问题
    var isNetworkError: Bool {
        return ErrorHandler.isNetworkError(self)
    }

    /// 是否为服务器错误
    var isServerError: Bool {
        return ErrorHandler.isServerError(self)
    }

    /// 是否需要重新登录
    var needsReLogin: Bool {
        return ErrorHandler.needsReLogin(self)
    }

    /// 是否可重试
    var isRetryable: Bool {
        return ErrorHandler.isRetryable(self)
    }
}
