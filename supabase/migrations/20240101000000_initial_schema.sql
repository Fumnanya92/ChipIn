-- ============================================================
-- ChipIn — Initial Schema Migration
-- ============================================================

-- Enable UUID generation


-- ============================================================
-- USERS
-- Extends Supabase auth.users with profile data
-- ============================================================
create table if not exists public.users (
  id            uuid primary key references auth.users(id) on delete cascade,
  name          text not null default '',
  email         text,
  avatar_url    text,
  bio           text,
  location      text,
  -- Trust / verification
  phone_verified    boolean not null default false,
  id_verified       boolean not null default false,
  payment_verified  boolean not null default false,
  trust_score       int     not null default 0,
  -- Stats
  total_splits      int     not null default 0,
  success_rate      numeric(4,1) not null default 0,
  avg_rating        numeric(3,2) not null default 0,
  -- Timestamps
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- Automatically create a profile row on new signup
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.users (id, name, email, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', ''),
    new.email,
    new.raw_user_meta_data->>'avatar_url'
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ============================================================
-- LISTINGS
-- A user-posted split opportunity
-- ============================================================
create table if not exists public.listings (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references public.users(id) on delete cascade,
  title         text not null,
  description   text,
  category      text not null,          -- e.g. 'rent', 'food', 'transport'
  amount        numeric(10,2) not null,
  split_ways    int  not null default 2, -- how many people to split with
  location      text,
  image_url     text,
  is_active     boolean not null default true,
  expires_at    timestamptz,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create index if not exists listings_user_id_idx     on public.listings(user_id);
create index if not exists listings_category_idx    on public.listings(category);
create index if not exists listings_is_active_idx   on public.listings(is_active);
create index if not exists listings_created_at_idx  on public.listings(created_at desc);

-- ============================================================
-- MATCHES
-- A connection between a listing and an interested user
-- ============================================================
create table if not exists public.matches (
  id              uuid primary key default gen_random_uuid(),
  listing_id      uuid not null references public.listings(id) on delete cascade,
  owner_id        uuid not null references public.users(id) on delete cascade,
  requester_id    uuid not null references public.users(id) on delete cascade,
  status          text not null default 'pending'
                  check (status in ('pending','accepted','active','declined','expired','completed')),
  message         text,
  -- Cached denormalised display fields (updated via trigger or app)
  listing_title   text,
  listing_amount  numeric(10,2),
  listing_image_url text,
  owner_name      text,
  owner_avatar_url  text,
  requester_name  text,
  requester_avatar_url text,
  -- Timestamps
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index if not exists matches_listing_id_idx     on public.matches(listing_id);
create index if not exists matches_owner_id_idx       on public.matches(owner_id);
create index if not exists matches_requester_id_idx   on public.matches(requester_id);
create index if not exists matches_status_idx         on public.matches(status);

-- ============================================================
-- MESSAGES
-- Real-time chat within a match
-- ============================================================
create table if not exists public.messages (
  id          uuid primary key default gen_random_uuid(),
  match_id    uuid not null references public.matches(id) on delete cascade,
  sender_id   uuid not null references public.users(id) on delete cascade,
  content     text not null,
  is_read     boolean not null default false,
  created_at  timestamptz not null default now()
);

create index if not exists messages_match_id_idx    on public.messages(match_id);
create index if not exists messages_sender_id_idx   on public.messages(sender_id);
create index if not exists messages_created_at_idx  on public.messages(created_at asc);

-- ============================================================
-- ESCROW PAYMENTS
-- Tracks each party's escrow deposit for a match
-- ============================================================
create table if not exists public.escrow_payments (
  id          uuid primary key default gen_random_uuid(),
  match_id    uuid not null references public.matches(id) on delete cascade,
  user_id     uuid not null references public.users(id) on delete cascade,
  amount      numeric(10,2) not null,
  status      text not null default 'pending'
              check (status in ('pending','held','released','refunded','disputed')),
  payment_ref text,   -- external payment reference (Stripe charge ID etc.)
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (match_id, user_id)
);

create index if not exists escrow_match_id_idx  on public.escrow_payments(match_id);
create index if not exists escrow_user_id_idx   on public.escrow_payments(user_id);

-- ============================================================
-- REVIEWS
-- Post-split ratings left by each party
-- ============================================================
create table if not exists public.reviews (
  id            uuid primary key default gen_random_uuid(),
  match_id      uuid not null references public.matches(id) on delete cascade,
  reviewer_id   uuid not null references public.users(id) on delete cascade,
  reviewee_id   uuid not null references public.users(id) on delete cascade,
  rating        int  not null check (rating between 1 and 5),
  comment       text,
  created_at    timestamptz not null default now(),
  unique (match_id, reviewer_id)
);

create index if not exists reviews_reviewee_id_idx  on public.reviews(reviewee_id);
create index if not exists reviews_reviewer_id_idx  on public.reviews(reviewer_id);

-- Keep users.avg_rating in sync after each review insert/update
create or replace function public.update_user_avg_rating()
returns trigger language plpgsql security definer as $$
begin
  update public.users
  set avg_rating = (
    select coalesce(avg(rating), 0)
    from public.reviews
    where reviewee_id = new.reviewee_id
  )
  where id = new.reviewee_id;
  return new;
end;
$$;

drop trigger if exists on_review_upsert on public.reviews;
create trigger on_review_upsert
  after insert or update on public.reviews
  for each row execute procedure public.update_user_avg_rating();

-- ============================================================
-- NOTIFICATIONS
-- In-app notifications for matches, messages, payments, etc.
-- ============================================================
create table if not exists public.notifications (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.users(id) on delete cascade,
  title       text not null,
  body        text not null,
  type        text not null default 'general'
              check (type in ('match_request','match_accepted','match_declined',
                              'message','escrow_deposited','escrow_released',
                              'dispute_opened','dispute_resolved','review','general')),
  is_read     boolean not null default false,
  payload     jsonb,  -- optional deep-link data (e.g. {"match_id": "..."})
  created_at  timestamptz not null default now()
);

create index if not exists notifications_user_id_idx    on public.notifications(user_id);
create index if not exists notifications_is_read_idx    on public.notifications(user_id, is_read);
create index if not exists notifications_created_at_idx on public.notifications(created_at desc);

-- ============================================================
-- DISPUTES
-- Raised when a party contests the outcome of an escrow
-- ============================================================
create table if not exists public.disputes (
  id          uuid primary key default gen_random_uuid(),
  match_id    uuid not null references public.matches(id) on delete cascade,
  raised_by   uuid not null references public.users(id) on delete cascade,
  reason      text not null,
  evidence    text,
  status      text not null default 'open'
              check (status in ('open','under_review','resolved','closed')),
  resolution_note text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index if not exists disputes_match_id_idx  on public.disputes(match_id);
create index if not exists disputes_raised_by_idx on public.disputes(raised_by);

-- ============================================================
-- ROW-LEVEL SECURITY (RLS)
-- ============================================================

alter table public.users             enable row level security;
alter table public.listings          enable row level security;
alter table public.matches           enable row level security;
alter table public.messages          enable row level security;
alter table public.escrow_payments   enable row level security;
alter table public.reviews           enable row level security;
alter table public.notifications     enable row level security;
alter table public.disputes          enable row level security;

-- ---- USERS ----
-- Anyone can read public profiles
create policy "Public profiles are viewable by everyone"
  on public.users for select using (true);

-- Users can only update their own profile
create policy "Users can update own profile"
  on public.users for update using (auth.uid() = id);

-- ---- LISTINGS ----
-- Everyone can read active listings
create policy "Active listings are public"
  on public.listings for select using (is_active = true);

-- Owners can see their own inactive listings too
create policy "Owners see all their listings"
  on public.listings for select using (auth.uid() = user_id);

create policy "Authenticated users can post listings"
  on public.listings for insert with check (auth.uid() = user_id);

create policy "Owners can update their listings"
  on public.listings for update using (auth.uid() = user_id);

create policy "Owners can delete their listings"
  on public.listings for delete using (auth.uid() = user_id);

-- ---- MATCHES ----
-- Only owner or requester can see a match
create policy "Match participants can view match"
  on public.matches for select
  using (auth.uid() = owner_id or auth.uid() = requester_id);

create policy "Authenticated users can create match requests"
  on public.matches for insert with check (auth.uid() = requester_id);

create policy "Match participants can update match"
  on public.matches for update
  using (auth.uid() = owner_id or auth.uid() = requester_id);

-- ---- MESSAGES ----
create policy "Match participants can read messages"
  on public.messages for select
  using (
    exists (
      select 1 from public.matches m
      where m.id = messages.match_id
        and (m.owner_id = auth.uid() or m.requester_id = auth.uid())
    )
  );

create policy "Match participants can send messages"
  on public.messages for insert
  with check (
    auth.uid() = sender_id
    and exists (
      select 1 from public.matches m
      where m.id = messages.match_id
        and (m.owner_id = auth.uid() or m.requester_id = auth.uid())
    )
  );

-- ---- ESCROW PAYMENTS ----
create policy "Match participants can view escrow"
  on public.escrow_payments for select
  using (
    exists (
      select 1 from public.matches m
      where m.id = escrow_payments.match_id
        and (m.owner_id = auth.uid() or m.requester_id = auth.uid())
    )
  );

create policy "Users can insert their own escrow payment"
  on public.escrow_payments for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own escrow payment"
  on public.escrow_payments for update using (auth.uid() = user_id);

-- ---- REVIEWS ----
create policy "Reviews are public"
  on public.reviews for select using (true);

create policy "Authenticated users can post reviews"
  on public.reviews for insert with check (auth.uid() = reviewer_id);

-- ---- NOTIFICATIONS ----
create policy "Users can see their own notifications"
  on public.notifications for select using (auth.uid() = user_id);

create policy "Users can update their own notifications"
  on public.notifications for update using (auth.uid() = user_id);

-- System can insert notifications (service role or trigger)
create policy "Service can insert notifications"
  on public.notifications for insert with check (true);

-- ---- DISPUTES ----
create policy "Match participants can view disputes"
  on public.disputes for select
  using (
    exists (
      select 1 from public.matches m
      where m.id = disputes.match_id
        and (m.owner_id = auth.uid() or m.requester_id = auth.uid())
    )
  );

create policy "Match participants can raise disputes"
  on public.disputes for insert
  with check (
    auth.uid() = raised_by
    and exists (
      select 1 from public.matches m
      where m.id = disputes.match_id
        and (m.owner_id = auth.uid() or m.requester_id = auth.uid())
    )
  );

-- ============================================================
-- REALTIME
-- Enable realtime for tables that need live updates
-- ============================================================
alter publication supabase_realtime add table public.messages;
alter publication supabase_realtime add table public.notifications;
alter publication supabase_realtime add table public.matches;
alter publication supabase_realtime add table public.escrow_payments;
