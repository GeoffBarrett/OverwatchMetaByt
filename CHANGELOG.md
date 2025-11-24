- [0.3.0](https://github.com/GeoffBarrett/OverwatchMetaByt/pull/3) - 2025-11-23
  - Bug Fix: Correct Ability to Pull Win Rate
  - *Added*
    - `get_rates_list`: will now retrieve both the pick and win rate as they are adjacent in the text.
  - *Modified*
    - Updated to pixlet version `0.34.0`
    - `OverBuff` has been sunset, now all requests go through `blizzard.com`.
    - `parse_char_type_percentage`: now is used to filter the character name and the win rate exclusively.
      The pick-rate ends up as its own item in the list in the following index.
    - `get_overbuff_text`: renamed to `get_blizzard_text`, and will now use the parameters to match Blizzard's
      API. Note: `role` can be toggle-able, but the full list is still sent. The role will be filtered later.
      - `get_heroes`: updated to retrieve a map of hero name -> hero role (used for filtering by role).
  - *Removed*
    - `TIME_WINDOWS`: no longer required, `blizzard.com` does not allow for us to use these filters.
    - `get_win_rate_raw_list`: replaced by `get_rates_list`.
    - `get_pick_rate_raw_list`: replaced by `get_rates_list`.
    - `find_image_with_size`: no longer needed as we don't have a list of images to parse.

- [0.2.0](https://github.com/GeoffBarrett/OverwatchMetaByt/pull/2) - 2024-10-07
  - Bug Fix: Reinhardt Spelling Fix
  _Fixed_
    - Correct the spelling of Reinhardt (was spelled Reinhard).

- [0.1.0](https://github.com/GeoffBarrett/OverwatchMetaByt/pull/1) - 2024-09-28
  - Initial Repository Push
  - _Added_
    - Added devcontainer configuration.
    - Added github workflows.
    - Initialized application.
    - Added the `overwatch_meta` app.
      - Currently it will retrieve the pick rate percentages and scroll the top 5 pick rates.
    - Included the `README.md` contents to explain the application.
    - Example `webp` for the two statistic modes (win rate and pick rate).