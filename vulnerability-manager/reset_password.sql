-- Questo è un hash per la password 'admin123' generato con argon2
UPDATE users 
SET password_hash = '$argon2id$v=19$m=19456,t=2,p=1$VE0e3g7DalWHgDwou3nuRA$LNMVPWt3S1V6IJaS0JqHxMdDbT4LQtPbLmYvtZbfKlA'
WHERE username = 'admin';