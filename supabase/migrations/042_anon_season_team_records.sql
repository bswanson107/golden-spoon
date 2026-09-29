-- Allow anon (public demo) to read season team records, matching nfl_games / nfl_teams.

drop policy if exists "season_team_records_select_authenticated" on public.season_team_records;

create policy "season_team_records_select_authenticated"
  on public.season_team_records for select
  to anon, authenticated
  using (true);
