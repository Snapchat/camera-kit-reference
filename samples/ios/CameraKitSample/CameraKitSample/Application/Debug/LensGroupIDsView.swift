import SwiftUI

@available(iOS 13.0, *)
struct LensGroupIDsView: View {
    
    let defaultGroupIDs: [String]
    @Binding var groupIDs: [String]
    @State var newID = ""
    
    var body: some View {
        List {
            Section {
                ForEach(groupIDs, id: \.self) { id in
                    Text(id)
                }
                .onMove { source, destination in
                    groupIDs.move(fromOffsets: source, toOffset: destination)
                }
                .onDelete { offsets in
                    groupIDs.remove(atOffsets: offsets)
                }
                TextField("camera_kit_group_id_textfield_placeholder", text: $newID)
                    .ck_onSubmit(save)
            }
            Section {
                if !newID.isEmpty {
                    Button("camera_kit_group_id_add_button", action: save)
                }
            }
        }
        .navigationBarItems(trailing: Button("camera_kit_debug_reset_button", action: {
            groupIDs = defaultGroupIDs
        }).foregroundColor(.red))
        .navigationBarTitle("camera_kit_update_lens_group_button")
    }
    
    func save() {
        groupIDs.append(newID)
        newID = ""
    }
    
}
