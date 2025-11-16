//
//  SpotSeekerApp.swift
//  SpotSeeker
//
//  Created by Wenhao.Wang on 7/5/25.
//

import SwiftUI
import UIKit

@main
struct SpotSeekerApp: App {
    init() {
        // Customize the Tab Bar appearance (background color, tints)
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 1.0) // modern dark background
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.2)
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        UITabBar.appearance().unselectedItemTintColor = UIColor.white.withAlphaComponent(0.6)
        UITabBar.appearance().tintColor = UIColor.white
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

struct RootView: View {
    @State private var showSplash = true

    var body: some View {
        ZStack {
            MainTabView()
                .opacity(showSplash ? 0 : 1)

            if showSplash {
                SplashView()
                    .transition(.opacity)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.6)) {
                    showSplash = false
                }
            }
        }
    }
}

struct MainTabView: View {
    enum Tab { case album, camera, profile }
    @State private var selection: Tab = .camera

    var body: some View {
        TabView(selection: $selection) {
            ImageSeriesView()
                .tabItem {
                    // Simplified album icon
                    Image(systemName: "photo")
                }
                .tag(Tab.album)

            ContentView()
                .tabItem {
                    // Simplified camera icon
                    Image(systemName: "camera")
                }
                .tag(Tab.camera)

            ProfileView()
                .tabItem {
                    // Simplified profile icon
                    Image(systemName: "person.circle")
                }
                .tag(Tab.profile)
        }
        .tint(.white) // ensure selected icon is white
    }
}
