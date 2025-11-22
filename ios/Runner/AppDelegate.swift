import Flutter
import UIKit
import Intents

@main
@objc class AppDelegate: FlutterAppDelegate {
  
  private var satellitePlugin: SatellitePlugin?
  private var securityPlugin: SecurityPlugin?
  private var phoneAIChannel: FlutterMethodChannel?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // Initialize satellite plugin
    if #available(iOS 14.0, *) {
      let controller = window?.rootViewController as! FlutterViewController
      satellitePlugin = SatellitePlugin.register(with: registrar(for: "SatellitePlugin")!) as? SatellitePlugin
      // Setup Phone AI channel for intents / transcripts
      phoneAIChannel = FlutterMethodChannel(name: "phone_ai", binaryMessenger: controller.binaryMessenger)
    }
    
    // Initialize security plugin
    securityPlugin = SecurityPlugin.register(with: registrar(for: "SecurityPlugin")!) as? SecurityPlugin
    
    GeneratedPluginRegistrant.register(with: self)
    
    // Donate Siri Shortcuts for safety commands
    if #available(iOS 12.0, *) {
      donateShortcuts()
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // MARK: - Siri Shortcuts donation
  @available(iOS 12.0, *)
  private func donateShortcuts() {
    let commands = [
      ("status", "Check my safety status"),
      ("sos", "Start emergency SOS"),
      ("hazards", "Check hazard alerts"),
      ("location", "Share my location"),
      ("battery", "Check battery level")
    ]
    
    for (id, phrase) in commands {
      let activity = NSUserActivity(activityType: "com.redping.redping.command.\(id)")
      activity.title = phrase
      activity.isEligibleForSearch = true
      activity.isEligibleForPrediction = true
      activity.persistentIdentifier = NSUserActivityPersistentIdentifier(id)
      activity.suggestedInvocationPhrase = phrase
      activity.userInfo = ["command": id]
      activity.becomeCurrent()
    }
  }
  
  // Handle Siri Shortcut continuation
  override func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    if userActivity.activityType.hasPrefix("com.redping.redping.command.") {
      if let command = userActivity.userInfo?["command"] as? String {
        let text = mapCommandToText(command)
        if !text.isEmpty {
          deliverIncomingIntent(type: "siri_shortcut", text: text, slots: ["command": command], confidence: 1.0)
        }
      }
      return true
    }
    return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
  }
  
  private func mapCommandToText(_ command: String) -> String {
    switch command {
    case "status": return "check my safety status"
    case "sos": return "start emergency SOS"
    case "hazards": return "check hazard alerts"
    case "location": return "share my location"
    case "battery": return "check battery level"
    default: return ""
    }
  }

  // MARK: - Phone AI delivery helpers
  func deliverTranscriptFinal(_ text: String) {
    phoneAIChannel?.invokeMethod("transcript_final", arguments: ["text": text])
  }

  func deliverIncomingIntent(type: String, text: String, slots: [String: Any]?, confidence: Double?) {
    var payload: [String: Any] = [
      "type": type,
      "text": text,
      "slots": slots ?? [:],
      "confidence": confidence ?? 0.0
    ]
    phoneAIChannel?.invokeMethod("incoming_intent", arguments: payload)
  }
}
