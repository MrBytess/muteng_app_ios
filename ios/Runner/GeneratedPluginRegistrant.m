//
//  GeneratedPluginRegistrant.m
//  Runner
//
//  Copyright © 2026. All rights reserved.
//

#import "GeneratedPluginRegistrant.h"

#if __has_include(<shared_preferences/SharedPreferencesPlugin.h>)
#import <shared_preferences/SharedPreferencesPlugin.h>
#else
@import shared_preferences;
#endif

#if __has_include(<video_player/VideoPlayerPlugin.h>)
#import <video_player/VideoPlayerPlugin.h>
#else
@import video_player;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [SharedPreferencesPlugin registerWithRegistrar:[registry registrarForPlugin:@"SharedPreferencesPlugin"]];
  [VideoPlayerPlugin registerWithRegistrar:[registry registrarForPlugin:@"VideoPlayerPlugin"]];
}

@end
