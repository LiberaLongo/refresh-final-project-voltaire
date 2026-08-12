-- definizione delle utenze del DB Voltaire

-- utenza operativa con diritti pieni, lettura, scrittura, cancellazione, sui tre schemi
CREATE ROLE voltoperator LOGIN PASSWORD 'cr7pRE1u#9'; 

-- utenza per l'accesso alle view di gold e la redazione dei report Powerbi
CREATE ROLE voltgolduser LOGIN PASSWORD 'wrI?2ipop8'; 

-- abilitazione di accesso al DB
GRANT CONNECT ON DATABASE postgres TO voltoperator;
GRANT CONNECT ON DATABASE postgres TO voltgolduser;

-- accesso ai tre schemi per l'account operativo
GRANT USAGE, CREATE ON SCHEMA bronze TO voltoperator;
GRANT USAGE, CREATE ON SCHEMA silver TO voltoperator;
GRANT USAGE, CREATE ON SCHEMA gold   TO voltoperator;

-- accesso completo a tutte le tabelle esistenti
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER 
ON ALL TABLES IN SCHEMA bronze TO voltoperator;
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER 
ON ALL TABLES IN SCHEMA silver TO voltoperator;
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER 
ON ALL TABLES IN SCHEMA gold TO voltoperator;

-- accesso alle 'sequences' (non si sa mai)
GRANT USAGE, SELECT, UPDATE 
ON ALL SEQUENCES IN SCHEMA bronze TO voltoperator;
GRANT USAGE, SELECT, UPDATE
ON ALL SEQUENCES IN SCHEMA silver TO voltoperator;
GRANT USAGE, SELECT, UPDATE
ON ALL SEQUENCES IN SCHEMA gold TO voltoperator;

-- impostazione dei privilegi di default per future tabelle
ALTER DEFAULT PRIVILEGES FOR ROLE voltoperator IN SCHEMA bronze 
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLES TO voltoperator;
ALTER DEFAULT PRIVILEGES FOR ROLE voltoperator IN SCHEMA silver 
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLES TO voltoperator; 
ALTER DEFAULT PRIVILEGES FOR ROLE voltoperator IN SCHEMA gold 
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLES TO voltoperator;

-- impostazione dei privilegi sulle tabelle create da voltadmin per voltoperator
ALTER DEFAULT PRIVILEGES FOR ROLE voltadmin IN SCHEMA bronze
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLES TO voltoperator;
ALTER DEFAULT PRIVILEGES FOR ROLE voltadmin IN SCHEMA silver
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLES TO voltoperator;
ALTER DEFAULT PRIVILEGES FOR ROLE voltadmin IN SCHEMA gold
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLES TO voltoperator;

-- accessi per voltgolduser per report
GRANT USAGE ON SCHEMA gold TO voltgolduser; 
GRANT SELECT ON ALL TABLES IN SCHEMA gold TO voltgolduser; 

-- impostazioni accessi di default per future tabelle in gold
ALTER DEFAULT PRIVILEGES FOR ROLE voltoperator IN SCHEMA gold GRANT SELECT ON TABLES TO voltgolduser;

------------------------
-- select di verifica --
------------------------

-- elenco delle utenze e delle abilitazioni
SELECT rolname AS username, 
       rolsuper AS is_superuser, 
       rolcreatedb AS can_create_database, 
       rolcreaterole AS can_create_role, 
       rolcanlogin AS can_login 
FROM pg_roles ORDER BY rolname; 


-- vedere solo le utenze che possono fare login
SELECT rolname AS username
FROM pg_roles
WHERE rolcanlogin = true
ORDER BY rolname;

-- vedere ruoli e appartenenze
SELECT
    member.rolname AS username,
    parent.rolname AS role
FROM pg_auth_members m
JOIN pg_roles parent
    ON parent.oid = m.roleid
JOIN pg_roles member
    ON member.oid = m.member
ORDER BY member.rolname, parent.rolname;

-- vedere chi può accedere ad un database specifico
SELECT
    r.rolname AS username,
    has_database_privilege(r.rolname, 'postgres', 'CONNECT') AS can_connect
FROM pg_roles r
WHERE r.rolcanlogin = true
ORDER BY r.rolname;

-- vedere i privilegi sugli schemi
SELECT
    n.nspname AS schema_name,
    r.rolname AS username,
    has_schema_privilege(r.rolname, n.nspname, 'USAGE') AS can_usage,
    has_schema_privilege(r.rolname, n.nspname, 'CREATE') AS can_create
FROM pg_namespace n
CROSS JOIN pg_roles r
WHERE n.nspname IN ('bronze', 'silver', 'gold')
  AND r.rolcanlogin = true
ORDER BY n.nspname, r.rolname;

