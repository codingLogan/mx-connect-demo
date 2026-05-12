//
//  WidgetWebView.swift
//  ios
//
//  Created by Logan Rasmussen on 8/16/24.
//

import SwiftUI

struct WidgetWebView: UIViewControllerRepresentable {
    typealias UIViewControllerType = WidgetWebViewController
    
    @EnvironmentObject var widgetEvents: WidgetEvents
    
    var url: String = ""
    var openOauthInSafariViewController: Bool = false
    
    func makeUIViewController(context: Context) -> WidgetWebViewController {
        let widgetViewController = WidgetWebViewController()
        widgetViewController.widgetUrl = url
        widgetViewController.widgetEvents = widgetEvents
        widgetViewController.oauthOpenMode = openOauthInSafariViewController ? .inAppSafariViewController : .externalBrowser
        
        return widgetViewController
    }
    
    func updateUIViewController(_ uiViewController: WidgetWebViewController, context: Context) {
        // Updates the view controller with new information from SwiftUI.
    }
}

#Preview {
    WidgetWebView()
}
