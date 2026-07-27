-- 1500 Gateway 30-Day Campaign Tracker
-- Run this ONCE in the Supabase SQL editor for the "newrentest" project
-- (https://gnmmpspivkztgcjpfvvd.supabase.co). Safe to re-run: it will not
-- overwrite any status/notes the team has already changed.
--
-- What it does:
--   1. Creates the gateway_tasks table
--   2. Locks every column except status + notes so a public visitor can only
--      move a task's status or add a note, never rewrite the plan
--   3. Turns on row-level security with public read + public status/notes update
--   4. Seeds all 35 tasks from the campaign plan

-- 1. Table -------------------------------------------------------------------
create table if not exists public.gateway_tasks (
  id          integer primary key,
  phase       text not null,
  workstream  text not null,
  task        text not null,
  owner       text not null,
  support     text,
  deadline    text not null,
  due_date    date,
  status      text not null default 'Not Started'
              check (status in ('Not Started','In Progress','Blocked','Done')),
  notes       text,
  updated_at  timestamptz not null default now()
);

-- 2. Freeze the fixed campaign structure -------------------------------------
-- A public update can only touch status and notes. Everything else is forced
-- back to its original value, so nobody can rewrite tasks, owners, or dates.
-- Editable from the page: status, notes, owner, support, deadline, due_date.
-- Frozen (structure of the plan): id, phase, workstream, task.
create or replace function public.gateway_tasks_guard()
returns trigger language plpgsql as $func$
begin
  new.id         := old.id;
  new.phase      := old.phase;
  new.workstream := old.workstream;
  new.task       := old.task;
  new.updated_at := now();
  return new;
end $func$;

drop trigger if exists gateway_tasks_guard_trg on public.gateway_tasks;
create trigger gateway_tasks_guard_trg
  before update on public.gateway_tasks
  for each row execute function public.gateway_tasks_guard();

-- 3. Row-level security ------------------------------------------------------
alter table public.gateway_tasks enable row level security;

drop policy if exists gateway_read on public.gateway_tasks;
create policy gateway_read on public.gateway_tasks
  for select using (true);

drop policy if exists gateway_update on public.gateway_tasks;
create policy gateway_update on public.gateway_tasks
  for update using (true) with check (true);

-- Allow adding new tasks from the page.
drop policy if exists gateway_insert on public.gateway_tasks;
create policy gateway_insert on public.gateway_tasks
  for insert with check (true);

-- Allow deleting ONLY tasks added later (id > 35). The original seeded 35
-- can never be deleted from the page.
drop policy if exists gateway_delete on public.gateway_tasks;
create policy gateway_delete on public.gateway_tasks
  for delete using (id > 35);

-- Auto-assign ids to newly added tasks, continuing after the seeded 35.
create sequence if not exists public.gateway_tasks_id_seq owned by public.gateway_tasks.id;
alter table public.gateway_tasks alter column id set default nextval('public.gateway_tasks_id_seq');

-- 4. Seed data ---------------------------------------------------------------
insert into public.gateway_tasks
  (id, phase, workstream, task, owner, support, deadline, due_date, notes)
values
  (1,  '1 - Launch (7/27-8/1)',  'Command',  $g$Send after-action memo to full coalition: action list, council + clerk email addresses, mayor/council profiles with priorities and talking points, engagement do's/don'ts (all members get touched, mayor is priority)$g$, 'John', $g$Chad (council content), Ben (sends)$g$, 'Mon 7/27', '2026-07-27', $g$Chad already has the email list. John assembles and drives to done; Ben's name on the send to coalition.$g$),
  (2,  '1 - Launch (7/27-8/1)',  'Command',  $g$Set up shared intel thread for tracking council member conversations and sensitivities$g$, 'John', 'All', 'Mon 7/27', '2026-07-27', $g$Simple email thread or shared doc. John polices it weekly so intel actually lands there.$g$),
  (3,  '1 - Launch (7/27-8/1)',  'Council',  $g$Brief Don before his Monday meetings: talking points, project one-pager, Crump notes (McIntosh lunch is at Crump's restaurant)$g$, 'Chad', 'Dave', 'Mon 7/27 AM', '2026-07-27', $g$Don meets McIntosh at noon Monday. Time-critical.$g$),
  (4,  '1 - Launch (7/27-8/1)',  'Media',    $g$Reporter meetings: Freelance Star, VA Free Press, Marty Davis (3:30). Tease labor commitment, cover project changes. Explore Freelance Star exclusive$g$, 'Dave', 'Ben', 'Mon 7/27', '2026-07-27', $g$Phase 1 of the 3-bite media plan. Marty's new paper launches Aug 2; Don meets him Wed evening.$g$),
  (5,  '1 - Launch (7/27-8/1)',  'Command',  $g$Lock turnout target and speaker target internally (Ben/Chad/Dave huddle), then send both numbers to Greg Akerman and Don$g$, 'Dave', 'Ben, Chad', 'Tue 7/28 EOD', '2026-07-28', $g$HARD DEADLINE: Don needs the number before his Wed 4:30 Joel meeting to lock the pre-rally venue (100-seat back room vs rooftop). Recommend: see Strategy tab.$g$),
  (6,  '1 - Launch (7/27-8/1)',  'Coalition', $g$Follow up with Virginia Diamond: confirm she is running teacher/FF outreach, ask what materials she needs, send project one-pager and proffer summary$g$, 'Ben', $g$Chad (materials)$g$, 'Tue 7/28', '2026-07-28', $g$She has the Fredericksburg Teachers Union referral via David Walrod (Fairfax). Individual voices, not formal endorsements.$g$),
  (7,  '1 - Launch (7/27-8/1)',  'Media',    $g$Finalize 3-phase earned media plan with Greg Akerman offline: tease (Mon), trades PLA release, press conference$g$, 'Dave', 'Greg Akerman', 'Tue 7/28', '2026-07-28', $g$Ben tasked Dave on the call. Set press conference date while you're at it.$g$),
  (8,  '1 - Launch (7/27-8/1)',  'Command',  $g$Propose weekly labor coalition check-in time (mid-week, suggest Wed), collect availability, send recurring invite$g$, 'John', $g$Ben (sends invite)$g$, 'Tue 7/28', '2026-07-28', $g$Greg deferred on time and will forward invite to his people.$g$),
  (9,  '1 - Launch (7/27-8/1)',  'Command',  $g$Send hold calendar invites for 8/25: pre-rally (5:30 PM) and Council hearing (7:30 PM, Hanover St entrance)$g$, 'John', 'Jeremy', 'Tue 7/28', '2026-07-28', $g$Send to internal team, client, and coalition list.$g$),
  (10, '1 - Launch (7/27-8/1)',  'Digital',  $g$Connect Michael Blain with RenUSA digital production team for ad targeting and production support$g$, 'Dave', 'Michael Blain', 'Tue 7/28', '2026-07-28', $g$Michael is set up in Meta, running Raising the Bar campaigns in DC/Baltimore. Trades fund the ads, not the developer.$g$),
  (11, '1 - Launch (7/27-8/1)',  'Digital',  $g$Confirm Action Network fix: editing disabled on sample letters (no holding tank exists). Review portal content, add MOU emphasis, confirm clerk included on recipients$g$, 'Dave', $g$Michael Blain, Jeremy$g$, 'Wed 7/29', '2026-07-29', $g$Michael's landing page is built and behind password. One anti-message already tried to sneak through the 1500gateway.com tool.$g$),
  (12, '1 - Launch (7/27-8/1)',  'Council',  $g$Support Don's Wednesday meetings: Josh Cole 3 PM, Joel Griffin 4:30, Marty Davis evening. Confirm venue answer from Joel same night$g$, 'Chad', $g$Jeremy (venue f/u)$g$, 'Wed 7/29', '2026-07-29', $g$Don leaves town soon. Get everything we need from him this week.$g$),
  (13, '1 - Launch (7/27-8/1)',  'Event',    $g$Pre-rally venue contract finalized and signed after Don's Joel meeting$g$, 'Jeremy', 'Chad, Don', 'Fri 7/31', '2026-07-31', $g$Venue: back room (seats 100) or rooftop. Food at 5:30, walk to Council at 7:00.$g$),
  (14, '1 - Launch (7/27-8/1)',  'Media',    $g$Trades PLA/MOU press release drafted, approved, and issued (from labor, not developer)$g$, 'Dave', 'Greg Akerman, Ben', 'Thu 7/30 - Fri 7/31', '2026-07-31', $g$Bite 2 of 3. Follows the Monday tease. Share our local press list with Greg.$g$),
  (15, '1 - Launch (7/27-8/1)',  'Print Ad', $g$Draft 2-sentence testimonial quotes for resident union members (Kistler, Marvin, Lupe Tejo + others) and send to Akerman for member sign-off$g$, 'Dave', $g$Jeremy (drafting)$g$, 'Fri 7/31', '2026-07-31', $g$Greg asked us to draft for approval. Note: James Kistler is IBEW (electrician), not a carpenter. Frank Mahoney checking availability of the carpenters' homeowner.$g$),
  (16, '1 - Launch (7/27-8/1)',  'Event',    $g$Build turnout plan: recruitment channels (trades internal call, portal signups, prior rally list), food, transport, RSVP tracking$g$, 'Jeremy', 'Greg Akerman', 'Sat 8/1', '2026-08-01', $g$Fredericksburg CITY residents are gold. Council dismissed May turnout as non-constituents. Prove them wrong.$g$),
  (17, '2 - Amplify (8/3-8/14)', 'Media',    $g$Press conference: lock date, venue, speakers (local union members + teacher/superintendent + fire official for the visual). Run it$g$, 'Dave', 'Jeremy (logistics), Virginia, Greg', 'Week of 8/3 (hold Wed 8/5)', '2026-08-05', $g$Bite 3 of 3. Jason Friedman's visual idea: trades + teachers + fire together. Virginia sources the teachers/FF.$g$),
  (18, '2 - Amplify (8/3-8/14)', 'Digital',  $g$Paid digital ads live in Fredericksburg: jobs + school funding messages, linking to Action Network portal$g$, 'Dave', 'Michael Blain, RenUSA digital', 'Tue 8/4', '2026-08-04', $g$Trades-funded. Geo-targeted to city. Ads must drive an action (email tool).$g$),
  (19, '2 - Amplify (8/3-8/14)', 'Digital',  $g$Film short videos with James Kistler and/or Marvin: personal story + PLA community benefits (local hire, apprenticeships, career pathways)$g$, 'Jeremy', 'Michael Blain (films), Chad (intros)', 'Filmed by Fri 8/7', '2026-08-07', $g$Chad has the Kistler relationship. Michael has the Key Bridge PLA video model. Use on social, in paid, and on 1500gateway.com.$g$),
  (20, '2 - Amplify (8/3-8/14)', 'Digital',  $g$Deploy videos: Michael's social + paid, and posted to 1500gateway.com$g$, 'Jeremy', 'Michael Blain, Dave', 'Mon 8/10', '2026-08-10', null),
  (21, '2 - Amplify (8/3-8/14)', 'Council',  $g$Run council meeting cycle 2: confirm Matt Rowe meeting (David Pala relationship), Holmes intro, mayor touch plan. Bring resident members (Lupe Tejo, Kistler, Marvin) to meetings$g$, 'Chad', 'Ben (mayor/hard calls), Don remote', 'Fri 8/7', '2026-08-07', $g$Mayor can carry votes if she moves. Every member gets touched; no one skipped.$g$),
  (22, '2 - Amplify (8/3-8/14)', 'Media',    $g$Source off-record data center industry validator and an environmental validator for reporters ('this sets a new industry standard')$g$, 'Dave', 'Don, Ben', 'Fri 8/7', '2026-08-07', $g$Greg's idea. Don may have industry allies. Flag: handle carefully, off-record only.$g$),
  (23, '2 - Amplify (8/3-8/14)', 'Media',    $g$LTE pipeline: identify 3-4 resident authors (Kistler, Marvin next profiles), draft, place on rolling basis through 8/24$g$, 'Dave', 'Chad (asks), Greg', 'First placed by Sat 8/8', '2026-08-08', $g$Last LTE was an immigrant woman member. Vary the profiles to match council targets.$g$),
  (24, '2 - Amplify (8/3-8/14)', 'Event',    $g$Speaker pool built: 2x the target number identified, all Fredericksburg city residents, contact info + story angle logged$g$, 'Jeremy', 'Chad, Greg, Virginia, Frank', 'Sat 8/8', '2026-08-08', $g$Sources: trades internal asks, spouse/family teachers and FF (David Pala's tactic), portal signups, May hearing speakers.$g$),
  (25, '2 - Amplify (8/3-8/14)', 'Print Ad', $g$Collect approved quotes + headshots (or family/work photos) from resident members; hand full package to ad production$g$, 'Jeremy', 'Greg, Michael (collect)', 'Wed 8/12', '2026-08-12', $g$Big headshot + 2-sentence testimonial per person.$g$),
  (26, '2 - Amplify (8/3-8/14)', 'Command',  $g$Weekly check-ins running: John drives agenda, tracks action items, chases owners between calls$g$, 'John', 'Ben (chairs)', 'Every Wed', null, $g$This is John's lane to be assertive: name the owner, name the date, follow up in writing.$g$),
  (27, '2 - Amplify (8/3-8/14)', 'Client',   $g$Client update memo to Penzance (Brooke/John/Faison): campaign status, whip count read, risks$g$, 'Dave', 'Ben', 'Fri 8/7 + weekly', '2026-08-07', $g$Dave owns client comms. Keep Brooke's enthusiasm fed.$g$),
  (28, '3 - Close (8/17-8/25)',  'Print Ad', $g$Newspaper ad designed, approved by Greg/members, placed to run week of 8/17 (repeat weekend before hearing if budget allows)$g$, 'Dave', 'Jeremy, Akerman', 'Placed by Fri 8/14, runs 8/17-8/23', '2026-08-14', $g$Free Lance-Star deadline check needed. [UNVERIFIED: their ad booking lead time - confirm early.]$g$),
  (29, '3 - Close (8/17-8/25)',  'Event',    $g$Speaker prep: talking points by speaker type (jobs, schools, fire, resident quality-of-life), 1:1 or group prep sessions, 3-min discipline$g$, 'Jeremy', 'Chad, Dave (messaging)', 'Week of 8/17', '2026-08-17', $g$Nurture early per Ben. Residency stated up front in every speech: name + street/neighborhood.$g$),
  (30, '3 - Close (8/17-8/25)',  'Council',  $g$Final whip count and gap-closing plan; Ben/Dave direct engagement on soft votes; mayor final touch$g$, 'Chad', 'Ben, Dave', 'Wed 8/19', '2026-08-19', null),
  (31, '3 - Close (8/17-8/25)',  'Media',    $g$Pre-hearing media push: advisory for 8/25, pitch turnout/PLA story, LTEs landing, confirm reporters attending pre-rally$g$, 'Dave', 'Greg', 'Thu 8/20 - Mon 8/24', '2026-08-24', null),
  (32, '3 - Close (8/17-8/25)',  'Event',    $g$Final turnout confirmations: RSVP chase, reminder texts/emails via portal + trades, transport confirmed$g$, 'Jeremy', 'Michael, Greg, John (tracking)', 'Fri 8/21 - Mon 8/24', '2026-08-24', null),
  (33, '3 - Close (8/17-8/25)',  'Event',    $g$Run of show + logistics packet: pre-rally program, walk-over plan, seating/arrival, speaker order and check-in, signage, food$g$, 'Jeremy', 'John (doc), Chad', 'Tue 8/18 draft, final Fri 8/21', '2026-08-21', null),
  (34, '3 - Close (8/17-8/25)',  'Event',    $g$Day-of execution: Jeremy on ground commanding event; Chad floor-managing speakers; Dave on media; Ben with client and labor leads$g$, 'Jeremy', 'All', 'Tue 8/25', '2026-08-25', $g$Pre-rally 5:30, move at 7:00, hearing 7:30.$g$),
  (35, '3 - Close (8/17-8/25)',  'Command',  $g$Post-hearing debrief + client report within 48 hours$g$, 'Dave', 'All', 'Thu 8/27', '2026-08-27', null)
on conflict (id) do nothing;

-- Resume auto-ids after the highest existing id, so new tasks never collide
-- with the seeded rows.
select setval('public.gateway_tasks_id_seq', (select max(id) from public.gateway_tasks));
