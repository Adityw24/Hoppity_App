import UIKit
import Flutter
import AVFoundation

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // video_player: allow audio to mix with other apps and work
    // even when the silent switch is on (standard for travel apps)
    do {
      try AVAudioSession.sharedInstance().setCategory(
        .playback,
        mode: .moviePlayback,
        options: [.mixWithOthers, .allowAirPlay]
      )
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      print("AVAudioSession setup failed: \(error)")
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
