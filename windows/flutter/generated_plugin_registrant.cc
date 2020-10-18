//
//  Generated file. Do not edit.
//

#include "generated_plugin_registrant.h"

#include <flutter_audio_desktop/flutter_audio_desktop_plugin.h>
#include <url_launcher_windows/url_launcher_plugin.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  FlutterAudioDesktopPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FlutterAudioDesktopPlugin"));
  UrlLauncherPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("UrlLauncherPlugin"));
}
