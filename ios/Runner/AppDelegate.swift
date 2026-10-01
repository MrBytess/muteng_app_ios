//
//  AppDelegate.swift
//  Runner
//
//  Copyright © 2026. All rights reserved.
//

import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let flutterEngine = self.flutterEngine {
      GeneratedPluginRegistrant.register(with: flutterEngine)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
