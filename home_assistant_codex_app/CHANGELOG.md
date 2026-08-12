# Changelog

All notable changes to HA Codex are documented here.

## 1.2.2

- Clarified that Patch compatibility mode's full-access sandbox is applied when a Codex session starts, so a persistent session that began before the mode was enabled (or one changed with `/approvals`) can still hit the `bwrap: Failed to make / slave: Permission denied` error until the add-on is restarted.
- Added start-up logging that states the effective Codex sandbox mode and reminds you to restart the add-on after changing it.
- Documented how to recover a session stuck in `workspace-write`: choose Full Access in `/approvals`, or restart the add-on with Patch compatibility mode enabled.
- Started new sessions with Codex's `--sandbox danger-full-access` flag for the full-access patch path.

## 1.2.1

- Removed browser-callback sign-in, which cannot reliably return to an isolated Home Assistant add-on container from a user's browser at `localhost`.
- Made Device Code the first, preferred sign-in option and renumbered API-key sign-in as option 2.
- Preserved the working persistent-session terminal history rail, including its mouse-wheel, click, drag, and arrow controls.

## 1.2.0

- Rebuilt the terminal history rail injection to avoid `sed` replacement corruption that prevented prior rails from working and caused layout artifacts.
- The side rail now stays visible and supports arrows, clicking its track, and dragging its thumb, while retaining persistent sessions and mouse-wheel scrolling.

## 1.1.9

- Removed the malformed interactive history-rail fallback that could obscure the terminal with a large banner. Mouse-wheel and trackpad scrolling remain available.

## 1.1.8

- Made the always-visible history rail interactive: click or drag its track, or use its arrows, to navigate terminal scrollback in addition to mouse-wheel and trackpad scrolling.

## 1.1.7

- Added a CSS-rendered, always-visible history indicator for embedded browsers that defer the terminal page's injected rail script.

## 1.1.6

- Added an always-visible history rail for persistent tmux sessions, including arrow controls and a draggable track that use the same working wheel-navigation path.

## 1.1.5

- Loads tmux's mouse and alternate-screen settings before its server starts, preserving the browser's xterm scrollback and visible scrollbar for persistent sessions.

## 1.1.4

- Restored tmux mouse/copy-mode scrolling for persistent sessions, so mouse-wheel and trackpad gestures navigate terminal history instead of cycling through previously typed commands.
- Disabled tmux pane alternate-screen mode while preserving the persistent session and all three sign-in options.

## 1.1.3

- Corrected the history rail to use ttyd's actual xterm viewport; ttyd 1.7.7 does not expose a `window.term` object.
- Made history-rail initialization retry until ttyd has created its terminal, restoring the visible rail and mouse-wheel history navigation.

## 1.1.2

- Added an always-visible terminal-history rail that reads xterm's full buffer directly, including on Home Assistant's embedded browsers that hide native overlay scrollbars.
- Restored mouse-wheel terminal-history navigation through the rail's xterm buffer handling.

## 1.1.1

- Restored the stable persistent terminal-session identity so existing terminal scrollback and its visible scrollbar remain available after updating.

## 1.1.0

- Restored browser-based ChatGPT sign-in: Codex provides a terminal URL when a browser cannot open automatically.
- Kept Device Code as the preferred sign-in method for Home Assistant's embedded page and retained API-key sign-in as the third option.
- Replaced outdated App Store installation instructions with a My Home Assistant repository link and current Apps terminology.
- Added contribution guidance requiring personally reviewed, human-authored communication for any Open Home Foundation submission.

## 1.0.1

- Minor documentation update.

## 1.0.0

- Released the first official stable version of HA Codex.
- Refreshed the repository introduction and added a Buy Me a Coffee support link at the top of the GitHub README.

## 0.1.29

- Added default-on Patch compatibility mode so Codex's normal `apply_patch` mechanism works on Home Assistant OS, where nested Bubblewrap user namespaces are unavailable.
- Kept normal Codex command-approval behavior unchanged and added a Configuration toggle for troubleshooting.

## 0.1.28

- Made session persistence work with the default inline-history mode, so Codex stays running when you leave the HA Codex sidebar and reattaches when you return.
- Preserved the browser's visible scrollbar and mouse-wheel behavior while using the persistent terminal session.
- Reduced the default terminal scrollback from 10,000 to 5,000 lines; both session persistence and history preservation remain enabled by default.

## 0.1.27

- Promoted Home Assistant control setup to a prominent notice at the top of both README files and the Home Assistant add-on description.

## 0.1.26

- Added opt-in, built-in Home Assistant control actions with no user-managed token, IP address, or host setup.
- Added the restricted `ha-codex-ha` helper for configuration validation, selected reload actions, and a validated Home Assistant Core restart.
- Added separate disabled-by-default controls for Home Assistant actions and Core restart, plus Codex instructions to explain and request approval before using them.

## 0.1.25

- Added a permanently visible, styled native xterm scrollbar for terminal history.
- Removed the unused synthetic history gutter so the terminal keeps its full width.

## 0.1.24

- Removed the tmux display layer from inline-history mode so Codex output reaches xterm's scrollback buffer directly.
- Restored the visible history rail and mouse-wheel scrolling for long Codex responses.
- Keeps fullscreen-mode session persistence through tmux while ttyd owns the inline session for the add-on runtime.

## 0.1.23

- Initializes xterm's history buffer with the configured scrollback size before terminal output arrives.
- Fixed long output being limited to the visible screen despite a larger Terminal scrollback setting.

## 0.1.22

- Applies the configured terminal-history limit to persistent tmux sessions.
- Enables tmux mouse/copy-mode scrolling so wheel and trackpad gestures scroll history instead of recalling shell commands.
- Starts a fresh persistent session so the history and mouse settings take effect after updating.

## 0.1.21

- Made the history rail navigate xterm's full terminal buffer directly instead of the browser viewport.
- Explicitly reapplies the configured terminal scrollback size after the terminal client initializes.

## 0.1.20

- Start a fresh persistent terminal session after the sign-in-menu update so existing sessions do not retain Codex's previous three-choice prompt.

## 0.1.19

- Replaced Codex's three-choice first-run login screen with an HA Codex sign-in menu.
- Made **Sign in with Device Code (Preferred Method)** option 1 and kept API-key sign-in as option 2.

## 0.1.18

- Put model selection first in the Home Assistant Apps description and setup guidance, directing users to App Configuration before starting HA Codex.

## 0.1.17

- Removed the current-browser sign-in path from setup instructions.
- Promoted **Log in with a different device (Preferred Method)** to sign-in option 1 and renumbered the API-key path as option 2.

## 0.1.16

- Replaced wordy Top/End controls with compact, accessible up/down arrows.
- Restored xterm's native wheel, trackpad, and touch history handling so the full configured scrollback range is available.
- Slimmed the history gutter and removed the duplicate native scrollbar to preserve terminal space in the Home Assistant sidebar.

## 0.1.15

- Added an inset terminal-history gutter that never covers terminal text or the status row.
- Added draggable history, Top/End buttons, mouse-wheel and trackpad scrolling, and touch-swipe scrolling.

## 0.1.14

- Fixed the visible terminal scrollbar build path by including the standard text and compression utilities it requires.

## 0.1.13

- Added all currently documented Codex CLI models to the Configuration selector.
- Documented the model choices and clarified the difference between the add-on default and Codex's in-session `/model` command.

## 0.1.12

- Made the recommended **Log in with a different device** sign-in path prominent in both READMEs.

## 0.1.11

- Added an always-visible, touch-draggable terminal scrollbar for reviewing long Codex responses in Home Assistant.
- Kept the browser's native scrollbar available as well, where the device shows it.

## 0.1.10

- Added Preserve terminal history, which starts Codex in inline transcript mode so long reviews can be scrolled in Home Assistant.
- Reduced the default terminal history buffer to 10,000 lines for a better browser-memory balance.
- Documented every add-on setting in the repository and add-on READMEs.

## 0.1.9

- Increased the terminal history buffer to 20,000 lines so long Codex reviews remain scrollable.
- Added a configurable Terminal scrollback setting (1,000–50,000 lines).

## 0.1.8

- Updated the repository URL to `ambient-home-systems/ha-codex` after the repository rename.
- Replaced the illustrated README images with a privacy-safe, real HA Codex workspace screenshot.

## 0.1.7

- Changed the default Codex model to GPT-5.6 Terra to better balance everyday Home Assistant work and usage.
- Added an add-on setting to choose GPT-5.6 Terra or GPT-5.6 Sol before startup.

## 0.1.6

- Added a full repository setup guide with sign-in options, visual examples, safety guidance, and troubleshooting notes.

## 0.1.5

- Reworked the app icon and logo with a high-contrast badge that is clear in both light and dark Home Assistant themes.

## 0.1.4

- Added Bubblewrap to remove Codex's bundled-sandbox warning at startup.

## 0.1.3

- Renamed the visible app and sidebar label to **HA Codex**.

## 0.1.2

- Added the Home Assistant app icon and logo.
- Added this changelog so update details are visible before installation.

## 0.1.1

- Fixed Codex not being found after the app started.
- Separated Codex's installed program files from its persistent login and settings directory.

## 0.1.0

- Initial release with a persistent Codex terminal in the Home Assistant sidebar.
