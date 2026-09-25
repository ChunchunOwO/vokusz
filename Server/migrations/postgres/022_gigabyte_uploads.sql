-- Upgrade stock defaults, preserving administrator-configured limits.
UPDATE server_settings SET max_attachment_size = 1073741824
WHERE max_attachment_size = 26214400;
UPDATE server_settings SET upload_bytes_per_minute = 2147483648
WHERE upload_bytes_per_minute = 52428800;

ALTER TABLE server_settings ALTER COLUMN max_attachment_size SET DEFAULT 1073741824;
ALTER TABLE server_settings ALTER COLUMN upload_bytes_per_minute SET DEFAULT 2147483648;
