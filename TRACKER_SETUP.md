# 1500 Gateway Campaign Tracker: setup

The tracker is a single file, `tracker.html`, served alongside the stakeholder
dashboard at `https://dave-renusa.github.io/gateway/tracker.html`. It reads and
writes a shared task list in Supabase so the whole team sees the same status.

## Two one-time steps

### 1. Create the table (paste, no terminal)

1. Open the Supabase dashboard for the **newrentest** project
   (https://gnmmpspivkztgcjpfvvd.supabase.co).
2. Left sidebar > **SQL Editor** > **New query**.
3. Paste the entire contents of `supabase_setup.sql` and click **Run**.

This creates `gateway_tasks`, seeds all 35 tasks, and sets it so a public
visitor can change only a task's **status** and **notes**, never the plan.
Re-running the file is safe; it will not wipe status the team has already set.

### 2. Add the anon key

1. Supabase dashboard > **Project Settings** > **API**.
2. Under **Project API keys**, copy the **anon / public** key
   (safe to expose; it is meant to live in public client code).
3. In `tracker.html`, near the top of the `<script>` block, replace
   `PASTE_ANON_KEY_HERE` with that key.

Reload the page and the 35 tasks appear.

## Editing

Viewing is open to anyone with the link. To change a status or note, click
**Enable editing** and type the edit word. It is `hanover` by default; change
the `EDIT_WORD` line in `tracker.html` to whatever you want.

## What it shows

- Countdown to the Aug 25, 2026 7:30 PM hearing.
- Three phase cards (Launch, Amplify, Close) with percent complete.
- Stat row: total, done, in progress, blocked, overdue.
- Filter by phase, owner, status; search; overdue-only and blocked-only toggles.
- Overdue tasks flagged with a red edge; hard deadlines called out.

The page re-pulls every 30 seconds and on tab focus, so teammates see each
other's updates without reloading.
