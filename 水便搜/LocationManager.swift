import CoreLocation
import Foundation
import Observation

@MainActor
@Observable
final class LocationManager: NSObject {
    private let manager = CLLocationManager()

    private(set) var authorizationStatus: CLAuthorizationStatus
    private(set) var userLocation: CLLocation?
    private(set) var locationError: String?

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    var canRequestLocation: Bool {
        CLLocationManager.locationServicesEnabled()
    }

    var isDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    func requestLocation() {
        guard canRequestLocation else {
            setUserLocationToDefault()
            locationError = "此裝置尚未開啟定位服務，已為您提供預設定位計算距離。"
            return
        }

        switch authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            manager.requestLocation()
            setUserLocationToDefaultIfNil()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
            setUserLocationToDefaultIfNil()
        case .denied, .restricted:
            setUserLocationToDefault()
            locationError = "定位權限未開啟，已切換至預設地點計算距離。"
        @unknown default:
            setUserLocationToDefaultIfNil()
        }
    }

    private func setUserLocationToDefault() {
        userLocation = CLLocation(latitude: 25.04776, longitude: 121.51706)
    }

    private func setUserLocationToDefaultIfNil() {
        if userLocation == nil {
            userLocation = CLLocation(latitude: 25.04776, longitude: 121.51706)
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        } else if authorizationStatus == .denied || authorizationStatus == .restricted {
            setUserLocationToDefault()
            locationError = "定位權限未開啟，已切換至預設地點計算距離。"
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let lastLocation = locations.last {
            userLocation = lastLocation
            locationError = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if userLocation == nil {
            setUserLocationToDefault()
            locationError = "目前無法取得即時 GPS，已使用預設地點計算距離。"
        }
    }
}
