-- Sequence and defined type
CREATE SEQUENCE IF NOT EXISTS users_id_seq;
-- Table Definition
CREATE TABLE "public"."users" (
	"id" int4 NOT NULL DEFAULT nextval('users_id_seq'::regclass),
	"email" text NOT NULL,
	"name" text NOT NULL,
	PRIMARY KEY ("id")
);
-- This script only contains the table creation statements and does not fully represent the table in the database. It's still missing: indices, triggers. Do not use it as a backup.
-- Sequence and defined type
CREATE SEQUENCE IF NOT EXISTS wishlist_items_id_seq;
-- Table Definition
CREATE TABLE "public"."wishlist_items" (
	"id" int4 NOT NULL DEFAULT nextval('wishlist_items_id_seq'::regclass),
	"name" text NOT NULL,
	"url" text,
	"price" int4,
	"currency" text,
	"bought_count" int4 NOT NULL DEFAULT 0,
	"wishlist_id" int4 NOT NULL,
	PRIMARY KEY ("id")
);
-- This script only contains the table creation statements and does not fully represent the table in the database. It's still missing: indices, triggers. Do not use it as a backup.
-- Sequence and defined type
CREATE SEQUENCE IF NOT EXISTS wishlists_id_seq;
-- Table Definition
CREATE TABLE "public"."wishlists" (
	"id" int4 NOT NULL DEFAULT nextval('wishlists_id_seq'::regclass),
	"name" text NOT NULL,
	"slug" text NOT NULL,
	"user_id" int4 NOT NULL,
	PRIMARY KEY ("id")
);
ALTER TABLE "public"."wishlist_items"
ADD FOREIGN KEY ("wishlist_id") REFERENCES "public"."wishlists"("id");
ALTER TABLE "public"."wishlists"
ADD FOREIGN KEY ("user_id") REFERENCES "public"."users"("id");
--
-- Add a function to handle bought count increment
CREATE OR REPLACE FUNCTION increment_bought_count_wishlist_item (wishlist_item_id int4) RETURNS int4 AS $$
UPDATE wishlist_items
SET bought_count = bought_count + 1
WHERE id = wishlist_item_id
RETURNING bought_count;
$$ LANGUAGE SQL;
--
-- Wishlist settings as a different table so that we can apply different RLS
CREATE SEQUENCE IF NOT EXISTS wishlist_settings_id_seq;
CREATE TABLE "public"."wishlist_settings" (
	"id" int4 NOT NULL DEFAULT nextval('wishlist_settings_id_seq'::regclass),
	"visibility" bool NOT NULL DEFAULT true,
	"wishlist_id" int4 NOT NULL UNIQUE,
	CONSTRAINT "wishlist_settings_wishlist_id_fkey" FOREIGN KEY ("wishlist_id") REFERENCES "public"."wishlists"("id"),
	PRIMARY KEY ("id")
);
--
-- Add a trigger that creates setting for each new wishlist
CREATE OR REPLACE FUNCTION public.add_wishlists_settings () RETURNS TRIGGER AS $$ BEGIN
INSERT INTO "wishlist_settings" ("visibility", "wishlist_id")
VALUES(FALSE, NEW.id);
RETURN NEW;
END $$ LANGUAGE plpgsql;
CREATE OR REPLACE TRIGGER "wishlists_add_settings_insert"
AFTER
INSERT ON "wishlists" FOR EACH ROW EXECUTE PROCEDURE add_wishlists_settings();