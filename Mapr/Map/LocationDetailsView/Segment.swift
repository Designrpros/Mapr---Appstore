//
//  Segment.swift
//  Handy
//
//  Created by Vegar Berentsen on 18/06/2023.
//

import SwiftUI

struct CustomSegmentedControl: View {
    @Binding var selectedTab: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<5) { index in
                Button(action: {
                    withAnimation {
                        selectedTab = index
                    }
                    
                }){
                
                
                    VStack {
                        Image(systemName: getImageName(for: index))
#if os(macOS)
                        Text(getText(for: index))
#endif
                    }
                    .padding()
                    .foregroundColor(selectedTab == index ? .blue : .gray)
                }
                .buttonStyle(BorderlessButtonStyle())
                .frame(maxWidth: .infinity)
                .overlay(
                    Rectangle()
                        .frame(height: 3)
                        .foregroundColor(selectedTab == index ? .blue : .clear),
                    alignment: .bottom
                )
            }
        }
    }

    func getImageName(for index: Int) -> String {
        switch index {
        case 0: return "info.circle"
        case 1: return "clock"
        case 2: return "cube.box"
        case 3: return "checkmark.square"
        case 4: return "doc.text"
        default: return ""
        }
    }
#if os(macOS)
    func getText(for index: Int) -> String {
        switch index {
        case 0: return "Details"
        case 1: return "Time"
        case 2: return "Materials"
        case 3: return "Checklist"
        case 4: return "Preview"
        default: return ""
        }
    }
#endif
}

