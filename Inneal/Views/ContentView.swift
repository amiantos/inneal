//
//  ContentView.swift
//  Inneal
//
//  Created by Brad Root on 4/26/24.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    // We need this content view because of
    // https://stackoverflow.com/questions/78265564/background-crash-swiftdata-swiftui-one-time-initialization-function-for-empty

    let container: ModelContainer
    let modelContext: ModelContext

    init(container: ModelContainer) {
        self.container = container
        modelContext = ModelContext(container)
    }

    var body: some View {
        ChatsView().modelContext(modelContext)
    }
}

#Preview {
    ContentView(container: PreviewDataController.previewContainer)
}
