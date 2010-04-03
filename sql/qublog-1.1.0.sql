BEGIN TRANSACTION;
CREATE TABLE journal_sessions(
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    name text NOT NULL,
    owner integer NOT NULL,
    use_timers bool NOT NULL DEFAULT 1,
    start_time datetime NOT NULL,
    stop_time datetime
);

INSERT INTO journal_sessions(name, owner, start_time, stop_time)
    SELECT datestamp, COALESCE(journal_entries.owner, comments.owner), 
           date(datestamp, 'start of day'),
           date(datestamp, 'start of day', '+1 day')
      FROM journal_days 
 LEFT JOIN journal_entries ON (journal_days.id = journal_entries.journal_day)
 LEFT JOIN comments ON (journal_days.id = comments.journal_day)
     WHERE COALESCE(journal_entries.owner, comments.owner) IS NOT NULL;

ALTER TABLE journal_entries RENAME TO rev_1_0_2_journal_entries;
CREATE TABLE journal_entries(
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL  ,
  journal_session integer NOT NULL  ,
  owner integer NOT NULL  ,
  name text NOT NULL  ,
  start_time datetime NOT NULL  ,
  stop_time datetime   ,
  primary_link text   ,
  project integer   
);

INSERT INTO journal_entries(id, journal_session, owner, name, start_time, stop_time, primary_link, project)
    SELECT rev_1_0_2_journal_entries.id, journal_sessions.id, 
           rev_1_0_2_journal_entries.owner, rev_1_0_2_journal_entries.name, 
           rev_1_0_2_journal_entries.start_time, rev_1_0_2_journal_entries.stop_time, 
           primary_link, project
      FROM rev_1_0_2_journal_entries
      JOIN journal_days ON (journal_days.id = rev_1_0_2_journal_entries.journal_day)
      JOIN journal_sessions ON (date(journal_days.datestamp, 'start of day') = journal_sessions.start_time)
  GROUP BY rev_1_0_2_journal_entries.id;

ALTER TABLE comments RENAME TO rev_1_0_2_comments;
CREATE TABLE comments (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL  ,
  journal_session integer   ,
  owner integer NOT NULL  ,
  journal_timer integer   ,
  created_on datetime  NOT NULL ,
  name text NOT NULL  ,
  processed_name_cache text   
);

INSERT INTO comments(id, journal_session, owner, journal_timer, created_on, name, processed_name_cache)
    SELECT rev_1_0_2_comments.id, journal_sessions.id, rev_1_0_2_comments.owner, 
           journal_timer, created_on, rev_1_0_2_comments.name, processed_name_cache
      FROM rev_1_0_2_comments
      JOIN journal_days ON (journal_days.id = rev_1_0_2_comments.journal_day)
      JOIN journal_sessions ON (date(journal_days.datestamp, 'start of day') = journal_sessions.start_time)
  GROUP BY rev_1_0_2_comments.id;

DROP TABLE journal_days;
COMMIT;
