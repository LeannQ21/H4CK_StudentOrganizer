import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        applyAccentColor(to: scene)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Reapply the accent after the window becomes active.
        applyAccentColor(to: scene)
    }

    func sceneWillResignActive(_ scene: UIScene) {
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
    }

    private func applyAccentColor(to scene: UIScene) {
        guard let accentColor = UIColor(named: "AccentColor") else {
            return
        }

        window?.tintColor = accentColor

        if let windowScene = scene as? UIWindowScene {
            windowScene.windows.forEach { window in
                window.tintColor = accentColor
            }
        }
    }
}
