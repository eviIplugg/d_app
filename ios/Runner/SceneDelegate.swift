import Flutter
import UIKit
import vkid_flutter_sdk

class SceneDelegate: FlutterSceneDelegate {

  func scene(
    _ scene: UIScene,
    openURLContexts URLContexts: Set<UIOpenURLContext>
  ) {
    URLContexts.forEach { ctx in
      _ = VkidFlutterSdkPlugin.vkid.open(url: ctx.url)
    }
  }
}
