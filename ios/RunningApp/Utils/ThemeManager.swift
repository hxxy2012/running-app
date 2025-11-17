import Foundation
import SwiftUI
import Combine

// MARK: - 主题管理器
class ThemeManager: ObservableObject {

    static let shared = ThemeManager()

    // 主题模式
    enum ThemeMode: String, CaseIterable {
        case light = "Light"      // 浅色主题
        case dark = "Dark"        // 深色主题
        case system = "System"    // 跟随系统

        var displayName: String {
            switch self {
            case .light: return "浅色主题"
            case .dark: return "深色主题"
            case .system: return "跟随系统"
            }
        }
    }

    // 主题配色
    enum ColorTheme: String, CaseIterable {
        case blue = "Blue"
        case green = "Green"
        case orange = "Orange"
        case purple = "Purple"
        case red = "Red"

        var displayName: String {
            switch self {
            case .blue: return "蓝色"
            case .green: return "绿色"
            case .orange: return "橙色"
            case .purple: return "紫色"
            case .red: return "红色"
            }
        }
    }

    // MARK: - Properties

    @Published var themeMode: ThemeMode {
        didSet {
            saveThemeMode(themeMode)
            Logger.d("Theme mode changed to: \(themeMode.rawValue)")
        }
    }

    @Published var colorTheme: ColorTheme {
        didSet {
            saveColorTheme(colorTheme)
            Logger.d("Color theme changed to: \(colorTheme.rawValue)")
        }
    }

    private let defaults = UserDefaults.standard
    private let themeModeKey = "theme_mode"
    private let colorThemeKey = "color_theme"

    private init() {
        self.themeMode = ThemeManager.loadThemeMode()
        self.colorTheme = ThemeManager.loadColorTheme()
    }

    // MARK: - 主题切换

    /// 设置浅色主题
    func setLightTheme() {
        themeMode = .light
    }

    /// 设置深色主题
    func setDarkTheme() {
        themeMode = .dark
    }

    /// 跟随系统主题
    func setSystemTheme() {
        themeMode = .system
    }

    /// 设置配色主题
    func setColorTheme(_ theme: ColorTheme) {
        colorTheme = theme
    }

    // MARK: - 主题判断

    /// 当前是否为深色主题
    func isDarkMode(for colorScheme: ColorScheme) -> Bool {
        switch themeMode {
        case .light:
            return false
        case .dark:
            return true
        case .system:
            return colorScheme == .dark
        }
    }

    /// 获取当前颜色方案
    func currentColorScheme() -> ColorScheme? {
        switch themeMode {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }

    // MARK: - 颜色定义

    /// 主色调
    func primaryColor(for colorScheme: ColorScheme) -> Color {
        let isDark = isDarkMode(for: colorScheme)

        switch colorTheme {
        case .blue:
            return isDark ? Color(hex: 0x42A5F5) : Color(hex: 0x1E88E5)
        case .green:
            return isDark ? Color(hex: 0x66BB6A) : Color(hex: 0x43A047)
        case .orange:
            return isDark ? Color(hex: 0xFFB74D) : Color(hex: 0xFFA726)
        case .purple:
            return isDark ? Color(hex: 0xAB47BC) : Color(hex: 0x8E24AA)
        case .red:
            return isDark ? Color(hex: 0xEF5350) : Color(hex: 0xE53935)
        }
    }

    /// 次要色调
    func secondaryColor(for colorScheme: ColorScheme) -> Color {
        let isDark = isDarkMode(for: colorScheme)

        switch colorTheme {
        case .blue:
            return isDark ? Color(hex: 0x66BB6A) : Color(hex: 0x43A047)
        case .green:
            return isDark ? Color(hex: 0x42A5F5) : Color(hex: 0x1E88E5)
        case .orange:
            return isDark ? Color(hex: 0xAB47BC) : Color(hex: 0x8E24AA)
        case .purple:
            return isDark ? Color(hex: 0xFFB74D) : Color(hex: 0xFFA726)
        case .red:
            return isDark ? Color(hex: 0x42A5F5) : Color(hex: 0x1E88E5)
        }
    }

    /// 背景色
    func backgroundColor(for colorScheme: ColorScheme) -> Color {
        return isDarkMode(for: colorScheme) ?
            Color(hex: 0x121212) :
            Color(hex: 0xFAFAFA)
    }

    /// 次要背景色
    func secondaryBackgroundColor(for colorScheme: ColorScheme) -> Color {
        return isDarkMode(for: colorScheme) ?
            Color(hex: 0x1E1E1E) :
            Color.white
    }

    /// 文本颜色
    func textColor(for colorScheme: ColorScheme) -> Color {
        return isDarkMode(for: colorScheme) ?
            Color(hex: 0xE0E0E0) :
            Color(hex: 0x212121)
    }

    /// 次要文本颜色
    func secondaryTextColor(for colorScheme: ColorScheme) -> Color {
        return isDarkMode(for: colorScheme) ?
            Color(hex: 0xBDBDBD) :
            Color(hex: 0x616161)
    }

    /// 分隔线颜色
    func dividerColor(for colorScheme: ColorScheme) -> Color {
        return isDarkMode(for: colorScheme) ?
            Color(hex: 0x424242) :
            Color(hex: 0xE0E0E0)
    }

    /// 成功颜色
    func successColor(for colorScheme: ColorScheme) -> Color {
        return isDarkMode(for: colorScheme) ?
            Color(hex: 0x66BB6A) :
            Color(hex: 0x43A047)
    }

    /// 错误颜色
    func errorColor(for colorScheme: ColorScheme) -> Color {
        return isDarkMode(for: colorScheme) ?
            Color(hex: 0xEF5350) :
            Color(hex: 0xE53935)
    }

    /// 警告颜色
    func warningColor(for colorScheme: ColorScheme) -> Color {
        return isDarkMode(for: colorScheme) ?
            Color(hex: 0xFFB74D) :
            Color(hex: 0xFFA726)
    }

    // MARK: - 持久化

    /// 保存主题模式
    private func saveThemeMode(_ mode: ThemeMode) {
        defaults.set(mode.rawValue, forKey: themeModeKey)
    }

    /// 加载主题模式
    private static func loadThemeMode() -> ThemeMode {
        let defaults = UserDefaults.standard
        if let modeString = defaults.string(forKey: "theme_mode"),
           let mode = ThemeMode(rawValue: modeString) {
            return mode
        }
        return .system
    }

    /// 保存配色主题
    private func saveColorTheme(_ theme: ColorTheme) {
        defaults.set(theme.rawValue, forKey: colorThemeKey)
    }

    /// 加载配色主题
    private static func loadColorTheme() -> ColorTheme {
        let defaults = UserDefaults.standard
        if let themeString = defaults.string(forKey: "color_theme"),
           let theme = ColorTheme(rawValue: themeString) {
            return theme
        }
        return .blue
    }

    // MARK: - 主题信息

    /// 获取主题配置信息
    func getThemeInfo(for colorScheme: ColorScheme) -> [String: String] {
        return [
            "themeMode": themeMode.rawValue,
            "themeName": themeMode.displayName,
            "colorTheme": colorTheme.rawValue,
            "colorThemeName": colorTheme.displayName,
            "isDark": isDarkMode(for: colorScheme).description
        ]
    }
}

// MARK: - Color扩展

extension Color {
    /// 从十六进制创建颜色
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

// MARK: - Environment Key

struct ThemeManagerKey: EnvironmentKey {
    static let defaultValue = ThemeManager.shared
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
}

// MARK: - SwiftUI 修饰符

extension View {
    /// 应用主题
    func themed() -> some View {
        self.modifier(ThemedModifier())
    }
}

struct ThemedModifier: ViewModifier {
    @ObservedObject var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .preferredColorScheme(themeManager.currentColorScheme())
            .accentColor(themeManager.primaryColor(for: colorScheme))
    }
}

// MARK: - 预定义颜色集

extension ThemeManager {

    /// 运动数据颜色
    struct RunningColors {
        let distance: Color
        let duration: Color
        let pace: Color
        let calories: Color

        static func `default`(for colorScheme: ColorScheme, theme: ThemeManager) -> RunningColors {
            let isDark = theme.isDarkMode(for: colorScheme)
            return RunningColors(
                distance: isDark ? Color(hex: 0x42A5F5) : Color(hex: 0x1E88E5),
                duration: isDark ? Color(hex: 0x66BB6A) : Color(hex: 0x43A047),
                pace: isDark ? Color(hex: 0xFFB74D) : Color(hex: 0xFFA726),
                calories: isDark ? Color(hex: 0xEF5350) : Color(hex: 0xE53935)
            )
        }
    }

    /// 获取运动数据颜色
    func runningColors(for colorScheme: ColorScheme) -> RunningColors {
        return RunningColors.default(for: colorScheme, theme: self)
    }
}

// MARK: - 主题预览

#if DEBUG
struct ThemeManager_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Text("主题预览")
                .font(.title)

            ForEach(ThemeManager.ColorTheme.allCases, id: \.self) { theme in
                HStack {
                    Text(theme.displayName)
                    Spacer()
                    Circle()
                        .fill(ThemeManager.shared.primaryColor(for: .light))
                        .frame(width: 30, height: 30)
                    Circle()
                        .fill(ThemeManager.shared.primaryColor(for: .dark))
                        .frame(width: 30, height: 30)
                }
                .padding()
            }
        }
        .padding()
    }
}
#endif
