-- Reset everyting related to permissions
BEGIN;
RESET ROLE;
REVOKE
SELECT,
	INSERT,
	UPDATE,
	DELETE ON slugs
FROM wishlist_user;
REVOKE
SELECT,
	INSERT,
	UPDATE,
	DELETE ON users
FROM wishlist_user;
REVOKE
SELECT,
	INSERT,
	UPDATE,
	DELETE ON wishlists
FROM wishlist_user;
REVOKE
SELECT,
	INSERT,
	UPDATE,
	DELETE ON wishlist_items
FROM wishlist_user;
DROP POLICY users_select_rls_policy on users;
DROP POLICY users_insert_rls_policy on users;
DROP POLICY users_update_rls_policy on users;
DROP POLICY wishlists_rls_policy on wishlists;
DROP POLICY wishlist_items_rls_policy on wishlist_items;
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE wishlists DISABLE ROW LEVEL SECURITY;
ALTER TABLE wishlist_items DISABLE ROW LEVEL SECURITY;
DROP ROLE wishlist_user;
COMMIT;
-------------------------------------------------
-- Set permissions
BEGIN;
CREATE ROLE wishlist_user;
-- Grant access to the query user to every table
-- Not giving DELETE permission because we'll use soft deletions
GRANT SELECT,
	INSERT,
	UPDATE ON slugs TO wishlist_user;
GRANT SELECT,
	INSERT,
	UPDATE ON users TO wishlist_user;
GRANT SELECT,
	INSERT,
	UPDATE ON wishlists TO wishlist_user;
GRANT SELECT,
	INSERT,
	UPDATE ON wishlist_items TO wishlist_user;
-- IDK why sequences need its own permission
GRANT USAGE,
	SELECT ON SEQUENCE slugs_id_seq TO wishlist_user;
GRANT USAGE,
	SELECT ON SEQUENCE wishlists_id_seq TO wishlist_user;
GRANT USAGE,
	SELECT ON SEQUENCE wishlist_items_id_seq TO wishlist_user;
-- users table is always insertable (create new users)
CREATE POLICY users_insert_rls_policy ON public.users FOR
INSERT TO wishlist_user WITH CHECK (true);
-- Getting data is only allowed to the own user
CREATE POLICY users_select_rls_policy ON public.users FOR
SELECT TO wishlist_user USING (
		id = current_setting('app.current_user_id')::int4
	);
-- Same thing for writting data
CREATE POLICY users_update_rls_policy ON public.users FOR
UPDATE TO wishlist_user WITH CHECK (
		id = current_setting('app.current_user_id')::int4
	);
-- wishlists are only available for the own user
-- Maybe we'll have to change this since other users have to be allowed to see other users wishlists
-- Other option is to have a new database user to handle that kind of viewers
CREATE POLICY wishlists_rls_policy ON public.wishlists FOR ALL TO wishlist_user USING (
	user_id = current_setting('app.current_user_id')::int4
) WITH CHECK (
	user_id = current_setting('app.current_user_id')::int4
);
-- Exactly same thing for wishlist_items
CREATE POLICY wishlist_items_rls_policy ON public.wishlist_items FOR ALL TO wishlist_user USING (
	wishlist_id IN (
		SELECT id
		FROM public.wishlists
		WHERE user_id = current_setting('app.current_user_id')::int4
	)
) WITH CHECK (
	wishlist_id IN (
		SELECT id
		FROM public.wishlists
		WHERE user_id = current_setting('app.current_user_id')::int4
	)
);
-- Then enable RLS for each table
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE wishlists ENABLE ROW LEVEL SECURITY;
ALTER TABLE wishlist_items ENABLE ROW LEVEL SECURITY;
COMMIT;
------------
-- -- This is the database user we'll use for all the queries
-- SET ROLE wishlist_user;
-- -- I think transactions are needed to keep the config context
-- -- Postgraphile takes care of it, so we'll only need this if we use raw queries
-- BEGIN;
-- SELECT set_config('app.current_user_id', '1', false);
-- SELECT * FROM wishlists; -- this should return only records from user_id = 1
-- COMMIT;
-- BEGIN;
-- SELECT set_config('app.current_user_id', '1', false);
-- INSERT INTO
-- 	wishlists (name, slug, user_id)
-- 	VALUES ('list 4', 'list-4', 1::int4); -- this should work since user_id = app.current_user_id
-- COMMIT; --                                 Probably we don't need the ::int4 cast. Check it and remove if so
-- BEGIN;
-- SELECT set_config('app.current_user_id', '2', false);
-- INSERT INTO
-- 	wishlists (name, slug, user_id)
-- 	VALUES ('list 4', 'list-4', 1::int4); -- this should NOT work since user_id != app.current_user_id
-- COMMIT;
-- BEGIN;
-- SELECT set_config('app.current_user_id', '1', false);
-- INSERT INTO
-- 	wishlist_items (name, wishlist_id)
-- 	VALUES ('item aaa', 1::int4); -- This should work. Not redundant because the RLS policy is different and more complex
-- COMMIT;