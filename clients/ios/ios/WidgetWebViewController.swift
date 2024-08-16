//
//  WidgetWebViewController.swift
//  ios
//
//  Created by Logan Rasmussen on 8/16/24.
//

import Foundation
import UIKit
import WebKit

class WidgetWebViewController : UIViewController, WKNavigationDelegate, WKUIDelegate {
    var widgetWebView: WKWebView!
    var widgetUrl: String = ""
    
    /**
     Set up a WKWebView with configurations to intercept navigation requests.
     The Connect widget (inside the webview) uses navigation changes to send data to the iOS app.
     */
    override func loadView() {
        let webPreferences = WKPreferences()
        webPreferences.javaScriptCanOpenWindowsAutomatically = true

        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.preferences = webPreferences

        widgetWebView = WKWebView(frame: .zero, configuration: webConfiguration)
        widgetWebView.navigationDelegate = self // For WKNavigationDelegate
        widgetWebView.uiDelegate = self
        view = widgetWebView
    }

    /**
     Load WKWebView with the initial widgetUrl
     */
    override func viewDidLoad() {
        super.viewDidLoad()

        print("Load WKWebView with: \(widgetUrl)")
        widgetWebView.load(URLRequest(url: URL(string:widgetUrl)!))
    }
    
    /**
     When an OAuth connection attempt is being made, open the URL in the devices default browser.
     */
    func handleOauthRedirect(payload: URLQueryItem?) {
        let metadataString = payload?.value ?? ""

        do {
            if let json = try JSONSerialization.jsonObject(with: Data(metadataString.utf8), options: []) as? [String: Any] {
                if let url = json["url"] as? String {
                    // open safari with the url from the json payload
                    UIApplication.shared.open(URL(string: url)!)
                }
            }
        } catch let error as NSError {
            print("Failed to parse payload: \(error.localizedDescription)")
        }
    }
    
    /**
     Handle messages and events coming from the Connect widget's webview
     */
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        print("Capture WKNavigationAction")
        
        let appScheme = "mxconnectdemo://"
        
        let navigationUrl = navigationAction.request.url?.absoluteString
        print("\(navigationUrl ?? "navigation url"))")
        let isPostMessageFromMX = navigationUrl?.hasPrefix(appScheme)
        
        print(navigationUrl!)
        
        if (isPostMessageFromMX!) {
            let urlc = URLComponents(string: navigationUrl ?? "")
            let path = urlc?.path ?? ""
            // there is only one query param ("metadata") with each navigationUrl, so just grab the first
            let metaDataQueryItem = urlc?.queryItems?.first
            
            print("===================================")
            print("Widget Event: \(path)")
            print("data: \(metaDataQueryItem?.value ?? "")")
            print("-----------------------------------")
            
            if path == "/oauthRequested" {
                handleOauthRedirect(payload: metaDataQueryItem)
            }
            
            /**
             This prevents the iOS app from changing the Connect webview's URL.
             */
            decisionHandler(.cancel)
            return
        }
        print("Is not a post message")
        
        // Make sure to open links in the user agent, not the webview.
        // Allowing a navigation action could navigate the user away from
        // connect and lose their session.
        if let urlToOpen = navigationUrl {
            // Don't open the navigationUrl, if it is the widget url itself on the first load
            let shouldOpenUrlInBrowser = urlToOpen != widgetUrl
            if (shouldOpenUrlInBrowser) {
                print("Opening Url in the browser")
                UIApplication.shared.open(URL(string: urlToOpen)!)
            }
        }
        
        decisionHandler(.allow)
    }
    
    /**
     Handle when the widget tries to open a new tab or page, such as going to an intitution's website
     
     Sometimes the widget will make calls to `window.open` these calls will end up here if
     `javaScriptCanOpenWindowsAutomatically` is set to `true`. When doing this, make sure
     to return `nil` here so you don't end up overwriting the widget webview instance. Generally speaking
     it is best to open the url in a new browser session.
     */
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        let url = navigationAction.request.url?.absoluteString

        print("WKWindowFeatures...")
        print(url ?? "")

        if let urlToOpen = url {
            // Don't open the url, if it is the widget url itself on the first load
            if (urlToOpen != widgetUrl) {
                UIApplication.shared.open(URL(string: urlToOpen)!)
            }
        }

        return nil
    }
}
