---
title: Managing Your Space
description: Configure channels, roles, and settings for your space.
order: 1
section: administration
---

# Managing Your Space

If you have admin permissions, you can manage your space's channels, roles, and settings.

## Accessing Space Settings

Right-click a space icon in the space bar and select **Space Settings** (or the equivalent admin option) to open the management panel.

## Icon and Banner

Upload an icon in **Overview**, apply the crop, then choose **Save settings**.
The pending preview shows the selected crop immediately. Icons are exported as
PNG up to 512 pixels; banners use a 16:9 crop up to 1024 pixels wide. Banner
changes and removal save immediately, with **Save settings** available to retry
an unsuccessful change. Saved replacements refresh the settings preview and
space bar during the same session, even when the server reuses the image URL.

## Channels

### Creating a Channel

1. In space settings, go to the Channels section.
2. Click **Create Channel**.
3. Choose a channel type (text, voice, announcement, or forum).
4. Enter a name and optionally assign it to a category.
5. Click **Create**.

### Editing a Channel

Click on a channel in the settings list to edit its name, topic, or other properties.

### Deleting a Channel

Select a channel and click **Delete**. This permanently removes the channel and all its messages.

### Categories

Channels can be organized into categories. Create, rename, or delete categories from the Channels section.

## Roles

Roles control what members can do in your space.

### Creating a Role

1. Go to the Roles section in space settings.
2. Click **Create Role**.
3. Set a name and color.
4. Toggle individual permissions on or off.
5. Save the role.

### Assigning Roles

Right-click a member in the member list and select a role to assign or remove.

### Channel Permissions

You can set per-channel permission overrides for specific roles:

1. Open the channel's settings.
2. Go to Permissions.
3. Add a role and set permissions to **Allow**, **Inherit**, or **Deny** for each permission.

## Invites

See [Invites](invites.md) for details on inviting people to your server.

Overview edits (including the community icon) can be saved with the top Save settings button. Returning from settings saves pending edits first; if saving fails, the page stays open with your edits and an error so you can retry.
`Discard` is available after a failed save if you want to leave without applying the draft.


Domain permissions: 社区 is the server-wide community; 域 maps to Space; a domain
contains category groups and text/voice channels. The domain creator is 域主.
Default groups are 高级管理员 (structure and moderation), 管理员 (moderation),
嘉宾 (no administrative grants), and 普通成员 (the implicit position-zero role).
Only the domain owner or community administrator creates permission groups;
role edits and assignments respect hierarchy. Community administrators manage
all domains and their names use a distinct color. Channel overrides refine
existing domain roles; channels do not have a separate owner/role system.

Sidebar groups use server-scoped collapse preferences. Members with manage_channels
can drag channels directly onto a group header or the Ungrouped drop area; group
headers can also be reordered. Members with move_members can drag voice participants
onto another voice channel in the same domain. The server validates both channel
permissions, hierarchy, current source, and the moved member's destination access.

Member popouts label assignments as 域内权限分配 and show the target domain. These assignments update only that domain membership, never community administration. Profile data is retained when role-update events omit it.

Interface terminology: 社区 → 域 → 分组 → 文字／语音频道. The rail creation action is 创建域; domain channel creation remains 创建频道. Domain links, mute, leave, settings and ownership actions use 域 and 域主 consistently; disconnecting the whole server connection is 移除社区连接.

## Join or create a domain

Select **+** in the left rail, then **Join domain** or **Create domain**. Join with a numeric domain ID from the current community. Click the square ID badge beneath a domain name to copy its full ID. Private domains require an invitation. When creating a domain, **Allow joining by domain ID** makes it public; disable the switch to require invitations.

左侧 **+** 可选择加入或创建域。点击域名下方的方框复制完整域 ID，在当前社区输入公开域 ID 即可加入；私有域需要邀请。创建时关闭「允许通过域 ID 加入」即可保持私有。
