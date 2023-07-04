//
//  SettingsView.swift
//  Mapr
//
//  Created by Vegar Berentsen on 03/07/2023.
//
import SwiftUI

struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = true

    var body: some View {
        Form {
            Section(header: Text("Appearance")) {
                Toggle(isOn: $isDarkMode) {
                    Text("Dark Mode")
                }
                .toggleStyle(SwitchToggleStyle(tint: .accentColor))
            }
        }
        .navigationTitle("Settings")
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .frame(width: 200, height: 200)
    }
}
