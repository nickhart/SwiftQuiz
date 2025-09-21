//
//  AnalyticsView.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/17/25.
//

import CoreData
import SwiftUI

struct AnalyticsView: View {
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        ProgressOverviewView(context: self.viewContext)
    }
}

#Preview {
    AnalyticsView()
}
