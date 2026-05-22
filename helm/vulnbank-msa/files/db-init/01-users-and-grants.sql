CREATE USER IF NOT EXISTS 'user_svc'@'%' IDENTIFIED BY 'user_svc_pw';
CREATE USER IF NOT EXISTS 'tx_svc'@'%' IDENTIFIED BY 'tx_svc_pw';
CREATE USER IF NOT EXISTS 'file_svc'@'%' IDENTIFIED BY 'file_svc_pw';
CREATE USER IF NOT EXISTS 'settings_svc'@'%' IDENTIFIED BY 'settings_svc_pw';

ALTER USER 'user_svc'@'%' IDENTIFIED BY 'user_svc_pw';
ALTER USER 'tx_svc'@'%' IDENTIFIED BY 'tx_svc_pw';
ALTER USER 'file_svc'@'%' IDENTIFIED BY 'file_svc_pw';
ALTER USER 'settings_svc'@'%' IDENTIFIED BY 'settings_svc_pw';

GRANT SELECT, INSERT, UPDATE, DELETE ON vb_user.* TO 'user_svc'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON vb_tx.* TO 'tx_svc'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON vb_file.* TO 'file_svc'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON vb_settings.* TO 'settings_svc'@'%';

FLUSH PRIVILEGES;
