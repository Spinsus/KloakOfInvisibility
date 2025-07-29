//
//  ContentView.swift
//  KloakOfInvisibility
//
//  Created by Kevo on 7/28/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "eye.slash.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Kloak of Invisibility")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Your metadata stripping extension is active! Share photos and videos to automatically remove all identifying information.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("EXIF data removal")
                }
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("GPS location stripping")
                }
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Camera model anonymization")
                }
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Timestamp removal")
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            Text("To use: Share any photo and tap 'KloakOfInvisibility' in the share menu")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
