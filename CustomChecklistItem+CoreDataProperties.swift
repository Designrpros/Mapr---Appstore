//
//  CustomChecklistItem+CoreDataProperties.swift
//  Mapr
//
//  Created by Vegar Berentsen on 10/07/2023.
//
//

import Foundation
import CoreData


extension CustomChecklistItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CustomChecklistItem> {
        return NSFetchRequest<CustomChecklistItem>(entityName: "CustomChecklistItem")
    }

    @NSManaged public var creationDate: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var isChecked: Bool
    @NSManaged public var item: String?
    @NSManaged public var title: String?
    @NSManaged public var childern: NSSet?
    @NSManaged public var parent: CustomChecklistItem?
    @NSManaged public var checklist: CustomChecklist?

}

// MARK: Generated accessors for childern
extension CustomChecklistItem {

    @objc(addChildernObject:)
    @NSManaged public func addToChildern(_ value: CustomChecklistItem)

    @objc(removeChildernObject:)
    @NSManaged public func removeFromChildern(_ value: CustomChecklistItem)

    @objc(addChildern:)
    @NSManaged public func addToChildern(_ values: NSSet)

    @objc(removeChildern:)
    @NSManaged public func removeFromChildern(_ values: NSSet)

}

extension CustomChecklistItem : Identifiable {

}
