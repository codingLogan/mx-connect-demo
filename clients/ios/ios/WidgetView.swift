//
//  WidgetView.swift
//  ios
//
//  Created by Logan Rasmussen on 8/14/24.
//

import SwiftUI
import SafariServices

struct WidgetView: View {
    @State var showMXConnect = false
    @State var widgetUrl = ""
    
    func getWidgetUrl() async {
        let url = URL(string: "http://localhost:3000/api/web_url")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decodedWidgetUrlResponse = try JSONDecoder().decode(WidgetUrlResponse.self, from: data)
            widgetUrl = decodedWidgetUrlResponse.widget_url.url
            showMXConnect = true
        } catch {
            print("Could not get widget URL: \(error.localizedDescription)")
        }
    }
    
    var body: some View {
        VStack {
            Text("Welcome to the MX Connect demo app")
            Button("Click to launch Connect in a webview") {
                Task {
                    await getWidgetUrl()
                }
            }
            .padding()
            .sheet(isPresented: $showMXConnect) {
                if (widgetUrl != "") {
                    SafariSheetView(url:URL(string: widgetUrl)!)
                } else {
                    Text("Something went wrong with the Connect URL")
                }
            }
            
            if (widgetUrl != "") {
                Text("Launched widget!")
            }
        }
    }
}

struct SafariSheetView: UIViewControllerRepresentable {

    let url: URL

    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariSheetView>) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariSheetView>) {
        
    }

}

struct WidgetUrl: Codable {
    var type: String
    var url: String
    var user_id: String
}

struct WidgetUrlResponse: Codable {
    var widget_url: WidgetUrl
}

#Preview {
    WidgetView()
}
