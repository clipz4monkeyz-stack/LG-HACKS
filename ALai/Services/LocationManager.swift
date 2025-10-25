//
//  LocationManager.swift
//  ALai
//
//  Created by Anwen Li on 9/24/25.
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    private let userDefaults = UserDefaults.standard
    private let userLocationKey = "savedUserLocation"
    
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var savedLocation: UserLocation?
    @Published var isLoading = false
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        loadSavedLocation()
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func requestCurrentLocation() {
        #if os(iOS)
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestLocationPermission()
            return
        }
        #elseif os(macOS)
        guard authorizationStatus == .authorizedAlways else {
            requestLocationPermission()
            return
        }
        #endif
        
        isLoading = true
        locationManager.requestLocation()
    }
    
    func saveLocation(_ location: UserLocation) {
        savedLocation = location
        if let encoded = try? JSONEncoder().encode(location) {
            userDefaults.set(encoded, forKey: userLocationKey)
        }
    }
    
    func clearSavedLocation() {
        savedLocation = nil
        userDefaults.removeObject(forKey: userLocationKey)
    }
    
    private func loadSavedLocation() {
        guard let data = userDefaults.data(forKey: userLocationKey),
              let location = try? JSONDecoder().decode(UserLocation.self, from: data) else {
            return
        }
        savedLocation = location
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        isLoading = false
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
        isLoading = false
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        
        switch status {
        #if os(iOS)
        case .authorizedWhenInUse, .authorizedAlways:
            requestCurrentLocation()
        #elseif os(macOS)
        case .authorizedAlways:
            requestCurrentLocation()
        #endif
        case .denied, .restricted:
            print("Location access denied")
        case .notDetermined:
            requestLocationPermission()
        @unknown default:
            break
        }
    }
}
