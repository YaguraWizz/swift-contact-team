//
//  CreateContactView.swift
//  MyRideOrDies
//
//  Created by Tunde Adegoroye on 10/12/2022.
//
import SwiftUI


struct CreateContactView: View {
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var vm: EditContactViewModel
    
    @State private var hasError: Bool = false

    var body: some View {
        List {
            Section("General") {
                TextField("Name", text: $vm.contact.name)
                    .keyboardType(.namePhonePad)

                TextField("Email", text: $vm.contact.email)
                    .keyboardType(.emailAddress)

                DatePicker("Birthday",
                           selection: $vm.contact.dob,
                           displayedComponents: [.date])
                    .datePickerStyle(.compact)
                
                Toggle("Favourite", isOn: $vm.contact.isFavourite)
            }

            Section("Phone Numbers") {
                ForEach(Array(vm.contact.phoneNumbers), id: \.self) { phoneNumber in
                    HStack {
                        TextField("Number", text: Binding(
                            get: { phoneNumber.number },
                            set: { newValue in
                                phoneNumber.number = newValue
                            }
                        ))
                        .keyboardType(.phonePad)

                        TextField("Type", text: Binding(
                            get: { phoneNumber.type },
                            set: { newValue in
                                phoneNumber.type = newValue
                            }
                        ))
                        .keyboardType(.default)
                    }
                }
                .onDelete { indexSet in
                    vm.removePhoneNumbers(at: indexSet)
                }
                
                Button(action: {
                    vm.addPhoneNumber()
                }) {
                    Label("Add Phone Number", systemImage: "plus")
                }
            }

            Section("Notes") {
                TextField("Notes",
                          text: $vm.contact.notes,
                          axis: .vertical)
            }
        }
        .navigationTitle(vm.isNew ? "New Contact" : "Update Contact")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    validate()
                }
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .alert("Something ain't right",
               isPresented: $hasError,
               actions: {}) {
            Text("It looks like your form is invalid")
        }
    }
}

private extension CreateContactView {
    
    func validate() {
        if vm.contact.isValid {
            do {
                try vm.save()
                dismiss()
            } catch {
                print(error)
            }
        } else {
            hasError = true
        }
    }
}

struct CreateContactView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            let preview = ContactsProvider.shared
            CreateContactView(vm: .init(provider: preview))
                .environment(\.managedObjectContext, preview.viewContext)
        }
    }
}
