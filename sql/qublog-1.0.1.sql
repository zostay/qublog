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

ALTER TABLE tasks RENAME TO tasks2;

CREATE TABLE tasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  name text NOT NULL,
  owner integer NOT NULL,
  task_type text NOT NULL DEFAULT 'action',
  child_handling text NOT NULL DEFAULT 'serial',
  status text NOT NULL DEFAULT 'open',
  created_on datetime NOT NULL,
  completed_on datetime,
  order_by int NOT NULL DEFAULT 0,
  project integer,
  parent integer NOT NULL  
);

INSERT INTO tasks(id, name, owner, task_type, child_handling, status, created_on, completed_on, order_by, project, parent)
    SELECT id, name, owner, task_type, child_handling, status, created_on, completed_on, order_by, project, parent
    FROM tasks2;

DROP TABLE tasks2;

CREATE TABLE sequences(
    id         int NOT NULL,
    last_value int NOT NULL,
    PRIMARY KEY (id)
);

INSERT INTO sequences(id, last_value)
    SELECT 1, COALESCE(MAX(id), 0)
    FROM tags;
