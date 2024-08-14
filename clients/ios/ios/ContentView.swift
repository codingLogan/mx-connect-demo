//
//  ContentView.swift
//  ios
//
//  Created by Logan Rasmussen on 8/14/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            WidgetView().tabItem {
                Image(systemName: "smartphone")
                Text("Connect Widget")
            }
            
            WidgetEventsView().tabItem {
                Image(systemName: "ellipsis.curlybraces")
                Text("Widget Events")
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
