ALTER TABLE tasks ADD latest_comment int REFERENCES comments (id);
