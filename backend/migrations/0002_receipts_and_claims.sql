-- 0002_receipts_and_claims.sql
-- Adds the For Real?? receipt artifact and its component claims.
-- All times stored as Unix epoch seconds (INTEGER) per the existing schema convention.
-- url_hash is sha256(normalized url) hex-encoded; used for global cache lookup.

CREATE TABLE receipts (
  id                TEXT    PRIMARY KEY,
  source_url        TEXT    NOT NULL,
  url_hash          TEXT    NOT NULL,
  source_type       TEXT    NOT NULL CHECK (source_type IN ('video', 'article')),
  source_provider   TEXT    NOT NULL CHECK (source_provider IN ('tiktok', 'youtube', 'article')),
  title             TEXT,
  status            TEXT    NOT NULL CHECK (status IN ('pending', 'streaming', 'done', 'failed')),
  final_verdict     TEXT             CHECK (final_verdict IS NULL OR final_verdict IN ('nope', 'mixed', 'yep', 'skip')),
  final_commentary  TEXT,
  error_code        TEXT,
  device_id         TEXT,           -- nullable: cleared by DELETE /v1/receipts/:id (soft delete)
  user_id           TEXT,
  created_at        INTEGER NOT NULL,
  finished_at       INTEGER
) STRICT;

CREATE INDEX idx_receipts_url_hash             ON receipts(url_hash);
CREATE INDEX idx_receipts_device_created_at    ON receipts(device_id, created_at DESC);
CREATE INDEX idx_receipts_user_created_at      ON receipts(user_id, created_at DESC) WHERE user_id IS NOT NULL;

CREATE TABLE claims (
  id            TEXT    PRIMARY KEY,
  receipt_id    TEXT    NOT NULL REFERENCES receipts(id),
  position      INTEGER NOT NULL CHECK (position IN (1, 2, 3)),
  claim_text    TEXT    NOT NULL,
  verdict       TEXT    NOT NULL CHECK (verdict IN ('nope', 'mixed', 'yep', 'skip')),
  commentary    TEXT    NOT NULL,
  sources       TEXT    NOT NULL DEFAULT '[]',
  resolved_at   INTEGER NOT NULL
) STRICT;

CREATE INDEX idx_claims_receipt_id ON claims(receipt_id);
CREATE UNIQUE INDEX idx_claims_receipt_position ON claims(receipt_id, position);
