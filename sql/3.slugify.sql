--
-- Needed
CREATE EXTENSION IF NOT EXISTS "unaccent";
--
-- Create slugs table
CREATE SEQUENCE IF NOT EXISTS slugs_id_seq;
CREATE SEQUENCE IF NOT EXISTS slugs_count_seq;
CREATE TABLE "public"."slugs" (
	"id" int4 NOT NULL DEFAULT nextval('slugs_id_seq'::regclass),
	"name" text NOT NULL,
	"count" int4 NOT NULL DEFAULT nextval('slugs_count_seq'::regclass),
	PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "name_unique" ON "public"."slugs" USING BTREE ("name");
--
-- Slugify function
CREATE OR REPLACE FUNCTION slugify (value TEXT) RETURNS TEXT AS $$ WITH "slugged" AS (
		SELECT regexp_replace(
				regexp_replace(
					regexp_replace(
						lower(unaccent ("value")),
						'[^a-z0-9\\-_]+',
						'-',
						'gi'
					),
					'\\-+$',
					''
				),
				'^\\-',
				''
			) AS "name"
	),
	"table_check" AS (
		SELECT slugged."name"
		FROM "slugged"
			LEFT JOIN slugs ON slugs.name = slugged.name
	),
	"return" AS (
		INSERT INTO "slugs" ("name", "count")
		SELECT "name"
		FROM "table_check" ON CONFLICT ("name") DO
		UPDATE
		SET "count" = "slugs"."count" + 1
		RETURNING CASE
				WHEN "count" > 0 THEN "name" || '-' || "count"
				ELSE "name"
			END AS "name"
	)
SELECT "name"
FROM "return";
$$ LANGUAGE SQL;
--
-- Add the trigger to the wishlists table
CREATE TRIGGER "wishlists_slug_insert" BEFORE
INSERT ON "wishlists" FOR EACH ROW
	WHEN (
		NEW.name IS NOT NULL
		AND NEW.slug IS NULL
	) EXECUTE PROCEDURE set_slug_from_name();
--
-- Make the slug column read only from the API side
COMMENT ON COLUMN "wishlists"."slug" IS E'@omit create,update';