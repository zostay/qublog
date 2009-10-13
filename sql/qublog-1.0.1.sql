ALTER TABLE tasks ADD latest_comment int REFERENCES comments (id);

CREATE TABLE sequences(
    id         int NOT NULL,
    last_value int NOT NULL,
    PRIMARY KEY (id)
);

INSERT INTO sequences(id, last_value)
    SELECT 1, MAX(id)
    FROM tags;
