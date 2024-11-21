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
    @State var showLoader = false
    @State var widgetUrl = ""
    
    func getWidgetUrl() async {
        let url = URL(string: "http://localhost:3000/api/mobile_url")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        await makeWidgetUrlRequest(url: url)
    }

    func getMasterWidgetUrl() async {
        let url = URL(string: "http://localhost:3000/api/master_mobile_url")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        await makeWidgetUrlRequest(url: url)
    }

    func makeWidgetUrlRequest(url: URL) async {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decodedWidgetUrlResponse = try JSONDecoder().decode(WidgetUrlResponse.self, from: data)
            widgetUrl = decodedWidgetUrlResponse.widget_url.url
            showLoader = false
            showMXConnect = true
        } catch {
            print("Could not get widget URL: \(error.localizedDescription)")
        }
    }
    
    func mobileMasterWidgetUrl() {
        widgetUrl = "https://int-widgets.moneydesktop.com/md/mobile_master/NmNhYjAwNjQyNjBlZmQ4YjMxNjRkNTgwMjg3ZWExNzk2OGYwMWYyNzY3YTVjNmVlY2JmMWU3MWRlM2Q0MmJhYzcxMWM5ZjI4NGE3ZmYxOWUwN2VhMjMxMGJjMGZjMzNlOGUxMjZlY2VjYzAyOTgxZmNkM2NmYTBmYjBkMTgxZWVmMzM0YTMwNDliYjVlODRmZGI5YWJmNzY0ZmVmM2U4YnxVU1ItNmIyMDE3YmItYmE5My00OTBhLTk4M2YtNTkwMzU1NjQyODMy/eyJpc19tb2JpbGVfd2VidmlldyI6dHJ1ZX0%3D"
        showLoader = false
        showMXConnect = true
    }
    
    var body: some View {
        VStack {
            if (showLoader) {
                ProgressView()
            } else if (showMXConnect && widgetUrl != "") {
                Button("Close Connect") {
                    showMXConnect = false
                }
                WidgetWebView(url:widgetUrl)
            } else {
                Text("Welcome to the MX Connect demo app").padding()
                
                Button("Click to launch Connect in a webview") {
                    Task {
                        showLoader = true
                        await getWidgetUrl()
                    }
                }
                .padding()
                
                Button("Click to launch Master in a webview") {
                    Task {
                        showLoader = true
                        await getMasterWidgetUrl()
                    }
                }
                .padding()
                
                Button("Click to launch Master Mobile in a webview") {
                    Task {
                        showLoader = true
                        mobileMasterWidgetUrl()
                    }
                }
                .padding()
            }
        }
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
