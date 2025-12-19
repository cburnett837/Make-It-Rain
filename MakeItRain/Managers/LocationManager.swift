//
//  LocationManager.swift
//  SearchableMapDemo
//
//  Created by Cody Burnett on 4/10/25.
//

import Foundation
import CoreLocation
import MapKit


@Observable
class LocationManager: NSObject, CLLocationManagerDelegate  {
    static let shared = LocationManager()
    let manager = CLLocationManager()
    var currentLocation: CLLocationCoordinate2D?
    var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
    
    var authIsAllowed: Bool = false
    
    override init() {
        super.init()
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        #if os(macOS)
        manager.allowsBackgroundLocationUpdates = false
        #else
        manager.allowsBackgroundLocationUpdates = true
        #endif
        manager.pausesLocationUpdatesAutomatically = false
        manager.activityType = .otherNavigation
        manager.desiredAccuracy = kCLLocationAccuracyBest
        
        /// Locations are fetched in the `locationManagerDidChangeAuthorization()` callback.
    }
        
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //print("-- \(#function)")
        currentLocation = locations.last?.coordinate
        locations.last.map {
            region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: $0.coordinate.latitude,
                    longitude: $0.coordinate.longitude
                ),
                span: MKCoordinateSpan(
                    latitudeDelta: 0.005,
                    longitudeDelta: 0.005
                )
            )
        }
        //print(currentLocation?.latitude)
        //print(currentLocation?.longitude)
    }
    
    
    func requestLocation() {
        //print("-- \(#function)")
        manager.requestLocation()
    }
        
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        //print("-- \(#function)")
        switch manager.authorizationStatus {
        case .notDetermined:
            print("Location authorization notDetermined")
            authIsAllowed = false
            manager.requestWhenInUseAuthorization()
            
        case .restricted, .denied:
            print("Location authorization restricted, denied")
            authIsAllowed = false
            
        case .authorizedAlways:
            print("Location authorization authorizedAlways")
            authIsAllowed = true
            manager.requestLocation()
            //fetchCoreLocations()
            
        case .authorizedWhenInUse:
            print("Location authorization authorizedWhenInUse")
            authIsAllowed = true
            manager.requestLocation()
            //fetchCoreLocations()
            
        @unknown default:
            break
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        //print("-- \(#function)")
        print(error.localizedDescription)
    }
}
