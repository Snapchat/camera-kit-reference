import SwiftUI

@available(iOS 13.0, *)
struct APITokenView: View {
    
    @Binding var apiToken: String
    @State var initialAPIToken: String

    init(apiToken: Binding<String>) {
        _apiToken = apiToken
        self.initialAPIToken = apiToken.wrappedValue
    }
    
    var body: some View {
        List {
            Section {
                if #available(iOS 14, *) {
                    TextEditor(text: $apiToken)
                        .frame(minHeight: 250)
                } else {
                    TextField("camera_kit_update_api_token_placeholder", text: $apiToken)
                }
            }
            Section {
                if apiToken != initialAPIToken {
                    Text("camera_kit_update_api_token_restart_prompt")
                    Button {
                        exit(0)
                    } label: {
                        Text("camera_kit_update_api_token_quit_button")
                            .bold()
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .navigationBarItems(trailing: Button("camera_kit_debug_reset_button", action: {
            apiToken = ApplicationInfo.apiToken!
        }).foregroundColor(.red))
        .ck_navigationTitle("camera_kit_update_api_token_button")
    }
        
}
