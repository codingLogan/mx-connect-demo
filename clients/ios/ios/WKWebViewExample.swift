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
        wkwebView.load(request)
        return wkwebView
    }
        
    func updateUIView(_ uiView: WKWebView, context: Context) {
    }
}
