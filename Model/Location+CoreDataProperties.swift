//
//  Location+CoreDataProperties.swift
//  Mapr
//
//  Created by Vegar Berentsen on 06/07/2023.
//
//

import Foundation
import CoreData


extension Location {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Location> {
        return NSFetchRequest<Location>(entityName: "Location")
    }

    @NSManaged public var city: String?
    @NSManaged public var country: String?
    @NSManaged public var id: UUID?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var name: String?
    @NSManaged public var postalCode: String?
    @NSManaged public var project: Project?

}

extension Location : Identifiable {

}
