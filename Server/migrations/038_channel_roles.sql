CREATE TABLE channel_roles (
    id TEXT PRIMARY KEY,
    channel_id TEXT NOT NULL REFERENCES channels(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    position BIGINT NOT NULL CHECK (position >= 0),
    permissions TEXT NOT NULL DEFAULT '[]',
    UNIQUE (channel_id, id)
);
CREATE INDEX channel_roles_channel ON channel_roles(channel_id);
CREATE TABLE channel_member_roles (
    channel_id TEXT NOT NULL,
    space_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    role_id TEXT NOT NULL,
    PRIMARY KEY (channel_id, user_id),
    FOREIGN KEY (channel_id, role_id) REFERENCES channel_roles(channel_id, id) ON DELETE CASCADE,
    FOREIGN KEY (user_id, space_id) REFERENCES members(user_id, space_id) ON DELETE CASCADE
);
-- Older channels did not record their creator. The community owner is the fallback.
UPDATE channels SET owner_id = (SELECT owner_id FROM spaces WHERE spaces.id = channels.space_id)
WHERE owner_id IS NULL AND space_id IS NOT NULL AND type IN ('text', 'voice');
INSERT INTO channel_roles (id, channel_id, name, position, permissions) SELECT id || '-role-0', id, '普通成员', 0, '["view_channel","send_messages","read_history","add_reactions","create_invites","connect","speak","use_vad","embed_links","attach_files","use_external_emojis","stream","use_soundboard","create_threads","send_in_threads"]' FROM channels WHERE space_id IS NOT NULL AND type IN ('text', 'voice');
INSERT INTO channel_roles (id, channel_id, name, position, permissions) SELECT id || '-role-1', id, '贵宾', 1, '["view_channel","send_messages","read_history","add_reactions","create_invites","connect","speak","use_vad","embed_links","attach_files","use_external_emojis","stream","use_soundboard","create_threads","send_in_threads","priority_speaker"]' FROM channels WHERE space_id IS NOT NULL AND type IN ('text', 'voice');
INSERT INTO channel_roles (id, channel_id, name, position, permissions) SELECT id || '-role-2', id, '管理员', 2, '["view_channel","send_messages","read_history","add_reactions","create_invites","connect","speak","use_vad","embed_links","attach_files","use_external_emojis","stream","use_soundboard","create_threads","send_in_threads","manage_messages","mention_everyone","manage_threads","priority_speaker"]' FROM channels WHERE space_id IS NOT NULL AND type IN ('text', 'voice');
INSERT INTO channel_roles (id, channel_id, name, position, permissions) SELECT id || '-role-3', id, '高级管理员', 3, '["view_channel","send_messages","read_history","add_reactions","create_invites","connect","speak","use_vad","embed_links","attach_files","use_external_emojis","stream","use_soundboard","create_threads","send_in_threads","manage_messages","mention_everyone","manage_threads","priority_speaker","manage_channels","manage_roles","manage_webhooks"]' FROM channels WHERE space_id IS NOT NULL AND type IN ('text', 'voice');
