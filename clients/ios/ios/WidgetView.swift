//
//  WidgetView.swift
//  ios
//
//  Created by Logan Rasmussen on 8/14/24.
//

import SwiftUI

struct WidgetView: View {
    @State var showMXConnect = false
    @State var showLocalhostWebView = false
    @State var showLoader = false
    @State var widgetUrl = ""
    @State var openOauthInSafariViewController = false

    private static let localServerBaseUrl = "http://localhost:3000"
    private static let mobileAggregationPath = "/api/mobile_aggregation_url"
    private static let mobileVerificationPath = "/api/mobile_verification_url"
    private static let mobileMasterPath = "/api/mobile_master_url"

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
        let url = URL(string: Self.localServerBaseUrl + Self.mobileAggregationPath)!
        await makeWidgetUrlRequest(url: url)
    }

    func getVerificationWidgetUrl() async {
        let url = URL(string: Self.localServerBaseUrl + Self.mobileVerificationPath)!
        await makeWidgetUrlRequest(url: url)
    }

    func getMasterWidgetUrl() async {
        let url = URL(string: Self.localServerBaseUrl + Self.mobileMasterPath)!
        await makeWidgetUrlRequest(url: url)
    }

    func openLocalhostHomePage() async {
        showLoader = false
        showMXConnect = false
        showLocalhostWebView = true
    }

    func makeWidgetUrlRequest(url: URL) async {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decodedWidgetUrlResponse = try JSONDecoder().decode(WidgetUrlResponse.self, from: data)
            widgetUrl = decodedWidgetUrlResponse.widget_url.url
            showLoader = false
            showLocalhostWebView = false
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
            } else if (showLocalhostWebView) {
                Button("Close Web App") {
                    showLocalhostWebView = false
                }
                LocalhostWebView(urlString: Self.localServerBaseUrl)
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

                widgetLaunchButton("Open web app (connect loads in iframe)", action: openLocalhostHomePage)
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
