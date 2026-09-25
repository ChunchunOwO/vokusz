import 'package:flutter/widgets.dart';
import 'static_copy.dart';

/// Interface copy. Chinese is the default; English is the other complete set.
class AppStrings {
  const AppStrings._(this.zh);

  /// Used by background validation and notifications that have no widget context.
  static String languageCode = 'en';

  /// For fixed application catalogs only, not names, messages or other user data.
  static String label(String english, {BuildContext? context}) =>
      choose(english, staticChineseCopy[english] ?? english, context: context);

  static String choose(
    String english,
    String chinese, {
    BuildContext? context,
  }) {
    final code = context == null
        ? languageCode
        : Localizations.localeOf(context).languageCode;
    return code == 'en' ? english : chinese;
  }

  final bool zh;

  static AppStrings of(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return AppStrings._(code != 'en');
  }

  String get welcome => zh ? '欢迎来到 Vokusz' : 'Welcome to Vokusz';
  String get signIn => zh ? '登录' : 'Sign in';
  String get register => zh ? '注册' : 'Register';
  String get logIn => zh ? '登录' : 'Log in';
  String get username => zh ? '用户名' : 'Username';
  String get usernameOrEmail => zh ? '用户名或邮箱' : 'Username or email';
  String get password => zh ? '密码' : 'Password';
  String get displayNameOptional => zh ? '显示名称（可选）' : 'Display name (optional)';
  String get switchAccount => zh ? '切换账号' : 'Switch account';
  String get addChannel => zh ? '创建域' : 'Create a domain';
  String get pickChannel => zh ? '选择域' : 'Select a domain';
  String get channelName => zh ? '域名称' : 'Domain name';
  String get create => zh ? '创建' : 'Create';
  String get cancel => zh ? '取消' : 'Cancel';
  String get createChannelFailed =>
      zh ? '创建域失败' : 'Could not create the domain';
  String get channelPermissionsPartial => zh
      ? '域已创建，但未能设置默认权限'
      : 'Domain created, but its default permissions could not be set';
  String get settings => zh ? '设置' : 'Settings';
  String get appearance => zh ? '外观' : 'Appearance';
  String get language => zh ? '语言' : 'Language';
  String get logOut => zh ? '退出登录' : 'Log out';
  String get logOutTitle => zh ? '退出登录？' : 'Log out?';
  String get logOutMessage => zh
      ? '再次使用这个账号需要重新登录。'
      : "You'll need to sign in again to use this account.";
  String get accent => zh ? '强调色' : 'Accent colour';
  String get accentDefault => zh ? '默认' : 'Default';
  String get search => zh ? '搜索' : 'Search';
  String get channelMenu => zh ? '域菜单' : 'Domain menu';
  String get invite => zh ? '邀请成员' : 'Invite people';
  String get newRoom => zh ? '创建频道' : 'Create channel';
  String get reorderRooms => zh ? '调整顺序' : 'Reorder rooms';
  String get channelSettings => zh ? '域设置' : 'Domain settings';
  String get joinVoice => zh ? '加入语音' : 'Join voice';
  String get disconnect => zh ? '离开' : 'Disconnect';
  String get unmute => zh ? '取消静音' : 'Unmute';
  String get mute => zh ? '静音' : 'Mute';
  String get undeafen => zh ? '恢复声音' : 'Undeafen';
  String get deafen => zh ? '关闭听音' : 'Deafen';
  String get stopCamera => zh ? '关闭摄像头' : 'Stop camera';
  String get camera => zh ? '摄像头' : 'Camera';
  String get stopShare => zh ? '停止共享' : 'Stop sharing';
  String get screenShare => zh ? '共享屏幕' : 'Screen share';
  String get voiceSettings => zh ? '语音设置' : 'Voice settings';
  String get showPassword => zh ? '显示密码' : 'Show';
  String get hidePassword => zh ? '隐藏密码' : 'Hide';
  String get generatePassword => zh ? '生成密码' : 'Generate password';
  String get connecting => zh ? '正在连接…' : 'Connecting…';
  String get reconnecting => zh ? '正在重连…' : 'Reconnecting…';
  String get connectionFailed => zh ? '连接失败' : 'Connection failed';
  String get voiceConnected => zh ? '语音已接通' : 'Voice connected';
  String get voice => zh ? '语音' : 'Voice';
  String get soundboard => zh ? '音效' : 'Soundboard';
  String get joinVoiceButton => zh ? '加入语音' : 'Join Voice';
  String get voiceChannel => zh ? '语音频道' : 'Voice channel';
  String get joiningMuted => zh ? '加入时静音' : 'Joining muted';
  String get micWillBeLive => zh ? '麦克风将开启' : 'Microphone will be live';
  String get cameraStartsOff => zh ? '摄像头默认关闭' : 'Camera starts off';
  String get screenShareAvailable => zh ? '可以共享屏幕' : 'Screen share available';
  String get joinVoiceHintCompact => zh
      ? '进入后即可开摄像头或共享屏幕。'
      : 'Turn your camera on or share a screen once you are in.';
  String get joinVoiceHint => zh
      ? '加入后即可静音、开摄像头、共享屏幕，并在通话旁聊天。离开前会一直保持连接。'
      : 'Joining connects you to the call. Once in, you can mute, turn '
            'your camera on, share a screen, and chat alongside the '
            'call — and you stay until you disconnect.';
  String get members => zh ? '成员' : 'Members';
  String get channels => zh ? '频道' : 'Channels';
  String get dropToAttach => zh ? '松开即可添加文件' : 'Drop files to attach';
  String get noMessagesYet => zh ? '还没有消息' : 'No messages yet';
  String get pinnedMessages => zh ? '置顶消息' : 'Pinned messages';
  String get emoji => zh ? '表情' : 'Emoji';
  String get delete => zh ? '删除' : 'Delete';
  String get closeChat => zh ? '关闭聊天' : 'Close chat';
  String get chat => zh ? '聊天' : 'Chat';
  String get notifications => zh ? '通知' : 'Notifications';
  String get sounds => zh ? '提示音' : 'Sounds';
  String get voiceAndVideo => zh ? '语音与视频' : 'Voice & Video';
  String get account => zh ? '账号' : 'Account';
  String get editProfile => zh ? '编辑资料' : 'Edit profile';
  String get editProfileHint =>
      zh ? '显示名称、简介、头像和横幅' : 'Display name, bio, avatar, and banner';
  String get passwordSecurity => zh ? '密码与安全' : 'Password & Security';
  String get passwordSecurityHint => zh
      ? '密码、两步验证、注销账号'
      : 'Password, two-factor authentication, delete account';
  String get appCategory => zh ? '应用' : 'App';
  String get systemCategory => zh ? '系统' : 'System';
  String get advancedCategory => zh ? '高级' : 'Advanced';

  String awayIn(String? channelName) => zh
      ? '暂时离开${channelName == null ? '' : ' · $channelName'}'
      : 'Away — ${channelName ?? 'Voice'}';

  String voiceOccupancy(int count) => switch (count) {
    0 => zh ? '还没有人，你是第一个。' : "No one is here yet — you'd be the first.",
    1 => zh ? '频道里有 1 人。' : '1 person is in this channel.',
    _ => zh ? '频道里有 $count 人。' : '$count people are in this channel.',
  };

  String voiceMoveNote(String? channelName) => zh
      ? (channelName == null
            ? '你正在另一个语音频道中，加入后将切换至此频道。'
            : '你正在 #$channelName 中，加入后将切换至此频道。')
      : (channelName == null
            ? "You're connected to another voice channel — joining moves you."
            : "You're connected to #$channelName — joining moves you.");

  String messageHint(String? channelName) => zh
      ? (channelName == null ? '说点什么' : '发送到 #$channelName')
      : (channelName == null ? 'Message' : 'Message #$channelName');

  String selectedCount(int count) => zh ? '已选 $count 条' : '$count selected';

  String settingsCategory(String name) => switch (name) {
    'account' => account,
    'app' => appCategory,
    'system' => systemCategory,
    'advanced' => advancedCategory,
    _ => name,
  };

  String themeName(String preset) {
    if (!zh) {
      return switch (preset) {
        'dark' => 'Dark',
        'midnight' => 'Midnight',
        'light' => 'Light',
        'nord' => 'Nord',
        'monokai' => 'Monokai',
        'solarized' => 'Solarized',
        _ => preset,
      };
    }
    return switch (preset) {
      'dark' => '深色',
      'midnight' => '午夜',
      'light' => '浅色',
      'nord' => '北欧',
      'monokai' => '莫诺凯',
      'solarized' => '日晒',
      _ => preset,
    };
  }
}
