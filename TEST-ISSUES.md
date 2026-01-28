# ShadowChain ZK Arena — Test Issues (Player 1)

**Tester:** Dev Wallet 0x1387...f7f8 (Player 1)
**Date:** 2026-01-28
**URL:** https://shadowchain.netlify.app
**Game ID:** 2

---

## Issue 1: Dev wallet disconnects on page navigation
- **Severity:** major
- **Flow:** connect wallet → navigate
- **Description:** After connecting the dev wallet on the /lobby page, navigating to /game/2 (via "Join Game" link) causes the wallet to disconnect. The header reverts to showing "Connect Wallet" instead of the connected address. User must re-enter the private key on the game page.
- **Expected:** Dev wallet connection should persist across client-side navigations within the Next.js app. The wallet state should be maintained in React context/provider across route changes.
- **Snapshot:** Header showed "Connect Wallet" + 🔧 button after navigation, instead of ⚠️ DEV badge + address.

## Issue 2: Max players defaults to 4 instead of visually selected 2
- **Severity:** major
- **Flow:** create game
- **Description:** When opening the Create Arena modal, the Max Players buttons show "2, 4, 6, 8" but none appears visually selected by default. Without clicking a player count button (expecting 2 to be selected as first option), the game was created with maxPlayers=4 (lobby showed "0/4 players"). The "2" button should either be pre-selected or the UI needs clearer default indication.
- **Expected:** The "2" button should be visually selected by default, OR the default should actually be 2. The UI should clearly indicate which option is active.
- **Snapshot:** Lobby showed Arena #2 with "0/4 players" after creation.

## Issue 3: Players sidebar count inconsistent with main area
- **Severity:** minor
- **Flow:** game page display
- **Description:** After joining Arena #2, the sidebar "Players" heading showed "(1/1)" while the center waiting message showed "0/4 players joined". The maxPlayers denominator differs between sidebar and main content. After both players joined, sidebar showed "(2/2)" but the game was supposedly created with maxPlayers=4.
- **Expected:** Both displays should show consistent maxPlayers count.

## Issue 4: Game #0 — phantom game from contract initialization
- **Severity:** minor
- **Flow:** lobby display
- **Description:** Arena #0 in the lobby shows "0/0 players" and was created by "0x0000...0000" (zero address). This is a phantom game from the contract's initialization (game ID 0 doesn't represent a real game). The "Join Game" link is active but the game is invalid.
- **Expected:** Game #0 should either not appear in the lobby, or be filtered out. Alternatively, games by the zero address should be hidden.

## Issue 5: Console error — Cross-Origin-Opener-Policy header
- **Severity:** minor
- **Flow:** page load
- **Description:** On every page load, console shows: "Base Account SDK requires the Cross-Origin-Opener-Policy header to not be set to 'same-origin'." This comes from the wagmi/Base Account SDK integration and may prevent Base Smart Wallet from functioning.
- **Expected:** Configure the COOP header correctly on Netlify via `_headers` file, or suppress if Base Smart Wallet is not the primary connector.

## Issue 6: Console 404 for game/0.txt RSC prefetch
- **Severity:** cosmetic
- **Flow:** lobby → game navigation
- **Description:** Console shows 404 error for `https://shadowchain.netlify.app/game/0.txt?_rsc=1yx0n`. This is a Next.js React Server Component prefetch hitting a non-existent route, likely caused by Game #0 being listed in the lobby.
- **Expected:** RSC prefetch should not generate 404s.

## Issue 7: Join Game / Join Arena buttons timeout on Playwright click
- **Severity:** minor
- **Flow:** join game
- **Description:** Both the sidebar "Join Game (0)" button and the main "Join Arena" button time out when clicked via Playwright's `locator.click()` (8s timeout). They ARE clickable via JavaScript `element.click()`. This suggests pointer-events issues, overlay elements, or CSS layout problems preventing Playwright's actionability checks.
- **Expected:** Buttons should be clickable via standard automation tools.
- **Workaround:** Use `page.evaluate()` to click via JS.

## Issue 8: Deprecated WASM initialization parameters
- **Severity:** cosmetic
- **Flow:** game page load
- **Description:** Console shows two warnings: "using deprecated parameters for the initialization function; pass a single object instead" from Noir/Barretenberg WASM initialization on every page load.
- **Expected:** Update WASM initialization calls to use the new single-object API.

## Issue 9: Entry fee displayed without "ETH" unit on game page
- **Severity:** cosmetic
- **Flow:** game page display
- **Description:** On the game page waiting screen, entry fee shows "Entry fee: 0" without the "ETH" unit. The lobby correctly shows "Fee: 0 ETH".
- **Expected:** Show "Entry fee: 0 ETH" consistently.

## Issue 10: Adjacent cells clickable during WAITING state
- **Severity:** minor
- **Flow:** game page interaction
- **Description:** While the game is in "waiting" state, adjacent cells to the player's position show `cursor: pointer` and are interactive (not disabled). Other cells and fog-of-war cells are correctly disabled. This applies to cells where a valid move could be made.
- **Expected:** No cells should be interactable until the game state is "active" (LIVE).

## Issue 11: No confirmation dialog before Forfeit
- **Severity:** minor
- **Flow:** forfeit
- **Description:** Clicking "Forfeit" immediately submits the forfeit transaction without any confirmation dialog. This is a destructive, irreversible action that ends the game and makes the player lose.
- **Expected:** A confirmation dialog like "Are you sure you want to forfeit? You will lose and the opponent wins." should appear before submitting the transaction.

## Issue 12: Cells still clickable after game ends
- **Severity:** minor
- **Flow:** game ended state
- **Description:** After the game ended (via forfeit), some empty cells adjacent to the player's last position still show `cursor: pointer` and appear interactive (not disabled), even though the game state is "ended". Examples: empty (9,4), empty (10,5), empty (9,6).
- **Expected:** All cells should be disabled/non-interactive when the game state is "ended".

## Issue 13: Shared browser wallet state conflicts between players
- **Severity:** minor (test infrastructure issue)
- **Flow:** multi-player testing
- **Description:** When two players use the same browser profile (same localStorage/wagmi state), the dev wallet connection of Player 2 overwrites Player 1's connection across all tabs. The header, position, and "You" label switch to the last-connected wallet. This is expected behavior for shared browser state, but creates issues for testing.
- **Expected:** This is more of a test infrastructure issue than a game bug. However, the game could use per-tab session isolation for dev wallet to support multi-player testing in the same browser.

## Issue 14: Game doesn't auto-start when maxPlayers reached
- **Severity:** major
- **Flow:** game start
- **Description:** After both players joined (2/2), the game remained in WAITING state. A "Start Game" button appeared that required manual clicking. The game should auto-start when the maxPlayers count is reached, especially for a 2-player game.
- **Expected:** Game should automatically transition from WAITING to LIVE when the configured maxPlayers count is reached, or at minimum, the button should be labeled "Start Game (2/2 ready)" to make it clear all players are present.
- **Note:** This may be intentional to allow the creator to decide when to start, but it's unclear from the UI.

---

## Positive Observations ✅
- Landing page loads correctly with on-chain stats (all zeros for fresh testnet)
- Dev wallet popover UX is clean — private key input, address preview, clear warning labels
- Arena creation deploys successfully on Sepolia (~15s confirmation)
- Lobby correctly displays all games with status filters (all/waiting/active/ended)
- ZK proof generation works reliably via in-browser WASM:
  - `position_commit`: ~5 seconds, 16,256 bytes
  - `valid_move`: ~6 seconds, 16,256 bytes, 18 public inputs
- Game grid renders correctly with 16×16 fog-of-war, walls, player position
- Movement via directional buttons (↑←●→↓) works smoothly
- Combat log shows all events with timestamps and ZK proof verification
- Player stats (HP 100/100, ⚔ 10, 🛡 5, ★ 0) display correctly
- Turn advancement works via "Advance Turn ▶" button
- Forfeit transaction processes correctly, game resolves with winner declared
- Noir circuits load and execute properly (v1.0.0-beta.18)
- UltraHonk backend works as expected
- Full game lifecycle completed: create → join → play → forfeit → ended

---

## Test Summary

| Flow | Status | Notes |
|------|--------|-------|
| Landing page | ✅ Pass | Loads with stats |
| Lobby | ✅ Pass | Shows games, filters work |
| Dev wallet connect | ⚠️ Partial | Works per-page, loses state on navigation |
| Create arena | ⚠️ Partial | Creates but default maxPlayers unclear |
| Join game | ✅ Pass | ZK proof + tx works |
| Game grid | ✅ Pass | Fog of war, walls, position all correct |
| Movement | ✅ Pass | ZK proofs generated, positions update |
| Advance turn | ✅ Pass | Turn increments correctly |
| Forfeit | ⚠️ Partial | Works but no confirmation dialog |
| Game end | ✅ Pass | Winner resolved, state updates |

**Total issues found: 14** (2 major, 7 minor, 3 cosmetic, 2 context-dependent)
