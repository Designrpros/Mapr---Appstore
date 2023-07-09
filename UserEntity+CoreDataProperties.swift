//
//  UserEntity+CoreDataProperties.swift
//  Mapr
//
//  Created by Vegar Berentsen on 09/07/2023.
//
//

import Foundation
import CoreData


extension UserEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserEntity> {
        return NSFetchRequest<UserEntity>(entityName: "UserEntity")
    }

    @NSManaged public var color: String?
    @NSManaged public var email: String?
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var recordData: Data?
    @NSManaged public var recordIDData: Data?
    @NSManaged public var role: String?
    @NSManaged public var project: NSSet?

}

// MARK: Generated accessors for project
extension UserEntity {

    @objc(addProjectObject:)
    @NSManaged public func addToProject(_ value: Project)

    @objc(removeProjectObject:)
    @NSManaged public func removeFromProject(_ value: Project)

    @objc(addProject:)
    @NSManaged public func addToProject(_ values: NSSet)

    @objc(removeProject:)
    @NSManaged public func removeFromProject(_ values: NSSet)

}

extension UserEntity : Identifiable {

}
