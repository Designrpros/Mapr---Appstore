//
//  Material+CoreDataProperties.swift
//  Mapr
//
//  Created by Vegar Berentsen on 06/07/2023.
//
//

import Foundation
import CoreData


extension Material {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Material> {
        return NSFetchRequest<Material>(entityName: "Material")
    }

    @NSManaged public var amount: Int16
    @NSManaged public var id: UUID?
    @NSManaged public var materialDescription: String?
    @NSManaged public var number: Int64
    @NSManaged public var price: Double
    @NSManaged public var project: Project?

}

extension Material : Identifiable {

}
