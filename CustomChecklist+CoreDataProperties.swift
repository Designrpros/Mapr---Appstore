//
//  CustomChecklist+CoreDataProperties.swift
//  Mapr
//
//  Created by Vegar Berentsen on 10/07/2023.
//
//

import Foundation
import CoreData


extension CustomChecklist {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CustomChecklist> {
        return NSFetchRequest<CustomChecklist>(entityName: "CustomChecklist")
    }

    @NSManaged public var title: String?
    @NSManaged public var items: NSSet?

}

// MARK: Generated accessors for items
extension CustomChecklist {

    @objc(addItemsObject:)
    @NSManaged public func addToItems(_ value: CustomChecklistItem)

    @objc(removeItemsObject:)
    @NSManaged public func removeFromItems(_ value: CustomChecklistItem)

    @objc(addItems:)
    @NSManaged public func addToItems(_ values: NSSet)

    @objc(removeItems:)
    @NSManaged public func removeFromItems(_ values: NSSet)

}

extension CustomChecklist : Identifiable {

}
