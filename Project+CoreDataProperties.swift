//
//  Project+CoreDataProperties.swift
//  Mapr
//
//  Created by Vegar Berentsen on 09/07/2023.
//
//

import Foundation
import CoreData


extension Project {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Project> {
        return NSFetchRequest<Project>(entityName: "Project")
    }

    @NSManaged public var addressDescription: String?
    @NSManaged public var addressSubtitle: String?
    @NSManaged public var addressTitle: String?
    @NSManaged public var id: UUID?
    @NSManaged public var isFinished: Bool
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var projectDescription: String?
    @NSManaged public var projectName: String?
    @NSManaged public var recordID: String?
    @NSManaged public var checklistItem: NSSet?
    @NSManaged public var contact: Contact?
    @NSManaged public var galleryImage: NSSet?
    @NSManaged public var location: Location?
    @NSManaged public var material: NSSet?
    @NSManaged public var timeTracker: NSSet?
    @NSManaged public var users: NSSet?

}

// MARK: Generated accessors for checklistItem
extension Project {

    @objc(addChecklistItemObject:)
    @NSManaged public func addToChecklistItem(_ value: ChecklistItem)

    @objc(removeChecklistItemObject:)
    @NSManaged public func removeFromChecklistItem(_ value: ChecklistItem)

    @objc(addChecklistItem:)
    @NSManaged public func addToChecklistItem(_ values: NSSet)

    @objc(removeChecklistItem:)
    @NSManaged public func removeFromChecklistItem(_ values: NSSet)

}

// MARK: Generated accessors for galleryImage
extension Project {

    @objc(addGalleryImageObject:)
    @NSManaged public func addToGalleryImage(_ value: GalleryImage)

    @objc(removeGalleryImageObject:)
    @NSManaged public func removeFromGalleryImage(_ value: GalleryImage)

    @objc(addGalleryImage:)
    @NSManaged public func addToGalleryImage(_ values: NSSet)

    @objc(removeGalleryImage:)
    @NSManaged public func removeFromGalleryImage(_ values: NSSet)

}

// MARK: Generated accessors for material
extension Project {

    @objc(addMaterialObject:)
    @NSManaged public func addToMaterial(_ value: Material)

    @objc(removeMaterialObject:)
    @NSManaged public func removeFromMaterial(_ value: Material)

    @objc(addMaterial:)
    @NSManaged public func addToMaterial(_ values: NSSet)

    @objc(removeMaterial:)
    @NSManaged public func removeFromMaterial(_ values: NSSet)

}

// MARK: Generated accessors for timeTracker
extension Project {

    @objc(addTimeTrackerObject:)
    @NSManaged public func addToTimeTracker(_ value: TimeTracker)

    @objc(removeTimeTrackerObject:)
    @NSManaged public func removeFromTimeTracker(_ value: TimeTracker)

    @objc(addTimeTracker:)
    @NSManaged public func addToTimeTracker(_ values: NSSet)

    @objc(removeTimeTracker:)
    @NSManaged public func removeFromTimeTracker(_ values: NSSet)

}

// MARK: Generated accessors for users
extension Project {

    @objc(addUsersObject:)
    @NSManaged public func addToUsers(_ value: UserEntity)

    @objc(removeUsersObject:)
    @NSManaged public func removeFromUsers(_ value: UserEntity)

    @objc(addUsers:)
    @NSManaged public func addToUsers(_ values: NSSet)

    @objc(removeUsers:)
    @NSManaged public func removeFromUsers(_ values: NSSet)

}

extension Project : Identifiable {

}
