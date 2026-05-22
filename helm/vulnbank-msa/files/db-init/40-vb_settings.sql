CREATE TABLE IF NOT EXISTS vb_settings.settings (
  param_name varchar(255) NOT NULL,
  param_value varchar(255) DEFAULT NULL,
  param_type varchar(100) DEFAULT NULL,
  PRIMARY KEY (param_name)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

INSERT INTO vb_settings.settings
  (param_name, param_value, param_type)
VALUES
  ('nexmo_api_key','0000000000','input'),
  ('nexmo_api_secret','0000000000000000','input'),
  ('sms_api','0','options'),
  ('upload_path','uploads','input'),
  ('vb_api','none','options'),
  ('vb_otp','0','checkbox')
ON DUPLICATE KEY UPDATE
  param_value=VALUES(param_value),
  param_type=VALUES(param_type);
