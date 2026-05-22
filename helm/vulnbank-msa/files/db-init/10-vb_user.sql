CREATE TABLE IF NOT EXISTS vb_user.users (
  id mediumint(9) NOT NULL AUTO_INCREMENT,
  login varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  firstname varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  lastname varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  email varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  phone varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  password varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  account varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  creditcard varchar(25) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  birthdate date DEFAULT NULL,
  lastvisit datetime DEFAULT NULL,
  amount float DEFAULT NULL,
  role varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  code smallint(6) DEFAULT NULL,
  avatar varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  about varchar(10000) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  otp int(11) DEFAULT NULL,
  PRIMARY KEY (id)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS vb_user.codes (
  login varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  code smallint(6) DEFAULT NULL,
  updated_at datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (login)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

INSERT INTO vb_user.users
  (id, login, firstname, lastname, email, phone, password, account, creditcard, birthdate, lastvisit, amount, role, code, avatar, about, otp)
VALUES
  (1,'j.doe','John','Doe','j.doe@vulnbank.com','+15555555','5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8','DE12345123451234512345','5138-3266-5138-5315','1984-04-04','2017-06-02 11:07:04',760,'admin',845,'uploads/1_profile-1.png','Hi!',0),
  (2,'j.adams','Jack','Adams','j.adams@vulnbank.com','+14444444','5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8','DE00000111112222233333','4556-7491-4729-3700','1990-05-05','2017-04-29 13:36:55',940,'user',121,'uploads/2_profile-3.png',NULL,1)
ON DUPLICATE KEY UPDATE
  login=VALUES(login),
  firstname=VALUES(firstname),
  lastname=VALUES(lastname),
  email=VALUES(email),
  phone=VALUES(phone),
  password=VALUES(password),
  account=VALUES(account),
  creditcard=VALUES(creditcard),
  birthdate=VALUES(birthdate),
  lastvisit=VALUES(lastvisit),
  amount=VALUES(amount),
  role=VALUES(role),
  code=VALUES(code),
  avatar=VALUES(avatar),
  about=VALUES(about),
  otp=VALUES(otp);

INSERT INTO vb_user.codes (login, code)
VALUES
  ('j.doe', 845),
  ('j.adams', 121)
ON DUPLICATE KEY UPDATE
  code=VALUES(code);
