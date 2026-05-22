CREATE TABLE IF NOT EXISTS vb_file.uploads_audit (
  id mediumint(9) NOT NULL AUTO_INCREMENT,
  user_id mediumint(9) DEFAULT NULL,
  path varchar(1024) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  uploaded_at datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
