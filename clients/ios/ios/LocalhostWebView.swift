//
//  LocalhostWebView.swift
//  ios
//
//  Created by GitHub Copilot on 5/13/26.
//

import SwiftUI
import SafariServices
import WebKit

struct LocalhostWebView: UIViewRepresentable {
    var urlString: String
    var onNavigationAttempt: ((WKNavigationAction) -> Void)? = nil

    // Build a WKWebView configured to allow JavaScript-driven new windows.
    func makeUIView(context: Context) -> WKWebView {
        let webPreferences = WKPreferences()
        webPreferences.javaScriptCanOpenWindowsAutomatically = true

        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.preferences = webPreferences

        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator

        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }

        return webView
    }

    // Keep the existing webview pointed at the requested URL if SwiftUI re-renders it.
    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let currentUrl = uiView.url?.absoluteString, currentUrl == urlString else {
            if let url = URL(string: urlString) {
                uiView.load(URLRequest(url: url))
            }
            return
        }
    }

    // WKNavigationDelegate handles normal navigation requests, including main-frame and iframe/subframe attempts.
    final class Coordinator: NSObject, WKNavigationDelegate {
        var onNavigationAttempt: ((WKNavigationAction) -> Void)?

        init(onNavigationAttempt: ((WKNavigationAction) -> Void)? = nil) {
            self.onNavigationAttempt = onNavigationAttempt
        }

        // This is the hook for actual navigation requests made by the web content.
        // Use targetFrame to distinguish the main web frame from iframe/subframe navigation.
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            let urlString = navigationAction.request.url?.absoluteString ?? "unknown url"
            let frameType = navigationAction.targetFrame?.isMainFrame == true ? "main frame" : "subframe"
            print("LocalhostWebView navigation event [\(frameType)]: \(urlString)")
            onNavigationAttempt?(navigationAction)
            decisionHandler(.allow)
        }
    }

    // SwiftUI asks for a coordinator once and keeps it around as the delegate object.
    func makeCoordinator() -> Coordinator {
        Coordinator(onNavigationAttempt: onNavigationAttempt)
    }
}

// WKUIDelegate handles browser-style window creation attempts, including window.open.
extension LocalhostWebView.Coordinator: WKUIDelegate {
    // This is the hook for window.open or similar new-window requests coming from the page.
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        let urlString = navigationAction.request.url?.absoluteString ?? "unknown url"
        print("LocalhostWebView window.open event: \(urlString)")

        if let url = navigationAction.request.url,
           let presentingViewController = webView.window?.rootViewController {
            let safariViewController = SFSafariViewController(url: url)
            presentingViewController.present(safariViewController, animated: true)
        }

        return nil
    }
}

#Preview {
    LocalhostWebView(urlString: "http://localhost:3000")
}
