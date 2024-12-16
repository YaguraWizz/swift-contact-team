//
//  contact_bookApp.swift
//  contact-book
//
//  Created by Nikita on 16.12.2024.
//

import SwiftUI

@main
struct contact_bookApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, ContactsProvider.shared.viewContext)
        }
    }
}
