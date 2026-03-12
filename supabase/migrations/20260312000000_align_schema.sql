-- ============================================================
-- Migration: align database schema with app model fields
-- Adds columns that app code expects but the original schema
-- did not define.
-- ============================================================

-- ── USERS ───────────────────────────────────────────────────────────────

-- App uses 'full_name'; original schema used 'name'.
alter table public.users
  add column if not exists full_name text;

-- Copy existing name → full_name for any pre-existing rows.
update public.users
  set full_name = name
  where full_name is null;

-- Phone number stored on the profile.
alter table public.users
  add column if not exists phone_number text;

-- App uses 'average_rating'; original schema used 'avg_rating'.
alter table public.users
  add column if not exists average_rating numeric(3,2) not null default 0;

update public.users
  set average_rating = avg_rating
  where average_rating = 0 and avg_rating > 0;

-- Update the auto-create trigger to populate full_name.
-- The app sends data: {'full_name': fullName} during signUp.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.users (id, full_name, email, avatar_url)
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data->>'full_name',
      new.raw_user_meta_data->>'name',
      ''
    ),
    new.email,
    new.raw_user_meta_data->>'avatar_url'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

-- ── LISTINGS ────────────────────────────────────────────────────────────

-- total_cost: the full price of the listing (original: 'amount').
alter table public.listings
  add column if not exists total_cost numeric(10,2) not null default 0;

update public.listings
  set total_cost = amount
  where total_cost = 0;

-- split_amount: per-person cost (amount / split_ways).
alter table public.listings
  add column if not exists split_amount numeric(10,2) not null default 0;

update public.listings
  set split_amount = case
    when split_ways > 0 then round(amount / split_ways, 2)
    else amount
  end
  where split_amount = 0;

-- slots_total: number of spots available (original: 'split_ways').
alter table public.listings
  add column if not exists slots_total int not null default 2;

update public.listings set slots_total = split_ways;

-- slots_filled: how many spots have been taken.
alter table public.listings
  add column if not exists slots_filled int not null default 0;

-- status: lifecycle state (original: 'is_active' boolean).
alter table public.listings
  add column if not exists status text not null default 'active'
  check (status in ('active', 'filled', 'paused', 'expired'));

update public.listings
  set status = case when is_active then 'active' else 'paused' end;

-- duration: payment frequency cycle.
alter table public.listings
  add column if not exists duration text not null default 'monthly'
  check (duration in ('oneTime', 'monthly', 'custom'));

-- is_remote: whether this listing is location-independent.
alter table public.listings
  add column if not exists is_remote boolean not null default false;

-- tags: free-form labels for filtering.
alter table public.listings
  add column if not exists tags text[] not null default '{}';
