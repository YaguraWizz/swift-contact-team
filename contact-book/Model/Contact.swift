//
//  Contact.swift
//  contact-book
//
//  Created by Nikita on 16.12.2024.
//


import Foundation
import CoreData

final class Contact: NSManagedObject, Identifiable {
    
    @NSManaged var dob: Date
    @NSManaged var name: String
    @NSManaged var notes: String
    @NSManaged var phoneNumbers: Set<PhoneNumber>
    @NSManaged var email: String
    @NSManaged var isFavourite: Bool
    
    var isValid: Bool {
        !name.isEmpty && !email.isEmpty
    }
    
    var isBirthday: Bool {
        Calendar.current.isDateInToday(dob)
    }
    
    var formattedName: String {
        "\(isBirthday ? "🎈" : "")\(name)"
    }
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(Date.now, forKey: "dob")
        setPrimitiveValue(false, forKey: "isFavourite")
    }
}

final class PhoneNumber: NSManagedObject, Identifiable {
    @NSManaged var number: String
    @NSManaged var type: String
    @NSManaged var contact: Contact
}





extension Contact {
    
    private static var contactsFetchRequest: NSFetchRequest<Contact> {
        NSFetchRequest(entityName: "Contact")
    }
    
    static func all() -> NSFetchRequest<Contact> {
        let request: NSFetchRequest<Contact> = contactsFetchRequest
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Contact.name, ascending: true)
        ]
        return request
    }
    
    static func filter1(with config: SearchConfig) -> NSPredicate {
        switch config.filter {
        case .all:
            return config.query.isEmpty ? NSPredicate(value: true) : NSPredicate(format: "name CONTAINS[cd] %@", config.query)
        case .fave:
            return config.query.isEmpty ? NSPredicate(format: "isFavourite == %@", NSNumber(value: true)) :
            NSPredicate(format: "name CONTAINS[cd] %@ AND isFavourite == %@", config.query, NSNumber(value: true))
        }
    }
    
    static func filter(with config: SearchConfig) -> NSPredicate {
        guard !config.query.isEmpty else {
            // Если строка запроса пуста, возвращаем всех
            return NSPredicate(value: true)
        }
        
        let trimmedQuery = config.query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Проверка на наличие тега в запросе
        if let range = trimmedQuery.range(of: ":") {
            let tag = trimmedQuery[..<range.lowerBound].trimmingCharacters(in: .whitespaces)
            let value = trimmedQuery[range.upperBound...].trimmingCharacters(in: .whitespaces)
            
            switch tag.lowercased() {
            case "name":
                return NSPredicate(format: "name CONTAINS[cd] %@", value)
            case "number":
                return NSPredicate(format: "ANY phoneNumbers.number CONTAINS[cd] %@", value)
            case "email":
                return NSPredicate(format: "email CONTAINS[cd] %@", value)
            default:
                // Если тег не распознан, можно либо вернуть пустой результат, либо считать по умолчанию как поиск по имени
                return NSPredicate(format: "name CONTAINS[cd] %@", trimmedQuery)
            }
        } else {
            // Если тег не найден, считаем запрос как поиск по имени по умолчанию
            return NSPredicate(format: "name CONTAINS[cd] %@", trimmedQuery)
        }
    }
    
    static func sort(order: Sort) -> [NSSortDescriptor] {
        [NSSortDescriptor(keyPath: \Contact.name, ascending: order == .asc)]
    }
}

extension Contact {
    
    @discardableResult
    static func makePreview(count: Int, in context: NSManagedObjectContext) -> [Contact] {
        var contacts = [Contact]()
        for i in 0..<count {
            let contact = Contact(context: context)
            contact.name = "item \(i)"
            contact.email = "test_\(i)@mail.com"
            contact.isFavourite = Bool.random()
            contact.dob = Calendar.current.date(byAdding: .day,
                                                value: -i,
                                                to: .now) ?? .now
            contact.notes = "This is a preview for item \(i)"
            
            for j in 0...2 {
                let phoneNumber = PhoneNumber(context: context)
                phoneNumber.number = "0700000\(i)\(j)"
                phoneNumber.type = j == 0 ? "Mobile" : j == 1 ? "Work" : "Home"
                phoneNumber.contact = contact
            }
            
            contacts.append(contact)
        }
        return contacts
    }
    
    static func preview(context: NSManagedObjectContext = ContactsProvider.shared.viewContext) -> Contact {
        return makePreview(count: 1, in: context)[0]
    }
    
    static func empty(context: NSManagedObjectContext = ContactsProvider.shared.viewContext) -> Contact {
        return Contact(context: context)
    }
}
