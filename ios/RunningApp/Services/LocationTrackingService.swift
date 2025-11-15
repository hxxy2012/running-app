import Foundation
import CoreLocation
import Combine

// MARK: - GPS跟踪服务
class LocationTrackingService: NSObject, ObservableObject {
    static let shared = LocationTrackingService()

    private let locationManager = CLLocationManager()

    // Published properties
    @Published var isTracking = false
    @Published var currentLocation: CLLocation?
    @Published var trackPoints: [TrackPoint] = []
    @Published var runningData = RunningData()

    // Private properties
    private var startTime: Date?
    private var lastLocation: CLLocation?
    private var totalDistance: Double = 0

    private override init() {
        super.init()
        setupLocationManager()
    }

    // MARK: - Setup
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5 // 5米更新一次
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.showsBackgroundLocationIndicator = true
    }

    // MARK: - 权限检查
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
    }

    var hasPermission: Bool {
        return locationManager.authorizationStatus == .authorizedAlways ||
               locationManager.authorizationStatus == .authorizedWhenInUse
    }

    // MARK: - 跟踪控制
    func startTracking() {
        guard hasPermission else {
            requestPermission()
            return
        }

        isTracking = true
        startTime = Date()
        lastLocation = nil
        totalDistance = 0
        trackPoints.removeAll()
        runningData = RunningData()

        locationManager.startUpdatingLocation()
    }

    func stopTracking() {
        isTracking = false
        locationManager.stopUpdatingLocation()
    }

    func pauseTracking() {
        locationManager.stopUpdatingLocation()
    }

    func resumeTracking() {
        locationManager.startUpdatingLocation()
    }

    // MARK: - 数据计算
    private func updateRunningData() {
        guard let startTime = startTime else { return }

        let duration = Int(Date().timeIntervalSince(startTime))
        let distanceKm = totalDistance / 1000
        let hours = Double(duration) / 3600
        let speed = hours > 0 ? Float(distanceKm / hours) : 0
        let pace = speed > 0 ? Int(60 / (speed / 60)) : 0
        let calories = LocationUtils.calculateCalories(distance: Float(totalDistance))

        runningData = RunningData(
            distance: Float(totalDistance),
            duration: duration,
            avgSpeed: speed,
            avgPace: pace,
            currentSpeed: currentLocation?.speed ?? 0,
            calories: calories
        )
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationTrackingService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        currentLocation = location

        // 计算距离
        if let lastLocation = lastLocation {
            let distance = location.distance(from: lastLocation)

            // 过滤异常点
            if distance > 5 && distance < 100 {
                totalDistance += distance

                // 添加轨迹点
                let trackPoint = TrackPoint(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    altitude: location.altitude,
                    speed: Float(location.speed),
                    accuracy: Float(location.horizontalAccuracy),
                    timestamp: Int64(location.timestamp.timeIntervalSince1970 * 1000)
                )
                trackPoints.append(trackPoint)

                // 更新跑步数据
                updateRunningData()
            }
        }

        lastLocation = location
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // 权限变化处理
    }
}

// MARK: - 跑步数据
struct RunningData {
    var distance: Float = 0
    var duration: Int = 0
    var avgSpeed: Float = 0
    var avgPace: Int = 0
    var currentSpeed: Float = 0
    var calories: Int = 0
}

// MARK: - 位置工具
struct LocationUtils {
    static func calculateCalories(distance: Float, weight: Int = 70) -> Int {
        let distanceKm = distance / 1000
        return Int(Float(weight) * distanceKm * 1.036)
    }

    static func formatDistance(_ meters: Float) -> String {
        if meters < 1000 {
            return String(format: "%.0f 米", meters)
        } else {
            return String(format: "%.2f 公里", meters / 1000)
        }
    }

    static func formatPace(_ secondsPerKm: Int) -> String {
        guard secondsPerKm > 0 else { return "--'--\"" }
        let minutes = secondsPerKm / 60
        let seconds = secondsPerKm % 60
        return String(format: "%d'%02d\"", minutes, seconds)
    }

    static func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
}
