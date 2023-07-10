//
//  ChecklistItem+CoreDataProperties.swift
//  Mapr
//
//  Created by Vegar Berentsen on 10/07/2023.
//
//

import Foundation
import CoreData


extension ChecklistItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChecklistItem> {
        return NSFetchRequest<ChecklistItem>(entityName: "ChecklistItem")
    }

    @NSManaged public var creationDate: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var isChecked: Bool
    @NSManaged public var item: String?
    @NSManaged public var children: NSSet?
    @NSManaged public var parent: ChecklistItem?
    @NSManaged public var project: Project?

}

// MARK: Generated accessors for children
extension ChecklistItem {

    @objc(addChildrenObject:)
    @NSManaged public func addToChildren(_ value: ChecklistItem)

    @objc(removeChildrenObject:)
    @NSManaged public func removeFromChildren(_ value: ChecklistItem)

    @objc(addChildren:)
    @NSManaged public func addToChildren(_ values: NSSet)

    @objc(removeChildren:)
    @NSManaged public func removeFromChildren(_ values: NSSet)

}

extension ChecklistItem : Identifiable {

}
