-- Script per ripristinare password admin
-- Nuove credenziali: admin / Admin123!

UPDATE users
SET password_hash = '$argon2id$v=19$m=19456,t=2,p=1$l4ROhY0PMyOdMDVUGPPGOA$9ycBlp9Eb8rLlb8H9OVj+YQAD36EhvyCUzEGbXFJrb4'
WHERE username = 'admin';

-- Verifica aggiornamento
SELECT
    username,
    email,
    role,
    '✅ Password ripristinata a: Admin123!' as status
FROM users
WHERE username = 'admin';
