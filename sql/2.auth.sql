-- Add JWT auth

CREATE EXTENSION pgcrypto; -- Enable pgcrypto


-- Add JWT type
CREATE OR REPLACE TYPE public.jwt_token as (
  exp integer, --expiry date as the unix epoch
  user_id integer,
  email text,
	name text
);


create OR REPLACE function public.authenticate(email text, password text) returns public.jwt_token as $$
declare account public.users;
begin
select a.* into account
from public.users as a
where a.email = authenticate.email;
if account.password_hash = crypt(password, account.password_hash) then return (
	extract(
		epoch
		from now() + interval '7 days'
	),
	account.id,
	account.email,
	account.name
)::public.jwt_token;
else return null;
end if;
end;
$$ language plpgsql strict security definer;
