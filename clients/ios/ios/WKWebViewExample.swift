//
//  WKWebViewExample.swift
//  ios
//
//  Created by Logan Rasmussen on 8/15/24.
//
import SwiftUI
import WebKit


struct WKWebViewExample: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView  {
        let wkwebView = WKWebView()
        let request = URLRequest(url: url)
        wkwebView.navigationDelegate = context.coordinator
        wkwebView.load(request)
        return wkwebView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        print("makeCoordinator called...")
        let coord = Coordinator()
        return coord
    }
    
    @MainActor class Coordinator: NSObject, WKNavigationDelegate {
        private nonisolated func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) async {
            
            print("capture event")
            
            let appScheme = "mxconnectdemo://"
            
            let navigationUrl = navigationAction.request.url?.absoluteString
            print("\(navigationUrl ?? "navigation url"))")
            let isPostMessageFromMX = navigationUrl?.hasPrefix(appScheme)
            
            if (isPostMessageFromMX!) {
                let urlc = URLComponents(string: navigationUrl ?? "")
                let path = urlc?.path ?? ""
                // there is only one query param ("metadata") with each navigationUrl, so just grab the first
                let metaDataQueryItem = urlc?.queryItems?.first
                
                if path == "/oauthRequested" {
                    await handleOauthRedirect(payload: metaDataQueryItem)
                }
                
                decisionHandler(.cancel)
                return
            }
            
            // Make sure to open links in the user agent, not the webview.
            // Allowing a navigation action could navigate the user away from
            // connect and lose their session.
            if let urlToOpen = navigationUrl {
                // Don't open the navigationUrl, if it is the widget url itself on the first load
                if (!urlToOpen.contains("/connect/")) {
                    await UIApplication.shared.open(URL(string: urlToOpen)!)
                }
            }
            
            decisionHandler(.allow)
        }
        
        /**
         Handle the oauthRequested event. Parse out the oauth url from the event and open safari to that url
         NOTE: This code is somewhat optimistic, you'll want to add error handling that makes sense for your app.
         */
        nonisolated func handleOauthRedirect(payload: URLQueryItem?) async {
            let metadataString = payload?.value ?? ""

            do {
                if let json = try JSONSerialization.jsonObject(with: Data(metadataString.utf8), options: []) as? [String: Any] {
                    if let url = json["url"] as? String {
                        // open safari with the url from the json payload
                        await UIApplication.shared.open(URL(string: url)!)
                    }
                }
            } catch let error as NSError {
                print("Failed to parse payload: \(error.localizedDescription)")
            }
        }
    }
}
