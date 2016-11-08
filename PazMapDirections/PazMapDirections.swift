//
//  PazMapDirections.swift
//  PazMapDirections
//
//  Created by Pantelis Zirinis on 08/11/2016.
//  Copyright © 2016 paz-labs. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

public enum PazNavigationApp {
    case AppleMaps
    case GoogleMaps
    case Navigon
    case TomTom
    case Waze
    
    public static let AllValues: [PazNavigationApp] = [.AppleMaps, .GoogleMaps, .Navigon, .TomTom, .Waze]
    
    public static var AvailableServices: [PazNavigationApp] {
        var availableServices = self.AllValues
        for app in self.AllValues {
            if app.available {
                availableServices.append(app)
            }
        }
        return availableServices
    }
    
    public var name: String {
        switch self {
        case .AppleMaps:
            return "Apple Maps"
        case .GoogleMaps:
            return "Google Maps"
        case .Navigon:
            return "Navigon"
        case .TomTom:
            return "TomTom"
        case .Waze:
            return "Waze"
        }
    }
    
    public var urlString: String {
        switch self {
        case .AppleMaps:
            return "maps.apple.com://"
        case .GoogleMaps:
            return "comgooglemaps://"
        case .Navigon:
            return "navigon://"
        case .TomTom:
            return "tomtomhome://"
        case .Waze:
            return "waze://"
        }
        
    }
    
    public var url: URL? {
        return URL(string: self.urlString)
    }
    
    public var available: Bool {
        guard let url = self.url else {
            return false
        }
        return UIApplication.shared.canOpenURL(url)
    }
    
    public func directionsUrlString(coordinate: CLLocationCoordinate2D, name: String = "Destination") -> String {
        var urlString = self.urlString
        switch self {
        case .AppleMaps:
            urlString.append("?daddr=\(coordinate.latitude),\(coordinate.longitude)=d&t=h")
        case .GoogleMaps:
            urlString.append("?saddr=&daddr=\(coordinate.latitude),\(coordinate.longitude)&directionsmode=driving")
        case .Navigon:
            urlString.append("coordinate/\(name)/\(coordinate.latitude)/\(coordinate.longitude)")
        case .TomTom:
            urlString.append("geo:action=navigateto&lat=\(coordinate.latitude)&long=\(coordinate.longitude)&name=\(name)")
        case .Waze:
            urlString.append("?ll=\(coordinate.latitude),\(coordinate.longitude)&navigate=yes")
        }
        return urlString
    }

    public func directionsUrl(coordinate: CLLocationCoordinate2D, name: String = "Destination") -> URL? {
        let urlString = self.directionsUrlString(coordinate: coordinate, name: name)
        return URL(string: urlString)
    }
    
    public func openWithDirections(coordinate: CLLocationCoordinate2D, name: String = "Destination", completion: ((Bool) -> Swift.Void)? = nil) {
        guard let url = self.directionsUrl(coordinate: coordinate, name: name) else {
            completion?(false)
            return
        }
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: {
                (success) in
                print("Open \(url.absoluteString): \(success)")
                completion?(success)
            })
        } else {
            let success = UIApplication.shared.openURL(url)
            completion?(success)
        }
    }
    
    public static func directionsAlertController(coordinate: CLLocationCoordinate2D, name: String = "Destination", title: String = "Directions Using", message: String? = nil, completion: ((Bool) -> Swift.Void)? = nil) -> UIAlertController {
        let directionsAlertView = UIAlertController(title: title, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        for navigationApp in PazNavigationApp.AvailableServices {
            directionsAlertView.addAction(UIAlertAction(title: navigationApp.name, style: UIAlertActionStyle.default, handler: { (action) in
                navigationApp.openWithDirections(coordinate: coordinate, name: name, completion: { (success) in
                    completion?(success)
                })
            }))
        }
        directionsAlertView.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel, handler: { (action) in
            completion?(false)
        }))
        return directionsAlertView
    }
    
}
