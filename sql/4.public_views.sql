DROP VIEW IF EXISTS "public"."public_wishlist_items";
DROP VIEW IF EXISTS "public"."public_wishlists";
CREATE VIEW "public"."public_wishlists" AS
SELECT wishlists.id,
	wishlists.name,
	wishlists.slug
FROM wishlists
	JOIN wishlist_settings ON wishlists.id = wishlist_settings.wishlist_id
WHERE wishlist_settings.visibility = true;
--
CREATE VIEW "public"."public_wishlist_items" AS
SELECT wishlist_items.id,
	wishlist_items.name,
	wishlist_items.url,
	wishlist_items.price,
	wishlist_items.currency,
	wishlist_items.bought_count,
	wishlist_items.wishlist_id
FROM wishlist_items
	JOIN public_wishlists ON public_wishlists.id = wishlist_items.wishlist_id;
--
--
GRANT SELECT ON public_wishlists TO wishlist_user;
GRANT SELECT ON public_wishlist_items TO wishlist_user;
comment on view public_wishlist_items is E'@foreignKey (wishlist_id) references public_wishlists (id)';
comment on view public_wishlists is E'@unique id,slug\n@foreignKey (id) references public_wishlist_items (wishlist_id)';