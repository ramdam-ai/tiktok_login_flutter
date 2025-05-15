import Flutter
import UIKit
import TikTokOpenSDKCore
import TikTokOpenAuthSDK

public class SwiftTiktokLoginFlutterPlugin: NSObject, FlutterPlugin {
    private var pendingAuthRequest: TikTokAuthRequest?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "tiktok_login_flutter", binaryMessenger: registrar.messenger())
        let instance = SwiftTiktokLoginFlutterPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initializeTiktokLogin":
            self.initializeTiktokLogin(call: call, result: result)
        case "authorize":
            self.authorize(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func initializeTiktokLogin(call: FlutterMethodCall, result: @escaping FlutterResult) {
        // TikTok OpenSDK auto-registers client key from Info.plist
        return result(true)
    }

    private func authorize(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let viewController = UIApplication.shared.delegate?.window??.rootViewController else {
            result(FlutterError(code: "VIEW_CONTROLLER_NOT_FOUND", message: "Could not find root view controller", details: nil))
            return
        }

        guard let args = call.arguments as? [String: Any],
              let scope = args["scope"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid or missing arguments", details: nil))
            return
        }

        // Split by comma into a list
        let scopeList = scope.components(separatedBy: ",")

        // Create URL for redirect
        // Using the key "redirectUrl" as specified in your Flutter implementation
        let redirectUrl = args["redirectUrl"] as? String ?? "https://www.example.com/path"

        // Create auth request - Note: TikTokAuthRequest expects Set<String> for scopes
        let scopeSet = Set(scopeList)
        let authRequest = TikTokAuthRequest(scopes: scopeSet, redirectURI: redirectUrl)

        // Save a reference to the request to ensure it stays alive during the callback
        self.pendingAuthRequest = authRequest
        let codeVerifier = authRequest.pkce.codeVerifier
        let codeChallenge = authRequest.pkce.codeChallenge

        // Send the request with explicit type annotation for response
        authRequest.send { [weak self] (response: TikTokBaseResponse) in
            guard let authResponse = response as? TikTokAuthResponse else {
                result(FlutterError(code: "INVALID_RESPONSE", message: "Invalid response from TikTok", details: nil))
                return
            }

            if authResponse.errorCode == .noError {
                // Success - access auth code which is now available as 'code' property
                let resultMap: [String: String?] = [
                            "authCode": authResponse.authCode,
                            "codeVerifier": codeVerifier,
                            "codeChallenge": codeChallenge
                        ]
                        result(resultMap)
            } else {
                // Error
                result(FlutterError(
                    code: "AUTHORIZATION_REQUEST_FAILED",
                    message: authResponse.errorDescription ?? authResponse.error ?? "Unknown error",
                    details: nil
                ))
            }

            // Clear the reference
            self?.pendingAuthRequest = nil
        }
    }

    // MARK: - App Delegate Methods

    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [AnyHashable: Any] = [:]) -> Bool {
        // No specific initialization needed for the new SDK
        return true
    }

    public func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
        // Use the new TikTokURLHandler to handle the URL
        if TikTokURLHandler.handleOpenURL(url) {
            return true
        }
        return false
    }

    public func application(_ application: UIApplication, open url: URL, sourceApplication: String, annotation: Any) -> Bool {
        // Use the new TikTokURLHandler to handle the URL
        if TikTokURLHandler.handleOpenURL(url) {
            return true
        }
        return false
    }

    public func application(_ application: UIApplication, handleOpen url: URL) -> Bool {
        // Use the new TikTokURLHandler to handle the URL
        if TikTokURLHandler.handleOpenURL(url) {
            return true
        }
        return false
    }

    public func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]) -> Void) -> Bool {
        // Handle Universal Links for iOS 12+
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
            if let url = userActivity.webpageURL, TikTokURLHandler.handleOpenURL(url) {
                return true
            }
        }
        return false
    }
}