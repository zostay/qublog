BEGIN TRANSACTION;
CREATE TABLE comment_tags (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL  ,
  comment integer NOT NULL  ,
  tag integer NOT NULL  
);
DELETE FROM sqlite_sequence;
INSERT INTO "sqlite_sequence" VALUES('_jifty_metadata',10);
CREATE TABLE user_preferences (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL  ,
  user integer NOT NULL  ,
  name text NOT NULL  ,
  value text NOT NULL  
);
CREATE TABLE journal_entries (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL  ,
  journal_day integer   ,
  owner integer   ,
  name text NOT NULL  ,
  start_time datetime   ,
  stop_time datetime   ,
  primary_link text   ,
  project integer   
);
CREATE TABLE journal_entry_tags (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL  ,
  journal_entry integer NOT NULL  ,
  tag integer NOT NULL  
);
CREATE TABLE remote_users (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL  ,
  user integer NOT NULL  ,
  name text NOT NULL  ,
  site_url text NOT NULL  
);
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL  ,
  name text NOT NULL  ,
  email text   ,
  email_verified bool NOT NULL DEFAULT 0 ,
  password text NOT NULL  ,
  time_zone text NOT NULL DEFAULT 'US/Central' 
);
CREATE TABLE journal_days (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL  ,
  datestamp date NOT NULL  
);
CREATE TABLE journal_timers (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL  ,
  journal_entry integer NOT NULL  ,
  start_time datetime   ,
  stop_time datetime   
);
CREATE TABLE comments (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL  ,
  journal_day integer   ,
  owner integer   ,
  journal_timer integer   ,
  created_on datetime   ,
  name text NOT NULL  ,
  processed_name_cache text   
);
CREATE TABLE tags (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL  ,
  name text NOT NULL DEFAULT '-' 
);
CREATE TABLE _jifty_metadata (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL  ,
  data_key text   ,
  value text   
);
INSERT INTO "_jifty_metadata" VALUES(1,'application_db_version','0.6.1');
INSERT INTO "_jifty_metadata" VALUES(2,'jifty_db_version','0.90701');
INSERT INTO "_jifty_metadata" VALUES(3,'Jifty::Plugin::LetMe_db_version','0.0.1');
INSERT INTO "_jifty_metadata" VALUES(4,'Jifty::Plugin::SkeletonApp_db_version','0.0.1');
INSERT INTO "_jifty_metadata" VALUES(5,'Jifty::Plugin::REST_db_version','0.0.1');
INSERT INTO "_jifty_metadata" VALUES(6,'Jifty::Plugin::Halo_db_version','0.0.1');
INSERT INTO "_jifty_metadata" VALUES(7,'Jifty::Plugin::ErrorTemplates_db_version','0.0.1');
INSERT INTO "_jifty_metadata" VALUES(8,'Jifty::Plugin::OnlineDocs_db_version','0.0.1');
INSERT INTO "_jifty_metadata" VALUES(9,'Jifty::Plugin::CompressedCSSandJS_db_version','0.0.1');
INSERT INTO "_jifty_metadata" VALUES(10,'Jifty::Plugin::AdminUI_db_version','0.0.1');
CREATE TABLE _jifty_sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL  ,
  session_id varchar(32)   ,
  data_key text   ,
  value blob   ,
  created timestamp   ,
  updated timestamp   ,
  key_type varchar(32)   
);
CREATE TABLE task_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL  ,
  owner integer   ,
  task integer NOT NULL  ,
  log_type text NOT NULL  ,
  created_on datetime NOT NULL  ,
  comment integer   
);
CREATE TABLE task_tags (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL  ,
  task integer NOT NULL  ,
  tag integer NOT NULL  ,
  sticky boolean NOT NULL DEFAULT 0 ,
  nickname boolean NOT NULL DEFAULT 0 
);
CREATE TABLE task_changes (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL  ,
  task_log integer NOT NULL  ,
  name text NOT NULL  ,
  old_value text   ,
  new_value text NOT NULL  
);
CREATE TABLE tasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL  ,
  name text NOT NULL  ,
  owner integer   ,
  task_type text NOT NULL DEFAULT 'action' ,
  child_handling text NOT NULL DEFAULT 'serial' ,
  status text NOT NULL DEFAULT 'open' ,
  created_on datetime   ,
  completed_on datetime   ,
  order_by int NOT NULL DEFAULT 0 ,
  project integer   ,
  parent integer   
);
CREATE TABLE _jifty_pubsub_publishers (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL  ,
  channel text   ,
  name text   ,
  idx int   
);
CREATE TABLE _jifty_pubsub_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL  ,
  data_key text   ,
  val blob   ,
  expiry int   
);
CREATE INDEX _jifty_sessions1 ON _jifty_sessions ( session_id );
COMMIT;
