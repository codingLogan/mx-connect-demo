//
//  WidgetEventsView.swift
//  ios
//
//  Created by Logan Rasmussen on 8/14/24.
//

import SwiftUI

struct WidgetEventsView: View {
    @EnvironmentObject var widgetEvents: WidgetEvents
    
    var body: some View {
        VStack {
            Text("Widget events list")
            List(widgetEvents.events) { event in
                Text("\(event.name):\n \(event.data ?? "")")
            }
            Button("Clear Events") {
                widgetEvents.events.removeAll()
            }.padding()
            .background(.red)
            .foregroundColor(.white)
            .clipShape(Capsule())
        }
    }
}

#Preview {
    WidgetEventsView()
}
