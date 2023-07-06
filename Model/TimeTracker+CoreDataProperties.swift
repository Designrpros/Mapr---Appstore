//
//  TimeTracker+CoreDataProperties.swift
//  Mapr
//
//  Created by Vegar Berentsen on 06/07/2023.
//
//

import Foundation
import CoreData


extension TimeTracker {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TimeTracker> {
        return NSFetchRequest<TimeTracker>(entityName: "TimeTracker")
    }

    @NSManaged public var date: Date?
    @NSManaged public var hours: Double
    @NSManaged public var id: UUID?
    @NSManaged public var notes: String?
    @NSManaged public var project: Project?

}

extension TimeTracker : Identifiable {

}
