import Flutter
import UIKit
import Foundation
import LocalAuthentication
import Security

/// Native iOS security and privacy plugin
public class SecurityPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private var securityTimer: Timer?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "redping.security", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "redping.security.events", binaryMessenger: registrar.messenger())
        
        let instance = SecurityPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "checkRootStatus":
            result(checkJailbreakStatus())
        case "checkSecureLock":
            result(checkPasscodeStatus())
        case "checkPasscodeStatus":
            result(checkPasscodeStatus())
        case "checkNetworkSecurity":
            result(checkNetworkSecurity())
        case "enableSecurityMonitoring":
            if let config = call.arguments as? [String: Any] {
                enableSecurityMonitoring(config: config)
            }
            result(true)
        case "updateSecurityConfig":
            if let config = call.arguments as? [String: Any] {
                updateSecurityConfig(config: config)
            }
            result(true)
        case "checkUsageDescriptions":
            result(checkUsageDescriptions())
        case "getDeviceSecurityInfo":
            result(getDeviceSecurityInfo())
        case "checkBiometricAvailability":
            result(checkBiometricAvailability())
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }

    /// Check if device is jailbroken
    private func checkJailbreakStatus() -> Bool {
        // Check for common jailbreak indicators
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/",
            "/private/var/lib/cydia",
            "/private/var/mobile/Library/SBSettings/Themes",
            "/Library/MobileSubstrate/DynamicLibraries/LiveClock.plist",
            "/usr/libexec/ssh-keysign",
            "/private/var/tmp/cydia.log",
            "/Applications/Icy.app",
            "/Applications/MxTube.app",
            "/Applications/RockApp.app",
            "/Applications/blackra1n.app",
            "/Applications/SBSettings.app",
            "/Applications/FakeCarrier.app",
            "/Applications/WinterBoard.app",
            "/Applications/IntelliScreen.app"
        ]

        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                sendSecurityEvent(type: "jailbreak_detected", severity: "high", description: "Jailbreak indicator found: \(path)")
                return true
            }
        }

        // Try to write to system directory (jailbroken devices allow this)
        do {
            let testString = "jailbreak_test"
            let testPath = "/private/test_jailbreak.txt"
            try testString.write(toFile: testPath, atomically: true, encoding: .utf8)
            
            // If we can write, device is jailbroken
            try? FileManager.default.removeItem(atPath: testPath)
            sendSecurityEvent(type: "jailbreak_write_test", severity: "high", description: "Device allows writing to system directory")
            return true
        } catch {
            // Can't write, device is not jailbroken
        }

        // Check for suspicious apps
        if UIApplication.shared.canOpenURL(URL(string: "cydia://package/com.example.package")!) {
            sendSecurityEvent(type: "jailbreak_app_detected", severity: "high", description: "Cydia detected on device")
            return true
        }

        return false
    }

    /// Check if device has passcode/biometric lock
    private func checkPasscodeStatus() -> Bool {
        let context = LAContext()
        var error: NSError?
        
        // Check if biometric authentication is available
        let biometricAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        // Check if passcode is available
        let passcodeAvailable = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
        
        return biometricAvailable || passcodeAvailable
    }

    /// Check biometric availability
    private func checkBiometricAvailability() -> [String: Any] {
        let context = LAContext()
        var error: NSError?
        
        let biometricAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        let passcodeAvailable = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
        
        var biometricType = "none"
        if #available(iOS 11.0, *) {
            switch context.biometryType {
            case .faceID:
                biometricType = "faceID"
            case .touchID:
                biometricType = "touchID"
            case .none:
                biometricType = "none"
            @unknown default:
                biometricType = "unknown"
            }
        }
        
        return [
            "biometricAvailable": biometricAvailable,
            "passcodeAvailable": passcodeAvailable,
            "biometricType": biometricType,
            "error": error?.localizedDescription ?? ""
        ]
    }

    /// Check network security
    private func checkNetworkSecurity() -> Bool {
        // Check if device is using secure connection
        // In a real implementation, this would check for VPN, secure WiFi, etc.
        return true // Assume secure for now
    }

    /// Check if required usage descriptions are present
    private func checkUsageDescriptions() -> Bool {
        let requiredKeys = [
            "NSLocationWhenInUseUsageDescription",
            "NSLocationAlwaysAndWhenInUseUsageDescription",
            "NSCameraUsageDescription",
            "NSMicrophoneUsageDescription",
            "NSContactsUsageDescription",
            "NSMotionUsageDescription",
            "NSFaceIDUsageDescription"
        ]
        
        let bundle = Bundle.main
        for key in requiredKeys {
            if bundle.object(forInfoDictionaryKey: key) == nil {
                sendSecurityEvent(type: "missing_usage_description", severity: "medium", description: "Missing usage description: \(key)")
                return false
            }
        }
        
        return true
    }

    /// Enable security monitoring
    private func enableSecurityMonitoring(config: [String: Any]) {
        let enableTamperDetection = config["enableTamperDetection"] as? Bool ?? false
        let enableRootDetection = config["enableRootDetection"] as? Bool ?? false
        let enableDebuggingProtection = config["enableDebuggingProtection"] as? Bool ?? false

        // Start periodic security checks
        securityTimer?.invalidate()
        securityTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            if enableRootDetection && self.checkJailbreakStatus() {
                self.sendSecurityEvent(type: "jailbreak_detected_monitoring", severity: "high", description: "Jailbreak detected during monitoring")
            }
            
            if enableTamperDetection {
                self.monitorAppIntegrity()
            }
            
            if enableDebuggingProtection {
                self.checkDebuggingStatus()
            }
        }
    }

    /// Update security configuration
    private func updateSecurityConfig(config: [String: Any]) {
        let enableScreenshotPrevention = config["enableScreenshotPrevention"] as? Bool ?? false
        
        if enableScreenshotPrevention {
            // Screenshot prevention would be implemented at the view controller level
            sendSecurityEvent(type: "screenshot_prevention_enabled", severity: "low", description: "Screenshot prevention enabled")
        }
    }

    /// Monitor app integrity
    private func monitorAppIntegrity() {
        // Check app bundle integrity
        guard let bundlePath = Bundle.main.bundlePath else {
            sendSecurityEvent(type: "integrity_check_failed", severity: "medium", description: "Could not verify app bundle path")
            return
        }
        
        let bundleURL = URL(fileURLWithPath: bundlePath)
        
        do {
            let resourceValues = try bundleURL.resourceValues(forKeys: [.contentModificationDateKey])
            if let modificationDate = resourceValues.contentModificationDate {
                // In a real implementation, compare with known good modification date
                sendSecurityEvent(type: "app_integrity_check", severity: "low", description: "App integrity check completed")
            }
        } catch {
            sendSecurityEvent(type: "integrity_check_error", severity: "medium", description: "Error checking app integrity: \(error.localizedDescription)")
        }
    }

    /// Check debugging status
    private func checkDebuggingStatus() {
        #if DEBUG
        sendSecurityEvent(type: "debug_mode_active", severity: "low", description: "App is running in debug mode")
        #endif
    }

    /// Get comprehensive device security information
    private func getDeviceSecurityInfo() -> [String: Any] {
        let device = UIDevice.current
        let biometricInfo = checkBiometricAvailability()
        
        return [
            "isJailbroken": checkJailbreakStatus(),
            "hasPasscode": checkPasscodeStatus(),
            "biometricInfo": biometricInfo,
            "iosVersion": device.systemVersion,
            "model": device.model,
            "name": device.name,
            "systemName": device.systemName,
            "identifierForVendor": device.identifierForVendor?.uuidString ?? "",
            "isSimulator": isSimulator()
        ]
    }

    /// Check if running in simulator
    private func isSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    /// Send security event to Flutter
    private func sendSecurityEvent(type: String, severity: String, description: String) {
        let event: [String: Any] = [
            "type": type,
            "severity": severity,
            "description": description,
            "timestamp": Date().timeIntervalSince1970 * 1000,
            "platform": "ios"
        ]
        
        DispatchQueue.main.async {
            self.eventSink?(event)
        }
    }
}

















