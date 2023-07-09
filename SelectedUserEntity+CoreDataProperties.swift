//
//  SelectedUserEntity+CoreDataProperties.swift
//  Mapr
//
//  Created by Vegar Berentsen on 09/07/2023.
//
//

import Foundation
import CoreData


extension SelectedUserEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SelectedUserEntity> {
        return NSFetchRequest<SelectedUserEntity>(entityName: "SelectedUserEntity")
    }

    @NSManaged public var color: String?
    @NSManaged public var email: String?
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var recordData: Data?
    @NSManaged public var recordIDData: Data?
    @NSManaged public var role: String?

}

extension SelectedUserEntity : Identifiable {

}
