-- 0001_initial_schema.sql
-- Initial schema for THE CRIME BOARD backend.
-- Six tables: outlets, clusters, articles, fact_checks, users, push_subscriptions.
-- All times stored as Unix epoch seconds (INTEGER).
-- All JSON-shaped fields stored as TEXT (D1/SQLite has no JSON type but supports JSON1 functions).
-- Embeddings stored as BLOB (JSON-encoded float arrays per the spec).

CREATE TABLE outlets (
  id                 TEXT    PRIMARY KEY,
  name               TEXT    NOT NULL,
  homepage_url       TEXT    NOT NULL,
  rss_urls           TEXT    NOT NULL DEFAULT '[]',
  logo_url           TEXT,
  bias_score         REAL    NOT NULL,
  reliability_score  REAL    NOT NULL,
  bias_source        TEXT    NOT NULL CHECK (bias_source IN ('allsides', 'adfontes', 'manual')),
  ownership          TEXT,
  funding_model      TEXT,
  wikipedia_url      TEXT
) STRICT;

CREATE TABLE clusters (
  id                  TEXT    PRIMARY KEY,
  created_at          INTEGER NOT NULL,
  updated_at          INTEGER NOT NULL,
  representative_title TEXT   NOT NULL,
  centroid_embedding  BLOB    NOT NULL,
  topic_tags          TEXT    NOT NULL DEFAULT '[]',
  bias_distribution   TEXT    NOT NULL DEFAULT '{}',
  is_breaking         INTEGER NOT NULL DEFAULT 0 CHECK (is_breaking IN (0, 1)),
  article_count       INTEGER NOT NULL DEFAULT 0
) STRICT;

CREATE INDEX idx_clusters_updated_at ON clusters(updated_at);
CREATE INDEX idx_clusters_breaking   ON clusters(is_breaking) WHERE is_breaking = 1;

CREATE TABLE articles (
  id            TEXT    PRIMARY KEY,
  outlet_id     TEXT    NOT NULL REFERENCES outlets(id),
  url           TEXT    NOT NULL UNIQUE,
  title         TEXT    NOT NULL,
  description   TEXT,
  published_at  INTEGER NOT NULL,
  fetched_at    INTEGER NOT NULL,
  embedding     BLOB,
  cluster_id    TEXT             REFERENCES clusters(id),
  topic_tags    TEXT    NOT NULL DEFAULT '[]'
) STRICT;

CREATE INDEX idx_articles_published_at ON articles(published_at);
CREATE INDEX idx_articles_cluster      ON articles(cluster_id);
CREATE INDEX idx_articles_outlet       ON articles(outlet_id);

CREATE TABLE fact_checks (
  id              TEXT    PRIMARY KEY,
  claim_text      TEXT    NOT NULL,
  verdict         TEXT    NOT NULL CHECK (verdict IN ('true', 'mostly-true', 'mixed', 'mostly-false', 'false', 'unverifiable')),
  source          TEXT    NOT NULL,
  evidence_url    TEXT,
  checked_at      INTEGER NOT NULL,
  claim_embedding BLOB
) STRICT;

CREATE INDEX idx_factchecks_checked_at ON fact_checks(checked_at);

CREATE TABLE users (
  id                  TEXT    PRIMARY KEY,
  apple_sub           TEXT    UNIQUE,
  email               TEXT,
  created_at          INTEGER NOT NULL,
  pro_until           INTEGER,
  feed_mode           TEXT    NOT NULL DEFAULT 'strict' CHECK (feed_mode IN ('strict', 'balanced')),
  selected_topics     TEXT    NOT NULL DEFAULT '[]',
  selected_outlets    TEXT    NOT NULL DEFAULT '[]',
  excluded_outlets    TEXT    NOT NULL DEFAULT '[]',
  notification_prefs  TEXT    NOT NULL DEFAULT '{}'
) STRICT;

CREATE INDEX idx_users_apple_sub ON users(apple_sub);

CREATE TABLE push_subscriptions (
  user_id              TEXT    NOT NULL REFERENCES users(id),
  device_token         TEXT    NOT NULL,
  topic_subscriptions  TEXT    NOT NULL DEFAULT '[]',
  last_seen_at         INTEGER NOT NULL,
  PRIMARY KEY (user_id, device_token)
) STRICT;
