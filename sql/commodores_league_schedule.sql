-- Official SBMSA Fall 2026 JV 7on7 Maxwell book for the Commodores field book.
-- Run manually on the Commodores project only (adjnmtpjoyxvmlogjjpz).
-- Do not run on Studio Pod or CBP.
--
-- Reserved commodores_plans id: sbmsa-jv-maxwell
-- Source: https://sbmsa.net/schedule/740099/jv-7-on-7-maxwell
-- Schedule revision on that page: Tue, Aug 25, 2026 5:17 PM
--
-- Score / standings updates: edit the JSON (standings w/l/t/gp and games[].result
-- as {"home": n, "away": n}), bump updated_at, and re-run. Same revisedAt keeps
-- the current slate; a newer revisedAt replaces the book. The page reads this
-- row after coach sign-in, so a score change does not need a deploy.
-- Commodores games only. Do not invent games or scores.
--
-- Venues (SBMSA locations):
-- MMS*  = Memorial Middle School, 12550 Vindon Dr, Houston, TX 77024
-- SFMS* = Spring Forest Middle School, 14240 Memorial Dr, Houston, TX 77079
-- Do not label SFMS as St. Francis.

insert into public.commodores_plans (id, payload, updated_at)
values (
  'sbmsa-jv-maxwell',
  $league${
    "id": "sbmsa-jv-maxwell",
    "kind": "league-schedule",
    "league": "SBMSA Fall 2026 JV 7on7 Maxwell",
    "source": "https://sbmsa.net/schedule/740099/jv-7-on-7-maxwell",
    "revisedAt": "2026-08-25T17:17:00-05:00",
    "timezone": "America/Chicago",
    "team": "Commodores",
    "coach": "Selber",
    "updatedAt": "2026-08-27T14:45:00-05:00",
    "venues": {
      "MMS": {"name": "Memorial Middle School", "address": "12550 Vindon Dr, Houston, TX 77024"},
      "SFMS": {"name": "Spring Forest Middle School", "address": "14240 Memorial Dr, Houston, TX 77079"}
    },
    "standings": [
      {"team": "Sooners", "coach": "Laxalt", "w": 0, "l": 0, "t": 0, "gp": 0},
      {"team": "Rebels", "coach": "Matlack", "w": 0, "l": 0, "t": 0, "gp": 0},
      {"team": "MS ST Bulldogs", "coach": "Johnson", "w": 0, "l": 0, "t": 0, "gp": 0},
      {"team": "LSU Tigers", "coach": "Meche", "w": 0, "l": 0, "t": 0, "gp": 0},
      {"team": "Longhorns", "coach": "Armbruster", "w": 0, "l": 0, "t": 0, "gp": 0},
      {"team": "Irish", "coach": "Robisheaux", "w": 0, "l": 0, "t": 0, "gp": 0},
      {"team": "Georgia Bulldogs", "coach": "Elliott", "w": 0, "l": 0, "t": 0, "gp": 0},
      {"team": "Crimson Tide", "coach": "Hicks", "w": 0, "l": 0, "t": 0, "gp": 0},
      {"team": "Commodores", "coach": "Selber", "w": 0, "l": 0, "t": 0, "gp": 0}
    ],
    "games": [
      {"id": "2026-09-01-georgia", "week": 1, "date": "2026-09-01", "time": "18:00", "home": "Commodores", "away": "Georgia Bulldogs", "location": "MMS North West", "result": null},
      {"id": "2026-09-08-msst", "week": 2, "date": "2026-09-08", "time": "18:00", "home": "MS ST Bulldogs", "away": "Commodores", "location": "MMS North West", "result": null},
      {"id": "2026-09-15-irish", "week": 3, "date": "2026-09-15", "time": "19:30", "home": "Commodores", "away": "Irish", "location": "MMS North West", "result": null},
      {"id": "2026-09-22-longhorns", "week": 4, "date": "2026-09-22", "time": "19:30", "home": "Commodores", "away": "Longhorns", "location": "MMS North West", "result": null},
      {"id": "2026-10-03-tide", "week": 5, "date": "2026-10-03", "time": "10:30", "home": "Crimson Tide", "away": "Commodores", "location": "SFMS South", "result": null},
      {"id": "2026-10-05-sooners", "week": 6, "date": "2026-10-05", "time": "18:00", "home": "Sooners", "away": "Commodores", "location": "MMS South East", "result": null},
      {"id": "2026-10-17-rebels", "week": 7, "date": "2026-10-17", "time": "09:00", "home": "Rebels", "away": "Commodores", "location": "SFMS North", "result": null},
      {"id": "2026-10-27-lsu", "week": 9, "date": "2026-10-27", "time": "19:30", "home": "Commodores", "away": "LSU Tigers", "location": "MMS North East", "result": null}
    ]
  }$league$::jsonb,
  timestamptz '2026-08-27 14:45:00-05'
)
on conflict (id) do update
set
  payload = excluded.payload,
  updated_at = excluded.updated_at
where
  coalesce(public.commodores_plans.payload->>'revisedAt','') < excluded.payload->>'revisedAt'
  or (
    coalesce(public.commodores_plans.payload->>'revisedAt','') = excluded.payload->>'revisedAt'
    and public.commodores_plans.updated_at < excluded.updated_at
  );
