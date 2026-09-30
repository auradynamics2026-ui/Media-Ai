create table profiles (id uuid primary key references auth.users on delete cascade, role text not null default 'student');
create table events (id uuid primary key default gen_random_uuid(), name text not null, event_date date not null, photo_count int not null default 0);
create table photos (id uuid primary key default gen_random_uuid(), event_id uuid references events on delete cascade, url text not null);
create table favorites (user_id uuid references auth.users on delete cascade, photo_id uuid references photos on delete cascade, primary key (user_id, photo_id));

create function handle_new_user() returns trigger language plpgsql security definer as $$
begin insert into profiles (id) values (new.id); return new; end $$;
create trigger on_auth_user_created after insert on auth.users for each row execute function handle_new_user();

alter table profiles enable row level security;
alter table events enable row level security;
alter table photos enable row level security;
alter table favorites enable row level security;
create policy "read own profile" on profiles for select using (auth.uid() = id);
create policy "read events" on events for select using (auth.role() = 'authenticated');
create policy "read photos" on photos for select using (auth.role() = 'authenticated');
create policy "own favorites" on favorites for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "admin write events" on events for insert with check (exists (select 1 from profiles where id = auth.uid() and role = 'admin'));
