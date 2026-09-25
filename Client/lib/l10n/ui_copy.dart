import 'package:flutter/widgets.dart';
import 'app_strings.dart';

/// Reviewed interface copy shared by the web and Windows clients.
abstract final class UiCopy {
  static String attachFiles({BuildContext? context, required String arg0}) =>
      AppStrings.choose(
        'Attach files ($arg0)',
        '添加附件（$arg0）',
        context: context,
      );
  static String serverAdministration({BuildContext? context}) =>
      AppStrings.choose('Server administration', '社区管理', context: context);
  static String youDoNotHaveAccessToThis({BuildContext? context}) =>
      AppStrings.choose(
        'You do not have access to this area.',
        '你没有权限访问此页面。',
        context: context,
      );
  static String spaces({BuildContext? context}) =>
      AppStrings.choose('Domains', '域', context: context);
  static String users({BuildContext? context}) =>
      AppStrings.choose('Users', '用户', context: context);
  static String reports({BuildContext? context}) =>
      AppStrings.choose('Reports', '举报', context: context);
  static String settings({BuildContext? context}) =>
      AppStrings.choose('Settings', '设置', context: context);
  static String automod({BuildContext? context}) =>
      AppStrings.choose('AutoMod', '自动审核', context: context);
  static String failedToResolve({BuildContext? context}) =>
      AppStrings.choose('Failed to resolve', '处理失败', context: context);
  static String kickMember({BuildContext? context}) =>
      AppStrings.choose('Kick member', '移出成员', context: context);
  static String kickTheReportedMemberAndActionThis({BuildContext? context}) =>
      AppStrings.choose(
        'Kick the reported member and action this report?',
        '将被举报成员移出域，并将此举报标记为已处理？',
        context: context,
      );
  static String kick({BuildContext? context}) =>
      AppStrings.choose('Kick', '移出', context: context);
  static String failedToKick({BuildContext? context}) =>
      AppStrings.choose('Failed to kick', '移出失败', context: context);
  static String theReportedMember({BuildContext? context}) =>
      AppStrings.choose('The reported member', '被举报成员', context: context);
  static String failedToBan({BuildContext? context}) =>
      AppStrings.choose('Failed to ban', '封禁失败', context: context);
  static String deleteMessage({BuildContext? context}) =>
      AppStrings.choose('Delete message', '删除消息', context: context);
  static String deleteTheReportedMessageAndActionThis({
    BuildContext? context,
  }) => AppStrings.choose(
    'Delete the reported message and action this report?',
    '删除被举报的消息，并将此举报标记为已处理？',
    context: context,
  );
  static String delete({BuildContext? context}) =>
      AppStrings.choose('Delete', '删除', context: context);
  static String failedToDeleteMessage({BuildContext? context}) =>
      AppStrings.choose('Failed to delete message', '删除消息失败', context: context);
  static String noReports({BuildContext? context}) =>
      AppStrings.choose('No reports', '暂无举报', context: context);
  static String refresh({BuildContext? context}) =>
      AppStrings.choose('Refresh', '刷新', context: context);
  static String failedToLoadSettings({BuildContext? context}) =>
      AppStrings.choose('Failed to load settings', '加载设置失败', context: context);
  static String uploadsPerMinuteMustBeAWhole({
    BuildContext? context,
    required Object? arg0,
    required Object? arg1,
  }) => AppStrings.choose(
    'Uploads per minute must be a whole number from ${arg0} to ${arg1}.',
    '每分钟上传次数须为 ${arg0} 至 ${arg1} 之间的整数。',
    context: context,
  );
  static String uploadMbPerMinuteMustBeMore({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    'Upload MB per minute must be more than 0 and at most ${arg0} MB (1 TiB).',
    '每分钟上传量须大于 0，且不超过 ${arg0} MB（1 TiB）。',
    context: context,
  );
  static String failedToSaveSettings({BuildContext? context}) =>
      AppStrings.choose('Failed to save settings', '保存设置失败', context: context);
  static String serverSettingsSaved({BuildContext? context}) =>
      AppStrings.choose('Server settings saved', '社区设置已保存', context: context);
  static String serverName({BuildContext? context}) =>
      AppStrings.choose('Community name', '社区名称', context: context);
  static String accordServer({BuildContext? context}) =>
      AppStrings.choose('Accord Server', 'Accord 服务器', context: context);
  static String registrationPolicy({BuildContext? context}) =>
      AppStrings.choose('Registration policy', '注册方式', context: context);
  static String open({BuildContext? context}) =>
      AppStrings.choose('Open', '打开', context: context);
  static String inviteOnly({BuildContext? context}) =>
      AppStrings.choose('Invite only', '仅限邀请', context: context);
  static String closed({BuildContext? context}) =>
      AppStrings.choose('Closed', '关闭注册', context: context);
  static String maxSpaces0({BuildContext? context}) => AppStrings.choose(
    'Max spaces (0 = ∞)',
    '域数量上限（0 表示不限）',
    context: context,
  );
  static String maxMembersSpace0({BuildContext? context}) => AppStrings.choose(
    'Max members/space (0 = ∞)',
    '每个域的成员上限（0 表示不限）',
    context: context,
  );
  static String uploadsPerUserPerMinute({
    BuildContext? context,
    required Object? arg0,
    required Object? arg1,
  }) => AppStrings.choose(
    'Uploads per user per minute (${arg0}–${arg1})',
    '每位用户每分钟上传次数（${arg0}–${arg1}）',
    context: context,
  );
  static String uploadMbPerUserPerMinute({BuildContext? context}) =>
      AppStrings.choose(
        'Upload MB per user per minute',
        '每位用户每分钟上传量（MB）',
        context: context,
      );
  static String perUserBudgetsForMessageSendsWith({
    BuildContext? context,
  }) => AppStrings.choose(
    'Per-user budgets for message sends with attachments, across all channels and DMs — moderators and admins included. Text messages don\'t count. Keep the MB budget at least as large as the biggest single upload you allow.',
    '限制每位用户在所有频道和私信中发送附件的总次数和总量，版主与管理员也受此限制。纯文字消息不计入。上传总量上限不应小于单个附件的大小上限。',
    context: context,
  );
  static String messageOfTheDay({BuildContext? context}) =>
      AppStrings.choose('Message of the day', '登录公告', context: context);
  static String shownToUsersOnLogin({BuildContext? context}) =>
      AppStrings.choose('Shown to users on login', '用户登录时显示', context: context);
  static String listOnPublicServerDirectory({BuildContext? context}) =>
      AppStrings.choose(
        'List on public server directory',
        '在公共服务器目录中展示',
        context: context,
      );
  static String termsOfService({BuildContext? context}) =>
      AppStrings.choose('Terms of Service', '服务条款', context: context);
  static String requireTosAcceptanceDuringRegistration({
    BuildContext? context,
  }) => AppStrings.choose(
    'Require ToS acceptance during registration',
    '注册时须同意服务条款',
    context: context,
  );
  static String currentVersion({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    'Current version: ${arg0}',
    '当前版本：${arg0}',
    context: context,
  );
  static String tosTextMarkdown({BuildContext? context}) => AppStrings.choose(
    'ToS text (markdown)',
    '服务条款正文（Markdown）',
    context: context,
  );
  static String enterTermsOfServiceText({BuildContext? context}) =>
      AppStrings.choose(
        'Enter Terms of Service text…',
        '请输入服务条款…',
        context: context,
      );
  static String tosExternalUrlOptional({BuildContext? context}) =>
      AppStrings.choose(
        'ToS external URL (optional)',
        '服务条款链接（可选）',
        context: context,
      );
  static String reset({BuildContext? context}) =>
      AppStrings.choose('Reset', '重置', context: context);
  static String saving({BuildContext? context}) =>
      AppStrings.choose('Saving…', '正在保存…', context: context);
  static String saveSettings({BuildContext? context}) =>
      AppStrings.choose('Save settings', '保存设置', context: context);
  static String failedToLoadSpaces({BuildContext? context}) =>
      AppStrings.choose('Failed to load spaces', '加载域失败', context: context);
  static String createSpace({BuildContext? context}) =>
      AppStrings.choose('Create domain', '创建域', context: context);
  static String spaceName({BuildContext? context}) =>
      AppStrings.choose('Domain name', '域名称', context: context);
  static String create({BuildContext? context}) =>
      AppStrings.choose('Create', '创建', context: context);
  static String failedToCreateSpace({BuildContext? context}) =>
      AppStrings.choose('Failed to create space', '创建域失败', context: context);
  static String spaceCreatedButItsDefaultMentionPermission({
    BuildContext? context,
  }) => AppStrings.choose(
    'Space created, but its default mention permission could not be secured',
    '域已创建，但未能设置默认的提及权限',
    context: context,
  );
  static String deleteSpace({BuildContext? context}) =>
      AppStrings.choose('Delete domain', '删除域', context: context);
  static String deleteThisCannotBeUndone({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    'Delete \'${arg0}\'? This cannot be undone.',
    '确定删除“${arg0}”？此操作无法撤销。',
    context: context,
  );
  static String failedToDeleteSpace({BuildContext? context}) =>
      AppStrings.choose('Failed to delete space', '删除域失败', context: context);
  static String transfer({BuildContext? context, required Object? arg0}) =>
      AppStrings.choose(
        'Transfer \'${arg0}\'',
        '转让“${arg0}”',
        context: context,
      );
  static String newOwnerUserId({BuildContext? context}) =>
      AppStrings.choose('New domain owner user ID', '新域主的用户 ID', context: context);
  static String copyAUserIdFromTheUsers({BuildContext? context}) =>
      AppStrings.choose(
        'Copy a user ID from the Users tab',
        '可在“用户”页面复制用户 ID',
        context: context,
      );
  static String transfer2({BuildContext? context}) =>
      AppStrings.choose('Transfer', '转让', context: context);
  static String failedToTransferOwnership({BuildContext? context}) =>
      AppStrings.choose(
        'Failed to transfer ownership',
        '转让域主身份失败',
        context: context,
      );
  static String noSpacesFound({BuildContext? context}) =>
      AppStrings.choose('No spaces found.', '未找到域。', context: context);
  static String filterByName({BuildContext? context}) =>
      AppStrings.choose('Filter by name', '按名称筛选', context: context);
  static String members({BuildContext? context, required Object? arg0}) =>
      AppStrings.choose('${arg0} members', '${arg0} 位成员', context: context);
  static String failedToLoadUsers({BuildContext? context}) =>
      AppStrings.choose('Failed to load users', '加载用户失败', context: context);
  static String failedToLoadMore({BuildContext? context}) =>
      AppStrings.choose('Failed to load more', '加载更多失败', context: context);
  static String failedToUpdateUser({BuildContext? context}) =>
      AppStrings.choose('Failed to update user', '更新用户失败', context: context);
  static String disableUser({BuildContext? context}) =>
      AppStrings.choose('Disable user', '停用用户', context: context);
  static String enableUser({BuildContext? context}) =>
      AppStrings.choose('Enable user', '启用用户', context: context);
  static String disableTheyWillBeUnableToLog({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    'Disable \'${arg0}\'? They will be unable to log in.',
    '确定停用“${arg0}”？停用后，该用户将无法登录。',
    context: context,
  );
  static String reEnableTheyWillBeAbleTo({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    'Re-enable \'${arg0}\'? They will be able to log in again.',
    '重新启用“${arg0}”？启用后，该用户即可恢复登录。',
    context: context,
  );
  static String disable({BuildContext? context}) =>
      AppStrings.choose('Disable', '停用', context: context);
  static String enable({BuildContext? context}) =>
      AppStrings.choose('Enable', '启用', context: context);
  static String failedToResetPassword({BuildContext? context}) =>
      AppStrings.choose('Failed to reset password', '重置密码失败', context: context);
  static String passwordResetFor({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    'Password reset for ${arg0}',
    '已重置 ${arg0} 的密码',
    context: context,
  );
  static String deleteUser({BuildContext? context}) =>
      AppStrings.choose('Delete user', '删除用户', context: context);

  static String failedToDeleteUser({BuildContext? context}) =>
      AppStrings.choose('Failed to delete user', '删除用户失败', context: context);
  static String noUsersFound({BuildContext? context}) =>
      AppStrings.choose('No users found.', '未找到用户。', context: context);
  static String searchByUsername({BuildContext? context}) =>
      AppStrings.choose('Search by username', '按用户名搜索', context: context);
  static String search({BuildContext? context}) =>
      AppStrings.choose('Search', '搜索', context: context);
  static String disabled({BuildContext? context}) =>
      AppStrings.choose('Disabled', '已停用', context: context);
  static String admin({BuildContext? context}) =>
      AppStrings.choose('Admin', '管理员', context: context);
  static String removeAdmin({BuildContext? context}) =>
      AppStrings.choose('Remove admin', '取消管理员权限', context: context);
  static String makeAdmin({BuildContext? context}) =>
      AppStrings.choose('Make admin', '设为管理员', context: context);
  static String enableAccount({BuildContext? context}) =>
      AppStrings.choose('Enable account', '启用账号', context: context);
  static String disableAccount({BuildContext? context}) =>
      AppStrings.choose('Disable account', '停用账号', context: context);
  static String resetPassword({BuildContext? context}) =>
      AppStrings.choose('Reset password', '重置密码', context: context);
  static String passwordMustBeAtLeast8Characters({BuildContext? context}) =>
      AppStrings.choose(
        'Password must be at least 8 characters',
        '密码至少需要 8 个字符',
        context: context,
      );
  static String passwordsDoNotMatch({BuildContext? context}) =>
      AppStrings.choose(
        'Passwords do not match',
        '两次输入的密码不一致',
        context: context,
      );
  static String resetPassword2({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    'Reset password — ${arg0}',
    '重置密码 · ${arg0}',
    context: context,
  );
  static String newPassword({BuildContext? context}) =>
      AppStrings.choose('New password', '新密码', context: context);
  static String confirmPassword({BuildContext? context}) =>
      AppStrings.choose('Confirm password', '确认密码', context: context);
  static String cancel({BuildContext? context}) =>
      AppStrings.choose('Cancel', '取消', context: context);
  static String connectionUnavailable({BuildContext? context}) =>
      AppStrings.choose('Connection unavailable', '连接不可用', context: context);
  static String passwordMustBeAtLeast8Characters2({BuildContext? context}) =>
      AppStrings.choose(
        'Password must be at least 8 characters.',
        '密码至少需要 8 个字符。',
        context: context,
      );
  static String youMustAcceptTheTermsOfService({BuildContext? context}) =>
      AppStrings.choose(
        'You must accept the Terms of Service.',
        '请先同意服务条款。',
        context: context,
      );
  static String usernameCanTBeAnEmailAddress({BuildContext? context}) =>
      AppStrings.choose(
        'Username can\'t be an email address.',
        '用户名不能使用邮箱地址。',
        context: context,
      );
  static String enterYourCurrentAndNewPassword({BuildContext? context}) =>
      AppStrings.choose(
        'Enter your current and new password.',
        '请输入当前密码和新密码。',
        context: context,
      );
  static String newPasswordMustBeAtLeast8({BuildContext? context}) =>
      AppStrings.choose(
        'New password must be at least 8 characters.',
        '新密码至少需要 8 个字符。',
        context: context,
      );
  static String passwordsDoNotMatch2({BuildContext? context}) =>
      AppStrings.choose(
        'Passwords do not match.',
        '两次输入的密码不一致。',
        context: context,
      );
  static String close({BuildContext? context}) =>
      AppStrings.choose('Close', '关闭', context: context);
  static String enterAValidServerUrl({BuildContext? context}) =>
      AppStrings.choose(
        'Enter a valid server URL',
        '请输入有效的服务器地址',
        context: context,
      );
  static String couldNotUseTheSavedAccount({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    'Could not use the saved account: ${arg0}',
    '无法使用已保存的账号：${arg0}',
    context: context,
  );
  static String couldNotJoin({BuildContext? context, required Object? arg0}) =>
      AppStrings.choose(
        'Could not join: ${arg0}',
        '加入失败：${arg0}',
        context: context,
      );
  static String reconnecting({BuildContext? context}) =>
      AppStrings.choose('Reconnecting…', '正在重新连接…', context: context);
  static String signingIn({BuildContext? context}) =>
      AppStrings.choose('Signing in…', '正在登录…', context: context);
  static String back({BuildContext? context}) =>
      AppStrings.choose('Back', '返回', context: context);
  static String discoverServers({BuildContext? context}) =>
      AppStrings.choose('Discover Servers', '发现服务器', context: context);
  static String twoFactorAuthentication({BuildContext? context}) =>
      AppStrings.choose('Two-factor authentication', '两步验证', context: context);
  static String enterTheCodeFromYourAuthenticatorApp({BuildContext? context}) =>
      AppStrings.choose(
        'Enter the code from your authenticator app',
        '请输入身份验证器中的验证码',
        context: context,
      );
  static String message6DigitCode({BuildContext? context}) =>
      AppStrings.choose('6-digit code', '6 位验证码', context: context);
  static String verify({BuildContext? context}) =>
      AppStrings.choose('Verify', '验证', context: context);
  static String serverUrl({BuildContext? context}) =>
      AppStrings.choose('Server URL', '服务器地址', context: context);
  static String iAgreeToThe({BuildContext? context}) =>
      AppStrings.choose('I agree to the ', '我同意', context: context);
  static String changeYourPassword({BuildContext? context}) =>
      AppStrings.choose('Change your password', '修改密码', context: context);
  static String theServerRequiresANewPasswordBefore({BuildContext? context}) =>
      AppStrings.choose(
        'The server requires a new password before you can continue',
        '此服务器要求你先设置新密码，才能继续使用',
        context: context,
      );
  static String currentPassword({BuildContext? context}) =>
      AppStrings.choose('Current password', '当前密码', context: context);
  static String confirmNewPassword({BuildContext? context}) =>
      AppStrings.choose('Confirm new password', '确认新密码', context: context);
  static String changePassword({BuildContext? context}) =>
      AppStrings.choose('Change Password', '修改密码', context: context);
  static String accounts({BuildContext? context}) =>
      AppStrings.choose('Accounts', '账号', context: context);
  static String noSavedAccountsYet({BuildContext? context}) =>
      AppStrings.choose(
        'No saved accounts yet.',
        '暂无已保存的账号。',
        context: context,
      );
  static String addAccount({BuildContext? context}) =>
      AppStrings.choose('Add account', '添加账号', context: context);
  static String remove({BuildContext? context}) =>
      AppStrings.choose('Remove', '移除', context: context);
  static String privacyPolicy({BuildContext? context}) =>
      AppStrings.choose('Privacy Policy', '隐私政策', context: context);
  static String agreeAndContinue({BuildContext? context}) =>
      AppStrings.choose('Agree and continue', '同意并继续', context: context);
  static String youMustAcceptTheseTermsToCreate({BuildContext? context}) =>
      AppStrings.choose(
        'You must accept these terms to create an account or sign in.',
        '创建账号或登录前，请先同意这些条款。',
        context: context,
      );
  static String byContinuingYouAgreeToThe({BuildContext? context}) =>
      AppStrings.choose(
        'By continuing you agree to the',
        '继续即表示你同意',
        context: context,
      );
  static String freeScreenSharingSmoothStableVoiceOn({
    BuildContext? context,
  }) => AppStrings.choose(
    'Free screen sharing. Smooth, stable voice — on infrastructure you control or trust.',
    '免费的屏幕共享，流畅稳定的语音。连接你自己掌控或信任的服务器。',
    context: context,
  );
  static String connectDirectlyToAServer({BuildContext? context}) =>
      AppStrings.choose(
        'Connect directly to a server',
        '直接连接服务器',
        context: context,
      );
  static String switchAccount({BuildContext? context}) =>
      AppStrings.choose('Switch account', '切换账号', context: context);
  static String browseServers({BuildContext? context}) =>
      AppStrings.choose('Browse Servers', '浏览服务器', context: context);
  static String runYourOwnServer({BuildContext? context}) =>
      AppStrings.choose('Run your own server', '搭建自己的服务器', context: context);
  static String keepEvidenceForBetween1And90({BuildContext? context}) =>
      AppStrings.choose(
        'Keep evidence for between 1 and 90 days.',
        '审核证据的保留时间须为 1 至 90 天。',
        context: context,
      );
  static String useAtMost32Rules({BuildContext? context}) => AppStrings.choose(
    'Use at most 32 rules.',
    '最多可设置 32 条规则。',
    context: context,
  );
  static String invalidRuleUpdateTheClientBeforeEditing({
    BuildContext? context,
  }) => AppStrings.choose(
    'Invalid rule. Update the client before editing.',
    '规则无效，请更新客户端后再编辑。',
    context: context,
  );
  static String eachRuleNeedsAUniqueNameOf({BuildContext? context}) =>
      AppStrings.choose(
        'Each rule needs a unique name of at most 64 bytes.',
        '每条规则须使用唯一名称，且不超过 64 字节。',
        context: context,
      );
  static String unsupportedChannelScope({BuildContext? context}) =>
      AppStrings.choose(
        'Unsupported channel scope.',
        '不支持此频道范围。',
        context: context,
      );
  static String thisPolicyUsesARuleTypeThis({
    BuildContext? context,
  }) => AppStrings.choose(
    'This policy uses a rule type this client cannot edit. Update the client first.',
    '此策略含有当前客户端无法编辑的规则类型，请先更新客户端。',
    context: context,
  );
  static String contentRulesNeedDetectorCategoriesAndA({
    BuildContext? context,
  }) => AppStrings.choose(
    'Content rules need detector categories and a threshold between 0 and 1.',
    '内容规则须指定检测类别，阈值须介于 0 和 1 之间。',
    context: context,
  );
  static String chooseBetween1And100ChannelsFor({BuildContext? context}) =>
      AppStrings.choose(
        'Choose between 1 and 100 channels for a channel-specific rule.',
        '针对指定频道的规则须选择 1 至 100 个频道。',
        context: context,
      );
  static String timeoutsRequireABlockedFileOrTrust({
    BuildContext? context,
  }) => AppStrings.choose(
    'Timeouts require a blocked-file or trust rule and a duration of 1–86400 seconds.',
    '禁言仅适用于文件屏蔽或信任规则，时长须为 1 至 86400 秒。',
    context: context,
  );
  static String connectToAServerFirst({BuildContext? context}) =>
      AppStrings.choose(
        'Connect to a server first.',
        '请先连接服务器。',
        context: context,
      );
  static String youDoNotHavePermissionToManage({BuildContext? context}) =>
      AppStrings.choose(
        'You do not have permission to manage AutoMod.',
        '你没有管理自动审核的权限。',
        context: context,
      );
  static String thisServerDoesNotSupportThisAutomod({
    BuildContext? context,
  }) => AppStrings.choose(
    'This server does not support this AutoMod operation. Update the server.',
    '此服务器不支持这项自动审核操作，请更新服务器。',
    context: context,
  );
  static String yourServerPermissionsDoNotAllowThis({BuildContext? context}) =>
      AppStrings.choose(
        'Your server permissions do not allow this operation.',
        '你没有执行此操作的服务器权限。',
        context: context,
      );
  static String reason({BuildContext? context}) =>
      AppStrings.choose('Reason', '原因', context: context);
  static String continueAction({BuildContext? context}) =>
      AppStrings.choose('Continue', '继续', context: context);
  static String enterAReasonOf12000Utf({BuildContext? context}) =>
      AppStrings.choose(
        'Enter a reason of 1–2000 UTF-8 bytes.',
        '请输入原因，长度为 1 至 2000 个 UTF-8 字节。',
        context: context,
      );
  static String blockFileDigest({BuildContext? context}) =>
      AppStrings.choose('Block file digest', '按文件指纹屏蔽', context: context);
  static String sha256Digest({BuildContext? context}) =>
      AppStrings.choose('SHA-256 digest', 'SHA-256 文件指纹', context: context);
  static String message64HexadecimalCharactersFromAKnownFile({
    BuildContext? context,
  }) => AppStrings.choose(
    '64 hexadecimal characters from a known file hash.',
    '请输入已知文件哈希值，由 64 个十六进制字符组成。',
    context: context,
  );
  static String enterAValid64CharacterSha256({BuildContext? context}) =>
      AppStrings.choose(
        'Enter a valid 64-character SHA-256 digest.',
        '请输入有效的 64 位 SHA-256 文件指纹。',
        context: context,
      );
  static String whyBlockThisFile({BuildContext? context}) =>
      AppStrings.choose('Why block this file?', '为什么屏蔽此文件？', context: context);
  static String thisEvidenceHasExpiredOrIsNo({BuildContext? context}) =>
      AppStrings.choose(
        'This evidence has expired or is no longer available.',
        '此审核证据已过期或不可用。',
        context: context,
      );
  static String noImagePreviewAvailableDownloadToReview({
    BuildContext? context,
  }) => AppStrings.choose(
    'No image preview available. Download to review.',
    '无法预览此图片，请下载后审核。',
    context: context,
  );
  static String downloadThisPrivateOriginalToReviewIt({
    BuildContext? context,
  }) => AppStrings.choose(
    'Download this private original to review it. Saved copies remain on your device.',
    '下载原始文件以进行审核。文件内容不公开，下载副本会保留在你的设备上。',
    context: context,
  );
  static String couldNotSaveTheEvidence({BuildContext? context}) =>
      AppStrings.choose(
        'Could not save the evidence.',
        '无法保存审核证据。',
        context: context,
      );
  static String downloadOriginal({BuildContext? context}) =>
      AppStrings.choose('Download original', '下载原文件', context: context);
  static String rules({BuildContext? context}) =>
      AppStrings.choose('Rules', '规则', context: context);
  static String review({BuildContext? context}) =>
      AppStrings.choose('Review', '待审核', context: context);
  static String blockedFiles({BuildContext? context}) =>
      AppStrings.choose('Blocked files', '已屏蔽文件', context: context);
  static String activity({BuildContext? context}) =>
      AppStrings.choose('Activity', '操作记录', context: context);
  static String refreshAutomod({BuildContext? context}) =>
      AppStrings.choose('Refresh AutoMod', '刷新自动审核', context: context);
  static String noPolicyLoaded({BuildContext? context}) =>
      AppStrings.choose('No policy loaded.', '尚未加载策略。', context: context);
  static String videoSampler({BuildContext? context, required Object? arg0}) =>
      AppStrings.choose(
        'Video sampler: ${arg0}',
        '视频采样器：${arg0}',
        context: context,
      );
  static String queueCapacityUploadsMib({
    BuildContext? context,
    required Object? arg0,
    required Object? arg1,
  }) => AppStrings.choose(
    'Queue capacity: ${arg0} uploads · ${arg1} MiB',
    '队列容量：${arg0} 个文件 · ${arg1} MiB',
    context: context,
  );
  static String askTheServerOperatorToInstallConfigure({
    BuildContext? context,
  }) => AppStrings.choose(
    'Ask the server operator to install/configure the local model and runtime. Enabling rules does not install them.',
    '请联系社区管理员安装并配置本地模型及运行环境。启用规则不会自动安装这些组件。',
    context: context,
  );
  static String usingTheServerPolicySavingCreatesA({BuildContext? context}) =>
      AppStrings.choose(
        'Using the server policy. Saving creates a complete space override.',
        '当前沿用服务器策略。保存后，本域将改用独立的完整策略。',
        context: context,
      );
  static String enableAutomaticScanning({BuildContext? context}) =>
      AppStrings.choose(
        'Enable automatic scanning',
        '启用自动扫描',
        context: context,
      );
  static String explicitFileBlocksAndUploadLimitsWork({
    BuildContext? context,
  }) => AppStrings.choose(
    'Explicit file blocks and upload limits work even when scanning is disabled.',
    '关闭扫描后，指定文件的屏蔽规则和上传限制仍然生效。',
    context: context,
  );
  static String keepHeldEvidenceDays190({BuildContext? context}) =>
      AppStrings.choose(
        'Keep held evidence (days, 1–90)',
        '审核证据保留天数（1–90）',
        context: context,
      );
  static String exemptRoles({BuildContext? context}) =>
      AppStrings.choose('Exempt roles', '豁免权限组', context: context);
  static String exemptPermissions({BuildContext? context}) =>
      AppStrings.choose('Exempt permissions', '豁免权限', context: context);
  static String rulesRunInOrderTheFirstMatch({BuildContext? context}) =>
      AppStrings.choose(
        'Rules run in order; the first match decides the action.',
        '规则按顺序执行，由首条匹配的规则决定处理方式。',
        context: context,
      );
  static String moveRuleUp({BuildContext? context}) =>
      AppStrings.choose('Move rule up', '上移规则', context: context);
  static String deleteRule({BuildContext? context}) =>
      AppStrings.choose('Delete rule', '删除规则', context: context);
  static String addRule({BuildContext? context}) =>
      AppStrings.choose('Add rule', '添加规则', context: context);
  static String savePolicy({BuildContext? context}) =>
      AppStrings.choose('Save policy', '保存策略', context: context);
  static String useServerPolicy({BuildContext? context}) =>
      AppStrings.choose('Use server policy?', '改用服务器策略？', context: context);
  static String thisRemovesThisSpaceSOverrideAnd({BuildContext? context}) =>
      AppStrings.choose(
        'This removes this space’s override and discards unsaved changes.',
        '这将移除本域的独立策略，并放弃尚未保存的更改。',
        context: context,
      );
  static String useServerPolicy2({BuildContext? context}) =>
      AppStrings.choose('Use server policy', '使用服务器策略', context: context);
  static String noUploadsWithThisStatus({BuildContext? context}) =>
      AppStrings.choose(
        'No uploads with this status.',
        '暂无此状态的上传文件。',
        context: context,
      );
  static String attachment({BuildContext? context}) =>
      AppStrings.choose('Attachment', '附件', context: context);
  static String viewEvidence({BuildContext? context}) =>
      AppStrings.choose('View evidence', '查看审核证据', context: context);
  static String loadOlderUploads({BuildContext? context}) =>
      AppStrings.choose('Load older uploads', '加载更早的上传记录', context: context);
  static String exactFileBlocksRemainActiveWithoutModel({
    BuildContext? context,
  }) => AppStrings.choose(
    'Exact file blocks remain active without model scanning. Modified or re-encoded copies have different hashes.',
    '即使未启用模型扫描，仍会屏蔽指纹相同的文件。经过修改或重新编码的文件具有不同的指纹。',
    context: context,
  );
  static String noBlockedFilesInThisScope({BuildContext? context}) =>
      AppStrings.choose(
        'No blocked files in this scope.',
        '当前范围内没有已屏蔽的文件。',
        context: context,
      );
  static String unblockFile({BuildContext? context}) =>
      AppStrings.choose('Unblock file', '解除文件屏蔽', context: context);
  static String unblockFile2({BuildContext? context}) =>
      AppStrings.choose('Unblock file?', '解除文件屏蔽？', context: context);
  static String identicalCopiesWillBeAllowedUnlessAnother({
    BuildContext? context,
  }) => AppStrings.choose(
    'Identical copies will be allowed unless another rule or instance block applies.',
    '解除后将允许上传相同文件，但其他规则或服务器级屏蔽仍可能限制上传。',
    context: context,
  );
  static String unblock({BuildContext? context}) =>
      AppStrings.choose('Unblock', '解除屏蔽', context: context);
  static String loadOlderBlocks({BuildContext? context}) =>
      AppStrings.choose('Load older blocks', '加载更早的屏蔽记录', context: context);
  static String noModerationActivity({BuildContext? context}) =>
      AppStrings.choose('No moderation activity.', '暂无审核记录。', context: context);
  static String loadOlderActivity({BuildContext? context}) =>
      AppStrings.choose('Load older activity', '加载更早的操作记录', context: context);
  static String updateRequired({BuildContext? context}) =>
      AppStrings.choose('Update required', '需要更新', context: context);
  static String thisRuleUsesOptionsThisClientCannot({BuildContext? context}) =>
      AppStrings.choose(
        'This rule uses options this client cannot edit.',
        '此规则使用了当前客户端无法编辑的选项。',
        context: context,
      );
  static String editRule({BuildContext? context}) =>
      AppStrings.choose('Edit rule', '编辑规则', context: context);
  static String ruleName({BuildContext? context}) =>
      AppStrings.choose('Rule name', '规则名称', context: context);
  static String enterAName({BuildContext? context}) =>
      AppStrings.choose('Enter a name.', '请输入名称。', context: context);
  static String when({BuildContext? context}) =>
      AppStrings.choose('When', '触发条件', context: context);
  static String detectorCategories({BuildContext? context}) =>
      AppStrings.choose('Detector categories', '检测类别', context: context);
  static String commaSeparatedCategoryNamesSupportedByThe({
    BuildContext? context,
  }) => AppStrings.choose(
    'Comma-separated category names supported by the server detector.',
    '填写服务器检测器支持的类别名称，以英文逗号分隔。',
    context: context,
  );
  static String threshold01({BuildContext? context}) =>
      AppStrings.choose('Threshold (0–1)', '阈值（0–1）', context: context);
  static String videosSampleFiveFramesAt1030({
    BuildContext? context,
  }) => AppStrings.choose(
    'Videos sample five frames at 10%, 30%, 50%, 70% and 90%. Content between samples can be missed.',
    '视频会在进度 10%、30%、50%、70% 和 90% 处各抽取一帧，采样帧之间的内容可能无法检出。',
    context: context,
  );
  static String minimumAccountAgeHours({BuildContext? context}) =>
      AppStrings.choose(
        'Minimum account age (hours)',
        '账号注册时长下限（小时）',
        context: context,
      );
  static String minimumMembershipAgeHours({BuildContext? context}) =>
      AppStrings.choose(
        'Minimum membership age (hours)',
        '加入域时长下限（小时）',
        context: context,
      );
  static String requireAnAssignedRole({BuildContext? context}) =>
      AppStrings.choose('Require an assigned role', '须已分配权限组', context: context);
  static String channels({BuildContext? context}) =>
      AppStrings.choose('Channels', '频道', context: context);
  static String allChannels({BuildContext? context}) =>
      AppStrings.choose('All channels', '所有频道', context: context);
  static String outsideNsfwChannels({BuildContext? context}) =>
      AppStrings.choose('Outside NSFW channels', '年龄限制频道之外', context: context);
  static String selectedChannels({BuildContext? context}) =>
      AppStrings.choose('Selected channels', '指定频道', context: context);
  static String openASpaceToLoadItsChannels({
    BuildContext? context,
  }) => AppStrings.choose(
    'Open a space to load its channels before adding a channel-specific rule.',
    '请先打开域并加载频道，再添加针对指定频道的规则。',
    context: context,
  );
  static String action({BuildContext? context}) =>
      AppStrings.choose('Action', '操作', context: context);
  static String useRule({BuildContext? context}) =>
      AppStrings.choose('Use rule', '使用此规则', context: context);
  static String accountChangedTheOperationStopped({BuildContext? context}) =>
      AppStrings.choose(
        'Account changed; the operation stopped.',
        '账号已切换，操作已停止。',
        context: context,
      );
  static String selectAtLeastOneAttachment({BuildContext? context}) =>
      AppStrings.choose(
        'Select at least one attachment.',
        '请至少选择一个附件。',
        context: context,
      );
  static String filesAreBlockedAccountChangedBeforeMessage({
    BuildContext? context,
  }) => AppStrings.choose(
    'Files are blocked. Account changed before message deletion.',
    '文件已屏蔽，但删除消息前账号发生了切换。',
    context: context,
  );
  static String filesAreBlockedButTheMessageCould({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    'Files are blocked, but the message could not be deleted. ${arg0}',
    '文件已屏蔽，但无法删除消息。${arg0}',
    context: context,
  );
  static String selectAFileAndEnterAReason({BuildContext? context}) =>
      AppStrings.choose(
        'Select a file and enter a reason (1–2000 characters).',
        '请选择文件并填写原因（1–2000 个字符）。',
        context: context,
      );
  static String blockFilesAndDeleteMessage({BuildContext? context}) =>
      AppStrings.choose(
        'Block files and delete message',
        '屏蔽文件并删除消息',
        context: context,
      );
  static String blockIdenticalReUploadsBeforeDeletingThis({
    BuildContext? context,
  }) => AppStrings.choose(
    'Block identical re-uploads before deleting this message. Modified copies may have different hashes.',
    '先屏蔽相同文件的再次上传，再删除此消息。修改后的文件可能具有不同的指纹。',
    context: context,
  );
  static String thisSpace({BuildContext? context}) =>
      AppStrings.choose('This space', '本域', context: context);
  static String entireServerIncludingDms({BuildContext? context}) =>
      AppStrings.choose(
        'Entire server, including DMs',
        '整个服务器，包括私信',
        context: context,
      );
  static String blockAndDelete({BuildContext? context}) =>
      AppStrings.choose('Block and delete', '屏蔽并删除', context: context);
  static String message({BuildContext? context}) =>
      AppStrings.choose('Message', '消息', context: context);
  static String failedToUnmuteChannel({BuildContext? context}) =>
      AppStrings.choose(
        'Failed to unmute channel',
        '取消频道静音失败',
        context: context,
      );
  static String failedToMuteChannel({BuildContext? context}) =>
      AppStrings.choose(
        'Failed to mute channel',
        '将频道设为静音失败',
        context: context,
      );
  static String markAsRead({BuildContext? context}) =>
      AppStrings.choose('Mark as read', '标为已读', context: context);
  static String unmuteChannel({BuildContext? context}) =>
      AppStrings.choose('Unmute channel', '取消频道静音', context: context);
  static String muteChannel({BuildContext? context}) =>
      AppStrings.choose('Mute channel', '频道静音', context: context);
  static String editChannel({BuildContext? context}) =>
      AppStrings.choose('Edit channel', '编辑频道', context: context);
  static String deleteChannel({BuildContext? context}) =>
      AppStrings.choose('Delete channel', '删除频道', context: context);
  static String expandCategory({BuildContext? context}) =>
      AppStrings.choose('Expand group', '展开分组', context: context);
  static String collapseCategory({BuildContext? context}) =>
      AppStrings.choose('Collapse group', '折叠分组', context: context);
  static String createChannelHere({BuildContext? context}) =>
      AppStrings.choose('Create channel here', '在此创建频道', context: context);
  static String editCategory({BuildContext? context}) =>
      AppStrings.choose('Edit group', '编辑分组', context: context);
  static String deleteCategory({BuildContext? context}) =>
      AppStrings.choose('Delete group', '删除分组', context: context);
  static String delete2({BuildContext? context, required Object? arg0}) =>
      AppStrings.choose('Delete ${arg0}', '删除${arg0}', context: context);
  static String deleteThisCannotBeUndone3({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    'Delete "${arg0}"? This cannot be undone.',
    '确定删除“${arg0}”？此操作无法撤销。',
    context: context,
  );
  static String failedToDelete({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    'Failed to delete ${arg0}',
    '删除${arg0}失败',
    context: context,
  );
  static String nameIsRequired({BuildContext? context}) =>
      AppStrings.choose('Name is required', '请填写名称', context: context);
  static String failedToSaveChannel({BuildContext? context}) =>
      AppStrings.choose('Failed to save channel', '保存频道失败', context: context);
  static String failedToCreateChannel({BuildContext? context}) =>
      AppStrings.choose('Failed to create channel', '创建频道失败', context: context);
  static String failedToDeleteChannel({BuildContext? context}) =>
      AppStrings.choose('Failed to delete channel', '删除频道失败', context: context);
  static String createChannel({BuildContext? context}) =>
      AppStrings.choose('Create channel', '创建频道', context: context);
  static String name({BuildContext? context}) =>
      AppStrings.choose('Name', '名称', context: context);
  static String type({BuildContext? context}) =>
      AppStrings.choose('Type', '类型', context: context);
  static String category({BuildContext? context}) =>
      AppStrings.choose('Group', '分组', context: context);
  static String none({BuildContext? context}) =>
      AppStrings.choose('None', '无', context: context);
  static String topicOptional({BuildContext? context}) =>
      AppStrings.choose('Topic (optional)', '主题（可选）', context: context);
  static String usersMustConfirmBeforeViewing({BuildContext? context}) =>
      AppStrings.choose(
        'Users must confirm before viewing',
        '用户须确认后才能查看',
        context: context,
      );
  static String slowmode({BuildContext? context}) =>
      AppStrings.choose('Slowmode', '慢速模式', context: context);
  static String oneMessagePerUserPerIntervalModerators({
    BuildContext? context,
  }) => AppStrings.choose(
    'One message per user per interval; moderators are exempt',
    '每位用户在指定时间间隔内只能发送一条消息，版主不受此限制',
    context: context,
  );
  static String permissions({BuildContext? context}) =>
      AppStrings.choose('Permissions', '权限', context: context);
  static String save({BuildContext? context}) =>
      AppStrings.choose('Save', '保存', context: context);
  static String searchMembers({BuildContext? context}) =>
      AppStrings.choose('Search members', '搜索成员', context: context);
  static String noMembers({BuildContext? context}) =>
      AppStrings.choose('No members', '暂无成员', context: context);
  static String failedToUpdatePermissions({BuildContext? context}) =>
      AppStrings.choose(
        'Failed to update permissions',
        '更新权限失败',
        context: context,
      );
  static String unsavedChanges({BuildContext? context}) =>
      AppStrings.choose('Unsaved Changes', '尚未保存的更改', context: context);
  static String youHaveUnsavedPermissionChangesDiscardThem({
    BuildContext? context,
  }) => AppStrings.choose(
    'You have unsaved permission changes. Discard them?',
    '权限更改尚未保存，确定放弃？',
    context: context,
  );
  static String discard({BuildContext? context}) =>
      AppStrings.choose('Discard', '放弃更改', context: context);
  static String permissions2({BuildContext? context, required Object? arg0}) =>
      AppStrings.choose(
        'Permissions: #${arg0}',
        '权限：#${arg0}',
        context: context,
      );
  static String selectARoleOrMember({BuildContext? context}) =>
      AppStrings.choose('Select a role or member', '选择权限组或成员', context: context);
  static String members2({BuildContext? context}) =>
      AppStrings.choose('MEMBERS', '成员', context: context);
  static String addMember({BuildContext? context}) =>
      AppStrings.choose('+ Add Member', '+ 添加成员', context: context);
  static String developer({BuildContext? context}) =>
      AppStrings.choose('Developer', '开发者', context: context);
  static String clientMcpServer({BuildContext? context}) =>
      AppStrings.choose('Client MCP server', '客户端 MCP 服务', context: context);
  static String exposesALocalModelContextProtocolServer({
    BuildContext? context,
  }) => AppStrings.choose(
    'Exposes a local Model Context Protocol server on 127.0.0.1 so AI agents on this machine can read state and drive the app. Bound to loopback only and protected by a bearer token that never leaves this device.',
    '在 127.0.0.1 上提供本地 MCP 服务，供本机 AI 助手读取状态并操作应用。仅监听本机回环地址，并使用仅保存在此设备上的访问令牌进行保护。',
    context: context,
  );
  static String enableMcpServer({BuildContext? context}) =>
      AppStrings.choose('Enable MCP server', '启用 MCP 服务', context: context);
  static String listeningOn127001({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    'Listening on 127.0.0.1:${arg0}',
    '正在监听 127.0.0.1:${arg0}',
    context: context,
  );
  static String stopped({BuildContext? context}) =>
      AppStrings.choose('Stopped', '已停止', context: context);
  static String exposedToolGroups({BuildContext? context}) =>
      AppStrings.choose('Exposed tool groups', '开放的工具组', context: context);
  static String recentActivity({BuildContext? context}) =>
      AppStrings.choose('Recent activity', '最近活动', context: context);
  static String clear({BuildContext? context}) =>
      AppStrings.choose('Clear', '清空', context: context);
  static String noToolCallsYet({BuildContext? context}) =>
      AppStrings.choose('No tool calls yet.', '暂无工具调用。', context: context);
  static String port({BuildContext? context}) =>
      AppStrings.choose('Port', '端口', context: context);
  static String bearerToken({BuildContext? context}) =>
      AppStrings.choose('Bearer token', '访问令牌', context: context);
  static String copy({BuildContext? context}) =>
      AppStrings.choose('Copy', '复制', context: context);
  static String tokenCopied({BuildContext? context}) =>
      AppStrings.choose('Token copied', '令牌已复制', context: context);
  static String regenerate({BuildContext? context}) =>
      AppStrings.choose('Regenerate', '重新生成', context: context);
  static String mentionEveryoneHereAndAllRoles({BuildContext? context}) =>
      AppStrings.choose(
        'Mention @everyone, @here, and all roles',
        '提及 @everyone、@here 及所有权限组',
        context: context,
      );
  static String couldnTLoadMembers({BuildContext? context}) =>
      AppStrings.choose('Couldn\'t load members', '无法加载成员', context: context);
  static String somethingWentWrongFetchingTheMemberList({
    BuildContext? context,
  }) => AppStrings.choose(
    'Something went wrong fetching the member list.',
    '获取成员列表时出错，请重试。',
    context: context,
  );
  static String members3({BuildContext? context}) =>
      AppStrings.choose('Members', '成员', context: context);
  static String offline({BuildContext? context}) =>
      AppStrings.choose('Offline', '离线', context: context);
  static String viewProfile({BuildContext? context}) =>
      AppStrings.choose('View Profile', '查看资料', context: context);
  static String directMessage({BuildContext? context}) =>
      AppStrings.choose('Direct Message', '发送私信', context: context);
  static String copyUserId({BuildContext? context}) =>
      AppStrings.choose('Copy User ID', '复制用户 ID', context: context);
  static String copyUsername({BuildContext? context}) =>
      AppStrings.choose('Copy Username', '复制用户名', context: context);
  static String userIdCopied({BuildContext? context}) =>
      AppStrings.choose('User ID copied', '用户 ID 已复制', context: context);
  static String usernameCopied({BuildContext? context}) =>
      AppStrings.choose('Username copied', '用户名已复制', context: context);
  static String failedToKickMember({BuildContext? context}) =>
      AppStrings.choose('Failed to kick member', '移出成员失败', context: context);
  static String blockUser({BuildContext? context}) =>
      AppStrings.choose('Block user', '屏蔽用户', context: context);
  static String blockedUsersCanTDmYouAnd({BuildContext? context}) =>
      AppStrings.choose(
        'Blocked users can\'t DM you and their messages are hidden. Continue?',
        '屏蔽后，对方将无法给你发送私信，其消息也会被隐藏。确定继续？',
        context: context,
      );
  static String block({BuildContext? context}) =>
      AppStrings.choose('Block', '屏蔽', context: context);
  static String failedToBlockUser({BuildContext? context}) =>
      AppStrings.choose('Failed to block user', '屏蔽用户失败', context: context);
  static String failedToBanMember({BuildContext? context}) =>
      AppStrings.choose('Failed to ban member', '封禁成员失败', context: context);
  static String bannedAndDeleted1Message({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    'Banned ${arg0} and deleted 1 message',
    '已封禁 ${arg0}，并删除 1 条消息',
    context: context,
  );
  static String bannedAndDeletedMessages({
    BuildContext? context,
    required Object? arg0,
    required Object? arg1,
  }) => AppStrings.choose(
    'Banned ${arg0} and deleted ${arg1} messages',
    '已封禁 ${arg0}，并删除 ${arg1} 条消息',
    context: context,
  );
  static String failedToTimeOutMember({BuildContext? context}) =>
      AppStrings.choose(
        'Failed to time out member',
        '禁言成员失败',
        context: context,
      );
  static String failedToRemoveTimeout({BuildContext? context}) =>
      AppStrings.choose('Failed to remove timeout', '解除禁言失败', context: context);
  static String changeNickname({BuildContext? context}) =>
      AppStrings.choose('Change nickname', '修改昵称', context: context);
  static String nickname({BuildContext? context}) =>
      AppStrings.choose('Nickname', '昵称', context: context);
  static String leaveEmptyToResetToTheirDisplay({BuildContext? context}) =>
      AppStrings.choose(
        'Leave empty to reset to their display name',
        '留空即可恢复为对方的显示名称',
        context: context,
      );
  static String failedToUpdateNickname({BuildContext? context}) =>
      AppStrings.choose(
        'Failed to update nickname',
        '更新昵称失败',
        context: context,
      );
  static String failedToUpdateRoles({BuildContext? context}) =>
      AppStrings.choose('Failed to update roles', '更新权限组失败', context: context);
  static String timedOutUntil({BuildContext? context, required Object? arg0}) =>
      AppStrings.choose(
        'Timed out until ${arg0}',
        '禁言至 ${arg0}',
        context: context,
      );
  static String setNickname({BuildContext? context}) =>
      AppStrings.choose('Set nickname', '设置昵称', context: context);
  static String editNickname({BuildContext? context}) =>
      AppStrings.choose('Edit nickname', '编辑昵称', context: context);
  static String reportUser({BuildContext? context}) =>
      AppStrings.choose('Report user', '举报用户', context: context);
  static String online({BuildContext? context}) =>
      AppStrings.choose('Online', '在线', context: context);
  static String idle({BuildContext? context}) =>
      AppStrings.choose('Idle', '暂离', context: context);
  static String doNotDisturb({BuildContext? context}) =>
      AppStrings.choose('Do Not Disturb', '请勿打扰', context: context);
  static String memberSince({BuildContext? context, required Object? arg0}) =>
      AppStrings.choose(
        'Member since ${arg0}',
        '加入时间：${arg0}',
        context: context,
      );
  static String roles({BuildContext? context}) =>
      AppStrings.choose('ROLES', '权限组', context: context);
  static String assignRoles({BuildContext? context}) =>
      AppStrings.choose('DOMAIN PERMISSIONS', '域内权限分配', context: context);
  static String timeOut({BuildContext? context}) =>
      AppStrings.choose('Time out', '禁言', context: context);
  static String timeOut2({BuildContext? context}) =>
      AppStrings.choose('Time out…', '禁言…', context: context);
  static String removeTimeout({BuildContext? context}) =>
      AppStrings.choose('Remove timeout', '解除禁言', context: context);
  static String banMember({BuildContext? context}) =>
      AppStrings.choose('Ban member', '封禁成员', context: context);
  static String homedOn({BuildContext? context, required Object? arg0}) =>
      AppStrings.choose('Homed on ${arg0}', '所属服务器：${arg0}', context: context);
  static String bytes({BuildContext? context, required Object? arg0}) =>
      AppStrings.choose('${arg0} bytes', '${arg0} 字节', context: context);
  static String couldnTBeReadCopyItTo({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    '${arg0} couldn\'t be read. Copy it to local storage and try again.',
    '无法读取 ${arg0}。请将文件复制到本地存储后重试。',
    context: context,
  );
  static String isTheLimitIs({
    BuildContext? context,
    required Object? arg0,
    required Object? arg1,
    required Object? arg2,
  }) => AppStrings.choose(
    '${arg0} is ${arg1} — the limit is ${arg2}.',
    '${arg0} 的大小为 ${arg1}，超过了 ${arg2} 的上限。',
    context: context,
  );
  static String wasnTAttachedYouCanSendAt({
    BuildContext? context,
    required Object? arg0,
    required Object? arg1,
    required Object? arg2,
  }) => AppStrings.choose(
    '${arg0} wasn\'t attached — you can send at most ${arg1} ${arg2} per message.',
    '未添加 ${arg0}：每条消息最多可附带 ${arg1} 个文件。',
    context: context,
  );
  static String upToEachPerMessage({
    BuildContext? context,
    required Object? arg0,
    required Object? arg1,
  }) => AppStrings.choose(
    'up to ${arg0} each, ${arg1} per message',
    '每个文件不超过 ${arg0}，每条消息最多 ${arg1} 个',
    context: context,
  );
  static String uploadsAreLimitedToPerMinute({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    'Uploads are limited to ${arg0} per minute.',
    '每分钟上传限制：${arg0}。',
    context: context,
  );
  static String searchEmoji({BuildContext? context}) =>
      AppStrings.choose('Search emoji', '搜索表情', context: context);
  static String noEmojiMatch({BuildContext? context, required Object? arg0}) =>
      AppStrings.choose(
        'No emoji match "${arg0}"',
        '没有与“${arg0}”匹配的表情',
        context: context,
      );
  static String noRecentEmojiYet({BuildContext? context}) =>
      AppStrings.choose('No recent emoji yet', '还没有最近使用的表情', context: context);
  static String thisSpaceHasNoCustomEmoji({BuildContext? context}) =>
      AppStrings.choose(
        'This space has no custom emoji',
        '此域暂无自定义表情',
        context: context,
      );
  static String recent({BuildContext? context}) =>
      AppStrings.choose('Recent', '最近使用', context: context);
  static String custom({BuildContext? context}) =>
      AppStrings.choose('Custom', '自定义', context: context);
  static String latestActivity({BuildContext? context}) =>
      AppStrings.choose('Latest activity', '最近活跃', context: context);
  static String newest({BuildContext? context}) =>
      AppStrings.choose('Newest', '最新发布', context: context);
  static String mostReplies({BuildContext? context}) =>
      AppStrings.choose('Most replies', '回复最多', context: context);
  static String newPost({BuildContext? context}) =>
      AppStrings.choose('New post', '发布帖子', context: context);
  static String post({BuildContext? context}) =>
      AppStrings.choose('Post', '帖子', context: context);
  static String failedToCreatePost({BuildContext? context}) =>
      AppStrings.choose('Failed to create post', '发布帖子失败', context: context);
  static String edit({BuildContext? context}) =>
      AppStrings.choose('Edit', '编辑', context: context);
  static String unpin({BuildContext? context}) =>
      AppStrings.choose('Unpin', '取消置顶', context: context);
  static String pin({BuildContext? context}) =>
      AppStrings.choose('Pin', '置顶', context: context);
  static String noPostsYet({BuildContext? context}) =>
      AppStrings.choose('No posts yet', '暂无帖子', context: context);
  static String sortPosts({BuildContext? context}) =>
      AppStrings.choose('Sort posts', '帖子排序', context: context);
  static String postActions({BuildContext? context}) =>
      AppStrings.choose('Post actions', '帖子操作', context: context);
  static String untitledPost({BuildContext? context}) =>
      AppStrings.choose('Untitled post', '无标题帖子', context: context);
  static String lastReply({BuildContext? context, required Object? arg0}) =>
      AppStrings.choose('last reply ${arg0}', '最后回复：${arg0}', context: context);
  static String openInBrowser({BuildContext? context}) =>
      AppStrings.choose('Open in browser', '在浏览器中打开', context: context);
  static String savedTo({BuildContext? context, required Object? arg0}) =>
      AppStrings.choose('Saved to ${arg0}', '已保存到 ${arg0}', context: context);
  static String showInFolder({BuildContext? context}) =>
      AppStrings.choose('Show in folder', '在文件夹中显示', context: context);
  static String yourDownloads({BuildContext? context}) =>
      AppStrings.choose('your downloads', '下载目录', context: context);
  static String download({BuildContext? context}) =>
      AppStrings.choose('Download', '下载', context: context);
  static String copyText({BuildContext? context}) =>
      AppStrings.choose('Copy text', '复制文字', context: context);
  static String loadExternalImageFrom({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    'Load external image from ${arg0}',
    '加载来自 ${arg0} 的外部图片',
    context: context,
  );
  static String attachmentUnderReview({BuildContext? context}) =>
      AppStrings.choose('Attachment under review', '附件正在审核', context: context);
  static String attachmentRemovedByAutomod({BuildContext? context}) =>
      AppStrings.choose(
        'Attachment removed by AutoMod',
        '附件已被自动审核移除',
        context: context,
      );
  static String attachmentProcessing({BuildContext? context}) =>
      AppStrings.choose('Attachment processing', '附件正在处理', context: context);
  static String beingCheckedByAutomodBeforeItIs({BuildContext? context}) =>
      AppStrings.choose(
        'Being checked by AutoMod before it is shown to others.',
        '自动审核完成后，其他成员才能看到此附件。',
        context: context,
      );
  static String n({
    BuildContext? context,
    required Object? arg0,
    required Object? arg1,
    required Object? arg2,
  }) => AppStrings.choose(
    '${arg0}\n${arg1} · ${arg2}',
    '${arg0}\n${arg1} · ${arg2}',
    context: context,
  );
  static String beginningOfChannel({BuildContext? context}) =>
      AppStrings.choose('Beginning of channel', '频道消息从这里开始', context: context);
  static String pasteLargeText({BuildContext? context}) =>
      AppStrings.choose('Paste large text', '粘贴长文本', context: context);
  static String thatSALotOfTextCharacters({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    'That\'s a lot of text (${arg0} characters). Attach it as a .txt file instead of pasting inline?',
    '这段文字较长（${arg0} 个字符），是否改为以 .txt 文件发送？',
    context: context,
  );
  static String pasteInline({BuildContext? context}) =>
      AppStrings.choose('Paste inline', '直接粘贴', context: context);
  static String attachAsFile({BuildContext? context}) =>
      AppStrings.choose('Attach as file', '作为文件添加', context: context);
  static String couldnTOpenTheFilePicker({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    'Couldn\'t open the file picker: ${arg0}',
    '无法打开文件选择器：${arg0}',
    context: context,
  );
  static String isAFolderDropTheFilesInside({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    '${arg0} is a folder — drop the files inside it instead.',
    '${arg0} 是文件夹，请改为拖入其中的文件。',
    context: context,
  );
  static String failedToSend({BuildContext? context, required Object? arg0}) =>
      AppStrings.choose(
        'Failed to send: ${arg0}',
        '发送失败：${arg0}',
        context: context,
      );
  static String replyingTo({BuildContext? context, required Object? arg0}) =>
      AppStrings.choose(
        'Replying to ${arg0}',
        '正在回复 ${arg0}',
        context: context,
      );
  static String cancelReply({BuildContext? context}) =>
      AppStrings.choose('Cancel reply', '取消回复', context: context);
  static String dismiss({BuildContext? context}) =>
      AppStrings.choose('Dismiss', '忽略', context: context);
  static String youDonTHavePermissionToMention({
    BuildContext? context,
  }) => AppStrings.choose(
    'You don\'t have permission to mention @everyone or @here in this channel.',
    '你没有在此频道提及 @everyone 或 @here 的权限。',
    context: context,
  );
  static String attachmentLimitReachedPerMessage({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    'Attachment limit reached (${arg0} per message)',
    '附件数量已达上限（每条消息最多 ${arg0} 个）',
    context: context,
  );
  static String send({BuildContext? context}) =>
      AppStrings.choose('Send', '发送', context: context);
  static String notifyEveryone({BuildContext? context}) =>
      AppStrings.choose('Notify everyone', '通知所有成员', context: context);
  static String notifyOnlineMembers({BuildContext? context}) =>
      AppStrings.choose('Notify online members', '通知在线成员', context: context);
  static String deleteMessages({BuildContext? context}) =>
      AppStrings.choose('Delete messages', '删除消息', context: context);
  static String deleteMessageSThisCannotBeUndone({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    'Delete ${arg0} message(s)? This cannot be undone.',
    '确定删除 ${arg0} 条消息？此操作无法撤销。',
    context: context,
  );
  static String couldnTLoadMessages({BuildContext? context}) =>
      AppStrings.choose('Couldn\'t load messages', '无法加载消息', context: context);
  static String somethingWentWrongFetchingThisChannelS({
    BuildContext? context,
  }) => AppStrings.choose(
    'Something went wrong fetching this channel’s history.',
    '获取此频道的历史消息时出错，请重试。',
    context: context,
  );
  static String selectAChannel({BuildContext? context}) =>
      AppStrings.choose('Select a channel', '选择频道', context: context);
  static String someone({BuildContext? context}) =>
      AppStrings.choose('Someone', '有人', context: context);
  static String isTyping({BuildContext? context, required Object? arg0}) =>
      AppStrings.choose(
        '${arg0} is typing…',
        '${arg0} 正在输入…',
        context: context,
      );
  static String andAreTyping({
    BuildContext? context,
    required Object? arg0,
    required Object? arg1,
  }) => AppStrings.choose(
    '${arg0} and ${arg1} are typing…',
    '${arg0} 和 ${arg1} 正在输入…',
    context: context,
  );
  static String severalPeopleAreTyping({BuildContext? context}) =>
      AppStrings.choose(
        'Several people are typing…',
        '多人正在输入…',
        context: context,
      );
  static String unknown({BuildContext? context}) =>
      AppStrings.choose('Unknown', '未知', context: context);
  static String thisMessageWillBePermanentlyDeleted({BuildContext? context}) =>
      AppStrings.choose(
        'This message will be permanently deleted.',
        '此消息将被永久删除。',
        context: context,
      );
  static String addReaction({BuildContext? context}) =>
      AppStrings.choose('Add reaction', '添加表情回应', context: context);
  static String reply({BuildContext? context}) =>
      AppStrings.choose('Reply', '回复', context: context);
  static String thread({BuildContext? context}) =>
      AppStrings.choose('Thread', '话题', context: context);
  static String blockFilesAndDelete({BuildContext? context}) =>
      AppStrings.choose('Block files and delete', '屏蔽文件并删除', context: context);
  static String report({BuildContext? context}) =>
      AppStrings.choose('Report', '举报', context: context);
  static String selectMessages({BuildContext? context}) =>
      AppStrings.choose('Select messages', '选择消息', context: context);
  static String messageActions({BuildContext? context}) =>
      AppStrings.choose('Message actions', '消息操作', context: context);
  static String allMessages({BuildContext? context}) =>
      AppStrings.choose('All messages', '所有消息', context: context);
  static String mentionsOnly({BuildContext? context}) =>
      AppStrings.choose('Mentions only', '仅提及我的消息', context: context);
  static String nothing({BuildContext? context}) =>
      AppStrings.choose('Nothing', '不通知', context: context);
  static String notificationSettings({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    'Notification settings — ${arg0}',
    '通知设置 · ${arg0}',
    context: context,
  );
  static String useDefault({BuildContext? context}) =>
      AppStrings.choose('Use default', '使用默认设置', context: context);
  static String reactedWith({BuildContext? context, required Object? arg0}) =>
      AppStrings.choose(
        'Reacted with ${arg0}',
        '使用了 ${arg0} 回应',
        context: context,
      );
  static String reactedWith2({BuildContext? context, required Object? arg0}) =>
      AppStrings.choose(
        'Reacted with :${arg0}:',
        '使用了 :${arg0}: 回应',
        context: context,
      );
  static String noOneYet({BuildContext? context}) =>
      AppStrings.choose('No one yet.', '暂无回应。', context: context);
  static String pinnedMessages({BuildContext? context}) =>
      AppStrings.choose('Pinned messages', '置顶消息', context: context);
  static String noPinnedMessages({BuildContext? context}) =>
      AppStrings.choose('No pinned messages', '暂无置顶消息', context: context);
  static String titleIsRequired({BuildContext? context}) =>
      AppStrings.choose('Title is required', '请填写标题', context: context);
  static String title({BuildContext? context}) =>
      AppStrings.choose('Title', '标题', context: context);
  static String failedToDeletePost({BuildContext? context}) =>
      AppStrings.choose('Failed to delete post', '删除帖子失败', context: context);
  static String shareVokuszLink({BuildContext? context}) =>
      AppStrings.choose('Share Vokusz link', '分享 Vokusz 链接', context: context);
  static String vokuszLinkCopiedToClipboard({BuildContext? context}) =>
      AppStrings.choose(
        'Vokusz link copied to clipboard',
        'Vokusz 链接已复制到剪贴板',
        context: context,
      );
  static String shareWithTheInternet({BuildContext? context}) =>
      AppStrings.choose('Share with the internet', '分享公开链接', context: context);
  static String publicLinkCopiedToClipboard({BuildContext? context}) =>
      AppStrings.choose(
        'Public link copied to clipboard',
        '公开链接已复制到剪贴板',
        context: context,
      );
  static String sharePost({BuildContext? context}) =>
      AppStrings.choose('Share post', '分享帖子', context: context);
  static String noRepliesYet({BuildContext? context}) =>
      AppStrings.choose('No replies yet', '暂无回复', context: context);
  static String share({BuildContext? context}) =>
      AppStrings.choose('Share', '分享', context: context);
  static String replyToThread({BuildContext? context}) =>
      AppStrings.choose('Reply to thread', '回复话题', context: context);
  static String sendReply({BuildContext? context}) =>
      AppStrings.choose('Send reply', '发送回复', context: context);
  static String actions({BuildContext? context}) =>
      AppStrings.choose('Actions', '操作', context: context);

  static String thisWillBePermanentlyDeleted({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    'This ${arg0} will be permanently deleted.',
    '此${arg0}将被永久删除。',
    context: context,
  );
  static String editPost({BuildContext? context}) =>
      AppStrings.choose('Edit post', '编辑帖子', context: context);
  static String editReply({BuildContext? context}) =>
      AppStrings.choose('Edit reply', '编辑回复', context: context);
  static String body({BuildContext? context}) =>
      AppStrings.choose('Body', '正文', context: context);
  static String failedToSaveChanges({BuildContext? context}) =>
      AppStrings.choose('Failed to save changes', '保存更改失败', context: context);
  static String youtubeDidNotLoadTryOpeningThe({BuildContext? context}) =>
      AppStrings.choose(
        'YouTube did not load. Try opening the video in YouTube.',
        '未能加载 YouTube，请尝试前往 YouTube 观看。',
        context: context,
      );
  static String youtubeCouldNotLoadTryOpeningThe({BuildContext? context}) =>
      AppStrings.choose(
        'YouTube could not load. Try opening the video in YouTube.',
        '无法加载 YouTube，请尝试前往 YouTube 观看。',
        context: context,
      );
  static String youtubeVideoPlayer({BuildContext? context}) =>
      AppStrings.choose(
        'YouTube video player',
        'YouTube 视频播放器',
        context: context,
      );
  static String playingLoadsContentFromYoutubeAndShares({
    BuildContext? context,
  }) => AppStrings.choose(
    'Playing loads content from YouTube and shares your connection with Google.',
    '播放时会从 YouTube 加载内容，并向 Google 提供你的网络连接信息。',
    context: context,
  );
  static String stopPlayback({BuildContext? context}) =>
      AppStrings.choose('Stop playback', '停止播放', context: context);
  static String playLoadFromYoutube({BuildContext? context}) =>
      AppStrings.choose(
        'Play · load from YouTube',
        '播放 · 从 YouTube 加载',
        context: context,
      );
  static String openInYoutube({BuildContext? context}) =>
      AppStrings.choose('Open in YouTube', '在 YouTube 中打开', context: context);
  static String notificationsForMessagesThatMentionYou({
    BuildContext? context,
  }) => AppStrings.choose(
    'Notifications for messages that mention you.',
    '当消息提及你时发送通知。',
    context: context,
  );
  static String helpSupport({BuildContext? context}) =>
      AppStrings.choose('Help & support', '帮助与支持', context: context);
  static String vokuszTourStepOf({
    BuildContext? context,
    required Object? arg0,
    required Object? arg1,
  }) => AppStrings.choose(
    'Vokusz tour, step ${arg0} of ${arg1}',
    'Vokusz 使用引导，第 ${arg0} 步，共 ${arg1} 步',
    context: context,
  );
  static String skip({BuildContext? context}) =>
      AppStrings.choose('Skip', '跳过', context: context);
  static String done({BuildContext? context}) =>
      AppStrings.choose('Done', '完成', context: context);
  static String next({BuildContext? context}) =>
      AppStrings.choose('Next', '下一步', context: context);
  static String stepOf({
    BuildContext? context,
    required Object? arg0,
    required Object? arg1,
  }) => AppStrings.choose(
    'Step ${arg0} of ${arg1}',
    '第 ${arg0} 步，共 ${arg1} 步',
    context: context,
  );
  static String helpTour({BuildContext? context}) =>
      AppStrings.choose('Help & tour', '帮助与引导', context: context);
  static String replayTheAppTour({BuildContext? context}) =>
      AppStrings.choose('Replay the app tour', '重新查看使用引导', context: context);
  static String walkThroughSpacesChannelsMessagingAndVoice({
    BuildContext? context,
  }) => AppStrings.choose(
    'Walk through spaces, channels, messaging and voice again.',
    '再次了解域、频道、消息和语音功能。',
    context: context,
  );
  static String documentationIssueTrackerAndTheProject({
    BuildContext? context,
  }) => AppStrings.choose(
    'Documentation, issue tracker and the project.',
    '查看文档、问题反馈和项目主页。',
    context: context,
  );
  static String deviceProfiles({BuildContext? context}) =>
      AppStrings.choose('Device Profiles', '本地使用档案', context: context);
  static String newProfile({BuildContext? context}) =>
      AppStrings.choose('New profile', '新建档案', context: context);
  static String profilesAreIsolatedLocalSpacesEachWith({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    'Profiles are isolated local spaces, each with its own accounts and settings. Switching restarts the app. ${arg0}',
    '每份本地档案都有独立的账号和设置，切换档案会重启应用。${arg0}',
    context: context,
  );
  static String renameProfile({BuildContext? context}) =>
      AppStrings.choose('Rename profile', '重命名档案', context: context);
  static String ok({BuildContext? context}) =>
      AppStrings.choose('OK', '确定', context: context);
  static String deleteProfile({BuildContext? context}) =>
      AppStrings.choose('Delete profile', '删除档案', context: context);
  static String deleteAndAllItsAccountsAndSettings({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    'Delete \'${arg0}\' and all its accounts and settings? This cannot be undone.',
    '确定删除“${arg0}”及其全部账号和设置？此操作无法撤销。',
    context: context,
  );
  static String enterCurrentPinToRemove({BuildContext? context}) =>
      AppStrings.choose(
        'Enter current PIN to remove',
        '请输入当前 PIN 以解除锁定',
        context: context,
      );
  static String incorrectPin({BuildContext? context}) =>
      AppStrings.choose('Incorrect PIN', 'PIN 不正确', context: context);
  static String setAPin({BuildContext? context}) =>
      AppStrings.choose('Set a PIN', '设置 PIN', context: context);
  static String active({BuildContext? context}) =>
      AppStrings.choose('Active', '当前使用', context: context);
  static String casualPinLockNotEncrypted({BuildContext? context}) =>
      AppStrings.choose(
        'Casual PIN lock (not encrypted)',
        'PIN 锁定（不加密资料）',
        context: context,
      );
  static String noPin({BuildContext? context}) =>
      AppStrings.choose('No PIN', '未设置 PIN', context: context);
  static String switchTo({BuildContext? context}) =>
      AppStrings.choose('Switch to', '切换至', context: context);
  static String rename({BuildContext? context}) =>
      AppStrings.choose('Rename', '重命名', context: context);
  static String removePin({BuildContext? context}) =>
      AppStrings.choose('Remove PIN', '移除 PIN', context: context);
  static String setPin({BuildContext? context}) =>
      AppStrings.choose('Set PIN', '设置 PIN', context: context);
  static String profileName({BuildContext? context}) =>
      AppStrings.choose('Profile name', '档案名称', context: context);
  static String pinOptional({BuildContext? context}) =>
      AppStrings.choose('PIN (optional)', 'PIN（可选）', context: context);
  static String enterYourPinToUnlockThisProfile({BuildContext? context}) =>
      AppStrings.choose(
        'Enter your PIN to unlock this profile',
        '请输入 PIN 以解锁此档案',
        context: context,
      );
  static String unlock({BuildContext? context}) =>
      AppStrings.choose('Unlock', '解锁', context: context);
  static String accordServerUrl({BuildContext? context}) =>
      AppStrings.choose('Accord server URL', 'Accord 服务器地址', context: context);
  static String registrationFailed({BuildContext? context}) =>
      AppStrings.choose('Registration failed', '注册失败', context: context);
  static String loginFailed({BuildContext? context}) =>
      AppStrings.choose('Login failed', '登录失败', context: context);
  static String invalidTwoFactorCode({BuildContext? context}) =>
      AppStrings.choose('Invalid two-factor code', '两步验证码无效', context: context);
  static String passwordChangeFailed({BuildContext? context}) =>
      AppStrings.choose('Password change failed', '修改密码失败', context: context);
  static String addAServer({BuildContext? context}) =>
      AppStrings.choose('Connect to a community', '连接社区', context: context);
  static String enterUrl({BuildContext? context}) =>
      AppStrings.choose('Enter URL', '输入地址', context: context);
  static String federated({BuildContext? context}) =>
      AppStrings.choose('Federated', '跨服域', context: context);
  static String connectTo({BuildContext? context, required Object? arg0}) =>
      AppStrings.choose('Connect to ${arg0}', '连接到 ${arg0}', context: context);
  static String twoFactorCode({BuildContext? context}) =>
      AppStrings.choose('Two-factor code', '两步验证码', context: context);
  static String connect({BuildContext? context}) =>
      AppStrings.choose('Connect', '连接', context: context);
  static String register({BuildContext? context}) =>
      AppStrings.choose('Register', '注册', context: context);
  static String signIn({BuildContext? context}) =>
      AppStrings.choose('Sign in', '登录', context: context);
  static String joinAFederatedSpace({BuildContext? context}) =>
      AppStrings.choose('Join a federated space', '加入跨服域', context: context);
  static String enterASpaceHostedOnAnotherVokusz({
    BuildContext? context,
  }) => AppStrings.choose(
    'Enter a space hosted on another Vokusz server. Your current server connects to it on your behalf.',
    '加入托管在其他 Vokusz 服务器上的域，当前服务器会代你与对方建立连接。',
    context: context,
  );
  static String spaceAddress({BuildContext? context}) =>
      AppStrings.choose('Space address', '域地址', context: context);
  static String connectToAServerFirstThenJoin({BuildContext? context}) =>
      AppStrings.choose(
        'Connect to a server first, then join a federated space from it.',
        '请先连接服务器，再通过它加入跨服域。',
        context: context,
      );
  static String join({BuildContext? context}) =>
      AppStrings.choose('Join', '加入', context: context);
  static String enterASpaceAsSpaceidServerExample({BuildContext? context}) =>
      AppStrings.choose(
        'Enter a space as spaceId@server.example',
        '请按 spaceId@server.example 格式输入域地址',
        context: context,
      );
  static String joinFederatedSpace({BuildContext? context}) =>
      AppStrings.choose('Join federated space?', '加入跨服域？', context: context);
  static String activeAccountNDestinationDomainNSpace({
    BuildContext? context,
    required Object? arg0,
    required Object? arg1,
    required Object? arg2,
  }) => AppStrings.choose(
    'Active account: ${arg0}\nDestination domain: ${arg1}\nSpace: ${arg2}',
    '当前账号：${arg0}\n目标服务器：${arg1}\n域：${arg2}',
    context: context,
  );
  static String joinSpace({BuildContext? context}) =>
      AppStrings.choose('Join domain', '加入域', context: context);
  static String showEmbedsAndLinkPreviews({BuildContext? context}) =>
      AppStrings.choose(
        'Show embeds and link previews',
        '显示嵌入内容和链接预览',
        context: context,
      );
  static String hidePreviewsOnlyForYouMessageText({BuildContext? context}) =>
      AppStrings.choose(
        'Hide previews only for you; message text stays visible',
        '关闭后仅对你隐藏预览，消息文字仍会显示',
        context: context,
      );
  static String compactMode({BuildContext? context}) =>
      AppStrings.choose('Compact mode', '紧凑模式', context: context);
  static String denserMessageLayoutSmallerSpacing({BuildContext? context}) =>
      AppStrings.choose(
        'Denser message layout (smaller spacing)',
        '缩小消息间距，让界面更紧凑',
        context: context,
      );
  static String convertEmoticonsToEmoji({BuildContext? context}) =>
      AppStrings.choose(
        'Convert emoticons to emoji',
        '将字符表情转换为表情符号',
        context: context,
      );
  static String turnAnd3IntoAndAsYou({BuildContext? context}) =>
      AppStrings.choose(
        'Turn :) and <3 into 🙂 and ❤️ as you send',
        '发送时将 :)、<3 等字符转换为 🙂、❤️',
        context: context,
      );
  static String reducedMotion({BuildContext? context}) =>
      AppStrings.choose('Reduced motion', '减少动态效果', context: context);
  static String minimiseUiAnimations({BuildContext? context}) =>
      AppStrings.choose('Minimise UI animations', '减少界面动画', context: context);
  static String uiScale({BuildContext? context}) =>
      AppStrings.choose('UI scale', '界面缩放', context: context);
  static String enableNotifications({BuildContext? context}) =>
      AppStrings.choose('Enable notifications', '启用通知', context: context);
  static String showASystemNotificationWhenMentioned({BuildContext? context}) =>
      AppStrings.choose(
        'Show a system notification when mentioned',
        '有人提及你时显示系统通知',
        context: context,
      );
  static String suppressEveryone({BuildContext? context}) =>
      AppStrings.choose('Suppress @everyone', '忽略全体提及', context: context);
  static String neverNotifyForEveryoneHereMentions({BuildContext? context}) =>
      AppStrings.choose(
        'Never notify for @everyone / @here mentions',
        '不接收 @everyone 或 @here 提及通知',
        context: context,
      );
  static String stayConnectedInTheBackground({BuildContext? context}) =>
      AppStrings.choose(
        'Stay connected in the background',
        '在后台保持连接',
        context: context,
      );
  static String keepsNotificationsArrivingWhileTheAppIs({
    BuildContext? context,
  }) => AppStrings.choose(
    'Keeps notifications arriving while the app is closed. Shows a permanent notification and uses more battery.',
    '关闭应用后仍可接收通知。启用后会显示常驻通知，并增加耗电。',
    context: context,
  );
  static String enableSounds({BuildContext? context}) =>
      AppStrings.choose('Enable sounds', '启用提示音', context: context);
  static String playSfxForMessagesAndMentions({BuildContext? context}) =>
      AppStrings.choose(
        'Play SFX for messages and mentions',
        '收到消息或被提及时播放提示音',
        context: context,
      );
  static String volume({BuildContext? context}) =>
      AppStrings.choose('Volume', '音量', context: context);
  static String voiceVideoSettings({BuildContext? context}) =>
      AppStrings.choose('Voice & video settings', '语音与视频设置', context: context);
  static String microphoneSpeakerSensitivityCameraMicTest({
    BuildContext? context,
  }) => AppStrings.choose(
    'Microphone, speaker, sensitivity, camera, mic test',
    '麦克风、扬声器、灵敏度、摄像头及麦克风测试',
    context: context,
  );
  static String perServerProfile({BuildContext? context}) =>
      AppStrings.choose('Per-server profile', '服务器专属资料', context: context);
  static String overrideNameBioAvatarOnOneServer({BuildContext? context}) =>
      AppStrings.choose(
        'Override name/bio/avatar on one server',
        '为特定服务器单独设置名称、简介和头像',
        context: context,
      );
  static String deviceProfiles2({BuildContext? context}) =>
      AppStrings.choose('Device profiles', '本地使用档案', context: context);
  static String localProfilesWithAnOptionalCasualPin({BuildContext? context}) =>
      AppStrings.choose(
        'Local profiles with an optional casual PIN lock',
        '独立保存本地账号和设置，可选用 PIN 锁定',
        context: context,
      );
  static String connections({BuildContext? context}) =>
      AppStrings.choose('Connections', '关联账号', context: context);
  static String linkedThirdPartyOauthAccounts({BuildContext? context}) =>
      AppStrings.choose(
        'Linked third-party (OAuth) accounts',
        '通过 OAuth 关联的第三方账号',
        context: context,
      );
  static String privacyData({BuildContext? context}) =>
      AppStrings.choose('Privacy & Data', '隐私与数据', context: context);
  static String dataExportLeaveDeleteDataRetention({BuildContext? context}) =>
      AppStrings.choose(
        'Data export, leave & delete data, retention',
        '导出数据、退出并删除数据、数据保留规则',
        context: context,
      );
  static String spacesUsersReportsSettings({BuildContext? context}) =>
      AppStrings.choose(
        'Spaces, users, reports, settings',
        '域、用户、举报与设置',
        context: context,
      );
  static String serverDirectory({BuildContext? context}) =>
      AppStrings.choose('Server Directory', '服务器目录', context: context);
  static String updates({BuildContext? context}) =>
      AppStrings.choose('Updates', '更新', context: context);
  static String currentVersionCheckForNewReleases({BuildContext? context}) =>
      AppStrings.choose(
        'Current version, check for new releases',
        '查看当前版本并检查更新',
        context: context,
      );
  static String backup({BuildContext? context}) =>
      AppStrings.choose('Backup', '备份', context: context);
  static String developerMode({BuildContext? context}) =>
      AppStrings.choose('Developer Mode', '开发者模式', context: context);
  static String unlockTheLocalClientMcpServerFor({BuildContext? context}) =>
      AppStrings.choose(
        'Unlock the local Client MCP server for AI agents',
        '启用本地客户端 MCP 服务，供 AI 助手使用',
        context: context,
      );
  static String tokenPortToolGroupsActivity({BuildContext? context}) =>
      AppStrings.choose(
        'Token, port, tool groups, activity',
        '令牌、端口、工具组及活动记录',
        context: context,
      );
  static String about({BuildContext? context}) =>
      AppStrings.choose('About', '关于', context: context);
  static String freeScreenSharingAndStableVoiceNo({BuildContext? context}) =>
      AppStrings.choose(
        'Free screen sharing and stable voice. No paywall on the call.',
        '免费屏幕共享，稳定语音通话，畅聊无需付费解锁。',
        context: context,
      );
  static String howTheAppAndIndependentServersHandle({BuildContext? context}) =>
      AppStrings.choose(
        'How the app and independent servers handle data.',
        '了解应用及独立服务器如何处理数据。',
        context: context,
      );
  static String masterServerUrlSaved({BuildContext? context}) =>
      AppStrings.choose(
        'Master server URL saved',
        '服务器目录地址已保存',
        context: context,
      );
  static String masterServerUrl({BuildContext? context}) =>
      AppStrings.choose('Master server URL', '服务器目录地址', context: context);
  static String notConnected({BuildContext? context}) =>
      AppStrings.choose('Not connected.', '尚未连接。', context: context);
  static String failedToLoadConnections({BuildContext? context}) =>
      AppStrings.choose(
        'Failed to load connections.',
        '加载关联账号失败。',
        context: context,
      );
  static String disconnect({BuildContext? context}) =>
      AppStrings.choose('Disconnect', '断开连接', context: context);
  static String disconnect2({
    BuildContext? context,
    required Object? arg0,
    required Object? arg1,
  }) => AppStrings.choose(
    'Disconnect ${arg0}${arg1}?',
    '确定断开与 ${arg0}${arg1} 的关联？',
    context: context,
  );
  static String failed({BuildContext? context}) =>
      AppStrings.choose('Failed', '操作失败', context: context);
  static String exportFailedPleaseTryAgain({BuildContext? context}) =>
      AppStrings.choose(
        'Export failed. Please try again.',
        '导出失败，请重试。',
        context: context,
      );
  static String saveDataExport({BuildContext? context}) =>
      AppStrings.choose('Save data export', '保存导出的数据', context: context);
  static String couldNotSaveTheExportFile({BuildContext? context}) =>
      AppStrings.choose(
        'Could not save the export file.',
        '无法保存导出文件。',
        context: context,
      );
  static String exportCancelled({BuildContext? context}) =>
      AppStrings.choose('Export cancelled.', '已取消导出。', context: context);
  static String dataExportedSuccessfully({BuildContext? context}) =>
      AppStrings.choose(
        'Data exported successfully.',
        '数据已导出。',
        context: context,
      );
  static String leaveDeleteData({BuildContext? context}) =>
      AppStrings.choose('Leave & Delete Data', '退出并删除数据', context: context);
  static String thisWillPermanentlyLeaveAndDeleteAll({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    'This will permanently leave \'${arg0}\' and delete all your messages, reactions, and data from this server. Your account stays active. This cannot be undone.',
    '将退出“${arg0}”，并永久删除你在此服务器上的消息、表情回应和其他数据。账号仍可继续使用。此操作无法撤销。',
    context: context,
  );
  static String leaveDelete({BuildContext? context}) =>
      AppStrings.choose('Leave & Delete', '退出并删除', context: context);
  static String leftAndDeletedYourData({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    'Left \'${arg0}\' and deleted your data',
    '已退出“${arg0}”并删除你的数据',
    context: context,
  );
  static String dataExport({BuildContext? context}) =>
      AppStrings.choose('Data export', '导出数据', context: context);
  static String downloadACopyOfYourPersonalData({
    BuildContext? context,
  }) => AppStrings.choose(
    'Download a copy of your personal data stored on this server, including your profile, messages, and relationships. The export is provided as a JSON file.',
    '下载你保存在此服务器上的个人数据副本，包括个人资料、消息和好友关系。数据将导出为 JSON 文件。',
    context: context,
  );
  static String exporting({BuildContext? context}) =>
      AppStrings.choose('Exporting…', '正在导出…', context: context);
  static String requestDataExport({BuildContext? context}) =>
      AppStrings.choose('Request Data Export', '申请导出数据', context: context);
  static String leaveDeleteData2({BuildContext? context}) =>
      AppStrings.choose('Leave & delete data', '退出并删除数据', context: context);
  static String leaveAServerAndPermanentlyDeleteAll({
    BuildContext? context,
  }) => AppStrings.choose(
    'Leave a server and permanently delete all your data from it, including messages, reactions, and read states. Your account on that instance remains active. This action cannot be undone.',
    '退出域，并永久删除你在其中的消息、表情回应和已读记录等数据。你在该服务器上的账号仍可继续使用。此操作无法撤销。',
    context: context,
  );
  static String youAreNotInAnySpaces({BuildContext? context}) =>
      AppStrings.choose(
        'You are not in any spaces.',
        '你尚未加入任何域。',
        context: context,
      );
  static String dataDeletion({BuildContext? context}) =>
      AppStrings.choose('Data deletion', '删除数据', context: context);
  static String whenYouDeleteYourAccountAllPersonal({
    BuildContext? context,
  }) => AppStrings.choose(
    'When you delete your account, all personal data is permanently removed from the server. This includes your profile, messages, reactions, memberships, tokens, and applications. This action cannot be undone. Account deletion lives under Account settings.',
    '注销账号后，服务器会永久删除你的个人资料、消息、表情回应、成员身份、令牌和应用等个人数据。此操作无法撤销。请在“账号设置”中注销账号。',
    context: context,
  );
  static String dataRetention({BuildContext? context}) =>
      AppStrings.choose('Data retention', '数据保留', context: context);
  static String dataIsRetainedForAsLongAs({
    BuildContext? context,
  }) => AppStrings.choose(
    'Data is retained for as long as your account exists. There is no automatic expiration of messages or attachments. Server administrators may configure their own retention policies.',
    '只要账号仍然存在，数据就会保留。消息和附件不会自动过期；社区管理员可以另行配置数据保留策略。',
    context: context,
  );
  static String youAreTheOwnerTransferOwnershipBefore({
    BuildContext? context,
  }) => AppStrings.choose(
    'You are the owner — transfer ownership before leaving.',
    '你是域主，请先转让域主身份再退出。',
    context: context,
  );
  static String exportSettings({BuildContext? context}) =>
      AppStrings.choose('Export settings', '导出设置', context: context);
  static String couldNotSaveTheSettingsFile({BuildContext? context}) =>
      AppStrings.choose(
        'Could not save the settings file.',
        '无法保存设置文件。',
        context: context,
      );
  static String settingsExported({BuildContext? context}) =>
      AppStrings.choose('Settings exported.', '设置已导出。', context: context);
  static String importSettings({BuildContext? context}) =>
      AppStrings.choose('Import settings', '导入设置', context: context);
  static String couldNotOpenTheSettingsFile({BuildContext? context}) =>
      AppStrings.choose(
        'Could not open the settings file.',
        '无法打开设置文件。',
        context: context,
      );
  static String thatFileIsNotAValidSettings({BuildContext? context}) =>
      AppStrings.choose(
        'That file is not a valid settings export.',
        '此文件不是有效的设置备份。',
        context: context,
      );
  static String settingsImported({BuildContext? context}) =>
      AppStrings.choose('Settings imported.', '设置已导入。', context: context);
  static String couldNotImportSettings({BuildContext? context}) =>
      AppStrings.choose(
        'Could not import settings.',
        '无法导入设置。',
        context: context,
      );
  static String saveYourPreferencesToAJsonFile({BuildContext? context}) =>
      AppStrings.choose(
        'Save your preferences to a JSON file',
        '将偏好设置保存为 JSON 文件',
        context: context,
      );
  static String restorePreferencesFromAJsonFile({BuildContext? context}) =>
      AppStrings.choose(
        'Restore preferences from a JSON file',
        '从 JSON 文件恢复偏好设置',
        context: context,
      );
  static String yesterdayAt({BuildContext? context, required Object? arg0}) =>
      AppStrings.choose('Yesterday at ${arg0}', '昨天 ${arg0}', context: context);
  static String failedToLoadAuditLog({BuildContext? context}) =>
      AppStrings.choose(
        'Failed to load audit log',
        '加载审核日志失败',
        context: context,
      );
  static String failedToLoadMoreEntries({BuildContext? context}) =>
      AppStrings.choose(
        'Failed to load more entries',
        '加载更多记录失败',
        context: context,
      );
  static String auditLog({BuildContext? context}) =>
      AppStrings.choose('Audit log', '审核日志', context: context);
  static String allActions({BuildContext? context}) =>
      AppStrings.choose('All actions', '所有操作', context: context);
  static String user({BuildContext? context}) =>
      AppStrings.choose('User', '用户', context: context);
  static String noMatchingEntries({BuildContext? context}) =>
      AppStrings.choose('No matching entries', '暂无匹配记录', context: context);
  static String failedToLoadBans({BuildContext? context}) =>
      AppStrings.choose('Failed to load bans', '加载封禁列表失败', context: context);
  static String unbanMember({BuildContext? context}) =>
      AppStrings.choose('Unban member?', '解除成员封禁？', context: context);
  static String allowBackIntoTheSpace({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    'Allow ${arg0} back into the space?',
    '允许 ${arg0} 重新加入域？',
    context: context,
  );
  static String unban({BuildContext? context}) =>
      AppStrings.choose('Unban', '解除封禁', context: context);
  static String failedToUnban({BuildContext? context}) =>
      AppStrings.choose('Failed to unban', '解除封禁失败', context: context);
  static String unbanMembers({BuildContext? context}) =>
      AppStrings.choose('Unban members?', '批量解除封禁？', context: context);
  static String allowMemberSBackIntoTheSpace({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    'Allow ${arg0} member(s) back into the space?',
    '允许这 ${arg0} 位成员重新加入域？',
    context: context,
  );
  static String failedToUnban2({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    'Failed to unban ${arg0}',
    '有 ${arg0} 位成员未能解除封禁',
    context: context,
  );
  static String bannedMembers({BuildContext? context}) =>
      AppStrings.choose('Banned members', '已封禁成员', context: context);
  static String searchBannedMembers({BuildContext? context}) =>
      AppStrings.choose('Search banned members', '搜索已封禁成员', context: context);
  static String unbanSelected({BuildContext? context}) =>
      AppStrings.choose('Unban selected', '解除所选成员的封禁', context: context);
  static String loading({BuildContext? context}) =>
      AppStrings.choose('Loading…', '正在加载…', context: context);
  static String noBansInThisSpace({BuildContext? context}) => AppStrings.choose(
    'No bans in this space.',
    '此域暂无封禁记录。',
    context: context,
  );
  static String noMatchingBans({BuildContext? context}) =>
      AppStrings.choose('No matching bans.', '没有匹配的封禁记录。', context: context);
  static String noReasonGiven({BuildContext? context}) =>
      AppStrings.choose('No reason given', '未填写原因', context: context);
  static String failedToReorder({BuildContext? context}) =>
      AppStrings.choose('Failed to reorder', '调整顺序失败', context: context);
  static String deleteChannels({BuildContext? context}) =>
      AppStrings.choose('Delete channels', '删除频道', context: context);
  static String deleteChannelSThisCannotBeUndone({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    'Delete ${arg0} channel(s)? This cannot be undone.',
    '确定删除 ${arg0} 个频道？此操作无法撤销。',
    context: context,
  );
  static String failedToDelete2({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    'Failed to delete ${arg0}',
    '有 ${arg0} 个频道未能删除',
    context: context,
  );
  static String reorderChannels({BuildContext? context}) =>
      AppStrings.choose('Reorder channels', '调整频道顺序', context: context);
  static String doneSelecting({BuildContext? context}) =>
      AppStrings.choose('Done selecting', '完成选择', context: context);
  static String selectToDelete({BuildContext? context}) =>
      AppStrings.choose('Select to delete', '选择要删除的频道', context: context);
  static String selectChannelsToDeleteThisCannotBe({BuildContext? context}) =>
      AppStrings.choose(
        'Select channels to delete. This cannot be undone.',
        '选择要删除的频道。此操作无法撤销。',
        context: context,
      );
  static String dragCategoriesAndChannelsIntoYourPreferred({
    BuildContext? context,
  }) => AppStrings.choose(
    'Drag categories and channels into your preferred order. Drop a channel onto a category to move it into that category.',
    '拖动分组和频道可调整顺序。将频道拖到分组上，即可将其移入该分组。',
    context: context,
  );
  static String deleteSelected({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    'Delete selected (${arg0})',
    '删除所选频道（${arg0}）',
    context: context,
  );
  static String failedToLoadDirectory({BuildContext? context}) =>
      AppStrings.choose(
        'Failed to load directory',
        '加载服务器目录失败',
        context: context,
      );
  static String thisListingIsMissingItsServerDetails({BuildContext? context}) =>
      AppStrings.choose(
        'This listing is missing its server details',
        '此条目缺少服务器信息',
        context: context,
      );
  static String searchServers({BuildContext? context}) =>
      AppStrings.choose('Search servers...', '搜索服务器…', context: context);
  static String all({BuildContext? context}) =>
      AppStrings.choose('All', '全部', context: context);
  static String noServersFound({BuildContext? context}) =>
      AppStrings.choose('No servers found', '未找到服务器', context: context);
  static String thisListIsShortOnPurpose({BuildContext? context}) =>
      AppStrings.choose(
        'This list is short on purpose',
        '这里只展示主动公开的域',
        context: context,
      );
  static String onlyCommunitiesThatChooseToAdvertiseThemselves({
    BuildContext? context,
  }) => AppStrings.choose(
    'Only communities that choose to advertise themselves appear in the public directory. Most Accord communities are private or self-hosted, so you usually reach them from an invite link, or by connecting straight to the server they run.',
    '公共目录仅展示选择公开的域。大多数 Accord 域属于私有域或自行托管，通常需要通过邀请链接加入，或直接连接其服务器。',
    context: context,
  );
  static String notListedHereAnyAccordServerWorks({BuildContext? context}) =>
      AppStrings.choose(
        'Not listed here? Any Accord server works.',
        '没在列表中找到？你仍可连接任何 Accord 服务器。',
        context: context,
      );
  static String connectToAServerByUrl({BuildContext? context}) =>
      AppStrings.choose(
        'Connect to a server by URL',
        '通过地址连接服务器',
        context: context,
      );
  static String hostYourOwn({BuildContext? context}) =>
      AppStrings.choose('Host your own', '自行搭建', context: context);

  static String online2({BuildContext? context, required Object? arg0}) =>
      AppStrings.choose(
        ' · ${arg0} online',
        ' · ${arg0} 人在线',
        context: context,
      );
  static String failedToUploadEmoji({BuildContext? context}) =>
      AppStrings.choose('Failed to upload emoji', '上传表情失败', context: context);
  static String failedToRenameEmoji({BuildContext? context}) =>
      AppStrings.choose('Failed to rename emoji', '重命名表情失败', context: context);
  static String deleteEmoji({BuildContext? context}) =>
      AppStrings.choose('Delete emoji?', '删除表情？', context: context);
  static String willBeRemovedFromThisSpace({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    ':${arg0}: will be removed from this space.',
    '将从此域移除 :${arg0}:。',
    context: context,
  );
  static String failedToDeleteEmoji({BuildContext? context}) =>
      AppStrings.choose('Failed to delete emoji', '删除表情失败', context: context);
  static String renameEmoji({BuildContext? context}) =>
      AppStrings.choose('Rename emoji', '重命名表情', context: context);
  static String lettersNumbersAndUnderscores({BuildContext? context}) =>
      AppStrings.choose(
        'Letters, numbers, and underscores',
        '仅可使用字母、数字和下划线',
        context: context,
      );
  static String customEmoji({BuildContext? context}) =>
      AppStrings.choose('Custom emoji', '自定义表情', context: context);
  static String uploadEmoji({BuildContext? context}) =>
      AppStrings.choose('Upload emoji', '上传表情', context: context);
  static String noCustomEmojiYet({BuildContext? context}) =>
      AppStrings.choose('No custom emoji yet.', '暂无自定义表情。', context: context);
  static String ageRestrictedChannel({BuildContext? context}) =>
      AppStrings.choose('Age-restricted channel', '年龄限制频道', context: context);
  static String isMarkedForContentThatMayNot({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    '#${arg0} is marked for content that may not be suitable for everyone. Are you over 18 and willing to view it?',
    '#${arg0} 中的内容可能不适合所有人。你是否已年满 18 周岁，并愿意查看？',
    context: context,
  );
  static String goBack({BuildContext? context}) =>
      AppStrings.choose('Go back', '返回', context: context);
  static String pleaseFollowThisCommunitySRules({BuildContext? context}) =>
      AppStrings.choose(
        'Please follow this community\'s rules.',
        '请遵守本域的规则。',
        context: context,
      );
  static String welcomeTo({BuildContext? context, required Object? arg0}) =>
      AppStrings.choose('Welcome to ${arg0}', '欢迎加入 ${arg0}', context: context);
  static String pleaseReviewTheRulesBeforeParticipating({
    BuildContext? context,
  }) => AppStrings.choose(
    'Please review the rules before participating.',
    '参与交流前，请先阅读域规则。',
    context: context,
  );
  static String iAgree({BuildContext? context}) =>
      AppStrings.choose('I agree', '我同意', context: context);
  static String publicServersAreDisabled({BuildContext? context}) =>
      AppStrings.choose(
        'Public servers are disabled',
        '公共服务器功能已关闭',
        context: context,
      );
  static String messageNotLoaded({BuildContext? context}) =>
      AppStrings.choose('Message not loaded', '消息尚未加载', context: context);
  static String notConnectedToAVoiceChannel({BuildContext? context}) =>
      AppStrings.choose(
        'Not connected to a voice channel',
        '尚未连接语音频道',
        context: context,
      );
  static String noSpaceSelected({BuildContext? context}) =>
      AppStrings.choose('No domain selected', '尚未选择域', context: context);
  static String theLinkedMessageIsUnavailable({BuildContext? context}) =>
      AppStrings.choose(
        'The linked message is unavailable.',
        '链接指向的消息不可用。',
        context: context,
      );
  static String theLinkedChannelIsUnavailable({BuildContext? context}) =>
      AppStrings.choose(
        'The linked channel is unavailable.',
        '链接指向的频道不可用。',
        context: context,
      );
  static String couldnTLoadChannels({BuildContext? context}) =>
      AppStrings.choose('Couldn\'t load channels', '无法加载频道', context: context);
  static String somethingWentWrongFetchingThisSpaceS({BuildContext? context}) =>
      AppStrings.choose(
        'Something went wrong fetching this space’s channels.',
        '获取此域的频道时出错，请重试。',
        context: context,
      );
  static String couldnTLoadYourSpaces({BuildContext? context}) =>
      AppStrings.choose(
        'Couldn\'t load your spaces',
        '无法加载你的域',
        context: context,
      );
  static String somethingWentWrongFetchingThisServerS({
    BuildContext? context,
  }) => AppStrings.choose(
    'Something went wrong fetching this server’s space list.',
    '获取此服务器的域列表时出错，请重试。',
    context: context,
  );
  static String newFolderWithThisSpace({BuildContext? context}) =>
      AppStrings.choose(
        'New folder with this space',
        '为此域新建文件夹',
        context: context,
      );
  static String moveTo({BuildContext? context, required Object? arg0}) =>
      AppStrings.choose('Move to "${arg0}"', '移至“${arg0}”', context: context);
  static String removeFromFolder({BuildContext? context}) =>
      AppStrings.choose('Remove from folder', '移出文件夹', context: context);
  static String hiddenServers({BuildContext? context}) =>
      AppStrings.choose('Hidden domains', '已隐藏的域', context: context);
  static String unhide({BuildContext? context}) =>
      AppStrings.choose('Unhide', '取消隐藏', context: context);
  static String folder({BuildContext? context}) =>
      AppStrings.choose('Folder', '文件夹', context: context);
  static String removeFromFolder2({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    'Remove "${arg0}" from folder',
    '将“${arg0}”移出文件夹',
    context: context,
  );
  static String expand({BuildContext? context}) =>
      AppStrings.choose('Expand', '展开', context: context);
  static String collapse({BuildContext? context}) =>
      AppStrings.choose('Collapse', '折叠', context: context);
  static String folderName({BuildContext? context}) =>
      AppStrings.choose('Folder name', '文件夹名称', context: context);
  static String recolor({BuildContext? context}) =>
      AppStrings.choose('Recolor', '更换颜色', context: context);
  static String deleteFolder({BuildContext? context}) =>
      AppStrings.choose('Delete folder', '删除文件夹', context: context);
  static String folderColor({BuildContext? context}) =>
      AppStrings.choose('Folder color', '文件夹颜色', context: context);
  static String directMessages({BuildContext? context}) =>
      AppStrings.choose('Direct messages', '私信', context: context);
  static String hidden({
    BuildContext? context,
    required Object? arg0,
    required Object? arg1,
  }) => AppStrings.choose(
    '${arg0} hidden domains',
    '已隐藏 ${arg0} 个域',
    context: context,
  );
  static String unmuteServer({BuildContext? context}) =>
      AppStrings.choose('Unmute domain', '取消域静音', context: context);
  static String muteServer({BuildContext? context}) =>
      AppStrings.choose('Mute domain', '域静音', context: context);
  static String silenceNotificationsFromThisServer({BuildContext? context}) =>
      AppStrings.choose(
        'Silence notifications from this domain',
        '不再接收此域的通知',
        context: context,
      );
  static String copyServerLink({BuildContext? context}) =>
      AppStrings.choose('Copy domain link', '复制域链接', context: context);
  static String invitePeople({BuildContext? context}) =>
      AppStrings.choose('Invite people', '邀请成员', context: context);
  static String spaceSettings({BuildContext? context}) =>
      AppStrings.choose('Domain settings', '域设置', context: context);
  static String hideFromList({BuildContext? context}) =>
      AppStrings.choose('Hide from list', '从列表中隐藏', context: context);
  static String removeFromYourRailWithoutLeaving({BuildContext? context}) =>
      AppStrings.choose(
        'Remove from your rail without leaving',
        '从侧栏隐藏，但不退出域',
        context: context,
      );
  static String leaveServer({BuildContext? context}) =>
      AppStrings.choose('Leave domain', '退出域', context: context);
  static String transferOwnershipBeforeLeaving({BuildContext? context}) =>
      AppStrings.choose(
        'Transfer ownership before leaving.',
        '请先转让域主身份再退出。',
        context: context,
      );
  static String permanentlyDeleteYourMessagesDataHere({
    BuildContext? context,
  }) => AppStrings.choose(
    'Permanently delete your messages & data here',
    '永久删除你在这里的消息和数据',
    context: context,
  );
  static String removeServer({BuildContext? context}) =>
      AppStrings.choose('Remove community connection', '移除社区连接', context: context);
  static String disconnectRemoveFromThisAppWorksEven({BuildContext? context}) =>
      AppStrings.choose(
        'Disconnect & remove from this app — works even when offline',
        '断开连接并从应用中移除，离线时也可操作',
        context: context,
      );
  static String thisDisconnectsYourAccountAndRemovesThe({
    BuildContext? context,
  }) => AppStrings.choose(
    'This disconnects your account and removes the server from this app, including any of its spaces. Nothing is deleted on the server, and you can add it back later with its address or an invite.',
    '这将断开账号连接，并从应用中移除此社区及其所有域。服务器上的数据不会被删除，你可以稍后通过地址或邀请重新连接。',
    context: context,
  );
  static String couldNotCreateAnInviteLink({BuildContext? context}) =>
      AppStrings.choose(
        'Could not create an invite link',
        '无法创建邀请链接',
        context: context,
      );
  static String serverLinkCopied({BuildContext? context}) =>
      AppStrings.choose('Domain link copied', '域链接已复制', context: context);
  static String leaveDelete2({BuildContext? context}) =>
      AppStrings.choose('Leave & delete', '退出并删除', context: context);
  static String failedToLeave({BuildContext? context}) =>
      AppStrings.choose('Failed to leave', '退出失败', context: context);
  static String youWillLoseAccessToThisServer({
    BuildContext? context,
  }) => AppStrings.choose(
    'You will lose access to this server until you rejoin with an invite. Your messages stay on the server.',
    '退出后需要通过邀请才能重新加入。你的消息仍会保留在服务器上。',
    context: context,
  );
  static String leave({BuildContext? context}) =>
      AppStrings.choose('Leave', '退出', context: context);
  static String copyLink({BuildContext? context}) =>
      AppStrings.choose('Copy Link', '复制链接', context: context);
  static String closeToTheRight({BuildContext? context}) =>
      AppStrings.choose('Close to the Right', '关闭右侧标签页', context: context);
  static String closeOthers({BuildContext? context}) =>
      AppStrings.choose('Close Others', '关闭其他标签页', context: context);
  static String linkCopied({BuildContext? context}) =>
      AppStrings.choose('Link copied!', '链接已复制', context: context);
  static String failedToLoadInvites({BuildContext? context}) =>
      AppStrings.choose('Failed to load invites', '加载邀请失败', context: context);
  static String failedToCreateInvite({BuildContext? context}) =>
      AppStrings.choose('Failed to create invite', '创建邀请失败', context: context);
  static String failedToRevokeInvite({BuildContext? context}) =>
      AppStrings.choose('Failed to revoke invite', '撤销邀请失败', context: context);
  static String inviteLinkCopied({BuildContext? context}) =>
      AppStrings.choose('Invite link copied', '邀请链接已复制', context: context);
  static String uses({
    BuildContext? context,
    required Object? arg0,
    required Object? arg1,
  }) => AppStrings.choose(
    '${arg0}/${arg1} uses',
    '已使用 ${arg0}/${arg1} 次',
    context: context,
  );
  static String expireAfter({BuildContext? context}) =>
      AppStrings.choose('Expire after', '有效期', context: context);
  static String maxUses({BuildContext? context}) =>
      AppStrings.choose('Max uses', '使用次数上限', context: context);
  static String temporaryMembership({BuildContext? context}) =>
      AppStrings.choose('Temporary membership', '临时成员', context: context);
  static String kickedOnDisconnectUnlessGivenARole({BuildContext? context}) =>
      AppStrings.choose(
        'Kicked on disconnect unless given a role',
        '未被分配权限组的成员会在断开连接后自动移出',
        context: context,
      );
  static String searchInvites({BuildContext? context}) =>
      AppStrings.choose('Search invites', '搜索邀请', context: context);
  static String noActiveInvites({BuildContext? context}) =>
      AppStrings.choose('No active invites', '暂无有效邀请', context: context);
  static String noMatches({BuildContext? context}) =>
      AppStrings.choose('No matches', '无匹配结果', context: context);
  static String copyLink2({BuildContext? context}) =>
      AppStrings.choose('Copy link', '复制链接', context: context);
  static String revoke({BuildContext? context}) =>
      AppStrings.choose('Revoke', '撤销', context: context);
  static String chooseAReasonForThisReport({BuildContext? context}) =>
      AppStrings.choose(
        'Choose a reason for this report.',
        '请选择举报原因。',
        context: context,
      );
  static String failedToSubmitReport({BuildContext? context}) =>
      AppStrings.choose('Failed to submit report', '提交举报失败', context: context);
  static String reportedButBlockingTheAccountFailed({BuildContext? context}) =>
      AppStrings.choose(
        'Reported, but blocking the account failed',
        '举报已提交，但未能屏蔽此账号',
        context: context,
      );
  static String nothingWasSentThisServerOnlyAccepts({
    BuildContext? context,
  }) => AppStrings.choose(
    'Nothing was sent — this server only accepts reports inside a space — and blocking the account failed',
    '此服务器仅接受域内的举报，本次举报未提交，且未能屏蔽此账号',
    context: context,
  );
  static String moderatorsWillReviewItShortly({BuildContext? context}) =>
      AppStrings.choose(
        'Moderators will review it shortly.',
        '版主将尽快处理。',
        context: context,
      );
  static String theMessageIsNowHiddenForYou({BuildContext? context}) =>
      AppStrings.choose(
        'The message is now hidden for you.',
        '此消息已对你隐藏。',
        context: context,
      );
  static String theAccountIsBlockedTheyCanNo({
    BuildContext? context,
  }) => AppStrings.choose(
    'The account is blocked: they can no longer message you, and their messages are hidden.',
    '此账号已被屏蔽，对方无法再向你发送消息，其消息也已隐藏。',
    context: context,
  );
  static String reportSubmitted({BuildContext? context}) =>
      AppStrings.choose('Report submitted', '举报已提交', context: context);
  static String reportNotSent({BuildContext? context}) =>
      AppStrings.choose('Report not sent', '举报未提交', context: context);
  static String thisServerOnlyAcceptsReportsInsideA({
    BuildContext? context,
  }) => AppStrings.choose(
    'This server only accepts reports inside a space, so nothing was sent. You can still block the account to stop it contacting you.',
    '此服务器仅接受域内的举报，因此本次举报未提交。你仍可屏蔽此账号，阻止对方与你联系。',
    context: context,
  );
  static String reportMessage({BuildContext? context}) =>
      AppStrings.choose('Report message', '举报消息', context: context);
  static String reportsGoToThisSpaceSModerators({BuildContext? context}) =>
      AppStrings.choose(
        'Reports go to this space\'s moderators.',
        '举报将交由本域的版主处理。',
        context: context,
      );
  static String reportsOutsideASpaceGoToThe({
    BuildContext? context,
  }) => AppStrings.choose(
    'Reports outside a space go to the server operator. Blocking takes effect immediately.',
    '域以外的举报将交由社区管理员处理。屏蔽会立即生效。',
    context: context,
  );
  static String chooseAReason({BuildContext? context}) =>
      AppStrings.choose('Choose a reason', '选择原因', context: context);
  static String alsoBlock({BuildContext? context, required Object? arg0}) =>
      AppStrings.choose('Also block ${arg0}', '同时屏蔽 ${arg0}', context: context);
  static String theyCanNoLongerMessageYouAnd({
    BuildContext? context,
  }) => AppStrings.choose(
    'They can no longer message you, and their messages are hidden from your view.',
    '对方将无法再给你发送消息，其消息也会对你隐藏。',
    context: context,
  );
  static String submitReport({BuildContext? context}) =>
      AppStrings.choose('Submit report', '提交举报', context: context);
  static String failedToLoad({BuildContext? context}) =>
      AppStrings.choose('Failed to load', '加载失败', context: context);
  static String newRole({BuildContext? context}) =>
      AppStrings.choose('new role', '新权限组', context: context);
  static String failedToCreateRole({BuildContext? context}) =>
      AppStrings.choose('Failed to create role', '创建权限组失败', context: context);
  static String failedToSaveRole({BuildContext? context}) =>
      AppStrings.choose('Failed to save role', '保存权限组失败', context: context);
  static String deleteRole({BuildContext? context}) =>
      AppStrings.choose('Delete role', '删除权限组', context: context);
  static String deleteTheRoleThisCannotBeUndone({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    'Delete the "${arg0}" role? This cannot be undone.',
    '确定删除“${arg0}”权限组？此操作无法撤销。',
    context: context,
  );
  static String failedToDeleteRole({BuildContext? context}) =>
      AppStrings.choose('Failed to delete role', '删除权限组失败', context: context);
  static String failedToReorderRoles({BuildContext? context}) =>
      AppStrings.choose(
        'Failed to reorder roles',
        '调整权限组顺序失败',
        context: context,
      );
  static String selectARoleToEdit({BuildContext? context}) =>
      AppStrings.choose('Select a role to edit', '选择要编辑的权限组', context: context);
  static String roles2({BuildContext? context}) =>
      AppStrings.choose('Roles', '权限组', context: context);
  static String createRole({BuildContext? context}) =>
      AppStrings.choose('Create role', '创建权限组', context: context);
  static String thisRoleIsManagedByAnIntegration({BuildContext? context}) =>
      AppStrings.choose(
        'This role is managed by an integration.',
        '此权限组由集成应用管理。',
        context: context,
      );
  static String thisRoleIsAtOrAboveYour({BuildContext? context}) =>
      AppStrings.choose(
        'This role is at or above your highest role.',
        '此权限组的级别不低于你的最高权限组。',
        context: context,
      );
  static String roleName({BuildContext? context}) =>
      AppStrings.choose('ROLE NAME', '权限组名称', context: context);
  static String color({BuildContext? context}) =>
      AppStrings.choose('COLOR', '颜色', context: context);
  static String displaySeparately({BuildContext? context}) =>
      AppStrings.choose('Display separately', '单独显示', context: context);
  static String showMembersWithThisRoleInTheir({BuildContext? context}) =>
      AppStrings.choose(
        'Show members with this role in their own section',
        '在成员列表中单独列出拥有此权限组的成员',
        context: context,
      );
  static String anyoneCanMentionThisRole({BuildContext? context}) =>
      AppStrings.choose(
        'Anyone can @mention this role',
        '所有人都可以 @提及此权限组',
        context: context,
      );
  static String permissions3({BuildContext? context}) =>
      AppStrings.choose('PERMISSIONS', '权限', context: context);
  static String previewAsRole({BuildContext? context}) =>
      AppStrings.choose('Preview as role', '以此权限组预览', context: context);
  static String saveChanges({BuildContext? context}) =>
      AppStrings.choose('Save changes', '保存更改', context: context);
  static String searchMessagesAndMembers({BuildContext? context}) =>
      AppStrings.choose(
        'Search messages and members',
        '搜索消息和成员',
        context: context,
      );
  static String messages({BuildContext? context}) =>
      AppStrings.choose('Messages', '消息', context: context);
  static String typeToSearchMessages({BuildContext? context}) =>
      AppStrings.choose(
        'Type to search messages',
        '输入关键词搜索消息',
        context: context,
      );
  static String noMessagesFound({BuildContext? context}) =>
      AppStrings.choose('No messages found', '未找到消息', context: context);
  static String typeToSearchMembers({BuildContext? context}) =>
      AppStrings.choose(
        'Type to search members',
        '输入关键词搜索成员',
        context: context,
      );
  static String noMembersFound({BuildContext? context}) =>
      AppStrings.choose('No members found', '未找到成员', context: context);
  static String failedToPlayJoinAVoiceChannel({BuildContext? context}) =>
      AppStrings.choose(
        'Failed to play (join a voice channel first)',
        '播放失败，请先加入语音频道',
        context: context,
      );
  static String failedToAddSound({BuildContext? context}) =>
      AppStrings.choose('Failed to add sound', '添加音效失败', context: context);
  static String renameSound({BuildContext? context}) =>
      AppStrings.choose('Rename sound', '重命名音效', context: context);
  static String failedToRenameSound({BuildContext? context}) =>
      AppStrings.choose('Failed to rename sound', '重命名音效失败', context: context);
  static String failedToSetVolume({BuildContext? context}) =>
      AppStrings.choose('Failed to set volume', '设置音量失败', context: context);
  static String failedToRemoveSound({BuildContext? context}) =>
      AppStrings.choose('Failed to remove sound', '移除音效失败', context: context);
  static String soundboard({BuildContext? context}) =>
      AppStrings.choose('Soundboard', '音效面板', context: context);
  static String addSound({BuildContext? context}) =>
      AppStrings.choose('Add sound', '添加音效', context: context);
  static String searchSounds({BuildContext? context}) =>
      AppStrings.choose('Search sounds', '搜索音效', context: context);
  static String noSoundsYet({BuildContext? context}) =>
      AppStrings.choose('No sounds yet', '暂无音效', context: context);
  static String manage({BuildContext? context}) =>
      AppStrings.choose('Manage', '管理', context: context);
  static String soundVolume({BuildContext? context}) =>
      AppStrings.choose('Sound volume', '音效音量', context: context);
  static String cropBanner({BuildContext? context}) =>
      AppStrings.choose('Crop banner', '裁剪横幅', context: context);
  static String failedToUpdateBanner({BuildContext? context}) =>
      AppStrings.choose('Failed to update banner', '更新横幅失败', context: context);
  static String failedToRemoveBanner({BuildContext? context}) =>
      AppStrings.choose('Failed to remove banner', '移除横幅失败', context: context);
  static String cropIcon({BuildContext? context}) =>
      AppStrings.choose('Crop icon', '裁剪图标', context: context);
  static String thisPermanentlyDeletesAndAllOfIts({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    'This permanently deletes "${arg0}" and all of its channels and messages. This cannot be undone.',
    '将永久删除“${arg0}”及其中的所有频道和消息。此操作无法撤销。',
    context: context,
  );
  static String typeTheSpaceNameToConfirm({BuildContext? context}) =>
      AppStrings.choose(
        'Type the space name to confirm',
        '输入域名称以确认',
        context: context,
      );
  static String leaveEmptyToResetToYourDisplay({BuildContext? context}) =>
      AppStrings.choose(
        'Leave empty to reset to your display name',
        '留空即可恢复为你的显示名称',
        context: context,
      );
  static String attachmentRulesAndModerationReview({BuildContext? context}) =>
      AppStrings.choose(
        'Attachment rules and moderation review',
        '附件规则与内容审核',
        context: context,
      );
  static String banner({BuildContext? context}) =>
      AppStrings.choose('Banner', '横幅', context: context);
  static String change({BuildContext? context}) =>
      AppStrings.choose('Change', '更换', context: context);
  static String upload({BuildContext? context}) =>
      AppStrings.choose('Upload', '上传', context: context);
  static String youNeedManageSpaceToEditThe({BuildContext? context}) =>
      AppStrings.choose(
        'You need Manage Space to edit the banner.',
        '编辑横幅需要“管理域”权限。',
        context: context,
      );
  static String overview({BuildContext? context}) =>
      AppStrings.choose('Overview', '概览', context: context);
  static String description({BuildContext? context}) =>
      AppStrings.choose('Description', '简介', context: context);
  static String moderation({BuildContext? context}) =>
      AppStrings.choose('Moderation', '内容管理', context: context);
  static String verificationLevel({BuildContext? context}) =>
      AppStrings.choose('Verification level', '验证等级', context: context);
  static String defaultNotifications({BuildContext? context}) =>
      AppStrings.choose('Default notifications', '默认通知', context: context);
  static String nsfwLevel({BuildContext? context}) =>
      AppStrings.choose('NSFW level', '年龄限制等级', context: context);
  static String explicitContentFilter({BuildContext? context}) =>
      AppStrings.choose('Explicit content filter', '成人内容过滤', context: context);
  static String publicSpace({BuildContext? context}) =>
      AppStrings.choose('Public domain', '公开域', context: context);
  static String discoverableAndJoinableByAnyone({BuildContext? context}) =>
      AppStrings.choose(
        'Discoverable and joinable by anyone',
        '所有人都可以发现并加入',
        context: context,
      );
  static String allowGuestAccess({BuildContext? context}) =>
      AppStrings.choose('Allow guest access', '允许访客访问', context: context);
  static String letUnauthenticatedUsersBrowse({BuildContext? context}) =>
      AppStrings.choose(
        'Let unauthenticated users browse',
        '未登录用户也可以浏览',
        context: context,
      );
  static String rulesChannel({BuildContext? context}) =>
      AppStrings.choose('Rules channel', '规则频道', context: context);
  static String systemMessagesChannel({BuildContext? context}) =>
      AppStrings.choose('System messages channel', '系统消息频道', context: context);
  static String membership({BuildContext? context}) =>
      AppStrings.choose('Membership', '成员身份', context: context);
  static String changeYourNickname({BuildContext? context}) =>
      AppStrings.choose('Change your nickname', '修改你的昵称', context: context);
  static String howYouAppearInThisSpace({BuildContext? context}) =>
      AppStrings.choose(
        'How you appear in this space',
        '你在此域中显示的名称',
        context: context,
      );
  static String management({BuildContext? context}) =>
      AppStrings.choose('Management', '管理', context: context);
  static String createEditAndOrderRoles({BuildContext? context}) =>
      AppStrings.choose(
        'Create, edit, and order roles',
        '创建、编辑权限组并调整顺序',
        context: context,
      );
  static String recentModerationAndAdminActions({BuildContext? context}) =>
      AppStrings.choose(
        'Recent moderation and admin actions',
        '最近的内容审核与管理操作',
        context: context,
      );
  static String reviewAndUnbanMembers({BuildContext? context}) =>
      AppStrings.choose(
        'Review and unban members',
        '查看封禁记录并解除封禁',
        context: context,
      );
  static String reviewAndResolveMemberReports({BuildContext? context}) =>
      AppStrings.choose(
        'Review and resolve member reports',
        '查看并处理成员举报',
        context: context,
      );
  static String uploadRenameAndDeleteEmoji({BuildContext? context}) =>
      AppStrings.choose(
        'Upload, rename, and delete emoji',
        '上传、重命名和删除表情',
        context: context,
      );
  static String playAndManageSoundboardClips({BuildContext? context}) =>
      AppStrings.choose(
        'Play and manage soundboard clips',
        '播放和管理音效',
        context: context,
      );
  static String dangerZone({BuildContext? context}) =>
      AppStrings.choose('Danger zone', '危险操作', context: context);
  static String transferOwnership({BuildContext? context}) =>
      AppStrings.choose('Transfer domain ownership', '转让域主身份', context: context);
  static String handThisSpaceToAnotherMember({BuildContext? context}) =>
      AppStrings.choose(
        'Hand this space to another member',
        '将此域转让给其他成员',
        context: context,
      );
  static String permanentlyRemoveThisSpace({BuildContext? context}) =>
      AppStrings.choose(
        'Permanently remove this space',
        '永久删除此域',
        context: context,
      );
  static String theNewOwnerGainsFullControlYou({BuildContext? context}) =>
      AppStrings.choose(
        'The new owner gains full control. You cannot undo this.',
        '新域主将获得该域的完整控制权。此操作无法撤销。',
        context: context,
      );
  static String noOtherMembersToTransferTo({BuildContext? context}) =>
      AppStrings.choose(
        'No other members to transfer to.',
        '没有可接受转让的其他成员。',
        context: context,
      );
  static String typeTransferToConfirm({BuildContext? context}) =>
      AppStrings.choose(
        'Type TRANSFER to confirm',
        '输入 TRANSFER 以确认',
        context: context,
      );
  static String createChannel2({BuildContext? context}) =>
      AppStrings.choose('Create domain', '创建域', context: context);
  static String previewingAsPermissionsShownAreThisRole({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    'Previewing as “${arg0}” — permissions shown are this role’s.',
    '正在以“${arg0}”预览，当前显示的是此权限组的权限。',
    context: context,
  );
  static String exitPreview({BuildContext? context}) =>
      AppStrings.choose('Exit preview', '退出预览', context: context);
  static String whatSNewInV({BuildContext? context, required Object? arg0}) =>
      AppStrings.choose(
        'What\'s new in v${arg0}',
        'v${arg0} 更新内容',
        context: context,
      );
  static String viewOnGithub({BuildContext? context}) =>
      AppStrings.choose('View on GitHub', '在 GitHub 上查看', context: context);
  static String gotIt({BuildContext? context}) =>
      AppStrings.choose('Got it', '知道了', context: context);
  static String noReleaseNotesPublishedForV({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    'No release notes published for v${arg0}.',
    'v${arg0} 暂未发布更新说明。',
    context: context,
  );
  static String currentVersion2({BuildContext? context}) =>
      AppStrings.choose('Current version', '当前版本', context: context);
  static String whatSNewInThisVersion({BuildContext? context}) =>
      AppStrings.choose(
        'What\'s new in this version',
        '本次更新内容',
        context: context,
      );
  static String releaseNotesForTheBuildYouRe({BuildContext? context}) =>
      AppStrings.choose(
        'Release notes for the build you\'re running',
        '查看当前版本的更新说明',
        context: context,
      );
  static String updatesAreDeliveredThroughYourPackageManager({
    BuildContext? context,
  }) => AppStrings.choose(
    'Updates are delivered through your package manager.',
    '请通过软件包管理器更新此应用。',
    context: context,
  );
  static String updatesAreDeliveredThroughTheAppStore({
    BuildContext? context,
  }) => AppStrings.choose(
    'Updates are delivered through the app store.',
    '请通过应用商店更新此应用。',
    context: context,
  );
  static String checkForUpdatesOnStartup({BuildContext? context}) =>
      AppStrings.choose(
        'Check for updates on startup',
        '启动时检查更新',
        context: context,
      );
  static String checking({BuildContext? context}) =>
      AppStrings.choose('Checking…', '正在检查…', context: context);
  static String checkForUpdates({BuildContext? context}) =>
      AppStrings.choose('Check for updates', '检查更新', context: context);
  static String youReUpToDate({BuildContext? context}) =>
      AppStrings.choose('You\'re up to date.', '已是最新版本。', context: context);
  static String updateAvailable({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    'Update available: ${arg0}',
    '发现新版本：${arg0}',
    context: context,
  );
  static String viewRelease({BuildContext? context}) =>
      AppStrings.choose('View release', '查看版本详情', context: context);
  static String skipThisVersion({BuildContext? context}) =>
      AppStrings.choose('Skip this version', '跳过此版本', context: context);
  static String onTheWebRefreshThePageTo({BuildContext? context}) =>
      AppStrings.choose(
        'On the web, refresh the page to load the latest version.',
        '网页版可通过刷新页面加载最新版本。',
        context: context,
      );
  static String downloading({BuildContext? context}) =>
      AppStrings.choose('Downloading…', '正在下载…', context: context);
  static String verifying({BuildContext? context}) =>
      AppStrings.choose('Verifying…', '正在校验…', context: context);
  static String restartInstall({BuildContext? context}) =>
      AppStrings.choose('Restart & install', '重启并安装', context: context);
  static String installing({BuildContext? context}) =>
      AppStrings.choose('Installing…', '正在安装…', context: context);
  static String retryUpdate({BuildContext? context}) =>
      AppStrings.choose('Retry update', '重试更新', context: context);
  static String downloadInstall({BuildContext? context}) =>
      AppStrings.choose('Download & install', '下载并安装', context: context);
  static String tapToInstallAdminRequired({BuildContext? context}) =>
      AppStrings.choose(
        'Tap to install (admin required).',
        '点击安装（需要管理员权限）。',
        context: context,
      );
  static String tapToRestartInstall({BuildContext? context}) =>
      AppStrings.choose(
        'Tap to restart & install.',
        '点击重启并安装。',
        context: context,
      );
  static String updateReady({
    BuildContext? context,
    required Object? arg0,
    required Object? arg1,
  }) => AppStrings.choose(
    'Update ready — ${arg0}. ${arg1}',
    '更新已就绪 · ${arg0}。${arg1}',
    context: context,
  );
  static String updateAvailableTapToView({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    'Update available — ${arg0}. Tap to view.',
    '发现新版本 · ${arg0}。点击查看。',
    context: context,
  );
  static String aNewVersionIsAvailableReloadTo({BuildContext? context}) =>
      AppStrings.choose(
        'A new version is available — reload to update.',
        '发现新版本，重新加载即可更新。',
        context: context,
      );
  static String reload({BuildContext? context}) =>
      AppStrings.choose('Reload', '重新加载', context: context);
  static String passwordSecurity({BuildContext? context}) =>
      AppStrings.choose('Password & Security', '密码与安全', context: context);
  static String password({BuildContext? context}) =>
      AppStrings.choose('PASSWORD', '密码', context: context);
  static String twoFactorAuthentication2({BuildContext? context}) =>
      AppStrings.choose('TWO-FACTOR AUTHENTICATION', '两步验证', context: context);
  static String dangerZone2({BuildContext? context}) =>
      AppStrings.choose('DANGER ZONE', '危险操作', context: context);
  static String passwordIsRequired({BuildContext? context}) =>
      AppStrings.choose('Password is required', '请输入密码', context: context);
  static String typeDeleteToConfirm({BuildContext? context}) =>
      AppStrings.choose(
        'Type DELETE to confirm',
        '输入 DELETE 以确认',
        context: context,
      );
  static String failedToDeleteAccount({BuildContext? context}) =>
      AppStrings.choose('Failed to delete account', '注销账号失败', context: context);
  static String permanentlyDeletesYourAccountOnThisServer({
    BuildContext? context,
  }) => AppStrings.choose(
    'Permanently deletes your account on this server, including your profile, messages, and memberships. This cannot be undone.',
    '将永久注销你在此服务器上的账号，并删除个人资料、消息及域成员身份。此操作无法撤销。',
    context: context,
  );
  static String password2({BuildContext? context}) =>
      AppStrings.choose('Password', '密码', context: context);
  static String deleteMyAccount({BuildContext? context}) =>
      AppStrings.choose('Delete my account', '注销我的账号', context: context);
  static String enterYourCurrentPasswordAndANew({BuildContext? context}) =>
      AppStrings.choose(
        'Enter your current password and a new one (8–128 characters)',
        '请输入当前密码和新密码（8–128 个字符）',
        context: context,
      );
  static String passwordUpdated({BuildContext? context}) =>
      AppStrings.choose('Password updated', '密码已更新', context: context);
  static String failedToChangePassword({BuildContext? context}) =>
      AppStrings.choose(
        'Failed to change password',
        '修改密码失败',
        context: context,
      );
  static String changePassword2({BuildContext? context}) =>
      AppStrings.choose('Change password', '修改密码', context: context);
  static String enterYourPassword({BuildContext? context}) =>
      AppStrings.choose('Enter your password', '请输入密码', context: context);
  static String failedToStart2faSetup({BuildContext? context}) =>
      AppStrings.choose(
        'Failed to start 2FA setup',
        '无法开始设置两步验证',
        context: context,
      );
  static String enterThe6DigitCode({BuildContext? context}) =>
      AppStrings.choose(
        'Enter the 6-digit code',
        '请输入 6 位验证码',
        context: context,
      );
  static String invalidCode({BuildContext? context}) =>
      AppStrings.choose('Invalid code', '验证码无效', context: context);
  static String enterYourPasswordToDisable2fa({BuildContext? context}) =>
      AppStrings.choose(
        'Enter your password to disable 2FA',
        '请输入密码以关闭两步验证',
        context: context,
      );
  static String failedToDisable2fa({BuildContext? context}) =>
      AppStrings.choose('Failed to disable 2FA', '关闭两步验证失败', context: context);
  static String message2faIsNowEnabledSaveTheseBackup({
    BuildContext? context,
  }) => AppStrings.choose(
    '2FA is now enabled. Save these backup codes:',
    '两步验证已启用，请妥善保存以下备用验证码：',
    context: context,
  );
  static String copyCodes({BuildContext? context}) =>
      AppStrings.choose('Copy codes', '复制备用验证码', context: context);
  static String message2faIsEnabled({BuildContext? context}) =>
      AppStrings.choose('2FA is enabled', '两步验证已启用', context: context);
  static String protectYourAccountWithAnAuthenticatorApp({
    BuildContext? context,
  }) => AppStrings.choose(
    'Protect your account with an authenticator app.',
    '使用身份验证器进一步保护账号安全。',
    context: context,
  );
  static String scanThisQrCodeWithYourAuthenticator({
    BuildContext? context,
  }) => AppStrings.choose(
    'Scan this QR code with your authenticator app, or enter the secret manually, then type the 6-digit code:',
    '使用身份验证器扫描二维码，或手动输入密钥，然后填写生成的 6 位验证码：',
    context: context,
  );
  static String copySecret({BuildContext? context}) =>
      AppStrings.choose('Copy secret', '复制密钥', context: context);
  static String verifyActivate({BuildContext? context}) =>
      AppStrings.choose('Verify & activate', '验证并启用', context: context);
  static String directMessage2({BuildContext? context}) =>
      AppStrings.choose('Direct message', '发送私信', context: context);
  static String failedToOpenDirectMessage({BuildContext? context}) =>
      AppStrings.choose(
        'Failed to open direct message',
        '打开私信失败',
        context: context,
      );
  static String viewProfile2({BuildContext? context}) =>
      AppStrings.choose('View profile', '查看资料', context: context);
  static String removeFriend({BuildContext? context}) =>
      AppStrings.choose('Remove friend', '删除好友', context: context);
  static String acceptFriendRequest({BuildContext? context}) =>
      AppStrings.choose('Accept friend request', '接受好友申请', context: context);
  static String cancelFriendRequest({BuildContext? context}) =>
      AppStrings.choose('Cancel friend request', '撤回好友申请', context: context);
  static String addFriend({BuildContext? context}) =>
      AppStrings.choose('Add friend', '添加好友', context: context);
  static String copyUserId2({BuildContext? context}) =>
      AppStrings.choose('Copy user ID', '复制用户 ID', context: context);
  static String copyUsername2({BuildContext? context}) =>
      AppStrings.choose('Copy username', '复制用户名', context: context);
  static String friendRemoved({BuildContext? context}) =>
      AppStrings.choose('Friend removed', '已删除好友', context: context);
  static String userUnblocked({BuildContext? context}) =>
      AppStrings.choose('User unblocked', '已解除用户屏蔽', context: context);
  static String friendRequestAccepted({BuildContext? context}) =>
      AppStrings.choose('Friend request accepted', '已接受好友申请', context: context);
  static String friendRequestCancelled({BuildContext? context}) =>
      AppStrings.choose(
        'Friend request cancelled',
        '已撤回好友申请',
        context: context,
      );
  static String friendRequestSent({BuildContext? context}) =>
      AppStrings.choose('Friend request sent', '好友申请已发送', context: context);
  static String failedToUpdateRelationship({BuildContext? context}) =>
      AppStrings.choose(
        'Failed to update relationship',
        '更新好友关系失败',
        context: context,
      );
  static String blockedUsersCannotDmYouAndTheir({BuildContext? context}) =>
      AppStrings.choose(
        'Blocked users cannot DM you and their messages are hidden.',
        '屏蔽后，对方将无法给你发送私信，其消息也会被隐藏。',
        context: context,
      );
  static String userBlocked({BuildContext? context}) =>
      AppStrings.choose('User blocked', '已屏蔽用户', context: context);
  static String friends({BuildContext? context}) =>
      AppStrings.choose('Friends', '好友', context: context);
  static String leaveGroup({BuildContext? context}) =>
      AppStrings.choose('Leave group', '退出群聊', context: context);
  static String closeDirectMessage({BuildContext? context}) =>
      AppStrings.choose('Close direct message', '关闭私信', context: context);
  static String leaveYouCanBeReAddedLater({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    'Leave ${arg0}? You can be re-added later.',
    '确定退出 ${arg0}？退出后仍可被重新邀请加入。',
    context: context,
  );
  static String removeThisConversationFromYourDirectMessage({
    BuildContext? context,
  }) => AppStrings.choose(
    'Remove this conversation from your direct-message list? Its history is retained if you message this user again.',
    '从私信列表中移除此会话？再次向对方发送消息时，仍可查看历史记录。',
    context: context,
  );
  static String failedToLeaveGroup({BuildContext? context}) =>
      AppStrings.choose('Failed to leave group', '退出群聊失败', context: context);
  static String failedToCloseConversation({BuildContext? context}) =>
      AppStrings.choose(
        'Failed to close conversation',
        '关闭会话失败',
        context: context,
      );
  static String searchConversations({BuildContext? context}) =>
      AppStrings.choose('Search conversations', '搜索会话', context: context);
  static String newGroup({BuildContext? context}) =>
      AppStrings.choose('New group', '新建群聊', context: context);
  static String messageRemoteUser({BuildContext? context}) =>
      AppStrings.choose('Message remote user', '向跨服用户发私信', context: context);
  static String noDirectMessagesYet({BuildContext? context}) =>
      AppStrings.choose('No direct messages yet', '暂无私信', context: context);
  static String noMatchingConversations({BuildContext? context}) =>
      AppStrings.choose(
        'No matching conversations',
        '未找到匹配的会话',
        context: context,
      );
  static String addToGroup({BuildContext? context}) =>
      AppStrings.choose('Add to group', '添加到群聊', context: context);
  static String failedToAddMember({BuildContext? context}) =>
      AppStrings.choose('Failed to add member', '添加成员失败', context: context);
  static String removeMember({BuildContext? context}) =>
      AppStrings.choose('Remove member', '移出成员', context: context);
  static String removeFromThisGroup({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    'Remove ${arg0} from this group?',
    '将 ${arg0} 移出此群聊？',
    context: context,
  );
  static String failedToRemoveMember({BuildContext? context}) =>
      AppStrings.choose('Failed to remove member', '移出成员失败', context: context);
  static String renameGroup({BuildContext? context}) =>
      AppStrings.choose('Rename group', '重命名群聊', context: context);
  static String groupName({BuildContext? context}) =>
      AppStrings.choose('Group name', '群聊名称', context: context);
  static String failedToRenameGroup({BuildContext? context}) =>
      AppStrings.choose('Failed to rename group', '重命名群聊失败', context: context);
  static String leaveThisGroupYouCanBeRe({BuildContext? context}) =>
      AppStrings.choose(
        'Leave this group? You can be re-added later.',
        '确定退出此群聊？退出后仍可被重新邀请加入。',
        context: context,
      );
  static String startVoiceCall({BuildContext? context}) =>
      AppStrings.choose('Start voice call', '发起语音通话', context: context);
  static String startVideoCall({BuildContext? context}) =>
      AppStrings.choose('Start video call', '发起视频通话', context: context);
  static String conversationOptions({BuildContext? context}) =>
      AppStrings.choose('Conversation options', '会话选项', context: context);
  static String groupOptions({BuildContext? context}) =>
      AppStrings.choose('Group options', '群聊选项', context: context);
  static String viewMembers({BuildContext? context}) =>
      AppStrings.choose('View members', '查看成员', context: context);
  static String addMember2({BuildContext? context}) =>
      AppStrings.choose('Add member', '添加成员', context: context);
  static String enterAQualifiedHandleEG123({BuildContext? context}) =>
      AppStrings.choose(
        'Enter a qualified handle, e.g. 123@server.example',
        '请输入完整用户标识，例如 123@server.example',
        context: context,
      );
  static String messageARemoteUser({BuildContext? context}) =>
      AppStrings.choose('Message a remote user', '向跨服用户发送消息', context: context);
  static String enterTheUserSQualifiedHandleOn({BuildContext? context}) =>
      AppStrings.choose(
        'Enter the user\'s qualified handle on their home server.',
        '请输入对方在所属服务器上的完整用户标识。',
        context: context,
      );
  static String couldNotAcceptThatFriendRequest({BuildContext? context}) =>
      AppStrings.choose(
        'Could not accept that friend request.',
        '无法接受此好友申请。',
        context: context,
      );
  static String couldNotRemoveThatRelationship({BuildContext? context}) =>
      AppStrings.choose(
        'Could not remove that relationship.',
        '无法删除此好友关系。',
        context: context,
      );
  static String couldNotBlockThatUser({BuildContext? context}) =>
      AppStrings.choose(
        'Could not block that user.',
        '无法屏蔽此用户。',
        context: context,
      );
  static String incomingRequests({BuildContext? context}) =>
      AppStrings.choose('Incoming requests', '收到的申请', context: context);
  static String accept({BuildContext? context}) =>
      AppStrings.choose('Accept', '接受', context: context);
  static String decline({BuildContext? context}) =>
      AppStrings.choose('Decline', '拒绝', context: context);
  static String outgoingRequests({BuildContext? context}) =>
      AppStrings.choose('Outgoing requests', '已发送的申请', context: context);
  static String blocked({BuildContext? context}) =>
      AppStrings.choose('Blocked', '已屏蔽', context: context);
  static String noFriendsYet({BuildContext? context}) =>
      AppStrings.choose('No friends yet', '暂无好友', context: context);
  static String friendRequestSentTo({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    'Friend request sent to ${arg0}',
    '已向 ${arg0} 发送好友申请',
    context: context,
  );
  static String failedToSendRequest({BuildContext? context}) =>
      AppStrings.choose('Failed to send request', '发送申请失败', context: context);
  static String sendRequest({BuildContext? context}) =>
      AppStrings.choose('Send request', '发送申请', context: context);
  static String failedToCreateGroup({BuildContext? context}) =>
      AppStrings.choose('Failed to create group', '创建群聊失败', context: context);
  static String groupNameOptional({BuildContext? context}) =>
      AppStrings.choose('Group name (optional)', '群聊名称（可选）', context: context);
  static String searchUsersToAdd({BuildContext? context}) =>
      AppStrings.choose('Search users to add', '搜索并添加用户', context: context);
  static String noOtherMembers({BuildContext? context}) =>
      AppStrings.choose('No other members', '没有其他成员', context: context);
  static String removeFromGroup({BuildContext? context}) =>
      AppStrings.choose('Remove from group', '移出群聊', context: context);
  static String noUsersFound2({BuildContext? context}) =>
      AppStrings.choose('No users found', '未找到用户', context: context);
  static String cropAvatar({BuildContext? context}) =>
      AppStrings.choose('Crop avatar', '裁剪头像', context: context);
  static String failedToSaveProfile({BuildContext? context}) =>
      AppStrings.choose('Failed to save profile', '保存资料失败', context: context);
  static String editProfile({BuildContext? context}) =>
      AppStrings.choose('Edit profile', '编辑资料', context: context);
  static String editProfile2({BuildContext? context, required Object? arg0}) =>
      AppStrings.choose(
        'Edit profile · ${arg0}',
        '编辑资料 · ${arg0}',
        context: context,
      );
  static String changeAvatar({BuildContext? context}) =>
      AppStrings.choose('Change avatar', '更换头像', context: context);
  static String displayName({BuildContext? context}) =>
      AppStrings.choose('Display name', '显示名称', context: context);
  static String bio({BuildContext? context}) =>
      AppStrings.choose('Bio', '个人简介', context: context);
  static String aShortBioShownOnYourProfile({BuildContext? context}) =>
      AppStrings.choose(
        'A short bio shown on your profile',
        '在个人资料中展示的简短介绍',
        context: context,
      );
  static String avatarBackground({BuildContext? context}) =>
      AppStrings.choose('Avatar background', '头像背景', context: context);
  static String setCustomStatus({BuildContext? context}) =>
      AppStrings.choose('Set custom status', '设置自定义状态', context: context);
  static String editStatus({BuildContext? context}) =>
      AppStrings.choose('Edit status', '编辑状态', context: context);
  static String clearCustomStatus({BuildContext? context}) =>
      AppStrings.choose('Clear custom status', '清除自定义状态', context: context);
  static String emoji({BuildContext? context}) =>
      AppStrings.choose('Emoji', '表情', context: context);
  static String status({BuildContext? context}) =>
      AppStrings.choose('Status', '状态', context: context);
  static String whatSOnYourMind({BuildContext? context}) =>
      AppStrings.choose('What\'s on your mind?', '分享此刻的心情…', context: context);
  static String off({BuildContext? context}) =>
      AppStrings.choose('Off', '关闭', context: context);
  static String minutes({BuildContext? context, required Object? arg0}) =>
      AppStrings.choose('${arg0} minutes', '${arg0} 分钟', context: context);
  static String microphoneUnavailable({BuildContext? context}) =>
      AppStrings.choose('Microphone unavailable', '麦克风不可用', context: context);
  static String microphoneUnavailable2({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    'Microphone unavailable: ${arg0}',
    '麦克风不可用：${arg0}',
    context: context,
  );
  static String incomingVideoCall({BuildContext? context}) =>
      AppStrings.choose('Incoming video call', '视频来电', context: context);
  static String incomingCall({BuildContext? context}) =>
      AppStrings.choose('Incoming call', '来电', context: context);
  static String groupCall({BuildContext? context}) =>
      AppStrings.choose('Group call', '群组通话', context: context);
  static String call({BuildContext? context}) =>
      AppStrings.choose('Call', '通话', context: context);
  static String chooseWhatToShare({BuildContext? context}) =>
      AppStrings.choose('Choose what to share', '选择共享内容', context: context);
  static String entireScreen({BuildContext? context}) =>
      AppStrings.choose('Entire Screen', '整个屏幕', context: context);
  static String window({BuildContext? context}) =>
      AppStrings.choose('Window', '窗口', context: context);
  static String noSourcesAvailable({BuildContext? context}) =>
      AppStrings.choose('No sources available', '暂无可共享的内容', context: context);
  static String away({BuildContext? context}) =>
      AppStrings.choose('Away', '暂离', context: context);
  static String voiceVideo({BuildContext? context}) =>
      AppStrings.choose('Voice & Video', '语音与视频', context: context);
  static String relayOnlyVoice({BuildContext? context}) =>
      AppStrings.choose('Relay-only voice', '仅通过中继连接语音', context: context);
  static String routeVoiceVideoAndScreenSharingThrough({
    BuildContext? context,
  }) => AppStrings.choose(
    'Route voice, video and screen sharing through a TURN relay. Requires server support and may increase latency. Applies on your next connection; leave and rejoin to apply now.',
    '语音、视频和屏幕共享均通过 TURN 中继传输，需要服务器支持，可能增加延迟。下次连接时生效；如需立即应用，请退出语音频道后重新加入。',
    context: context,
  );
  static String inputDevice({BuildContext? context}) =>
      AppStrings.choose('Input device', '输入设备', context: context);
  static String microphone({BuildContext? context}) =>
      AppStrings.choose('Microphone', '麦克风', context: context);
  static String inputVolume({BuildContext? context}) =>
      AppStrings.choose('Input volume', '输入音量', context: context);
  static String micTest({BuildContext? context}) =>
      AppStrings.choose('Mic test', '麦克风测试', context: context);
  static String speakTheBarLightsUpGreenWhen({
    BuildContext? context,
  }) => AppStrings.choose(
    'Speak — the bar lights up green when you cross the threshold (yellow marker).',
    '试着说几句话。音量超过黄色标记所示的阈值时，指示条会变为绿色。',
    context: context,
  );
  static String joinAVoiceChannelToTestYour({BuildContext? context}) =>
      AppStrings.choose(
        'Join a voice channel to test your microphone.',
        '加入语音频道后即可测试麦克风。',
        context: context,
      );
  static String inputSensitivity({BuildContext? context}) =>
      AppStrings.choose('Input sensitivity', '输入灵敏度', context: context);
  static String outputDevice({BuildContext? context}) =>
      AppStrings.choose('Output device', '输出设备', context: context);
  static String speaker({BuildContext? context}) =>
      AppStrings.choose('Speaker', '扬声器', context: context);
  static String outputVolume({BuildContext? context}) =>
      AppStrings.choose('Output volume', '输出音量', context: context);
  static String markMeAwayAfter({BuildContext? context}) =>
      AppStrings.choose('Mark me away after', '自动标记暂离的时间', context: context);
  static String whileInAVoiceChannelWithNo({
    BuildContext? context,
  }) => AppStrings.choose(
    'While in a voice channel, with no input, mic activity or window focus. Shown to other members as an idle status.',
    '在语音频道中，持续没有键鼠输入、麦克风活动，且窗口失去焦点后生效。其他成员会看到你的暂离状态。',
    context: context,
  );
  static String moveMeToTheAfkChannel({BuildContext? context}) =>
      AppStrings.choose(
        'Move me to the AFK channel',
        '自动移入挂机频道',
        context: context,
      );
  static String whenTheSpaceHasOneSetYou({
    BuildContext? context,
  }) => AppStrings.choose(
    'When the space has one set. You\'ll be moved back by rejoining the channel you want.',
    '仅在域设置了挂机频道时生效。需要返回时，请重新加入想去的频道。',
    context: context,
  );
  static String camera({BuildContext? context}) =>
      AppStrings.choose('Camera', '摄像头', context: context);
  static String qualityOfYourWebcamWhenYouTurn({BuildContext? context}) =>
      AppStrings.choose(
        'Quality of your webcam when you turn on video.',
        '设置开启视频时的摄像头画质。',
        context: context,
      );
  static String cameraResolution({BuildContext? context}) =>
      AppStrings.choose('Camera resolution', '摄像头分辨率', context: context);
  static String cameraFrameRate({BuildContext? context}) =>
      AppStrings.choose('Camera frame rate', '摄像头帧率', context: context);
  static String fps({BuildContext? context, required Object? arg0}) =>
      AppStrings.choose('${arg0} fps', '${arg0} 帧/秒', context: context);
  static String screenShare({BuildContext? context}) =>
      AppStrings.choose('Screen share', '屏幕共享', context: context);
  static String separateFromTheCameraSettingsAboveThese({
    BuildContext? context,
  }) => AppStrings.choose(
    'Separate from the camera settings above — these apply when you share a screen or window.',
    '仅用于共享屏幕或窗口，与上方的摄像头设置相互独立。',
    context: context,
  );
  static String screenShareResolution({BuildContext? context}) =>
      AppStrings.choose('Screen share resolution', '屏幕共享分辨率', context: context);
  static String higherResolutionsNeedMoreUploadAndCpu({
    BuildContext? context,
  }) => AppStrings.choose(
    'Higher resolutions need more upload and CPU.',
    '分辨率越高，对上传带宽和处理器的要求越高。',
    context: context,
  );
  static String screenShareFrameRate({BuildContext? context}) =>
      AppStrings.choose('Screen share frame rate', '屏幕共享帧率', context: context);
  static String message60FpsForGamesAndVideo30({BuildContext? context}) =>
      AppStrings.choose(
        '60 fps for games and video; 30 or 15 is plenty for slides.',
        '游戏和视频推荐 60 帧/秒；演示文稿通常使用 30 或 15 帧/秒即可。',
        context: context,
      );
  static String prioritiseSmoothMotion({BuildContext? context}) =>
      AppStrings.choose(
        'Prioritise smooth motion',
        '优先保证流畅度',
        context: context,
      );
  static String keepsTheFrameRateUpOnA({
    BuildContext? context,
  }) => AppStrings.choose(
    'Keeps the frame rate up on a slow connection by softening the picture. Turn off to keep text sharp instead.',
    '网络较慢时降低画面清晰度，尽量保持帧率。关闭此项可优先保证文字清晰。',
    context: context,
  );
  static String systemDefault({BuildContext? context}) =>
      AppStrings.choose('System default', '系统默认', context: context);
  static String hideChat({BuildContext? context}) =>
      AppStrings.choose('Hide chat', '隐藏聊天', context: context);
  static String showChat({BuildContext? context}) =>
      AppStrings.choose('Show chat', '显示聊天', context: context);
  static String exitFullScreen({BuildContext? context}) =>
      AppStrings.choose('Exit full screen', '退出全屏', context: context);
  static String fullScreen({BuildContext? context}) =>
      AppStrings.choose('Full screen', '全屏', context: context);
  static String calling({BuildContext? context}) =>
      AppStrings.choose('Calling…', '正在呼叫…', context: context);
  static String connecting({BuildContext? context}) =>
      AppStrings.choose('Connecting…', '正在连接…', context: context);
  static String couldNotCropThisImageTryAnother({BuildContext? context}) =>
      AppStrings.choose(
        'Could not crop this image. Try another image.',
        '无法裁剪此图片，请尝试其他图片。',
        context: context,
      );
  static String couldNotPrepareThisImageTryAnother({BuildContext? context}) =>
      AppStrings.choose(
        'Could not prepare this image. Try another image.',
        '无法处理此图片，请尝试其他图片。',
        context: context,
      );
  static String dragToRepositionScrollOrPinchTo({BuildContext? context}) =>
      AppStrings.choose(
        'Drag to reposition · scroll or pinch to zoom',
        '拖动以调整位置，滚动鼠标或双指缩放',
        context: context,
      );
  static String apply({BuildContext? context}) =>
      AppStrings.choose('Apply', '应用', context: context);
  static String loadMore({BuildContext? context}) =>
      AppStrings.choose('Load more', '加载更多', context: context);
  static String deleteMsg({BuildContext? context}) =>
      AppStrings.choose('Delete msg', '删除消息', context: context);
  static String ban({BuildContext? context}) =>
      AppStrings.choose('Ban', '封禁', context: context);
  static String resolve({BuildContext? context}) =>
      AppStrings.choose('Resolve', '处理', context: context);
  static String vokuszTalksToAccordServersAndAnyone({
    BuildContext? context,
  }) => AppStrings.choose(
    'Vokusz talks to Accord servers, and anyone can run one. Your community keeps its own accounts, messages, uploads and voice traffic — this app never proxies them.',
    'Vokusz 连接 Accord 服务器，任何人都可以自行搭建。域的账号、消息、上传文件和语音流量均由自己的服务器处理，本应用不会代理这些数据。',
    context: context,
  );
  static String theAccordDesktopApp({BuildContext? context}) =>
      AppStrings.choose(
        'The Accord desktop app',
        'Accord 桌面服务端',
        context: context,
      );
  static String aTrayAppForWindowsMacosAnd({
    BuildContext? context,
  }) => AppStrings.choose(
    'A tray app for Windows, macOS and Linux that bundles the server and voice server and configures itself on first launch. Best for friends and small communities.',
    '支持 Windows、macOS 和 Linux 的托盘应用，内置消息与语音服务器，首次启动即可完成配置。适合朋友之间或小型社区使用。',
    context: context,
  );
  static String aServerDeployment({BuildContext? context}) =>
      AppStrings.choose('A server deployment', '部署独立服务器', context: context);
  static String runAccordserverWithDockerOnALinux({
    BuildContext? context,
  }) => AppStrings.choose(
    'Run accordserver with Docker on a Linux machine or VPS for an always-on community, with your own domain name and HTTPS.',
    '在 Linux 电脑或 VPS 上通过 Docker 运行 accordserver，搭配自己的域名和 HTTPS，让社区全天候在线。',
    context: context,
  );
  static String onceItIsRunningComeBackHere({BuildContext? context}) =>
      AppStrings.choose(
        'Once it is running, come back here and connect with its URL.',
        '服务器启动后，返回这里输入地址即可连接。',
        context: context,
      );
  static String connectByUrl({BuildContext? context}) =>
      AppStrings.choose('Connect by URL', '通过地址连接', context: context);
  static String readTheGuide({BuildContext? context}) =>
      AppStrings.choose('Read the guide', '阅读指南', context: context);
  static String retry({BuildContext? context}) =>
      AppStrings.choose('Retry', '重试', context: context);
  static String willBeBannedFromTheSpaceAnd({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    '${arg0} will be banned from the space and removed.',
    '${arg0} 将被封禁并移出域。',
    context: context,
  );
  static String deleteMessageHistory({BuildContext? context}) =>
      AppStrings.choose('Delete message history', '删除历史消息', context: context);
  static String thatAttachmentHasNoValidAddress({BuildContext? context}) =>
      AppStrings.choose(
        'That attachment has no valid address.',
        '此附件没有有效的下载地址。',
        context: context,
      );
  static String couldnTReachTheServerCheckYour({BuildContext? context}) =>
      AppStrings.choose(
        'Couldn\'t reach the server. Check your connection and try again.',
        '无法连接服务器，请检查网络后重试。',
        context: context,
      );
  static String theDownloadWasInterrupted({BuildContext? context}) =>
      AppStrings.choose(
        'The download was interrupted.',
        '下载已中断。',
        context: context,
      );
  static String couldnTSaveTheFile({BuildContext? context}) =>
      AppStrings.choose(
        'Couldn\'t save the file.',
        '无法保存文件。',
        context: context,
      );
  static String saveAttachment({BuildContext? context}) =>
      AppStrings.choose('Save attachment', '保存附件', context: context);
  static String theServerRefusedTheDownloadHttp({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    'The server refused the download (HTTP ${arg0}).',
    '服务器拒绝了下载请求（HTTP ${arg0}）。',
    context: context,
  );
  static String thatAttachmentIsTooLargeToDownload({BuildContext? context}) =>
      AppStrings.choose(
        'That attachment is too large to download.',
        '此附件过大，无法下载。',
        context: context,
      );
  static String couldnTCreateAFileToDownload({BuildContext? context}) =>
      AppStrings.choose(
        'Couldn\'t create a file to download into.',
        '无法创建用于保存下载内容的文件。',
        context: context,
      );
  static String thatAttachmentHasAnUnsafeFilename({BuildContext? context}) =>
      AppStrings.choose(
        'That attachment has an unsafe filename.',
        '此附件的文件名不安全。',
        context: context,
      );
  static String yourBrowserBlockedTheDownloadAllowPop({
    BuildContext? context,
  }) => AppStrings.choose(
    'Your browser blocked the download. Allow pop-ups and try again.',
    '浏览器阻止了下载，请允许弹出式窗口后重试。',
    context: context,
  );
  static String couldnTStartTheDownload({BuildContext? context}) =>
      AppStrings.choose(
        'Couldn\'t start the download.',
        '无法开始下载。',
        context: context,
      );
  static String onlyValidHttpAndHttpsLinksCan({BuildContext? context}) =>
      AppStrings.choose(
        'Only valid HTTP and HTTPS links can be opened.',
        '只能打开有效的 HTTP 或 HTTPS 链接。',
        context: context,
      );
  static String openExternalLink({BuildContext? context}) =>
      AppStrings.choose('Open external link?', '打开外部链接？', context: context);
  static String thisLinkWillOpenInYourBrowser({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    'This link will open in your browser.\n\nDestination: ${arg0}',
    '将在浏览器中打开此链接。\n\n目标网站：${arg0}',
    context: context,
  );
  static String openLink({BuildContext? context}) =>
      AppStrings.choose('Open link', '打开链接', context: context);
  static String couldnTOpenTheLinkTo({
    BuildContext? context,
    required Object? arg0,
  }) => AppStrings.choose(
    'Couldn\'t open the link to ${arg0}.',
    '无法打开 ${arg0} 的链接。',
    context: context,
  );
}
