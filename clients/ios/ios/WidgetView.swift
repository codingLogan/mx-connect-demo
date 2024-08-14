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
    @State var urlString = "http://localhost:3000/"
    
    var body: some View {
        VStack {
            Text("Welcome to the MX Connect demo app")
            Button("Click to launch Connect in a webview") {
                self.urlString = urlString
                self.showMXConnect = true
                print("Connect widget launch...")
            }
            .padding()
            
            // Open the URL
            .sheet(isPresented: $showMXConnect) {
                SafariView(url:URL(string: self.urlString)!)
            }
        }
    }
}

struct SafariView: UIViewControllerRepresentable {

    let url: URL

    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariView>) {

    }

}

#Preview {
    WidgetView()
}
