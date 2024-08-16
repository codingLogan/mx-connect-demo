//
//  ContentView.swift
//  ios
//
//  Created by Logan Rasmussen on 8/14/24.
//

import SwiftUI

struct WidgetEvent: Identifiable {
    var id = UUID()
    var name : String
    var data : String?
}

final class WidgetEvents: ObservableObject {
    @Published var events: [WidgetEvent] = []
}

struct ContentView: View {
    
    @StateObject var widgetEvents = WidgetEvents()
    
    var body: some View {
        TabView {
            WidgetView().tabItem {
                Image(systemName: "smartphone")
                Text("Connect Widget")
            }.environmentObject(widgetEvents)
                // onOpenUrl handles listening for URL Types that are registered in this app
                // This is how you "return" to your own app after an OAuth experience
                .onOpenURL(perform: { url in
                    print("handling url")
                    print(url)
                })
            
            WidgetEventsView().tabItem {
                Image(systemName: "ellipsis.curlybraces")
                Text("Widget Events")
            }.environmentObject(widgetEvents).badge(widgetEvents.events.count)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
