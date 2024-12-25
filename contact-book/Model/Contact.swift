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
    
static func filter(with config: SearchConfig) -> NSPredicate {
    // Если строка запроса пустая, просто возвращаем предикат, который зависит от filter
    guard !config.query.isEmpty else {
        return config.filter == .fave ? 
            NSPredicate(format: "isFavourite == %@", NSNumber(value: true)) : 
            NSPredicate(value: true)
    }
    
    let trimmedQuery = config.query.trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Проверка на наличие тега в запросе
    if let range = trimmedQuery.range(of: ":") {
        let tag = trimmedQuery[..<range.lowerBound].trimmingCharacters(in: .whitespaces).lowercased() // Приводим тег к нижнему регистру
        let value = trimmedQuery[range.upperBound...].trimmingCharacters(in: .whitespaces)
        
        // Создание базового предиката для поиска
        let basePredicate: NSPredicate
        switch tag {
        case "name":
            basePredicate = NSPredicate(format: "name CONTAINS[cd] %@", value)
        case "number":
            basePredicate = NSPredicate(format: "ANY phoneNumbers.number CONTAINS[cd] %@", value)
        case "email":
            basePredicate = NSPredicate(format: "email CONTAINS[cd] %@", value)
        default:
            // Если тег не распознан, считаем по умолчанию как поиск по имени
            basePredicate = NSPredicate(format: "name CONTAINS[cd] %@", trimmedQuery)
        }
        
        // Если фильтр .fave, добавляем условие для избранных
        return config.filter == .fave ? 
            NSCompoundPredicate(andPredicateWithSubpredicates: [
                basePredicate,
                NSPredicate(format: "isFavourite == %@", NSNumber(value: true))
            ]) : basePredicate
    }
    
    // Если тегов нет, просто ищем по имени по умолчанию
    let basePredicate = NSPredicate(format: "name CONTAINS[cd] %@", trimmedQuery)
    
    // Если фильтр .fave, добавляем условие для избранных
    return config.filter == .fave ? 
        NSCompoundPredicate(andPredicateWithSubpredicates: [
            basePredicate,
            NSPredicate(format: "isFavourite == %@", NSNumber(value: true))
        ]) : basePredicate
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
