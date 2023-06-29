import SwiftUI

@available(iOS 13.0.0, *)
struct DebugView: View {
    
    @ObservedObject var store: DebugStore
    
    var body: some View {
        List {
            NavigationLink("camera_kit_update_api_token_button") {
                APITokenView(apiToken: $store.apiToken)
            }
            NavigationLink("camera_kit_update_lens_group_button") {
                LensGroupIDsView(defaultGroupIDs: store.defaultGroupIDs, groupIDs: $store.groupIDs)
            }
        }
        .ck_navigationTitle("Debug")
    }
    
}

@available(iOS 13.0, *)
extension View {
    
    func ck_navigationTitle(_ titleKey: LocalizedStringKey) -> some View {
        if #available(iOS 14, *) {
            return navigationTitle(titleKey)
        } else {
            return navigationBarTitle(titleKey)
        }
    }
    
    func ck_onSubmit(_ action: @escaping (() -> Void)) -> some View {
        if #available(iOS 15, *) {
            return onSubmit(action)
        } else {
            return self
        }
    }

}
