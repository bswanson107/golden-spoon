-- Golden Spoon — seed Scag Family Pool 2025 (dev/test data)
-- Generated from data/scag_pool_2025.csv + data/games_2025.csv
-- Prerequisite: run 004_seed_2025_games.sql first.
-- Idempotent: safe to re-run (deletes and re-inserts picks for seed league).
-- Join in app with invite code: scag2025

do $$
begin
  if (select count(*) from public.nfl_games where season_year = 2025) = 0 then
    raise exception 'No 2025 games found. Run 004_seed_2025_games.sql first.';
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- Synthetic auth users + profiles
-- ---------------------------------------------------------------------------
insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data, is_super_admin, confirmation_token
) values (
  '7439c70c-c73e-4eec-af61-d2c7a0996373', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
  'scag-seed-erik@golden-spoon.test', crypt('seed-not-for-login', gen_salt('bf')), now(), now(), now(),
  '{"provider":"email","providers":["email"]}', '{"display_name":"Erik"}', false, ''
) on conflict (id) do nothing;

insert into auth.identities (
  id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at
) values (
  '7439c70c-c73e-4eec-af61-d2c7a0996373', '7439c70c-c73e-4eec-af61-d2c7a0996373',
  jsonb_build_object('sub', '7439c70c-c73e-4eec-af61-d2c7a0996373', 'email', 'scag-seed-erik@golden-spoon.test'),
  'email', '7439c70c-c73e-4eec-af61-d2c7a0996373', now(), now(), now()
) on conflict (provider, provider_id) do nothing;

insert into public.profiles (id, display_name)
values ('7439c70c-c73e-4eec-af61-d2c7a0996373', 'Erik')
on conflict (id) do update set display_name = excluded.display_name;

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data, is_super_admin, confirmation_token
) values (
  '56cac38f-d573-482a-a575-6da02e2288cb', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
  'scag-seed-nick@golden-spoon.test', crypt('seed-not-for-login', gen_salt('bf')), now(), now(), now(),
  '{"provider":"email","providers":["email"]}', '{"display_name":"Nick"}', false, ''
) on conflict (id) do nothing;

insert into auth.identities (
  id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at
) values (
  '56cac38f-d573-482a-a575-6da02e2288cb', '56cac38f-d573-482a-a575-6da02e2288cb',
  jsonb_build_object('sub', '56cac38f-d573-482a-a575-6da02e2288cb', 'email', 'scag-seed-nick@golden-spoon.test'),
  'email', '56cac38f-d573-482a-a575-6da02e2288cb', now(), now(), now()
) on conflict (provider, provider_id) do nothing;

insert into public.profiles (id, display_name)
values ('56cac38f-d573-482a-a575-6da02e2288cb', 'Nick')
on conflict (id) do update set display_name = excluded.display_name;

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data, is_super_admin, confirmation_token
) values (
  '88ae01d8-7c21-4e95-ad36-1dc27e0e453a', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
  'scag-seed-trish@golden-spoon.test', crypt('seed-not-for-login', gen_salt('bf')), now(), now(), now(),
  '{"provider":"email","providers":["email"]}', '{"display_name":"Trish"}', false, ''
) on conflict (id) do nothing;

insert into auth.identities (
  id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at
) values (
  '88ae01d8-7c21-4e95-ad36-1dc27e0e453a', '88ae01d8-7c21-4e95-ad36-1dc27e0e453a',
  jsonb_build_object('sub', '88ae01d8-7c21-4e95-ad36-1dc27e0e453a', 'email', 'scag-seed-trish@golden-spoon.test'),
  'email', '88ae01d8-7c21-4e95-ad36-1dc27e0e453a', now(), now(), now()
) on conflict (provider, provider_id) do nothing;

insert into public.profiles (id, display_name)
values ('88ae01d8-7c21-4e95-ad36-1dc27e0e453a', 'Trish')
on conflict (id) do update set display_name = excluded.display_name;

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data, is_super_admin, confirmation_token
) values (
  'e6c9506e-5c35-46d2-a5dc-7cb94194e588', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
  'scag-seed-des@golden-spoon.test', crypt('seed-not-for-login', gen_salt('bf')), now(), now(), now(),
  '{"provider":"email","providers":["email"]}', '{"display_name":"Des"}', false, ''
) on conflict (id) do nothing;

insert into auth.identities (
  id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at
) values (
  'e6c9506e-5c35-46d2-a5dc-7cb94194e588', 'e6c9506e-5c35-46d2-a5dc-7cb94194e588',
  jsonb_build_object('sub', 'e6c9506e-5c35-46d2-a5dc-7cb94194e588', 'email', 'scag-seed-des@golden-spoon.test'),
  'email', 'e6c9506e-5c35-46d2-a5dc-7cb94194e588', now(), now(), now()
) on conflict (provider, provider_id) do nothing;

insert into public.profiles (id, display_name)
values ('e6c9506e-5c35-46d2-a5dc-7cb94194e588', 'Des')
on conflict (id) do update set display_name = excluded.display_name;

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data, is_super_admin, confirmation_token
) values (
  '5e0d1cac-d616-471c-a1f6-3eef7c39a9af', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
  'scag-seed-dave-swan@golden-spoon.test', crypt('seed-not-for-login', gen_salt('bf')), now(), now(), now(),
  '{"provider":"email","providers":["email"]}', '{"display_name":"Dave Swan"}', false, ''
) on conflict (id) do nothing;

insert into auth.identities (
  id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at
) values (
  '5e0d1cac-d616-471c-a1f6-3eef7c39a9af', '5e0d1cac-d616-471c-a1f6-3eef7c39a9af',
  jsonb_build_object('sub', '5e0d1cac-d616-471c-a1f6-3eef7c39a9af', 'email', 'scag-seed-dave-swan@golden-spoon.test'),
  'email', '5e0d1cac-d616-471c-a1f6-3eef7c39a9af', now(), now(), now()
) on conflict (provider, provider_id) do nothing;

insert into public.profiles (id, display_name)
values ('5e0d1cac-d616-471c-a1f6-3eef7c39a9af', 'Dave Swan')
on conflict (id) do update set display_name = excluded.display_name;

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data, is_super_admin, confirmation_token
) values (
  'f926ce38-990c-4175-afe9-d3bfec7c0366', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
  'scag-seed-luke@golden-spoon.test', crypt('seed-not-for-login', gen_salt('bf')), now(), now(), now(),
  '{"provider":"email","providers":["email"]}', '{"display_name":"Luke"}', false, ''
) on conflict (id) do nothing;

insert into auth.identities (
  id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at
) values (
  'f926ce38-990c-4175-afe9-d3bfec7c0366', 'f926ce38-990c-4175-afe9-d3bfec7c0366',
  jsonb_build_object('sub', 'f926ce38-990c-4175-afe9-d3bfec7c0366', 'email', 'scag-seed-luke@golden-spoon.test'),
  'email', 'f926ce38-990c-4175-afe9-d3bfec7c0366', now(), now(), now()
) on conflict (provider, provider_id) do nothing;

insert into public.profiles (id, display_name)
values ('f926ce38-990c-4175-afe9-d3bfec7c0366', 'Luke')
on conflict (id) do update set display_name = excluded.display_name;

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data, is_super_admin, confirmation_token
) values (
  '9a6dd50f-42ab-4e37-a501-fe15f502554b', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
  'scag-seed-nancy@golden-spoon.test', crypt('seed-not-for-login', gen_salt('bf')), now(), now(), now(),
  '{"provider":"email","providers":["email"]}', '{"display_name":"Nancy"}', false, ''
) on conflict (id) do nothing;

insert into auth.identities (
  id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at
) values (
  '9a6dd50f-42ab-4e37-a501-fe15f502554b', '9a6dd50f-42ab-4e37-a501-fe15f502554b',
  jsonb_build_object('sub', '9a6dd50f-42ab-4e37-a501-fe15f502554b', 'email', 'scag-seed-nancy@golden-spoon.test'),
  'email', '9a6dd50f-42ab-4e37-a501-fe15f502554b', now(), now(), now()
) on conflict (provider, provider_id) do nothing;

insert into public.profiles (id, display_name)
values ('9a6dd50f-42ab-4e37-a501-fe15f502554b', 'Nancy')
on conflict (id) do update set display_name = excluded.display_name;

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data, is_super_admin, confirmation_token
) values (
  'f3d5b8c9-bddb-471d-a50e-2ddb8fdc938e', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
  'scag-seed-marcy@golden-spoon.test', crypt('seed-not-for-login', gen_salt('bf')), now(), now(), now(),
  '{"provider":"email","providers":["email"]}', '{"display_name":"Marcy"}', false, ''
) on conflict (id) do nothing;

insert into auth.identities (
  id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at
) values (
  'f3d5b8c9-bddb-471d-a50e-2ddb8fdc938e', 'f3d5b8c9-bddb-471d-a50e-2ddb8fdc938e',
  jsonb_build_object('sub', 'f3d5b8c9-bddb-471d-a50e-2ddb8fdc938e', 'email', 'scag-seed-marcy@golden-spoon.test'),
  'email', 'f3d5b8c9-bddb-471d-a50e-2ddb8fdc938e', now(), now(), now()
) on conflict (provider, provider_id) do nothing;

insert into public.profiles (id, display_name)
values ('f3d5b8c9-bddb-471d-a50e-2ddb8fdc938e', 'Marcy')
on conflict (id) do update set display_name = excluded.display_name;

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data, is_super_admin, confirmation_token
) values (
  '4bd4e5d9-2864-4ccb-a873-c549f8249f25', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
  'scag-seed-danny@golden-spoon.test', crypt('seed-not-for-login', gen_salt('bf')), now(), now(), now(),
  '{"provider":"email","providers":["email"]}', '{"display_name":"Danny"}', false, ''
) on conflict (id) do nothing;

insert into auth.identities (
  id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at
) values (
  '4bd4e5d9-2864-4ccb-a873-c549f8249f25', '4bd4e5d9-2864-4ccb-a873-c549f8249f25',
  jsonb_build_object('sub', '4bd4e5d9-2864-4ccb-a873-c549f8249f25', 'email', 'scag-seed-danny@golden-spoon.test'),
  'email', '4bd4e5d9-2864-4ccb-a873-c549f8249f25', now(), now(), now()
) on conflict (provider, provider_id) do nothing;

insert into public.profiles (id, display_name)
values ('4bd4e5d9-2864-4ccb-a873-c549f8249f25', 'Danny')
on conflict (id) do update set display_name = excluded.display_name;

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data, is_super_admin, confirmation_token
) values (
  '85978942-f5a7-4513-ae52-41055b9da732', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
  'scag-seed-todd@golden-spoon.test', crypt('seed-not-for-login', gen_salt('bf')), now(), now(), now(),
  '{"provider":"email","providers":["email"]}', '{"display_name":"Todd"}', false, ''
) on conflict (id) do nothing;

insert into auth.identities (
  id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at
) values (
  '85978942-f5a7-4513-ae52-41055b9da732', '85978942-f5a7-4513-ae52-41055b9da732',
  jsonb_build_object('sub', '85978942-f5a7-4513-ae52-41055b9da732', 'email', 'scag-seed-todd@golden-spoon.test'),
  'email', '85978942-f5a7-4513-ae52-41055b9da732', now(), now(), now()
) on conflict (provider, provider_id) do nothing;

insert into public.profiles (id, display_name)
values ('85978942-f5a7-4513-ae52-41055b9da732', 'Todd')
on conflict (id) do update set display_name = excluded.display_name;

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data, is_super_admin, confirmation_token
) values (
  '1dca2d73-65a7-4f28-acda-85dd4675e256', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
  'scag-seed-ben@golden-spoon.test', crypt('seed-not-for-login', gen_salt('bf')), now(), now(), now(),
  '{"provider":"email","providers":["email"]}', '{"display_name":"Ben"}', false, ''
) on conflict (id) do nothing;

insert into auth.identities (
  id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at
) values (
  '1dca2d73-65a7-4f28-acda-85dd4675e256', '1dca2d73-65a7-4f28-acda-85dd4675e256',
  jsonb_build_object('sub', '1dca2d73-65a7-4f28-acda-85dd4675e256', 'email', 'scag-seed-ben@golden-spoon.test'),
  'email', '1dca2d73-65a7-4f28-acda-85dd4675e256', now(), now(), now()
) on conflict (provider, provider_id) do nothing;

insert into public.profiles (id, display_name)
values ('1dca2d73-65a7-4f28-acda-85dd4675e256', 'Ben')
on conflict (id) do update set display_name = excluded.display_name;

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data, is_super_admin, confirmation_token
) values (
  'ebc98f93-b328-402f-a31e-4cf89582ae8e', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
  'scag-seed-grandma@golden-spoon.test', crypt('seed-not-for-login', gen_salt('bf')), now(), now(), now(),
  '{"provider":"email","providers":["email"]}', '{"display_name":"Grandma"}', false, ''
) on conflict (id) do nothing;

insert into auth.identities (
  id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at
) values (
  'ebc98f93-b328-402f-a31e-4cf89582ae8e', 'ebc98f93-b328-402f-a31e-4cf89582ae8e',
  jsonb_build_object('sub', 'ebc98f93-b328-402f-a31e-4cf89582ae8e', 'email', 'scag-seed-grandma@golden-spoon.test'),
  'email', 'ebc98f93-b328-402f-a31e-4cf89582ae8e', now(), now(), now()
) on conflict (provider, provider_id) do nothing;

insert into public.profiles (id, display_name)
values ('ebc98f93-b328-402f-a31e-4cf89582ae8e', 'Grandma')
on conflict (id) do update set display_name = excluded.display_name;

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data, is_super_admin, confirmation_token
) values (
  '44c8d145-65ef-4987-ac97-88e344d428c9', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
  'scag-seed-sheri@golden-spoon.test', crypt('seed-not-for-login', gen_salt('bf')), now(), now(), now(),
  '{"provider":"email","providers":["email"]}', '{"display_name":"Sheri"}', false, ''
) on conflict (id) do nothing;

insert into auth.identities (
  id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at
) values (
  '44c8d145-65ef-4987-ac97-88e344d428c9', '44c8d145-65ef-4987-ac97-88e344d428c9',
  jsonb_build_object('sub', '44c8d145-65ef-4987-ac97-88e344d428c9', 'email', 'scag-seed-sheri@golden-spoon.test'),
  'email', '44c8d145-65ef-4987-ac97-88e344d428c9', now(), now(), now()
) on conflict (provider, provider_id) do nothing;

insert into public.profiles (id, display_name)
values ('44c8d145-65ef-4987-ac97-88e344d428c9', 'Sheri')
on conflict (id) do update set display_name = excluded.display_name;

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data, is_super_admin, confirmation_token
) values (
  '7f865349-1435-488d-aafe-87b0565b8610', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
  'scag-seed-david-scag@golden-spoon.test', crypt('seed-not-for-login', gen_salt('bf')), now(), now(), now(),
  '{"provider":"email","providers":["email"]}', '{"display_name":"David Scag"}', false, ''
) on conflict (id) do nothing;

insert into auth.identities (
  id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at
) values (
  '7f865349-1435-488d-aafe-87b0565b8610', '7f865349-1435-488d-aafe-87b0565b8610',
  jsonb_build_object('sub', '7f865349-1435-488d-aafe-87b0565b8610', 'email', 'scag-seed-david-scag@golden-spoon.test'),
  'email', '7f865349-1435-488d-aafe-87b0565b8610', now(), now(), now()
) on conflict (provider, provider_id) do nothing;

insert into public.profiles (id, display_name)
values ('7f865349-1435-488d-aafe-87b0565b8610', 'David Scag')
on conflict (id) do update set display_name = excluded.display_name;

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data, is_super_admin, confirmation_token
) values (
  'b58e4217-d5df-498d-a488-c49c73033846', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
  'scag-seed-jackson@golden-spoon.test', crypt('seed-not-for-login', gen_salt('bf')), now(), now(), now(),
  '{"provider":"email","providers":["email"]}', '{"display_name":"Jackson"}', false, ''
) on conflict (id) do nothing;

insert into auth.identities (
  id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at
) values (
  'b58e4217-d5df-498d-a488-c49c73033846', 'b58e4217-d5df-498d-a488-c49c73033846',
  jsonb_build_object('sub', 'b58e4217-d5df-498d-a488-c49c73033846', 'email', 'scag-seed-jackson@golden-spoon.test'),
  'email', 'b58e4217-d5df-498d-a488-c49c73033846', now(), now(), now()
) on conflict (provider, provider_id) do nothing;

insert into public.profiles (id, display_name)
values ('b58e4217-d5df-498d-a488-c49c73033846', 'Jackson')
on conflict (id) do update set display_name = excluded.display_name;

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data, is_super_admin, confirmation_token
) values (
  '0621f100-0b9d-4158-ae0c-40f5455d0b7a', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
  'scag-seed-katherine@golden-spoon.test', crypt('seed-not-for-login', gen_salt('bf')), now(), now(), now(),
  '{"provider":"email","providers":["email"]}', '{"display_name":"Katherine"}', false, ''
) on conflict (id) do nothing;

insert into auth.identities (
  id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at
) values (
  '0621f100-0b9d-4158-ae0c-40f5455d0b7a', '0621f100-0b9d-4158-ae0c-40f5455d0b7a',
  jsonb_build_object('sub', '0621f100-0b9d-4158-ae0c-40f5455d0b7a', 'email', 'scag-seed-katherine@golden-spoon.test'),
  'email', '0621f100-0b9d-4158-ae0c-40f5455d0b7a', now(), now(), now()
) on conflict (provider, provider_id) do nothing;

insert into public.profiles (id, display_name)
values ('0621f100-0b9d-4158-ae0c-40f5455d0b7a', 'Katherine')
on conflict (id) do update set display_name = excluded.display_name;

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data, is_super_admin, confirmation_token
) values (
  '2019ef35-f471-4858-a726-89acc2594138', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
  'scag-seed-kristen@golden-spoon.test', crypt('seed-not-for-login', gen_salt('bf')), now(), now(), now(),
  '{"provider":"email","providers":["email"]}', '{"display_name":"Kristen"}', false, ''
) on conflict (id) do nothing;

insert into auth.identities (
  id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at
) values (
  '2019ef35-f471-4858-a726-89acc2594138', '2019ef35-f471-4858-a726-89acc2594138',
  jsonb_build_object('sub', '2019ef35-f471-4858-a726-89acc2594138', 'email', 'scag-seed-kristen@golden-spoon.test'),
  'email', '2019ef35-f471-4858-a726-89acc2594138', now(), now(), now()
) on conflict (provider, provider_id) do nothing;

insert into public.profiles (id, display_name)
values ('2019ef35-f471-4858-a726-89acc2594138', 'Kristen')
on conflict (id) do update set display_name = excluded.display_name;

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data, is_super_admin, confirmation_token
) values (
  'c821b559-7cd9-491d-abd3-082c877eeeb8', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
  'scag-seed-ryan@golden-spoon.test', crypt('seed-not-for-login', gen_salt('bf')), now(), now(), now(),
  '{"provider":"email","providers":["email"]}', '{"display_name":"Ryan"}', false, ''
) on conflict (id) do nothing;

insert into auth.identities (
  id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at
) values (
  'c821b559-7cd9-491d-abd3-082c877eeeb8', 'c821b559-7cd9-491d-abd3-082c877eeeb8',
  jsonb_build_object('sub', 'c821b559-7cd9-491d-abd3-082c877eeeb8', 'email', 'scag-seed-ryan@golden-spoon.test'),
  'email', 'c821b559-7cd9-491d-abd3-082c877eeeb8', now(), now(), now()
) on conflict (provider, provider_id) do nothing;

insert into public.profiles (id, display_name)
values ('c821b559-7cd9-491d-abd3-082c877eeeb8', 'Ryan')
on conflict (id) do update set display_name = excluded.display_name;

-- ---------------------------------------------------------------------------
-- League + members
-- ---------------------------------------------------------------------------
insert into public.leagues (
  id, name, season_year, commissioner_id, invite_code, is_active
) values (
  'b0000001-0000-4000-8000-000000000001', 'Scag Family Pool 2025', 2025, '7439c70c-c73e-4eec-af61-d2c7a0996373', 'scag2025', true
) on conflict (id) do update set
  name = excluded.name,
  season_year = excluded.season_year,
  commissioner_id = excluded.commissioner_id,
  invite_code = excluded.invite_code;

insert into public.league_members (league_id, user_id)
values
  ('b0000001-0000-4000-8000-000000000001', '7439c70c-c73e-4eec-af61-d2c7a0996373'),
  ('b0000001-0000-4000-8000-000000000001', '56cac38f-d573-482a-a575-6da02e2288cb'),
  ('b0000001-0000-4000-8000-000000000001', '88ae01d8-7c21-4e95-ad36-1dc27e0e453a'),
  ('b0000001-0000-4000-8000-000000000001', 'e6c9506e-5c35-46d2-a5dc-7cb94194e588'),
  ('b0000001-0000-4000-8000-000000000001', '5e0d1cac-d616-471c-a1f6-3eef7c39a9af'),
  ('b0000001-0000-4000-8000-000000000001', 'f926ce38-990c-4175-afe9-d3bfec7c0366'),
  ('b0000001-0000-4000-8000-000000000001', '9a6dd50f-42ab-4e37-a501-fe15f502554b'),
  ('b0000001-0000-4000-8000-000000000001', 'f3d5b8c9-bddb-471d-a50e-2ddb8fdc938e'),
  ('b0000001-0000-4000-8000-000000000001', '4bd4e5d9-2864-4ccb-a873-c549f8249f25'),
  ('b0000001-0000-4000-8000-000000000001', '85978942-f5a7-4513-ae52-41055b9da732'),
  ('b0000001-0000-4000-8000-000000000001', '1dca2d73-65a7-4f28-acda-85dd4675e256'),
  ('b0000001-0000-4000-8000-000000000001', 'ebc98f93-b328-402f-a31e-4cf89582ae8e'),
  ('b0000001-0000-4000-8000-000000000001', '44c8d145-65ef-4987-ac97-88e344d428c9'),
  ('b0000001-0000-4000-8000-000000000001', '7f865349-1435-488d-aafe-87b0565b8610'),
  ('b0000001-0000-4000-8000-000000000001', 'b58e4217-d5df-498d-a488-c49c73033846'),
  ('b0000001-0000-4000-8000-000000000001', '0621f100-0b9d-4158-ae0c-40f5455d0b7a'),
  ('b0000001-0000-4000-8000-000000000001', '2019ef35-f471-4858-a726-89acc2594138'),
  ('b0000001-0000-4000-8000-000000000001', 'c821b559-7cd9-491d-abd3-082c877eeeb8')
on conflict (league_id, user_id) do nothing;

-- ---------------------------------------------------------------------------
-- Picks (324 rows)
-- Duplicate team reuse in CSV → missed pick (0 pts)
-- ---------------------------------------------------------------------------
delete from public.picks where league_id = 'b0000001-0000-4000-8000-000000000001';

set session_replication_role = replica;

insert into public.picks (
  league_id, user_id, season_year, week_number, game_id, team_id,
  submitted_at, win_pct_at_pick, is_underdog_at_pick, team_season_wins_at_pick,
  outcome, points_awarded
)
values
  ('b0000001-0000-4000-8000-000000000001', '7439c70c-c73e-4eec-af61-d2c7a0996373', 2025, 1, (select id from public.nfl_games where espn_event_id = '2025_01_ARI_NO'), 'ARI', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_01_ARI_NO'), 70.02, false, 0, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '7439c70c-c73e-4eec-af61-d2c7a0996373', 2025, 2, (select id from public.nfl_games where espn_event_id = '2025_02_BUF_NYJ'), 'BUF', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_02_BUF_NYJ'), 71.36, false, 1, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '7439c70c-c73e-4eec-af61-d2c7a0996373', 2025, 3, (select id from public.nfl_games where espn_event_id = '2025_03_NYJ_TB'), 'TB', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_03_NYJ_TB'), 74.41, false, 2, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '7439c70c-c73e-4eec-af61-d2c7a0996373', 2025, 4, (select id from public.nfl_games where espn_event_id = '2025_04_LAC_NYG'), 'LAC', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_04_LAC_NYG'), 70.95, false, 3, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '7439c70c-c73e-4eec-af61-d2c7a0996373', 2025, 5, (select id from public.nfl_games where espn_event_id = '2025_05_NYG_NO'), 'NYG', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_05_NYG_NO'), 47.83, false, 1, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '7439c70c-c73e-4eec-af61-d2c7a0996373', 2025, 6, (select id from public.nfl_games where espn_event_id = '2025_06_DEN_NYJ'), 'DEN', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_06_DEN_NYJ'), 76.59, false, 3, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '7439c70c-c73e-4eec-af61-d2c7a0996373', 2025, 7, (select id from public.nfl_games where espn_event_id = '2025_07_CAR_NYJ'), 'CAR', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_07_CAR_NYJ'), 49.57, false, 3, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '7439c70c-c73e-4eec-af61-d2c7a0996373', 2025, 8, (select id from public.nfl_games where espn_event_id = '2025_08_TEN_IND'), 'IND', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_08_TEN_IND'), 90.83, false, 6, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '7439c70c-c73e-4eec-af61-d2c7a0996373', 2025, 9, (select id from public.nfl_games where espn_event_id = '2025_09_NO_LA'), 'LAR', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_09_NO_LA'), 88.7, false, 5, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '7439c70c-c73e-4eec-af61-d2c7a0996373', 2025, 10, (select id from public.nfl_games where espn_event_id = '2025_10_DET_WAS'), 'DET', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_10_DET_WAS'), 78.67, false, 5, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '7439c70c-c73e-4eec-af61-d2c7a0996373', 2025, 11, (select id from public.nfl_games where espn_event_id = '2025_11_NYJ_NE'), 'NE', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_11_NYJ_NE'), 86.77, false, 8, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '7439c70c-c73e-4eec-af61-d2c7a0996373', 2025, 12, (select id from public.nfl_games where espn_event_id = '2025_12_NYJ_BAL'), 'BAL', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_12_NYJ_BAL'), 87.62, false, 5, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '7439c70c-c73e-4eec-af61-d2c7a0996373', 2025, 13, (select id from public.nfl_games where espn_event_id = '2025_13_SF_CLE'), 'SF', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_13_SF_CLE'), 68.54, false, 8, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '7439c70c-c73e-4eec-af61-d2c7a0996373', 2025, 14, (select id from public.nfl_games where espn_event_id = '2025_14_SEA_ATL'), 'SEA', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_14_SEA_ATL'), 74.78, false, 9, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '7439c70c-c73e-4eec-af61-d2c7a0996373', 2025, 15, (select id from public.nfl_games where espn_event_id = '2025_15_LV_PHI'), 'PHI', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_15_LV_PHI'), 87.21, false, 8, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '7439c70c-c73e-4eec-af61-d2c7a0996373', 2025, 16, (select id from public.nfl_games where espn_event_id = '2025_16_LV_HOU'), 'HOU', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_16_LV_HOU'), 90.4, false, 9, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '7439c70c-c73e-4eec-af61-d2c7a0996373', 2025, 17, (select id from public.nfl_games where espn_event_id = '2025_17_NO_TEN'), 'NO', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_17_NO_TEN'), 52.17, false, 5, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '7439c70c-c73e-4eec-af61-d2c7a0996373', 2025, 18, (select id from public.nfl_games where espn_event_id = '2025_18_KC_LV'), 'LV', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_18_KC_LV'), 33.64, false, 2, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '56cac38f-d573-482a-a575-6da02e2288cb', 2025, 1, (select id from public.nfl_games where espn_event_id = '2025_01_NYG_WAS'), 'WAS', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_01_NYG_WAS'), 71.8, false, 0, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '56cac38f-d573-482a-a575-6da02e2288cb', 2025, 2, (select id from public.nfl_games where espn_event_id = '2025_02_NYG_DAL'), 'DAL', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_02_NYG_DAL'), 67.5, false, 0, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '56cac38f-d573-482a-a575-6da02e2288cb', 2025, 3, (select id from public.nfl_games where espn_event_id = '2025_03_MIA_BUF'), 'BUF', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_03_MIA_BUF'), 85.25, false, 2, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '56cac38f-d573-482a-a575-6da02e2288cb', 2025, 4, (select id from public.nfl_games where espn_event_id = '2025_04_TEN_HOU'), 'HOU', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_04_TEN_HOU'), 78.19, false, 0, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '56cac38f-d573-482a-a575-6da02e2288cb', 2025, 5, (select id from public.nfl_games where espn_event_id = '2025_05_DET_CIN'), 'DET', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_05_DET_CIN'), 81.73, false, 3, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '56cac38f-d573-482a-a575-6da02e2288cb', 2025, 6, (select id from public.nfl_games where espn_event_id = '2025_06_LAC_MIA'), 'LAC', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_06_LAC_MIA'), 64.47, false, 3, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '56cac38f-d573-482a-a575-6da02e2288cb', 2025, 7, (select id from public.nfl_games where espn_event_id = '2025_07_NE_TEN'), 'NE', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_07_NE_TEN'), 71.36, false, 4, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '56cac38f-d573-482a-a575-6da02e2288cb', 2025, 8, (select id from public.nfl_games where espn_event_id = '2025_08_TB_NO'), 'TB', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_08_TB_NO'), 65.75, false, 5, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '56cac38f-d573-482a-a575-6da02e2288cb', 2025, 9, (select id from public.nfl_games where espn_event_id = '2025_09_NO_LA'), 'LAR', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_09_NO_LA'), 88.7, false, 5, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '56cac38f-d573-482a-a575-6da02e2288cb', 2025, 10, (select id from public.nfl_games where espn_event_id = '2025_10_ATL_IND'), 'IND', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_10_ATL_IND'), 72.58, false, 7, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '56cac38f-d573-482a-a575-6da02e2288cb', 2025, 11, (select id from public.nfl_games where espn_event_id = '2025_11_GB_NYG'), 'GB', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_11_GB_NYG'), 78.19, false, 5, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '56cac38f-d573-482a-a575-6da02e2288cb', 2025, 12, (select id from public.nfl_games where espn_event_id = '2025_12_SEA_TEN'), 'SEA', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_12_SEA_TEN'), 86.77, false, 7, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '56cac38f-d573-482a-a575-6da02e2288cb', 2025, 13, (select id from public.nfl_games where espn_event_id = '2025_13_DEN_WAS'), 'DEN', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_13_DEN_WAS'), 72.58, false, 9, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '56cac38f-d573-482a-a575-6da02e2288cb', 2025, 14, (select id from public.nfl_games where espn_event_id = '2025_14_PHI_LAC'), 'PHI', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_14_PHI_LAC'), 52.17, false, 8, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '56cac38f-d573-482a-a575-6da02e2288cb', 2025, 15, (select id from public.nfl_games where espn_event_id = '2025_15_NYJ_JAX'), 'JAX', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_15_NYJ_JAX'), 87.62, false, 9, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '56cac38f-d573-482a-a575-6da02e2288cb', 2025, 16, (select id from public.nfl_games where espn_event_id = '2025_16_GB_CHI'), 'CHI', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_16_GB_CHI'), 51.74, false, 10, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '56cac38f-d573-482a-a575-6da02e2288cb', 2025, 17, (select id from public.nfl_games where espn_event_id = '2025_17_ARI_CIN'), 'CIN', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_17_ARI_CIN'), 74.41, false, 5, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '56cac38f-d573-482a-a575-6da02e2288cb', 2025, 18, (select id from public.nfl_games where espn_event_id = '2025_18_KC_LV'), 'KC', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_18_KC_LV'), 66.36, false, 6, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '88ae01d8-7c21-4e95-ad36-1dc27e0e453a', 2025, 1, (select id from public.nfl_games where espn_event_id = '2025_01_CAR_JAX'), 'JAX', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_01_CAR_JAX'), 64.47, false, 0, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '88ae01d8-7c21-4e95-ad36-1dc27e0e453a', 2025, 2, (select id from public.nfl_games where espn_event_id = '2025_02_SF_NO'), 'SF', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_02_SF_NO'), 59.96, false, 1, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '88ae01d8-7c21-4e95-ad36-1dc27e0e453a', 2025, 3, (select id from public.nfl_games where espn_event_id = '2025_03_NO_SEA'), 'SEA', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_03_NO_SEA'), 75.72, false, 1, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '88ae01d8-7c21-4e95-ad36-1dc27e0e453a', 2025, 4, (select id from public.nfl_games where espn_event_id = '2025_04_TEN_HOU'), 'HOU', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_04_TEN_HOU'), 78.19, false, 0, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '88ae01d8-7c21-4e95-ad36-1dc27e0e453a', 2025, 5, (select id from public.nfl_games where espn_event_id = '2025_05_LV_IND'), 'IND', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_05_LV_IND'), 75.08, false, 3, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '88ae01d8-7c21-4e95-ad36-1dc27e0e453a', 2025, 6, (select id from public.nfl_games where espn_event_id = '2025_06_LA_BAL'), 'LAR', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_06_LA_BAL'), 74.78, false, 3, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '88ae01d8-7c21-4e95-ad36-1dc27e0e453a', 2025, 7, (select id from public.nfl_games where espn_event_id = '2025_07_MIA_CLE'), 'CLE', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_07_MIA_CLE'), 57.21, false, 1, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '88ae01d8-7c21-4e95-ad36-1dc27e0e453a', 2025, 8, (select id from public.nfl_games where espn_event_id = '2025_08_BUF_CAR'), 'BUF', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_08_BUF_CAR'), 76.59, false, 4, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '88ae01d8-7c21-4e95-ad36-1dc27e0e453a', 2025, 9, (select id from public.nfl_games where espn_event_id = '2025_09_BAL_MIA'), 'BAL', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_09_BAL_MIA'), 78.67, false, 2, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '88ae01d8-7c21-4e95-ad36-1dc27e0e453a', 2025, 10, (select id from public.nfl_games where espn_event_id = '2025_10_NO_CAR'), 'CAR', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_10_NO_CAR'), 68.06, false, 5, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '88ae01d8-7c21-4e95-ad36-1dc27e0e453a', 2025, 11, (select id from public.nfl_games where espn_event_id = '2025_11_CIN_PIT'), 'PIT', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_11_CIN_PIT'), 68.54, false, 5, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '88ae01d8-7c21-4e95-ad36-1dc27e0e453a', 2025, 12, (select id from public.nfl_games where espn_event_id = '2025_12_NYG_DET'), 'DET', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_12_NYG_DET'), 87.62, false, 6, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '88ae01d8-7c21-4e95-ad36-1dc27e0e453a', 2025, 13, (select id from public.nfl_games where espn_event_id = '2025_13_LV_LAC'), 'LAC', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_13_LV_LAC'), 82.23, false, 7, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '88ae01d8-7c21-4e95-ad36-1dc27e0e453a', 2025, 14, (select id from public.nfl_games where espn_event_id = '2025_14_DEN_LV'), 'DEN', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_14_DEN_LV'), 79.14, false, 10, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '88ae01d8-7c21-4e95-ad36-1dc27e0e453a', 2025, 15, (select id from public.nfl_games where espn_event_id = '2025_15_LV_PHI'), 'PHI', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_15_LV_PHI'), 87.21, false, 8, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '88ae01d8-7c21-4e95-ad36-1dc27e0e453a', 2025, 16, (select id from public.nfl_games where espn_event_id = '2025_16_KC_TEN'), 'KC', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_16_KC_TEN'), 62.25, false, 6, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '88ae01d8-7c21-4e95-ad36-1dc27e0e453a', 2025, 17, (select id from public.nfl_games where espn_event_id = '2025_17_NE_NYJ'), 'NE', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_17_NE_NYJ'), 86.77, false, 12, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '88ae01d8-7c21-4e95-ad36-1dc27e0e453a', 2025, 18, (select id from public.nfl_games where espn_event_id = '2025_18_DAL_NYG'), 'DAL', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_18_DAL_NYG'), 59.96, false, 7, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', 'e6c9506e-5c35-46d2-a5dc-7cb94194e588', 2025, 1, (select id from public.nfl_games where espn_event_id = '2025_01_ARI_NO'), 'ARI', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_01_ARI_NO'), 70.02, false, 0, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'e6c9506e-5c35-46d2-a5dc-7cb94194e588', 2025, 2, (select id from public.nfl_games where espn_event_id = '2025_02_LA_TEN'), 'LAR', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_02_LA_TEN'), 68.54, false, 1, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'e6c9506e-5c35-46d2-a5dc-7cb94194e588', 2025, 3, (select id from public.nfl_games where espn_event_id = '2025_03_NYJ_TB'), 'TB', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_03_NYJ_TB'), 74.41, false, 2, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'e6c9506e-5c35-46d2-a5dc-7cb94194e588', 2025, 4, (select id from public.nfl_games where espn_event_id = '2025_04_CIN_DEN'), 'DEN', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_04_CIN_DEN'), 79.14, false, 1, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'e6c9506e-5c35-46d2-a5dc-7cb94194e588', 2025, 5, (select id from public.nfl_games where espn_event_id = '2025_05_LV_IND'), 'IND', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_05_LV_IND'), 75.08, false, 3, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'e6c9506e-5c35-46d2-a5dc-7cb94194e588', 2025, 6, (select id from public.nfl_games where espn_event_id = '2025_06_NE_NO'), 'NE', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_06_NE_NO'), 63.09, false, 3, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'e6c9506e-5c35-46d2-a5dc-7cb94194e588', 2025, 7, (select id from public.nfl_games where espn_event_id = '2025_07_NO_CHI'), 'CHI', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_07_NO_CHI'), 66.36, false, 3, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'e6c9506e-5c35-46d2-a5dc-7cb94194e588', 2025, 8, (select id from public.nfl_games where espn_event_id = '2025_08_NYJ_CIN'), 'CIN', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_08_NYJ_CIN'), 69.08, false, 3, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', 'e6c9506e-5c35-46d2-a5dc-7cb94194e588', 2025, 9, (select id from public.nfl_games where espn_event_id = '2025_09_LAC_TEN'), 'LAC', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_09_LAC_TEN'), 83.16, false, 5, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'e6c9506e-5c35-46d2-a5dc-7cb94194e588', 2025, 10, (select id from public.nfl_games where espn_event_id = '2025_10_NO_CAR'), 'CAR', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_10_NO_CAR'), 68.06, false, 5, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', 'e6c9506e-5c35-46d2-a5dc-7cb94194e588', 2025, 11, (select id from public.nfl_games where espn_event_id = '2025_11_GB_NYG'), 'GB', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_11_GB_NYG'), 78.19, false, 5, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'e6c9506e-5c35-46d2-a5dc-7cb94194e588', 2025, 12, (select id from public.nfl_games where espn_event_id = '2025_12_NYJ_BAL'), 'BAL', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_12_NYJ_BAL'), 87.62, false, 5, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'e6c9506e-5c35-46d2-a5dc-7cb94194e588', 2025, 13, (select id from public.nfl_games where espn_event_id = '2025_13_MIN_SEA'), 'SEA', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_13_MIN_SEA'), 86.3, false, 8, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'e6c9506e-5c35-46d2-a5dc-7cb94194e588', 2025, 14, (select id from public.nfl_games where espn_event_id = '2025_14_CIN_BUF'), 'BUF', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_14_CIN_BUF'), 70.95, false, 8, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'e6c9506e-5c35-46d2-a5dc-7cb94194e588', 2025, 15, (select id from public.nfl_games where espn_event_id = '2025_15_TEN_SF'), 'SF', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_15_TEN_SF'), 86.3, false, 9, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'e6c9506e-5c35-46d2-a5dc-7cb94194e588', 2025, 16, (select id from public.nfl_games where espn_event_id = '2025_16_LV_HOU'), 'HOU', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_16_LV_HOU'), 90.4, false, 9, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'e6c9506e-5c35-46d2-a5dc-7cb94194e588', 2025, 17, (select id from public.nfl_games where espn_event_id = '2025_17_DET_MIN'), 'DET', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_17_DET_MIN'), 75.08, false, 8, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', 'e6c9506e-5c35-46d2-a5dc-7cb94194e588', 2025, 18, (select id from public.nfl_games where espn_event_id = '2025_18_TEN_JAX'), 'JAX', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_18_TEN_JAX'), 84.65, false, 12, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '5e0d1cac-d616-471c-a1f6-3eef7c39a9af', 2025, 1, (select id from public.nfl_games where espn_event_id = '2025_01_NYG_WAS'), 'WAS', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_01_NYG_WAS'), 71.8, false, 0, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '5e0d1cac-d616-471c-a1f6-3eef7c39a9af', 2025, 2, (select id from public.nfl_games where espn_event_id = '2025_02_CAR_ARI'), 'ARI', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_02_CAR_ARI'), 72.58, false, 1, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '5e0d1cac-d616-471c-a1f6-3eef7c39a9af', 2025, 3, (select id from public.nfl_games where espn_event_id = '2025_03_MIA_BUF'), 'BUF', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_03_MIA_BUF'), 85.25, false, 2, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '5e0d1cac-d616-471c-a1f6-3eef7c39a9af', 2025, 4, (select id from public.nfl_games where espn_event_id = '2025_04_GB_DAL'), 'GB', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_04_GB_DAL'), 74.41, false, 2, 'tie', 0.5),
  ('b0000001-0000-4000-8000-000000000001', '5e0d1cac-d616-471c-a1f6-3eef7c39a9af', 2025, 5, (select id from public.nfl_games where espn_event_id = '2025_05_DET_CIN'), 'DET', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_05_DET_CIN'), 81.73, false, 3, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '5e0d1cac-d616-471c-a1f6-3eef7c39a9af', 2025, 6, (select id from public.nfl_games where espn_event_id = '2025_06_NE_NO'), 'NE', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_06_NE_NO'), 63.09, false, 3, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '5e0d1cac-d616-471c-a1f6-3eef7c39a9af', 2025, 7, (select id from public.nfl_games where espn_event_id = '2025_07_PIT_CIN'), 'PIT', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_07_PIT_CIN'), 68.06, false, 4, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '5e0d1cac-d616-471c-a1f6-3eef7c39a9af', 2025, 8, (select id from public.nfl_games where espn_event_id = '2025_08_WAS_KC'), 'KC', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_08_WAS_KC'), 84, false, 4, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '5e0d1cac-d616-471c-a1f6-3eef7c39a9af', 2025, 9, (select id from public.nfl_games where espn_event_id = '2025_09_NO_LA'), 'LAR', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_09_NO_LA'), 88.7, false, 5, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '5e0d1cac-d616-471c-a1f6-3eef7c39a9af', 2025, 10, (select id from public.nfl_games where espn_event_id = '2025_10_LV_DEN'), 'DEN', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_10_LV_DEN'), 80, false, 7, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '5e0d1cac-d616-471c-a1f6-3eef7c39a9af', 2025, 11, (select id from public.nfl_games where espn_event_id = '2025_11_BAL_CLE'), 'BAL', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_11_BAL_CLE'), 78.19, false, 4, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '5e0d1cac-d616-471c-a1f6-3eef7c39a9af', 2025, 12, (select id from public.nfl_games where espn_event_id = '2025_12_SEA_TEN'), 'SEA', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_12_SEA_TEN'), 86.77, false, 7, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '5e0d1cac-d616-471c-a1f6-3eef7c39a9af', 2025, 13, (select id from public.nfl_games where espn_event_id = '2025_13_JAX_TEN'), 'JAX', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_13_JAX_TEN'), 70.02, false, 7, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '5e0d1cac-d616-471c-a1f6-3eef7c39a9af', 2025, 14, (select id from public.nfl_games where espn_event_id = '2025_14_NO_TB'), 'TB', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_14_NO_TB'), 77.68, false, 7, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '5e0d1cac-d616-471c-a1f6-3eef7c39a9af', 2025, 15, (select id from public.nfl_games where espn_event_id = '2025_15_TEN_SF'), 'SF', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_15_TEN_SF'), 86.3, false, 9, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '5e0d1cac-d616-471c-a1f6-3eef7c39a9af', 2025, 16, (select id from public.nfl_games where espn_event_id = '2025_16_PHI_WAS'), 'PHI', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_16_PHI_WAS'), 76, false, 9, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '5e0d1cac-d616-471c-a1f6-3eef7c39a9af', 2025, 17, (select id from public.nfl_games where espn_event_id = '2025_17_ARI_CIN'), 'CIN', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_17_ARI_CIN'), 74.41, false, 5, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '5e0d1cac-d616-471c-a1f6-3eef7c39a9af', 2025, 18, (select id from public.nfl_games where espn_event_id = '2025_18_CAR_TB'), 'CAR', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_18_CAR_TB'), 41.7, false, 8, 'missed', 0),
  ('b0000001-0000-4000-8000-000000000001', 'f926ce38-990c-4175-afe9-d3bfec7c0366', 2025, 1, (select id from public.nfl_games where espn_event_id = '2025_01_TEN_DEN'), 'DEN', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_01_TEN_DEN'), 78.67, false, 0, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'f926ce38-990c-4175-afe9-d3bfec7c0366', 2025, 2, (select id from public.nfl_games where espn_event_id = '2025_02_LA_TEN'), 'LAR', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_02_LA_TEN'), 68.54, false, 1, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'f926ce38-990c-4175-afe9-d3bfec7c0366', 2025, 3, (select id from public.nfl_games where espn_event_id = '2025_03_NYJ_TB'), 'TB', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_03_NYJ_TB'), 74.41, false, 2, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'f926ce38-990c-4175-afe9-d3bfec7c0366', 2025, 4, (select id from public.nfl_games where espn_event_id = '2025_04_NO_BUF'), 'BUF', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_04_NO_BUF'), 89.34, false, 3, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'f926ce38-990c-4175-afe9-d3bfec7c0366', 2025, 5, (select id from public.nfl_games where espn_event_id = '2025_05_LV_IND'), 'IND', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_05_LV_IND'), 75.08, false, 3, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'f926ce38-990c-4175-afe9-d3bfec7c0366', 2025, 6, (select id from public.nfl_games where espn_event_id = '2025_06_NE_NO'), 'NE', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_06_NE_NO'), 63.09, false, 3, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'f926ce38-990c-4175-afe9-d3bfec7c0366', 2025, 7, (select id from public.nfl_games where espn_event_id = '2025_07_MIA_CLE'), 'CLE', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_07_MIA_CLE'), 57.21, false, 1, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'f926ce38-990c-4175-afe9-d3bfec7c0366', 2025, 8, (select id from public.nfl_games where espn_event_id = '2025_08_MIA_ATL'), 'ATL', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_08_MIA_ATL'), 74.78, false, 3, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', 'f926ce38-990c-4175-afe9-d3bfec7c0366', 2025, 9, (select id from public.nfl_games where espn_event_id = '2025_09_CAR_GB'), 'GB', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_09_CAR_GB'), 87.21, false, 5, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', 'f926ce38-990c-4175-afe9-d3bfec7c0366', 2025, 10, (select id from public.nfl_games where espn_event_id = '2025_10_ARI_SEA'), 'SEA', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_10_ARI_SEA'), 74.09, false, 6, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'f926ce38-990c-4175-afe9-d3bfec7c0366', 2025, 11, (select id from public.nfl_games where espn_event_id = '2025_11_SF_ARI'), 'SF', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_11_SF_ARI'), 63.09, false, 6, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'f926ce38-990c-4175-afe9-d3bfec7c0366', 2025, 12, (select id from public.nfl_games where espn_event_id = '2025_12_NYG_DET'), 'DET', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_12_NYG_DET'), 87.62, false, 6, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'f926ce38-990c-4175-afe9-d3bfec7c0366', 2025, 13, (select id from public.nfl_games where espn_event_id = '2025_13_NO_MIA'), 'MIA', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_13_NO_MIA'), 68.54, false, 4, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'f926ce38-990c-4175-afe9-d3bfec7c0366', 2025, 14, (select id from public.nfl_games where espn_event_id = '2025_14_WAS_MIN'), 'WAS', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_14_WAS_MIN'), 51.08, false, 3, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', 'f926ce38-990c-4175-afe9-d3bfec7c0366', 2025, 15, (select id from public.nfl_games where espn_event_id = '2025_15_CAR_NO'), 'CAR', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_15_CAR_NO'), 57.21, false, 7, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', 'f926ce38-990c-4175-afe9-d3bfec7c0366', 2025, 16, (select id from public.nfl_games where espn_event_id = '2025_16_NYJ_NO'), 'NO', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_16_NYJ_NO'), 71.8, false, 4, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'f926ce38-990c-4175-afe9-d3bfec7c0366', 2025, 17, (select id from public.nfl_games where espn_event_id = '2025_17_NYG_LV'), 'NYG', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_17_NYG_LV'), 59.34, false, 2, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'f926ce38-990c-4175-afe9-d3bfec7c0366', 2025, 18, (select id from public.nfl_games where espn_event_id = '2025_18_KC_LV'), 'LV', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_18_KC_LV'), 33.64, false, 2, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '9a6dd50f-42ab-4e37-a501-fe15f502554b', 2025, 1, (select id from public.nfl_games where espn_event_id = '2025_01_TEN_DEN'), 'DEN', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_01_TEN_DEN'), 78.67, false, 0, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '9a6dd50f-42ab-4e37-a501-fe15f502554b', 2025, 2, (select id from public.nfl_games where espn_event_id = '2025_02_CAR_ARI'), 'ARI', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_02_CAR_ARI'), 72.58, false, 1, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '9a6dd50f-42ab-4e37-a501-fe15f502554b', 2025, 3, (select id from public.nfl_games where espn_event_id = '2025_03_NO_SEA'), 'SEA', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_03_NO_SEA'), 75.72, false, 1, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '9a6dd50f-42ab-4e37-a501-fe15f502554b', 2025, 4, (select id from public.nfl_games where espn_event_id = '2025_04_NO_BUF'), 'BUF', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_04_NO_BUF'), 89.34, false, 3, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '9a6dd50f-42ab-4e37-a501-fe15f502554b', 2025, 5, (select id from public.nfl_games where espn_event_id = '2025_05_LV_IND'), 'IND', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_05_LV_IND'), 75.08, false, 3, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '9a6dd50f-42ab-4e37-a501-fe15f502554b', 2025, 6, (select id from public.nfl_games where espn_event_id = '2025_06_CIN_GB'), 'GB', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_06_CIN_GB'), 87.21, false, 2, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '9a6dd50f-42ab-4e37-a501-fe15f502554b', 2025, 7, (select id from public.nfl_games where espn_event_id = '2025_07_NE_TEN'), 'NE', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_07_NE_TEN'), 71.36, false, 4, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '9a6dd50f-42ab-4e37-a501-fe15f502554b', 2025, 8, (select id from public.nfl_games where espn_event_id = '2025_08_MIA_ATL'), 'ATL', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_08_MIA_ATL'), 74.78, false, 3, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '9a6dd50f-42ab-4e37-a501-fe15f502554b', 2025, 9, (select id from public.nfl_games where espn_event_id = '2025_09_LAC_TEN'), 'LAC', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_09_LAC_TEN'), 83.16, false, 5, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '9a6dd50f-42ab-4e37-a501-fe15f502554b', 2025, 10, (select id from public.nfl_games where espn_event_id = '2025_10_NO_CAR'), 'CAR', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_10_NO_CAR'), 68.06, false, 5, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '9a6dd50f-42ab-4e37-a501-fe15f502554b', 2025, 11, (select id from public.nfl_games where espn_event_id = '2025_11_CIN_PIT'), 'PIT', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_11_CIN_PIT'), 68.54, false, 5, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '9a6dd50f-42ab-4e37-a501-fe15f502554b', 2025, 12, (select id from public.nfl_games where espn_event_id = '2025_12_NYJ_BAL'), 'BAL', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_12_NYJ_BAL'), 87.62, false, 5, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '9a6dd50f-42ab-4e37-a501-fe15f502554b', 2025, 13, (select id from public.nfl_games where espn_event_id = '2025_13_JAX_TEN'), 'JAX', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_13_JAX_TEN'), 70.02, false, 7, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '9a6dd50f-42ab-4e37-a501-fe15f502554b', 2025, 14, (select id from public.nfl_games where espn_event_id = '2025_14_NO_TB'), 'TB', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_14_NO_TB'), 77.68, false, 7, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '9a6dd50f-42ab-4e37-a501-fe15f502554b', 2025, 15, (select id from public.nfl_games where espn_event_id = '2025_15_ARI_HOU'), 'HOU', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_15_ARI_HOU'), 82.71, false, 8, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '9a6dd50f-42ab-4e37-a501-fe15f502554b', 2025, 16, (select id from public.nfl_games where espn_event_id = '2025_16_PHI_WAS'), 'PHI', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_16_PHI_WAS'), 76, false, 9, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '9a6dd50f-42ab-4e37-a501-fe15f502554b', 2025, 17, (select id from public.nfl_games where espn_event_id = '2025_17_LA_ATL'), 'LAR', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_17_LA_ATL'), 76, false, 11, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '9a6dd50f-42ab-4e37-a501-fe15f502554b', 2025, 18, (select id from public.nfl_games where espn_event_id = '2025_18_CLE_CIN'), 'CLE', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_18_CLE_CIN'), 21.33, true, 4, 'win', 2),
  ('b0000001-0000-4000-8000-000000000001', 'f3d5b8c9-bddb-471d-a50e-2ddb8fdc938e', 2025, 1, (select id from public.nfl_games where espn_event_id = '2025_01_CIN_CLE'), 'CLE', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_01_CIN_CLE'), 32.5, true, 0, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', 'f3d5b8c9-bddb-471d-a50e-2ddb8fdc938e', 2025, 2, (select id from public.nfl_games where espn_event_id = '2025_02_BUF_NYJ'), 'BUF', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_02_BUF_NYJ'), 71.36, false, 1, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'f3d5b8c9-bddb-471d-a50e-2ddb8fdc938e', 2025, 3, (select id from public.nfl_games where espn_event_id = '2025_03_KC_NYG'), 'KC', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_03_KC_NYG'), 73.35, false, 0, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'f3d5b8c9-bddb-471d-a50e-2ddb8fdc938e', 2025, 4, (select id from public.nfl_games where espn_event_id = '2025_04_GB_DAL'), 'GB', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_04_GB_DAL'), 74.41, false, 2, 'tie', 0.5),
  ('b0000001-0000-4000-8000-000000000001', 'f3d5b8c9-bddb-471d-a50e-2ddb8fdc938e', 2025, 5, (select id from public.nfl_games where espn_event_id = '2025_05_LV_IND'), 'IND', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_05_LV_IND'), 75.08, false, 3, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'f3d5b8c9-bddb-471d-a50e-2ddb8fdc938e', 2025, 6, (select id from public.nfl_games where espn_event_id = '2025_06_TEN_LV'), 'LV', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_06_TEN_LV'), 62.25, false, 1, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'f3d5b8c9-bddb-471d-a50e-2ddb8fdc938e', 2025, 7, (select id from public.nfl_games where espn_event_id = '2025_07_NYG_DEN'), 'DEN', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_07_NYG_DEN'), 77.68, false, 4, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'f3d5b8c9-bddb-471d-a50e-2ddb8fdc938e', 2025, 8, (select id from public.nfl_games where espn_event_id = '2025_08_NYJ_CIN'), 'CIN', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_08_NYJ_CIN'), 69.08, false, 3, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', 'f3d5b8c9-bddb-471d-a50e-2ddb8fdc938e', 2025, 9, (select id from public.nfl_games where espn_event_id = '2025_09_ATL_NE'), 'NE', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_09_ATL_NE'), 68.54, false, 6, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'f3d5b8c9-bddb-471d-a50e-2ddb8fdc938e', 2025, 10, (select id from public.nfl_games where espn_event_id = '2025_10_NYG_CHI'), 'CHI', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_10_NYG_CHI'), 65.75, false, 5, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'f3d5b8c9-bddb-471d-a50e-2ddb8fdc938e', 2025, 11, (select id from public.nfl_games where espn_event_id = '2025_11_CIN_PIT'), 'PIT', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_11_CIN_PIT'), 68.54, false, 5, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'f3d5b8c9-bddb-471d-a50e-2ddb8fdc938e', 2025, 12, (select id from public.nfl_games where espn_event_id = '2025_12_NYG_DET'), 'DET', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_12_NYG_DET'), 87.62, false, 6, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'f3d5b8c9-bddb-471d-a50e-2ddb8fdc938e', 2025, 13, (select id from public.nfl_games where espn_event_id = '2025_13_ARI_TB'), 'TB', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_13_ARI_TB'), 63.69, false, 6, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'f3d5b8c9-bddb-471d-a50e-2ddb8fdc938e', 2025, 14, (select id from public.nfl_games where espn_event_id = '2025_14_SEA_ATL'), 'SEA', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_14_SEA_ATL'), 74.78, false, 9, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'f3d5b8c9-bddb-471d-a50e-2ddb8fdc938e', 2025, 15, (select id from public.nfl_games where espn_event_id = '2025_15_NYJ_JAX'), 'JAX', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_15_NYJ_JAX'), 87.62, false, 9, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'f3d5b8c9-bddb-471d-a50e-2ddb8fdc938e', 2025, 16, (select id from public.nfl_games where espn_event_id = '2025_16_LV_HOU'), 'HOU', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_16_LV_HOU'), 90.4, false, 9, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'f3d5b8c9-bddb-471d-a50e-2ddb8fdc938e', 2025, 17, (select id from public.nfl_games where espn_event_id = '2025_17_LA_ATL'), 'LAR', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_17_LA_ATL'), 76, false, 11, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', 'f3d5b8c9-bddb-471d-a50e-2ddb8fdc938e', 2025, 18, (select id from public.nfl_games where espn_event_id = '2025_18_SEA_SF'), 'SF', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_18_SEA_SF'), 42.79, false, 12, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '4bd4e5d9-2864-4ccb-a873-c549f8249f25', 2025, 1, (select id from public.nfl_games where espn_event_id = '2025_01_TEN_DEN'), 'DEN', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_01_TEN_DEN'), 78.67, false, 0, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '4bd4e5d9-2864-4ccb-a873-c549f8249f25', 2025, 2, (select id from public.nfl_games where espn_event_id = '2025_02_LA_TEN'), 'LAR', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_02_LA_TEN'), 68.54, false, 1, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '4bd4e5d9-2864-4ccb-a873-c549f8249f25', 2025, 3, (select id from public.nfl_games where espn_event_id = '2025_03_IND_TEN'), 'IND', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_03_IND_TEN'), 68.06, false, 2, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '4bd4e5d9-2864-4ccb-a873-c549f8249f25', 2025, 4, (select id from public.nfl_games where espn_event_id = '2025_04_NYJ_MIA'), 'MIA', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_04_NYJ_MIA'), 57.21, false, 0, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '4bd4e5d9-2864-4ccb-a873-c549f8249f25', 2025, 5, (select id from public.nfl_games where espn_event_id = '2025_05_DAL_NYJ'), 'DAL', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_05_DAL_NYJ'), 48.92, false, 1, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '4bd4e5d9-2864-4ccb-a873-c549f8249f25', 2025, 6, (select id from public.nfl_games where espn_event_id = '2025_06_LAC_MIA'), 'LAC', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_06_LAC_MIA'), 64.47, false, 3, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '4bd4e5d9-2864-4ccb-a873-c549f8249f25', 2025, 7, (select id from public.nfl_games where espn_event_id = '2025_07_NO_CHI'), 'CHI', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_07_NO_CHI'), 66.36, false, 3, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '4bd4e5d9-2864-4ccb-a873-c549f8249f25', 2025, 8, (select id from public.nfl_games where espn_event_id = '2025_08_NYJ_CIN'), 'CIN', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_08_NYJ_CIN'), 69.08, false, 3, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '4bd4e5d9-2864-4ccb-a873-c549f8249f25', 2025, 9, (select id from public.nfl_games where espn_event_id = '2025_09_ATL_NE'), 'NE', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_09_ATL_NE'), 68.54, false, 6, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '4bd4e5d9-2864-4ccb-a873-c549f8249f25', 2025, 10, (select id from public.nfl_games where espn_event_id = '2025_10_LV_DEN'), 'LV', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_10_LV_DEN'), 20, true, 2, 'missed', 0),
  ('b0000001-0000-4000-8000-000000000001', '4bd4e5d9-2864-4ccb-a873-c549f8249f25', 2025, 11, (select id from public.nfl_games where espn_event_id = '2025_11_SF_ARI'), 'SF', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_11_SF_ARI'), 63.09, false, 6, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '4bd4e5d9-2864-4ccb-a873-c549f8249f25', 2025, 12, (select id from public.nfl_games where espn_event_id = '2025_12_CLE_LV'), 'CLE', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_12_CLE_LV'), 40.66, false, 2, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '4bd4e5d9-2864-4ccb-a873-c549f8249f25', 2025, 13, (select id from public.nfl_games where espn_event_id = '2025_13_JAX_TEN'), 'JAX', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_13_JAX_TEN'), 70.02, false, 7, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '4bd4e5d9-2864-4ccb-a873-c549f8249f25', 2025, 14, (select id from public.nfl_games where espn_event_id = '2025_14_WAS_MIN'), 'WAS', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_14_WAS_MIN'), 51.08, false, 3, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '4bd4e5d9-2864-4ccb-a873-c549f8249f25', 2025, 15, (select id from public.nfl_games where espn_event_id = '2025_15_LV_PHI'), 'PHI', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_15_LV_PHI'), 87.21, false, 8, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '4bd4e5d9-2864-4ccb-a873-c549f8249f25', 2025, 16, (select id from public.nfl_games where espn_event_id = '2025_16_BUF_CLE'), 'BUF', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_16_BUF_CLE'), 81.73, false, 10, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '4bd4e5d9-2864-4ccb-a873-c549f8249f25', 2025, 17, (select id from public.nfl_games where espn_event_id = '2025_17_TB_MIA'), 'TB', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_17_TB_MIA'), 68.54, false, 7, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '4bd4e5d9-2864-4ccb-a873-c549f8249f25', 2025, 18, (select id from public.nfl_games where espn_event_id = '2025_18_ARI_LA'), 'ARI', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_18_ARI_LA'), 10.66, true, 3, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '85978942-f5a7-4513-ae52-41055b9da732', 2025, 1, (select id from public.nfl_games where espn_event_id = '2025_01_NYG_WAS'), 'WAS', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_01_NYG_WAS'), 71.8, false, 0, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '85978942-f5a7-4513-ae52-41055b9da732', 2025, 2, (select id from public.nfl_games where espn_event_id = '2025_02_SF_NO'), 'SF', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_02_SF_NO'), 59.96, false, 1, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '85978942-f5a7-4513-ae52-41055b9da732', 2025, 3, (select id from public.nfl_games where espn_event_id = '2025_03_NO_SEA'), 'SEA', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_03_NO_SEA'), 75.72, false, 1, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '85978942-f5a7-4513-ae52-41055b9da732', 2025, 4, (select id from public.nfl_games where espn_event_id = '2025_04_TEN_HOU'), 'HOU', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_04_TEN_HOU'), 78.19, false, 0, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '85978942-f5a7-4513-ae52-41055b9da732', 2025, 5, (select id from public.nfl_games where espn_event_id = '2025_05_LV_IND'), 'IND', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_05_LV_IND'), 75.08, false, 3, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '85978942-f5a7-4513-ae52-41055b9da732', 2025, 6, (select id from public.nfl_games where espn_event_id = '2025_06_TEN_LV'), 'LV', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_06_TEN_LV'), 62.25, false, 1, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '85978942-f5a7-4513-ae52-41055b9da732', 2025, 7, (select id from public.nfl_games where espn_event_id = '2025_07_NYG_DEN'), 'DEN', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_07_NYG_DEN'), 77.68, false, 4, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '85978942-f5a7-4513-ae52-41055b9da732', 2025, 8, (select id from public.nfl_games where espn_event_id = '2025_08_NYJ_CIN'), 'CIN', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_08_NYJ_CIN'), 69.08, false, 3, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '85978942-f5a7-4513-ae52-41055b9da732', 2025, 9, (select id from public.nfl_games where espn_event_id = '2025_09_ATL_NE'), 'NE', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_09_ATL_NE'), 68.54, false, 6, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '85978942-f5a7-4513-ae52-41055b9da732', 2025, 10, (select id from public.nfl_games where espn_event_id = '2025_10_NO_CAR'), 'CAR', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_10_NO_CAR'), 68.06, false, 5, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '85978942-f5a7-4513-ae52-41055b9da732', 2025, 11, (select id from public.nfl_games where espn_event_id = '2025_11_CIN_PIT'), 'PIT', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_11_CIN_PIT'), 68.54, false, 5, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '85978942-f5a7-4513-ae52-41055b9da732', 2025, 12, (select id from public.nfl_games where espn_event_id = '2025_12_MIN_GB'), 'GB', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_12_MIN_GB'), 71.36, false, 6, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '85978942-f5a7-4513-ae52-41055b9da732', 2025, 13, (select id from public.nfl_games where espn_event_id = '2025_13_LV_LAC'), 'LAC', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_13_LV_LAC'), 82.23, false, 7, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '85978942-f5a7-4513-ae52-41055b9da732', 2025, 14, (select id from public.nfl_games where espn_event_id = '2025_14_NO_TB'), 'TB', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_14_NO_TB'), 77.68, false, 7, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '85978942-f5a7-4513-ae52-41055b9da732', 2025, 15, (select id from public.nfl_games where espn_event_id = '2025_15_NYJ_JAX'), 'JAX', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_15_NYJ_JAX'), 87.62, false, 9, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '85978942-f5a7-4513-ae52-41055b9da732', 2025, 16, (select id from public.nfl_games where espn_event_id = '2025_16_PIT_DET'), 'DET', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_16_PIT_DET'), 77.68, false, 8, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '85978942-f5a7-4513-ae52-41055b9da732', 2025, 17, (select id from public.nfl_games where espn_event_id = '2025_17_LA_ATL'), 'LAR', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_17_LA_ATL'), 76, false, 11, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '85978942-f5a7-4513-ae52-41055b9da732', 2025, 18, (select id from public.nfl_games where espn_event_id = '2025_18_CLE_CIN'), 'CLE', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_18_CLE_CIN'), 21.33, true, 4, 'win', 2),
  ('b0000001-0000-4000-8000-000000000001', '1dca2d73-65a7-4f28-acda-85dd4675e256', 2025, 1, (select id from public.nfl_games where espn_event_id = '2025_01_TEN_DEN'), 'DEN', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_01_TEN_DEN'), 78.67, false, 0, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '1dca2d73-65a7-4f28-acda-85dd4675e256', 2025, 2, (select id from public.nfl_games where espn_event_id = '2025_02_LA_TEN'), 'LAR', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_02_LA_TEN'), 68.54, false, 1, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '1dca2d73-65a7-4f28-acda-85dd4675e256', 2025, 3, (select id from public.nfl_games where espn_event_id = '2025_03_NO_SEA'), 'SEA', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_03_NO_SEA'), 75.72, false, 1, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '1dca2d73-65a7-4f28-acda-85dd4675e256', 2025, 4, (select id from public.nfl_games where espn_event_id = '2025_04_NO_BUF'), 'BUF', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_04_NO_BUF'), 89.34, false, 3, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '1dca2d73-65a7-4f28-acda-85dd4675e256', 2025, 5, (select id from public.nfl_games where espn_event_id = '2025_05_TEN_ARI'), 'ARI', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_05_TEN_ARI'), 77.68, false, 2, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '1dca2d73-65a7-4f28-acda-85dd4675e256', 2025, 6, (select id from public.nfl_games where espn_event_id = '2025_06_DET_KC'), 'KC', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_06_DET_KC'), 56.35, false, 2, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '1dca2d73-65a7-4f28-acda-85dd4675e256', 2025, 7, (select id from public.nfl_games where espn_event_id = '2025_07_MIA_CLE'), 'CLE', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_07_MIA_CLE'), 57.21, false, 1, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '1dca2d73-65a7-4f28-acda-85dd4675e256', 2025, 8, (select id from public.nfl_games where espn_event_id = '2025_08_TEN_IND'), 'IND', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_08_TEN_IND'), 90.83, false, 6, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '1dca2d73-65a7-4f28-acda-85dd4675e256', 2025, 9, (select id from public.nfl_games where espn_event_id = '2025_09_CAR_GB'), 'GB', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_09_CAR_GB'), 87.21, false, 5, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '1dca2d73-65a7-4f28-acda-85dd4675e256', 2025, 10, (select id from public.nfl_games where espn_event_id = '2025_10_NYG_CHI'), 'CHI', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_10_NYG_CHI'), 65.75, false, 5, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '1dca2d73-65a7-4f28-acda-85dd4675e256', 2025, 11, (select id from public.nfl_games where espn_event_id = '2025_11_HOU_TEN'), 'HOU', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_11_HOU_TEN'), 69.58, false, 4, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '1dca2d73-65a7-4f28-acda-85dd4675e256', 2025, 12, (select id from public.nfl_games where espn_event_id = '2025_12_NYG_DET'), 'DET', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_12_NYG_DET'), 87.62, false, 6, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '1dca2d73-65a7-4f28-acda-85dd4675e256', 2025, 13, (select id from public.nfl_games where espn_event_id = '2025_13_LV_LAC'), 'LAC', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_13_LV_LAC'), 82.23, false, 7, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '1dca2d73-65a7-4f28-acda-85dd4675e256', 2025, 14, (select id from public.nfl_games where espn_event_id = '2025_14_PIT_BAL'), 'BAL', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_14_PIT_BAL'), 70.02, false, 6, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '1dca2d73-65a7-4f28-acda-85dd4675e256', 2025, 15, (select id from public.nfl_games where espn_event_id = '2025_15_TEN_SF'), 'SF', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_15_TEN_SF'), 86.3, false, 9, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '1dca2d73-65a7-4f28-acda-85dd4675e256', 2025, 16, (select id from public.nfl_games where espn_event_id = '2025_16_NYJ_NO'), 'NO', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_16_NYJ_NO'), 71.8, false, 4, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '1dca2d73-65a7-4f28-acda-85dd4675e256', 2025, 17, (select id from public.nfl_games where espn_event_id = '2025_17_PIT_CLE'), 'PIT', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_17_PIT_CLE'), 64.47, false, 9, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '1dca2d73-65a7-4f28-acda-85dd4675e256', 2025, 18, (select id from public.nfl_games where espn_event_id = '2025_18_WAS_PHI'), 'PHI', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_18_WAS_PHI'), 61.64, false, 11, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', 'ebc98f93-b328-402f-a31e-4cf89582ae8e', 2025, 1, (select id from public.nfl_games where espn_event_id = '2025_01_TEN_DEN'), 'DEN', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_01_TEN_DEN'), 78.67, false, 0, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'ebc98f93-b328-402f-a31e-4cf89582ae8e', 2025, 2, (select id from public.nfl_games where espn_event_id = '2025_02_BUF_NYJ'), 'BUF', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_02_BUF_NYJ'), 71.36, false, 1, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'ebc98f93-b328-402f-a31e-4cf89582ae8e', 2025, 3, (select id from public.nfl_games where espn_event_id = '2025_03_CIN_MIN'), 'MIN', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_03_CIN_MIN'), 59.34, false, 1, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'ebc98f93-b328-402f-a31e-4cf89582ae8e', 2025, 4, (select id from public.nfl_games where espn_event_id = '2025_04_LAC_NYG'), 'LAC', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_04_LAC_NYG'), 70.95, false, 3, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', 'ebc98f93-b328-402f-a31e-4cf89582ae8e', 2025, 5, (select id from public.nfl_games where espn_event_id = '2025_05_LV_IND'), 'IND', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_05_LV_IND'), 75.08, false, 3, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'ebc98f93-b328-402f-a31e-4cf89582ae8e', 2025, 6, (select id from public.nfl_games where espn_event_id = '2025_06_PHI_NYG'), 'NYG', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_06_PHI_NYG'), 23.41, true, 1, 'missed', 0),
  ('b0000001-0000-4000-8000-000000000001', 'ebc98f93-b328-402f-a31e-4cf89582ae8e', 2025, 7, (select id from public.nfl_games where espn_event_id = '2025_07_GB_ARI'), 'GB', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_07_GB_ARI'), 76.59, false, 3, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'ebc98f93-b328-402f-a31e-4cf89582ae8e', 2025, 8, (select id from public.nfl_games where espn_event_id = '2025_08_NYJ_CIN'), 'CIN', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_08_NYJ_CIN'), 69.08, false, 3, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', 'ebc98f93-b328-402f-a31e-4cf89582ae8e', 2025, 9, (select id from public.nfl_games where espn_event_id = '2025_09_NO_LA'), 'LAR', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_09_NO_LA'), 88.7, false, 5, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'ebc98f93-b328-402f-a31e-4cf89582ae8e', 2025, 10, (select id from public.nfl_games where espn_event_id = '2025_10_NO_CAR'), 'CAR', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_10_NO_CAR'), 68.06, false, 5, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', 'ebc98f93-b328-402f-a31e-4cf89582ae8e', 2025, 11, (select id from public.nfl_games where espn_event_id = '2025_11_CIN_PIT'), 'PIT', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_11_CIN_PIT'), 68.54, false, 5, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'ebc98f93-b328-402f-a31e-4cf89582ae8e', 2025, 12, (select id from public.nfl_games where espn_event_id = '2025_12_NYG_DET'), 'DET', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_12_NYG_DET'), 87.62, false, 6, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'ebc98f93-b328-402f-a31e-4cf89582ae8e', 2025, 13, (select id from public.nfl_games where espn_event_id = '2025_13_JAX_TEN'), 'JAX', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_13_JAX_TEN'), 70.02, false, 7, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'ebc98f93-b328-402f-a31e-4cf89582ae8e', 2025, 14, (select id from public.nfl_games where espn_event_id = '2025_14_HOU_KC'), 'KC', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_14_HOU_KC'), 65.75, false, 6, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', 'ebc98f93-b328-402f-a31e-4cf89582ae8e', 2025, 15, (select id from public.nfl_games where espn_event_id = '2025_15_ARI_HOU'), 'HOU', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_15_ARI_HOU'), 82.71, false, 8, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'ebc98f93-b328-402f-a31e-4cf89582ae8e', 2025, 16, (select id from public.nfl_games where espn_event_id = '2025_16_NE_BAL'), 'NE', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_16_NE_BAL'), 37.75, false, 11, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'ebc98f93-b328-402f-a31e-4cf89582ae8e', 2025, 17, (select id from public.nfl_games where espn_event_id = '2025_17_PHI_BUF'), 'PHI', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_17_PHI_BUF'), 39.62, false, 10, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'ebc98f93-b328-402f-a31e-4cf89582ae8e', 2025, 18, (select id from public.nfl_games where espn_event_id = '2025_18_CLE_CIN'), 'CLE', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_18_CLE_CIN'), 21.33, true, 4, 'win', 2),
  ('b0000001-0000-4000-8000-000000000001', '44c8d145-65ef-4987-ac97-88e344d428c9', 2025, 1, (select id from public.nfl_games where espn_event_id = '2025_01_TEN_DEN'), 'DEN', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_01_TEN_DEN'), 78.67, false, 0, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '44c8d145-65ef-4987-ac97-88e344d428c9', 2025, 2, (select id from public.nfl_games where espn_event_id = '2025_02_CLE_BAL'), 'BAL', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_02_CLE_BAL'), 86.3, false, 0, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '44c8d145-65ef-4987-ac97-88e344d428c9', 2025, 3, (select id from public.nfl_games where espn_event_id = '2025_03_NO_SEA'), 'SEA', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_03_NO_SEA'), 75.72, false, 1, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '44c8d145-65ef-4987-ac97-88e344d428c9', 2025, 4, (select id from public.nfl_games where espn_event_id = '2025_04_NO_BUF'), 'BUF', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_04_NO_BUF'), 89.34, false, 3, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '44c8d145-65ef-4987-ac97-88e344d428c9', 2025, 5, (select id from public.nfl_games where espn_event_id = '2025_05_DET_CIN'), 'DET', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_05_DET_CIN'), 81.73, false, 3, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '44c8d145-65ef-4987-ac97-88e344d428c9', 2025, 6, (select id from public.nfl_games where espn_event_id = '2025_06_CIN_GB'), 'GB', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_06_CIN_GB'), 87.21, false, 2, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '44c8d145-65ef-4987-ac97-88e344d428c9', 2025, 7, (select id from public.nfl_games where espn_event_id = '2025_07_LV_KC'), 'KC', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_07_LV_KC'), 86.77, false, 3, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '44c8d145-65ef-4987-ac97-88e344d428c9', 2025, 8, (select id from public.nfl_games where espn_event_id = '2025_08_CLE_NE'), 'NE', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_08_CLE_NE'), 76, false, 5, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '44c8d145-65ef-4987-ac97-88e344d428c9', 2025, 9, (select id from public.nfl_games where espn_event_id = '2025_09_IND_PIT'), 'IND', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_09_IND_PIT'), 62.25, false, 7, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '44c8d145-65ef-4987-ac97-88e344d428c9', 2025, 10, (select id from public.nfl_games where espn_event_id = '2025_10_NO_CAR'), 'CAR', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_10_NO_CAR'), 68.06, false, 5, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '44c8d145-65ef-4987-ac97-88e344d428c9', 2025, 11, (select id from public.nfl_games where espn_event_id = '2025_11_CIN_PIT'), 'PIT', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_11_CIN_PIT'), 68.54, false, 5, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '44c8d145-65ef-4987-ac97-88e344d428c9', 2025, 12, (select id from public.nfl_games where espn_event_id = '2025_12_CAR_SF'), 'SF', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_12_CAR_SF'), 76.59, false, 7, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '44c8d145-65ef-4987-ac97-88e344d428c9', 2025, 13, (select id from public.nfl_games where espn_event_id = '2025_13_JAX_TEN'), 'JAX', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_13_JAX_TEN'), 70.02, false, 7, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '44c8d145-65ef-4987-ac97-88e344d428c9', 2025, 14, (select id from public.nfl_games where espn_event_id = '2025_14_NO_TB'), 'TB', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_14_NO_TB'), 77.68, false, 7, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '44c8d145-65ef-4987-ac97-88e344d428c9', 2025, 15, (select id from public.nfl_games where espn_event_id = '2025_15_LV_PHI'), 'PHI', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_15_LV_PHI'), 87.21, false, 8, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '44c8d145-65ef-4987-ac97-88e344d428c9', 2025, 16, (select id from public.nfl_games where espn_event_id = '2025_16_LV_HOU'), 'HOU', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_16_LV_HOU'), 90.4, false, 9, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '44c8d145-65ef-4987-ac97-88e344d428c9', 2025, 17, (select id from public.nfl_games where espn_event_id = '2025_17_LA_ATL'), 'LAR', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_17_LA_ATL'), 76, false, 11, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '44c8d145-65ef-4987-ac97-88e344d428c9', 2025, 18, (select id from public.nfl_games where espn_event_id = '2025_18_DET_CHI'), 'CHI', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_18_DET_CHI'), 61.64, false, 11, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '7f865349-1435-488d-aafe-87b0565b8610', 2025, 1, (select id from public.nfl_games where espn_event_id = '2025_01_CIN_CLE'), 'CLE', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_01_CIN_CLE'), 32.5, true, 0, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '7f865349-1435-488d-aafe-87b0565b8610', 2025, 2, (select id from public.nfl_games where espn_event_id = '2025_02_CAR_ARI'), 'ARI', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_02_CAR_ARI'), 72.58, false, 1, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '7f865349-1435-488d-aafe-87b0565b8610', 2025, 3, (select id from public.nfl_games where espn_event_id = '2025_03_MIA_BUF'), 'BUF', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_03_MIA_BUF'), 85.25, false, 2, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '7f865349-1435-488d-aafe-87b0565b8610', 2025, 4, (select id from public.nfl_games where espn_event_id = '2025_04_TEN_HOU'), 'HOU', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_04_TEN_HOU'), 78.19, false, 0, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '7f865349-1435-488d-aafe-87b0565b8610', 2025, 5, (select id from public.nfl_games where espn_event_id = '2025_05_SF_LA'), 'LAR', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_05_SF_LA'), 78.19, false, 3, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '7f865349-1435-488d-aafe-87b0565b8610', 2025, 6, (select id from public.nfl_games where espn_event_id = '2025_06_CIN_GB'), 'GB', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_06_CIN_GB'), 87.21, false, 2, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '7f865349-1435-488d-aafe-87b0565b8610', 2025, 7, (select id from public.nfl_games where espn_event_id = '2025_07_NO_CHI'), 'CHI', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_07_NO_CHI'), 66.36, false, 3, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '7f865349-1435-488d-aafe-87b0565b8610', 2025, 8, (select id from public.nfl_games where espn_event_id = '2025_08_MIA_ATL'), 'ATL', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_08_MIA_ATL'), 74.78, false, 3, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '7f865349-1435-488d-aafe-87b0565b8610', 2025, 9, (select id from public.nfl_games where espn_event_id = '2025_09_MIN_DET'), 'DET', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_09_MIN_DET'), 81.19, false, 5, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '7f865349-1435-488d-aafe-87b0565b8610', 2025, 10, (select id from public.nfl_games where espn_event_id = '2025_10_LV_DEN'), 'DEN', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_10_LV_DEN'), 80, false, 7, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '7f865349-1435-488d-aafe-87b0565b8610', 2025, 11, (select id from public.nfl_games where espn_event_id = '2025_11_NYJ_NE'), 'NE', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_11_NYJ_NE'), 86.77, false, 8, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '7f865349-1435-488d-aafe-87b0565b8610', 2025, 12, (select id from public.nfl_games where espn_event_id = '2025_12_NYJ_BAL'), 'BAL', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_12_NYJ_BAL'), 87.62, false, 5, 'missed', 0),
  ('b0000001-0000-4000-8000-000000000001', '7f865349-1435-488d-aafe-87b0565b8610', 2025, 13, (select id from public.nfl_games where espn_event_id = '2025_13_MIN_SEA'), 'SEA', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_13_MIN_SEA'), 86.3, false, 8, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '7f865349-1435-488d-aafe-87b0565b8610', 2025, 14, (select id from public.nfl_games where espn_event_id = '2025_14_NO_TB'), 'TB', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_14_NO_TB'), 77.68, false, 7, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '7f865349-1435-488d-aafe-87b0565b8610', 2025, 15, (select id from public.nfl_games where espn_event_id = '2025_15_NYJ_JAX'), 'JAX', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_15_NYJ_JAX'), 87.62, false, 9, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '7f865349-1435-488d-aafe-87b0565b8610', 2025, 16, (select id from public.nfl_games where espn_event_id = '2025_16_NYJ_NO'), 'NO', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_16_NYJ_NO'), 71.8, false, 4, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '7f865349-1435-488d-aafe-87b0565b8610', 2025, 17, (select id from public.nfl_games where espn_event_id = '2025_17_ARI_CIN'), 'CIN', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_17_ARI_CIN'), 74.41, false, 5, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '7f865349-1435-488d-aafe-87b0565b8610', 2025, 18, (select id from public.nfl_games where espn_event_id = '2025_18_WAS_PHI'), 'PHI', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_18_WAS_PHI'), 61.64, false, 11, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', 'b58e4217-d5df-498d-a488-c49c73033846', 2025, 1, (select id from public.nfl_games where espn_event_id = '2025_01_CAR_JAX'), 'JAX', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_01_CAR_JAX'), 64.47, false, 0, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'b58e4217-d5df-498d-a488-c49c73033846', 2025, 2, (select id from public.nfl_games where espn_event_id = '2025_02_SF_NO'), 'SF', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_02_SF_NO'), 59.96, false, 1, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'b58e4217-d5df-498d-a488-c49c73033846', 2025, 3, (select id from public.nfl_games where espn_event_id = '2025_03_NO_SEA'), 'SEA', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_03_NO_SEA'), 75.72, false, 1, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'b58e4217-d5df-498d-a488-c49c73033846', 2025, 4, (select id from public.nfl_games where espn_event_id = '2025_04_CIN_DEN'), 'DEN', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_04_CIN_DEN'), 79.14, false, 1, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'b58e4217-d5df-498d-a488-c49c73033846', 2025, 5, (select id from public.nfl_games where espn_event_id = '2025_05_TEN_ARI'), 'ARI', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_05_TEN_ARI'), 77.68, false, 2, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', 'b58e4217-d5df-498d-a488-c49c73033846', 2025, 6, (select id from public.nfl_games where espn_event_id = '2025_06_ARI_IND'), 'IND', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_06_ARI_IND'), 79.14, false, 4, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'b58e4217-d5df-498d-a488-c49c73033846', 2025, 7, (select id from public.nfl_games where espn_event_id = '2025_07_NE_TEN'), 'NE', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_07_NE_TEN'), 71.36, false, 4, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'b58e4217-d5df-498d-a488-c49c73033846', 2025, 8, (select id from public.nfl_games where espn_event_id = '2025_08_NYJ_CIN'), 'CIN', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_08_NYJ_CIN'), 69.08, false, 3, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', 'b58e4217-d5df-498d-a488-c49c73033846', 2025, 9, (select id from public.nfl_games where espn_event_id = '2025_09_LAC_TEN'), 'LAC', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_09_LAC_TEN'), 83.16, false, 5, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'b58e4217-d5df-498d-a488-c49c73033846', 2025, 10, (select id from public.nfl_games where espn_event_id = '2025_10_LV_DEN'), 'LV', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_10_LV_DEN'), 20, true, 2, 'missed', 0),
  ('b0000001-0000-4000-8000-000000000001', 'b58e4217-d5df-498d-a488-c49c73033846', 2025, 11, (select id from public.nfl_games where espn_event_id = '2025_11_GB_NYG'), 'GB', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_11_GB_NYG'), 78.19, false, 5, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'b58e4217-d5df-498d-a488-c49c73033846', 2025, 12, (select id from public.nfl_games where espn_event_id = '2025_12_PIT_CHI'), 'CHI', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_12_PIT_CHI'), 58.3, false, 7, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'b58e4217-d5df-498d-a488-c49c73033846', 2025, 13, (select id from public.nfl_games where espn_event_id = '2025_13_CIN_BAL'), 'BAL', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_13_CIN_BAL'), 75.72, false, 6, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', 'b58e4217-d5df-498d-a488-c49c73033846', 2025, 14, (select id from public.nfl_games where espn_event_id = '2025_14_CIN_BUF'), 'BUF', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_14_CIN_BUF'), 70.95, false, 8, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'b58e4217-d5df-498d-a488-c49c73033846', 2025, 15, (select id from public.nfl_games where espn_event_id = '2025_15_CLE_CHI'), 'CLE', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_15_CLE_CHI'), 24.28, true, 3, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', 'b58e4217-d5df-498d-a488-c49c73033846', 2025, 16, (select id from public.nfl_games where espn_event_id = '2025_16_LV_HOU'), 'HOU', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_16_LV_HOU'), 90.4, false, 9, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'b58e4217-d5df-498d-a488-c49c73033846', 2025, 17, (select id from public.nfl_games where espn_event_id = '2025_17_LA_ATL'), 'LAR', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_17_LA_ATL'), 76, false, 11, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', 'b58e4217-d5df-498d-a488-c49c73033846', 2025, 18, (select id from public.nfl_games where espn_event_id = '2025_18_CAR_TB'), 'TB', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_18_CAR_TB'), 58.3, false, 7, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '0621f100-0b9d-4158-ae0c-40f5455d0b7a', 2025, 1, (select id from public.nfl_games where espn_event_id = '2025_01_ARI_NO'), 'ARI', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_01_ARI_NO'), 70.02, false, 0, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '0621f100-0b9d-4158-ae0c-40f5455d0b7a', 2025, 2, (select id from public.nfl_games where espn_event_id = '2025_02_LA_TEN'), 'LAR', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_02_LA_TEN'), 68.54, false, 1, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '0621f100-0b9d-4158-ae0c-40f5455d0b7a', 2025, 3, (select id from public.nfl_games where espn_event_id = '2025_03_NO_SEA'), 'SEA', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_03_NO_SEA'), 75.72, false, 1, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '0621f100-0b9d-4158-ae0c-40f5455d0b7a', 2025, 4, (select id from public.nfl_games where espn_event_id = '2025_04_NO_BUF'), 'BUF', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_04_NO_BUF'), 89.34, false, 3, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '0621f100-0b9d-4158-ae0c-40f5455d0b7a', 2025, 5, (select id from public.nfl_games where espn_event_id = '2025_05_NYG_NO'), 'NYG', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_05_NYG_NO'), 47.83, false, 1, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '0621f100-0b9d-4158-ae0c-40f5455d0b7a', 2025, 6, (select id from public.nfl_games where espn_event_id = '2025_06_CIN_GB'), 'CIN', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_06_CIN_GB'), 12.79, true, 2, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '0621f100-0b9d-4158-ae0c-40f5455d0b7a', 2025, 7, (select id from public.nfl_games where espn_event_id = '2025_07_LV_KC'), 'KC', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_07_LV_KC'), 86.77, false, 3, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '0621f100-0b9d-4158-ae0c-40f5455d0b7a', 2025, 8, (select id from public.nfl_games where espn_event_id = '2025_08_MIA_ATL'), 'ATL', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_08_MIA_ATL'), 74.78, false, 3, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '0621f100-0b9d-4158-ae0c-40f5455d0b7a', 2025, 9, (select id from public.nfl_games where espn_event_id = '2025_09_BAL_MIA'), 'BAL', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_09_BAL_MIA'), 78.67, false, 2, 'missed', 0),
  ('b0000001-0000-4000-8000-000000000001', '0621f100-0b9d-4158-ae0c-40f5455d0b7a', 2025, 10, (select id from public.nfl_games where espn_event_id = '2025_10_CLE_NYJ'), 'CLE', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_10_CLE_NYJ'), 54.27, false, 2, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '0621f100-0b9d-4158-ae0c-40f5455d0b7a', 2025, 11, (select id from public.nfl_games where espn_event_id = '2025_11_GB_NYG'), 'GB', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_11_GB_NYG'), 78.19, false, 5, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '0621f100-0b9d-4158-ae0c-40f5455d0b7a', 2025, 12, (select id from public.nfl_games where espn_event_id = '2025_12_ATL_NO'), 'NO', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_12_ATL_NO'), 52.61, false, 2, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '0621f100-0b9d-4158-ae0c-40f5455d0b7a', 2025, 13, (select id from public.nfl_games where espn_event_id = '2025_13_JAX_TEN'), 'JAX', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_13_JAX_TEN'), 70.02, false, 7, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '0621f100-0b9d-4158-ae0c-40f5455d0b7a', 2025, 14, (select id from public.nfl_games where espn_event_id = '2025_14_MIA_NYJ'), 'MIA', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_14_MIA_NYJ'), 57.21, false, 5, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '0621f100-0b9d-4158-ae0c-40f5455d0b7a', 2025, 15, (select id from public.nfl_games where espn_event_id = '2025_15_DET_LA'), 'DET', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_15_DET_LA'), 31.94, true, 8, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '0621f100-0b9d-4158-ae0c-40f5455d0b7a', 2025, 16, (select id from public.nfl_games where espn_event_id = '2025_16_LV_HOU'), 'HOU', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_16_LV_HOU'), 90.4, false, 9, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '0621f100-0b9d-4158-ae0c-40f5455d0b7a', 2025, 17, (select id from public.nfl_games where espn_event_id = '2025_17_CHI_SF'), 'SF', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_17_CHI_SF'), 64.47, false, 11, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '0621f100-0b9d-4158-ae0c-40f5455d0b7a', 2025, 18, (select id from public.nfl_games where espn_event_id = '2025_18_DET_CHI'), 'CHI', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_18_DET_CHI'), 61.64, false, 11, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '2019ef35-f471-4858-a726-89acc2594138', 2025, 1, (select id from public.nfl_games where espn_event_id = '2025_01_KC_LAC'), 'KC', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_01_KC_LAC'), 60.92, false, 0, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '2019ef35-f471-4858-a726-89acc2594138', 2025, 2, (select id from public.nfl_games where espn_event_id = '2025_02_LAC_LV'), 'LV', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_02_LAC_LV'), 36.31, false, 1, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '2019ef35-f471-4858-a726-89acc2594138', 2025, 3, (select id from public.nfl_games where espn_event_id = '2025_03_CIN_MIN'), 'MIN', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_03_CIN_MIN'), 59.34, false, 1, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '2019ef35-f471-4858-a726-89acc2594138', 2025, 4, (select id from public.nfl_games where espn_event_id = '2025_04_PHI_TB'), 'PHI', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_04_PHI_TB'), 62.25, false, 3, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '2019ef35-f471-4858-a726-89acc2594138', 2025, 5, (select id from public.nfl_games where espn_event_id = '2025_05_HOU_BAL'), 'BAL', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_05_HOU_BAL'), 42.79, false, 1, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '2019ef35-f471-4858-a726-89acc2594138', 2025, 6, (select id from public.nfl_games where espn_event_id = '2025_06_SEA_JAX'), 'JAX', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_06_SEA_JAX'), 48.92, false, 4, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '2019ef35-f471-4858-a726-89acc2594138', 2025, 7, (select id from public.nfl_games where espn_event_id = '2025_07_MIA_CLE'), 'MIA', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_07_MIA_CLE'), 42.79, false, 1, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '2019ef35-f471-4858-a726-89acc2594138', 2025, 8, (select id from public.nfl_games where espn_event_id = '2025_08_CHI_BAL'), 'CHI', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_08_CHI_BAL'), 42.79, false, 4, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '2019ef35-f471-4858-a726-89acc2594138', 2025, 9, (select id from public.nfl_games where espn_event_id = '2025_09_DEN_HOU'), 'DEN', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_09_DEN_HOU'), 46.75, false, 6, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '2019ef35-f471-4858-a726-89acc2594138', 2025, 10, (select id from public.nfl_games where espn_event_id = '2025_10_DET_WAS'), 'DET', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_10_DET_WAS'), 78.67, false, 5, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '2019ef35-f471-4858-a726-89acc2594138', 2025, 11, (select id from public.nfl_games where espn_event_id = '2025_11_SF_ARI'), 'ARI', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_11_SF_ARI'), 36.91, false, 3, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '2019ef35-f471-4858-a726-89acc2594138', 2025, 12, (select id from public.nfl_games where espn_event_id = '2025_12_IND_KC'), 'IND', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_12_IND_KC'), 34.25, false, 8, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', '2019ef35-f471-4858-a726-89acc2594138', 2025, 13, (select id from public.nfl_games where espn_event_id = '2025_13_LA_CAR'), 'CAR', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_13_LA_CAR'), 18.27, true, 6, 'win', 2),
  ('b0000001-0000-4000-8000-000000000001', '2019ef35-f471-4858-a726-89acc2594138', 2025, 14, (select id from public.nfl_games where espn_event_id = '2025_14_LA_ARI'), 'LAR', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_14_LA_ARI'), 80, false, 9, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '2019ef35-f471-4858-a726-89acc2594138', 2025, 15, (select id from public.nfl_games where espn_event_id = '2025_15_BUF_NE'), 'BUF', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_15_BUF_NE'), 56.35, false, 9, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '2019ef35-f471-4858-a726-89acc2594138', 2025, 16, (select id from public.nfl_games where espn_event_id = '2025_16_CIN_MIA'), 'CIN', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_16_CIN_MIA'), 64.47, false, 4, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', '2019ef35-f471-4858-a726-89acc2594138', 2025, 17, (select id from public.nfl_games where espn_event_id = '2025_17_LA_ATL'), 'ATL', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_17_LA_ATL'), 24, true, 6, 'win', 2),
  ('b0000001-0000-4000-8000-000000000001', '2019ef35-f471-4858-a726-89acc2594138', 2025, 18, (select id from public.nfl_games where espn_event_id = '2025_18_SEA_SF'), 'SEA', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_18_SEA_SF'), 57.21, false, 13, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'c821b559-7cd9-491d-abd3-082c877eeeb8', 2025, 1, (select id from public.nfl_games where espn_event_id = '2025_01_TEN_DEN'), 'DEN', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_01_TEN_DEN'), 78.67, false, 0, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'c821b559-7cd9-491d-abd3-082c877eeeb8', 2025, 2, (select id from public.nfl_games where espn_event_id = '2025_02_CLE_BAL'), 'BAL', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_02_CLE_BAL'), 86.3, false, 0, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'c821b559-7cd9-491d-abd3-082c877eeeb8', 2025, 3, (select id from public.nfl_games where espn_event_id = '2025_03_GB_CLE'), 'GB', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_03_GB_CLE'), 79.14, false, 2, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', 'c821b559-7cd9-491d-abd3-082c877eeeb8', 2025, 4, (select id from public.nfl_games where espn_event_id = '2025_04_JAX_SF'), 'SF', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_04_JAX_SF'), 61.64, false, 3, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', 'c821b559-7cd9-491d-abd3-082c877eeeb8', 2025, 5, (select id from public.nfl_games where espn_event_id = '2025_05_DET_CIN'), 'CIN', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_05_DET_CIN'), 18.27, true, 2, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', 'c821b559-7cd9-491d-abd3-082c877eeeb8', 2025, 6, (select id from public.nfl_games where espn_event_id = '2025_06_CHI_WAS'), 'CHI', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_06_CHI_WAS'), 30.92, true, 2, 'win', 2),
  ('b0000001-0000-4000-8000-000000000001', 'c821b559-7cd9-491d-abd3-082c877eeeb8', 2025, 7, (select id from public.nfl_games where espn_event_id = '2025_07_MIA_CLE'), 'CLE', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_07_MIA_CLE'), 57.21, false, 1, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'c821b559-7cd9-491d-abd3-082c877eeeb8', 2025, 8, (select id from public.nfl_games where espn_event_id = '2025_08_BUF_CAR'), 'BUF', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_08_BUF_CAR'), 76.59, false, 4, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'c821b559-7cd9-491d-abd3-082c877eeeb8', 2025, 9, (select id from public.nfl_games where espn_event_id = '2025_09_ARI_DAL'), 'ARI', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_09_ARI_DAL'), 39.08, false, 2, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'c821b559-7cd9-491d-abd3-082c877eeeb8', 2025, 10, (select id from public.nfl_games where espn_event_id = '2025_10_NE_TB'), 'TB', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_10_NE_TB'), 57.21, false, 6, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', 'c821b559-7cd9-491d-abd3-082c877eeeb8', 2025, 11, (select id from public.nfl_games where espn_event_id = '2025_11_LAC_JAX'), 'LAC', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_11_LAC_JAX'), 58.3, false, 7, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', 'c821b559-7cd9-491d-abd3-082c877eeeb8', 2025, 12, (select id from public.nfl_games where espn_event_id = '2025_12_IND_KC'), 'KC', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_12_IND_KC'), 65.75, false, 5, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'c821b559-7cd9-491d-abd3-082c877eeeb8', 2025, 13, (select id from public.nfl_games where espn_event_id = '2025_13_HOU_IND'), 'IND', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_13_HOU_IND'), 60.38, false, 8, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', 'c821b559-7cd9-491d-abd3-082c877eeeb8', 2025, 14, (select id from public.nfl_games where espn_event_id = '2025_14_WAS_MIN'), 'WAS', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_14_WAS_MIN'), 51.08, false, 3, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', 'c821b559-7cd9-491d-abd3-082c877eeeb8', 2025, 15, (select id from public.nfl_games where espn_event_id = '2025_15_MIN_DAL'), 'DAL', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_15_MIN_DAL'), 69.58, false, 6, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', 'c821b559-7cd9-491d-abd3-082c877eeeb8', 2025, 16, (select id from public.nfl_games where espn_event_id = '2025_16_CIN_MIA'), 'MIA', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_16_CIN_MIA'), 35.53, false, 6, 'loss', 0),
  ('b0000001-0000-4000-8000-000000000001', 'c821b559-7cd9-491d-abd3-082c877eeeb8', 2025, 17, (select id from public.nfl_games where espn_event_id = '2025_17_PHI_BUF'), 'PHI', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_17_PHI_BUF'), 39.62, false, 10, 'win', 1),
  ('b0000001-0000-4000-8000-000000000001', 'c821b559-7cd9-491d-abd3-082c877eeeb8', 2025, 18, (select id from public.nfl_games where espn_event_id = '2025_18_CAR_TB'), 'CAR', (select kickoff_at - interval '1 hour' from public.nfl_games where espn_event_id = '2025_18_CAR_TB'), 41.7, false, 8, 'missed', 0)
;

set session_replication_role = default;

-- Missed picks (duplicate team reuse): 7
-- Dave Swan week 18: wanted SF, recorded missed
-- Danny week 10: wanted CHI, recorded missed
-- Grandma week 6: wanted DEN, recorded missed
-- David Scag week 12: wanted ATL, recorded missed
-- Jackson week 10: wanted SEA, recorded missed
-- Katherine week 9: wanted LAR, recorded missed
-- Ryan week 18: wanted CHI, recorded missed
