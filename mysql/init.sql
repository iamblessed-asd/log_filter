CREATE TABLE IF NOT EXISTS message (
    created TIMESTAMP NOT NULL,
    id VARCHAR(255) NOT NULL,
    int_id CHAR(16) NOT NULL,
    str TEXT NOT NULL,
    status BOOLEAN,
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS log (
    created TIMESTAMP NOT NULL,
    int_id CHAR(16) NOT NULL,
    str TEXT,
    address VARCHAR(255)
);
