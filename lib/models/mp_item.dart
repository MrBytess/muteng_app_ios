/// 小程序条目
class MpItem {
  final String appId;
  final String appName;
  final String appIcon;
  final String appDesc;
  final String appVersion;
  final String appDownloadUrl;

  MpItem({
    required this.appId,
    this.appName = '',
    this.appIcon = '',
    this.appDesc = '',
    this.appVersion = '',
    this.appDownloadUrl = '',
  });

  factory MpItem.fromJson(Map<String, dynamic> json) => MpItem(
        appId: json['app_id']?.toString() ?? '',
        appName: json['app_name']?.toString() ?? '',
        appIcon: json['app_icon']?.toString() ?? '',
        appDesc: json['app_desc']?.toString() ?? '',
        appVersion: json['app_version']?.toString() ?? '',
        appDownloadUrl: json['app_download_url']?.toString() ?? '',
      );
}
