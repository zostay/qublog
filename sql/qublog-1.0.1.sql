ALTER TABLE tasks 
    ADD latest_comment integer REFERENCES comments (id);

ALTER TABLE journal_entries RENAME TO journal_entries2;

CREATE TABLE journal_entries(
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL  ,
    name text NOT NULL,
    start_time datetime NOT NULL,
    stop_time datetime DEFAULT NULL,
    primary_link text DEFAULT NULL,
    project integer NOT NULL, 
    journal_day integer NOT NULL, 
    owner integer NOT NULL
);

INSERT INTO journal_entries(id, name, start_time, stop_time, primary_link, project, journal_day, owner)
    SELECT id, name, start_time, stop_time, primary_link, COALESCE(project, 1), journal_day, owner
    FROM journal_entries2;

DROP TABLE journal_entries2;

CREATE TABLE sequences(
    id         int NOT NULL,
    last_value int NOT NULL,
    PRIMARY KEY (id)
);

INSERT INTO sequences(id, last_value)
    SELECT 1, COALESCE(MAX(id), 0)
    FROM tags;
