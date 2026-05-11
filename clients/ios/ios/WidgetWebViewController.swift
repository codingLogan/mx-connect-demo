//
//  WidgetWebViewController.swift
//  ios
//
//  Created by Logan Rasmussen on 8/16/24.
//

import Foundation
import UIKit
import WebKit

enum OauthOpenMode {
    case externalBrowser
    case inAppWebView
}

class WidgetWebViewController : UIViewController, WKNavigationDelegate, WKUIDelegate {
    var widgetWebView: WKWebView!
    var widgetUrl: String = ""
    var widgetEvents: WidgetEvents!
    var oauthOpenMode: OauthOpenMode = .externalBrowser

    private func recordEvent(_ name: String, data: String? = nil) {
        widgetEvents.events.append(WidgetEvent(name: name, data: data ?? ""))
    }
    
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
        widgetWebView.isInspectable = true // Allows a local Safari Browser's "Develop" menu to see the web console of the WKWebView
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
                    guard let oauthURL = URL(string: url) else {
                        recordEvent("oauth/debug/invalidUrl", data: url)
                        return
                    }

                    if oauthOpenMode == .inAppWebView {
                        recordEvent("oauth/debug/openingInAppWebView", data: oauthURL.absoluteString)
                        openOauthInDiagnosticWebView(url: oauthURL)
                    } else {
                        // Open system browser with the URL from the json payload.
                        recordEvent("oauth/debug/openingExternalBrowser", data: oauthURL.absoluteString)
                        UIApplication.shared.open(oauthURL)
                    }
                }
            }
        } catch let error as NSError {
            print("Failed to parse payload: \(error.localizedDescription)")
            recordEvent("oauth/debug/metadataParseFailure", data: error.localizedDescription)
        }
    }

    private func openOauthInDiagnosticWebView(url: URL) {
        let oauthController = OAuthDiagnosticWebViewController()
        oauthController.oauthUrl = url
        oauthController.widgetEvents = widgetEvents

        let navController = UINavigationController(rootViewController: oauthController)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
    
    /**
     Handle messages and events coming from the Connect widget's webview
     */
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        print("===================================")
        print("Capture WKNavigationAction")
        
        let appScheme = "mxconnectdemo://"
        
        let navigationUrl = navigationAction.request.url?.absoluteString
        print("\(navigationUrl ?? "navigation url"))")
        let isPostMessageFromMX = navigationUrl?.hasPrefix(appScheme)
        
        if (isPostMessageFromMX!) {
            let urlc = URLComponents(string: navigationUrl ?? "")
            let path = urlc?.path ?? ""
            // there is only one query param ("metadata") with each navigationUrl, so just grab the first
            let metaDataQueryItem = urlc?.queryItems?.first

            recordEvent((urlc?.host ?? "") + path, data: metaDataQueryItem?.value ?? "")
            
            if path == "/oauthRequested" {
                handleOauthRedirect(payload: metaDataQueryItem)
            }
            
            /**
             This prevents the iOS app from changing the Connect webview's URL.
             */
            decisionHandler(.cancel)
            return
        }
        
        // Make sure to open links in the user agent, not the webview.
        // Allowing a navigation action could navigate the user away from
        // connect and lose their session.
        if let urlToOpen = navigationUrl {
            // Don't open the navigationUrl, if it is the widget url itself on the first load
            let isWebviewsFirstURL = urlToOpen == widgetUrl
            let isConnectOrConnections = urlToOpen.contains("/connect")
            if (!isWebviewsFirstURL && !isConnectOrConnections) {
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

    /**
     Don't include this code in your app, this is just to get around ssl issues in development.
     */
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let serverTrust = challenge.protectionSpace.serverTrust else { return completionHandler(.useCredential, nil) }
        let exceptions = SecTrustCopyExceptions(serverTrust)
        SecTrustSetExceptions(serverTrust, exceptions)
        completionHandler(.useCredential, URLCredential(trust: serverTrust))
        print("TODO: fix this WKWebView 'func webView' handler... bad for peformance and it may lead to UI unresponsiveness???")
    }
}

class OAuthDiagnosticWebViewController: UIViewController, WKNavigationDelegate {
    var oauthUrl: URL!
    var widgetEvents: WidgetEvents!

    private var oauthWebView: WKWebView!

    private func recordEvent(_ name: String, data: String? = nil) {
        widgetEvents.events.append(WidgetEvent(name: name, data: data ?? ""))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "OAuth Debug"
        view.backgroundColor = .systemBackground

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeModal)
        )

        oauthWebView = WKWebView(frame: .zero)
        oauthWebView.navigationDelegate = self
        oauthWebView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(oauthWebView)
        NSLayoutConstraint.activate([
            oauthWebView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            oauthWebView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            oauthWebView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            oauthWebView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        recordEvent("oauth/debug/webviewStart", data: oauthUrl.absoluteString)
        oauthWebView.load(URLRequest(url: oauthUrl))
    }

    @objc private func closeModal() {
        dismiss(animated: true)
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let urlString = navigationAction.request.url?.absoluteString ?? ""
        recordEvent("oauth/debug/decidePolicy", data: urlString)

        if let callbackURL = navigationAction.request.url,
           callbackURL.scheme == "mxconnectdemo" {
            recordEvent("oauth/debug/callbackDetected", data: callbackURL.absoluteString)

            // Hand off app callback URL so the app's onOpenURL path runs.
            UIApplication.shared.open(callbackURL)
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        recordEvent("oauth/debug/didStartProvisionalNavigation", data: webView.url?.absoluteString ?? "")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        recordEvent("oauth/debug/didFinish", data: webView.url?.absoluteString ?? "")
    }

    func webView(_ webView: WKWebView,
                 didFail navigation: WKNavigation!,
                 withError error: Error) {
        recordEvent("oauth/debug/didFail", data: error.localizedDescription)
    }

    func webView(_ webView: WKWebView,
                 didFailProvisionalNavigation navigation: WKNavigation!,
                 withError error: Error) {
        recordEvent("oauth/debug/didFailProvisionalNavigation", data: error.localizedDescription)
    }
}
