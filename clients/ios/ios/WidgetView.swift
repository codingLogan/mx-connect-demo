//
//  WidgetView.swift
//  ios
//
//  Created by Logan Rasmussen on 8/14/24.
//

import SwiftUI

struct WidgetView: View {
    @State var showMXConnect = false
    @State var showLoader = false
    @State var widgetUrl = ""
    @State var openOauthInSafariViewController = false

    @ViewBuilder
    func widgetLaunchButton(_ title: String, action: @escaping () async -> Void) -> some View {
        Button(title) {
            Task {
                showLoader = true
                await action()
            }
        }
        .padding()
    }
    
    func getAggregationWidgetUrl() async {
        let url = URL(string: "http://localhost:3000/api/mobile_aggregation_url")!
        await makeWidgetUrlRequest(url: url)
    }

    func getVerificationWidgetUrl() async {
        let url = URL(string: "http://localhost:3000/api/mobile_verification_url")!
        await makeWidgetUrlRequest(url: url)
    }

    func getMasterWidgetUrl() async {
        let url = URL(string: "http://localhost:3000/api/mobile_master_url")!
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
    
    var body: some View {
        VStack {
            Toggle("Open OAuth in webview", isOn: $openOauthInSafariViewController)
                .padding(.horizontal)

            if (showLoader) {
                ProgressView()
            } else if (showMXConnect && widgetUrl != "") {
                Button("Close Connect") {
                    showMXConnect = false
                }
                WidgetWebView(url: widgetUrl, openOauthInSafariViewController: openOauthInSafariViewController)
            } else {
                Text("Click a link to launch a widget").padding()
                
                widgetLaunchButton("Aggregation Connect", action: getAggregationWidgetUrl)

                widgetLaunchButton("Verification Connect", action: getVerificationWidgetUrl)
                
                widgetLaunchButton("Master", action: getMasterWidgetUrl)
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
