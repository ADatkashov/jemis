-- JEMIS core schema. Money is stored as integer minor units (tiyn, 1 KZT = 100 tiyn).
-- Quantities are integer "milli-units": 1000 = 1 piece / 1 kg / 1 l, 500 = 0.5 kg.

CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email           VARCHAR(254),
    phone           VARCHAR(20),
    password_hash   VARCHAR(100) NOT NULL,
    full_name       VARCHAR(120) NOT NULL,
    role            VARCHAR(16)  NOT NULL CHECK (role IN ('CUSTOMER','COURIER','MANAGER','ADMIN')),
    status          VARCHAR(24)  NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','DISABLED','DELETION_REQUESTED')),
    locale          VARCHAR(2)   NOT NULL DEFAULT 'ru' CHECK (locale IN ('ru','kk','en')),
    notify_orders   BOOLEAN      NOT NULL DEFAULT TRUE,
    notify_promos   BOOLEAN      NOT NULL DEFAULT FALSE,
    deletion_requested_at TIMESTAMPTZ,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    version         BIGINT       NOT NULL DEFAULT 0,
    CONSTRAINT users_contact_chk CHECK (email IS NOT NULL OR phone IS NOT NULL)
);
CREATE UNIQUE INDEX ux_users_email ON users (lower(email)) WHERE email IS NOT NULL;
CREATE UNIQUE INDEX ux_users_phone ON users (phone) WHERE phone IS NOT NULL;

CREATE TABLE refresh_tokens (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash  VARCHAR(64) NOT NULL UNIQUE,
    expires_at  TIMESTAMPTZ NOT NULL,
    revoked_at  TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_refresh_user ON refresh_tokens(user_id);

CREATE TABLE password_reset_tokens (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash  VARCHAR(64) NOT NULL UNIQUE,
    expires_at  TIMESTAMPTZ NOT NULL,
    used_at     TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE addresses (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    label           VARCHAR(60),
    city            VARCHAR(80) NOT NULL,
    street          VARCHAR(160) NOT NULL,
    house           VARCHAR(20) NOT NULL,
    apartment       VARCHAR(20),
    entrance        VARCHAR(20),
    floor           VARCHAR(20),
    intercom        VARCHAR(40),
    recipient_name  VARCHAR(120),
    recipient_phone VARCHAR(20),
    instructions    VARCHAR(500),
    latitude        NUMERIC(9,6),
    longitude       NUMERIC(9,6),
    is_default      BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at      TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_addresses_user ON addresses(user_id) WHERE deleted_at IS NULL;

CREATE TABLE categories (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_id   UUID REFERENCES categories(id),
    slug        VARCHAR(80) NOT NULL UNIQUE,
    name_ru     VARCHAR(120) NOT NULL,
    name_kk     VARCHAR(120) NOT NULL,
    name_en     VARCHAR(120) NOT NULL,
    icon        VARCHAR(40),
    image_url   VARCHAR(500),
    sort_order  INT NOT NULL DEFAULT 0,
    active      BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Inventory lives on the product row (stock_milli / reserved_milli) so a single row lock
-- protects against overselling; every manual change is recorded in stock_adjustments.
CREATE TABLE products (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id         UUID NOT NULL REFERENCES categories(id),
    sku                 VARCHAR(40) NOT NULL UNIQUE,
    brand               VARCHAR(80),
    variant_group       VARCHAR(80),
    name_ru             VARCHAR(200) NOT NULL,
    name_kk             VARCHAR(200) NOT NULL,
    name_en             VARCHAR(200) NOT NULL,
    description_ru      TEXT,
    description_kk      TEXT,
    description_en      TEXT,
    ingredients_ru      TEXT,
    ingredients_kk      TEXT,
    ingredients_en      TEXT,
    storage_ru          TEXT,
    storage_kk          TEXT,
    storage_en          TEXT,
    allergens           VARCHAR(300),
    keywords            VARCHAR(400),
    attributes          JSONB NOT NULL DEFAULT '{}'::jsonb,
    unit                VARCHAR(8) NOT NULL CHECK (unit IN ('PIECE','KG','G','L','ML','PACK')),
    weighted            BOOLEAN NOT NULL DEFAULT FALSE,
    step_milli          INT NOT NULL DEFAULT 1000 CHECK (step_milli > 0),
    pack_label          VARCHAR(40),
    price_minor         BIGINT NOT NULL CHECK (price_minor >= 0),
    old_price_minor     BIGINT CHECK (old_price_minor IS NULL OR old_price_minor > price_minor),
    currency            VARCHAR(3) NOT NULL DEFAULT 'KZT',
    image_url           VARCHAR(500),
    stock_milli         BIGINT NOT NULL DEFAULT 0 CHECK (stock_milli >= 0),
    reserved_milli      BIGINT NOT NULL DEFAULT 0 CHECK (reserved_milli >= 0),
    low_stock_milli     BIGINT NOT NULL DEFAULT 5000,
    popularity          INT NOT NULL DEFAULT 0,
    active              BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    version             BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT products_reserved_chk CHECK (reserved_milli <= stock_milli)
);
CREATE INDEX ix_products_category ON products(category_id) WHERE active;
CREATE INDEX ix_products_variant ON products(variant_group) WHERE variant_group IS NOT NULL;

CREATE TABLE stock_adjustments (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id  UUID NOT NULL REFERENCES products(id),
    delta_milli BIGINT NOT NULL,
    stock_after BIGINT NOT NULL,
    reason      VARCHAR(200) NOT NULL,
    actor_id    UUID REFERENCES users(id),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE promotions (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code                VARCHAR(40) NOT NULL UNIQUE,
    type                VARCHAR(8) NOT NULL CHECK (type IN ('PERCENT','FIXED')),
    value               BIGINT NOT NULL CHECK (value > 0),  -- percent (1..100) or minor units
    max_discount_minor  BIGINT,
    min_order_minor     BIGINT NOT NULL DEFAULT 0,
    starts_at           TIMESTAMPTZ,
    ends_at             TIMESTAMPTZ,
    usage_limit         INT,
    per_customer_limit  INT,
    category_id         UUID REFERENCES categories(id),
    stackable           BOOLEAN NOT NULL DEFAULT FALSE, -- may apply to already discounted items
    used_count          INT NOT NULL DEFAULT 0,
    active              BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT promo_percent_chk CHECK (type <> 'PERCENT' OR value <= 100)
);

CREATE TABLE banners (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title_ru    VARCHAR(160) NOT NULL,
    title_kk    VARCHAR(160) NOT NULL,
    title_en    VARCHAR(160) NOT NULL,
    subtitle_ru VARCHAR(300),
    subtitle_kk VARCHAR(300),
    subtitle_en VARCHAR(300),
    image_url   VARCHAR(500),
    color       VARCHAR(9),
    link        VARCHAR(300),
    sort_order  INT NOT NULL DEFAULT 0,
    active      BOOLEAN NOT NULL DEFAULT TRUE,
    starts_at   TIMESTAMPTZ,
    ends_at     TIMESTAMPTZ
);

CREATE TABLE cart_items (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_id      UUID NOT NULL REFERENCES products(id),
    quantity_milli  BIGINT NOT NULL CHECK (quantity_milli > 0),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, product_id)
);

CREATE TABLE favorites (
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_id  UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, product_id)
);

CREATE TABLE delivery_zones (
    id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name                        VARCHAR(80) NOT NULL,
    city                        VARCHAR(80) NOT NULL,
    fee_minor                   BIGINT NOT NULL CHECK (fee_minor >= 0),
    min_order_minor             BIGINT NOT NULL DEFAULT 0,
    free_delivery_threshold_minor BIGINT,
    active                      BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE UNIQUE INDEX ux_zone_city ON delivery_zones (lower(city)) WHERE active;

CREATE TABLE delivery_slot_templates (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    start_time      TIME NOT NULL,
    end_time        TIME NOT NULL,
    capacity        INT NOT NULL CHECK (capacity >= 0),
    days_of_week    VARCHAR(20) NOT NULL DEFAULT '1,2,3,4,5,6,7', -- ISO: 1 = Monday
    extra_fee_minor BIGINT NOT NULL DEFAULT 0,
    active          BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT slot_time_chk CHECK (end_time > start_time)
);

CREATE TABLE settings (
    key         VARCHAR(80) PRIMARY KEY,
    value       VARCHAR(500) NOT NULL,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE SEQUENCE order_number_seq START 100001;

CREATE TABLE couriers (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id           UUID NOT NULL UNIQUE REFERENCES users(id),
    display_name      VARCHAR(120) NOT NULL,
    phone             VARCHAR(20),
    photo_url         VARCHAR(500),
    active            BOOLEAN NOT NULL DEFAULT TRUE,
    tracking_consent  BOOLEAN NOT NULL DEFAULT FALSE,
    last_lat          NUMERIC(9,6),
    last_lng          NUMERIC(9,6),
    last_location_at  TIMESTAMPTZ
);

CREATE TABLE orders (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    number              VARCHAR(20) NOT NULL UNIQUE,
    user_id             UUID NOT NULL REFERENCES users(id),
    status              VARCHAR(24) NOT NULL,
    payment_status      VARCHAR(16) NOT NULL,
    payment_method      VARCHAR(16) NOT NULL,
    addr_city           VARCHAR(80) NOT NULL,
    addr_street         VARCHAR(160) NOT NULL,
    addr_house          VARCHAR(20) NOT NULL,
    addr_apartment      VARCHAR(20),
    addr_entrance       VARCHAR(20),
    addr_floor          VARCHAR(20),
    addr_intercom       VARCHAR(40),
    addr_latitude       NUMERIC(9,6),
    addr_longitude      NUMERIC(9,6),
    recipient_name      VARCHAR(120) NOT NULL,
    recipient_phone     VARCHAR(20),
    instructions        VARCHAR(500),
    immediate           BOOLEAN NOT NULL DEFAULT FALSE,
    slot_template_id    UUID REFERENCES delivery_slot_templates(id),
    slot_date           DATE,
    slot_start          TIME,
    slot_end            TIME,
    subtotal_minor      BIGINT NOT NULL,
    discount_minor      BIGINT NOT NULL DEFAULT 0,
    delivery_fee_minor  BIGINT NOT NULL,
    service_fee_minor   BIGINT NOT NULL DEFAULT 0,
    total_minor         BIGINT NOT NULL,
    currency            VARCHAR(3) NOT NULL DEFAULT 'KZT',
    promo_code          VARCHAR(40),
    idempotency_key     VARCHAR(80) NOT NULL,
    courier_id          UUID REFERENCES couriers(id),
    stock_committed     BOOLEAN NOT NULL DEFAULT FALSE,
    paid_at             TIMESTAMPTZ,
    operator_notes      TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    version             BIGINT NOT NULL DEFAULT 0,
    UNIQUE (user_id, idempotency_key),
    CONSTRAINT orders_total_chk CHECK (total_minor = subtotal_minor - discount_minor + delivery_fee_minor + service_fee_minor)
);
CREATE INDEX ix_orders_user ON orders(user_id, created_at DESC);
CREATE INDEX ix_orders_status ON orders(status);
CREATE INDEX ix_orders_slot ON orders(slot_template_id, slot_date) WHERE status <> 'CANCELLED';

CREATE TABLE order_items (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id            UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id          UUID NOT NULL REFERENCES products(id),
    sku                 VARCHAR(40) NOT NULL,
    name_ru             VARCHAR(200) NOT NULL,
    name_kk             VARCHAR(200) NOT NULL,
    name_en             VARCHAR(200) NOT NULL,
    unit                VARCHAR(8) NOT NULL,
    image_url           VARCHAR(500),
    unit_price_minor    BIGINT NOT NULL,
    quantity_milli      BIGINT NOT NULL CHECK (quantity_milli > 0),
    line_total_minor    BIGINT NOT NULL
);
CREATE INDEX ix_order_items_order ON order_items(order_id);
CREATE INDEX ix_order_items_product ON order_items(product_id);

CREATE TABLE order_events (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id    UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    status      VARCHAR(24) NOT NULL,
    actor_id    UUID,
    note        VARCHAR(500),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_order_events_order ON order_events(order_id, created_at);

CREATE TABLE payments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id        UUID NOT NULL REFERENCES orders(id),
    provider        VARCHAR(24) NOT NULL,
    status          VARCHAR(16) NOT NULL CHECK (status IN ('PENDING','SUCCEEDED','FAILED','CANCELLED','REFUNDED')),
    amount_minor    BIGINT NOT NULL,
    currency        VARCHAR(3) NOT NULL DEFAULT 'KZT',
    provider_ref    VARCHAR(100) UNIQUE,
    failure_reason  VARCHAR(200),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    version         BIGINT NOT NULL DEFAULT 0
);
CREATE INDEX ix_payments_order ON payments(order_id);
-- at most one open attempt per order
CREATE UNIQUE INDEX ux_payments_open ON payments(order_id) WHERE status = 'PENDING';

CREATE TABLE payment_events (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider    VARCHAR(24) NOT NULL,
    event_id    VARCHAR(100) NOT NULL,
    payment_id  UUID REFERENCES payments(id),
    type        VARCHAR(24) NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (provider, event_id)
);

CREATE TABLE courier_assignments (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id    UUID NOT NULL REFERENCES orders(id),
    courier_id  UUID NOT NULL REFERENCES couriers(id),
    status      VARCHAR(12) NOT NULL CHECK (status IN ('OFFERED','ACCEPTED','REJECTED','COMPLETED','CANCELLED')),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_assign_courier ON courier_assignments(courier_id, status);
CREATE UNIQUE INDEX ux_assign_open ON courier_assignments(order_id) WHERE status IN ('OFFERED','ACCEPTED');

CREATE TABLE delivery_issues (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id    UUID NOT NULL REFERENCES orders(id),
    courier_id  UUID NOT NULL REFERENCES couriers(id),
    description VARCHAR(500) NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE notifications (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type        VARCHAR(40) NOT NULL,
    title       VARCHAR(200) NOT NULL,
    body        VARCHAR(500) NOT NULL,
    order_id    UUID,
    read_at     TIMESTAMPTZ,
    push_state  VARCHAR(16) NOT NULL DEFAULT 'NOT_CONFIGURED',
    push_attempts INT NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_notifications_user ON notifications(user_id, created_at DESC);

CREATE TABLE audit_log (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_id    UUID,
    action      VARCHAR(60) NOT NULL,
    entity      VARCHAR(40) NOT NULL,
    entity_id   VARCHAR(60),
    details     VARCHAR(1000),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_audit_created ON audit_log(created_at DESC);

CREATE TABLE promo_redemptions (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    promo_id    UUID NOT NULL REFERENCES promotions(id),
    user_id     UUID NOT NULL REFERENCES users(id),
    order_id    UUID NOT NULL UNIQUE REFERENCES orders(id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_redemptions_promo_user ON promo_redemptions(promo_id, user_id);

INSERT INTO settings(key, value) VALUES
    ('delivery.days_ahead', '3'),
    ('delivery.lead_minutes', '60'),
    ('delivery.immediate_enabled', 'false'),
    ('fees.service_minor', '0'),
    ('orders.unpaid_ttl_minutes', '20'),
    ('payment.cash_enabled', 'true');
