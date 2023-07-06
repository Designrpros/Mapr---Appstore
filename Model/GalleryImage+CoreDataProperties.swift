//
//  GalleryImage+CoreDataProperties.swift
//  Mapr
//
//  Created by Vegar Berentsen on 06/07/2023.
//
//

import Foundation
import CoreData


extension GalleryImage {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<GalleryImage> {
        return NSFetchRequest<GalleryImage>(entityName: "GalleryImage")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var imageData: Data?
    @NSManaged public var project: Project?

}

extension GalleryImage : Identifiable {

}
