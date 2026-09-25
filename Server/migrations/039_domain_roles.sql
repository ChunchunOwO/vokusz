UPDATE roles SET name = '普通成员' WHERE name = '@everyone' AND position = 0;
-- Rename only the original built-in templates; custom names/permissions stay intact.
UPDATE roles SET name = '高级管理员', position = 3 WHERE name = 'Admin' AND position = 2;
UPDATE roles SET name = '管理员', position = 2 WHERE name = 'Moderator' AND position = 1;
INSERT INTO roles (id, space_id, name, color, hoist, position, permissions)
SELECT 'domain-guest-' || s.id, s.id, '嘉宾', 10181046, TRUE, 1, '[]'
FROM spaces s WHERE NOT EXISTS (SELECT 1 FROM roles r WHERE r.space_id = s.id AND r.name = '嘉宾');
