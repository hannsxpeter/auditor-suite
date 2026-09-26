CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE tenants (
  id uuid PRIMARY KEY,
  company text NOT NULL,
  widget_key text UNIQUE NOT NULL
);

CREATE TABLE admins (
  id uuid PRIMARY KEY,
  tenant_id uuid NOT NULL REFERENCES tenants (id),
  api_token text UNIQUE NOT NULL
);

CREATE TABLE customers (
  id uuid PRIMARY KEY,
  tenant_id uuid NOT NULL REFERENCES tenants (id),
  email text NOT NULL,
  session_token text UNIQUE
);

CREATE TABLE orders (
  id uuid PRIMARY KEY,
  tenant_id uuid NOT NULL REFERENCES tenants (id),
  customer_id uuid NOT NULL REFERENCES customers (id),
  number text NOT NULL,
  status text NOT NULL,
  items jsonb NOT NULL,
  shipping_address text NOT NULL,
  total numeric(10, 2) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE tickets (
  id uuid PRIMARY KEY,
  tenant_id uuid NOT NULL REFERENCES tenants (id),
  subject text NOT NULL,
  body text NOT NULL,
  status text NOT NULL DEFAULT 'open',
  priority text,
  team text,
  tags text[] NOT NULL DEFAULT '{}',
  summary text,
  created_at timestamptz NOT NULL DEFAULT now(),
  closed_at timestamptz
);

CREATE TABLE ticket_messages (
  id bigserial PRIMARY KEY,
  tenant_id uuid NOT NULL REFERENCES tenants (id),
  ticket_id uuid NOT NULL REFERENCES tickets (id),
  author text NOT NULL,
  body text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- One shared table holds every tenant's knowledge base: help-center articles
-- and community forum answers.
CREATE TABLE kb_chunks (
  id bigserial PRIMARY KEY,
  tenant_id uuid NOT NULL REFERENCES tenants (id),
  article_id text NOT NULL,
  title text NOT NULL,
  position int NOT NULL,
  body text NOT NULL,
  embedding vector(1536) NOT NULL,
  embedding_model text NOT NULL
);

CREATE INDEX kb_chunks_embedding_idx ON kb_chunks USING hnsw (embedding vector_cosine_ops);
CREATE INDEX kb_chunks_article_idx ON kb_chunks (tenant_id, article_id);
