# ShadowChain E2E Test Plan

## App URL
https://shadowchain.netlify.app

## Dev Wallets
- **Player 1 (P1):** `0xe50e4f3d55f41ce8c245f8b226da9cc76528e7559df40981b50c9a33ab052e32`
  - Address: `0x1387895435ac9777dA595e41650b7EFd6559f7f8`
- **Player 2 (P2):** `0x5f811339ae2b46129c59ccbacb109e0c5539022e33eda5365f2492116a6680bb`
  - Address: `0x8c871b46d08632e3775B6CCfAdB8Dd4E080409E9`

## Test Flows

### Flow 1: Landing Page
- [ ] Page loads at /
- [ ] Shows on-chain stats (games, players, etc.)
- [ ] Navigation links work (lobby, etc.)

### Flow 2: Lobby Page
- [ ] /lobby loads, shows game list from chain
- [ ] Filter tabs work (All, Waiting, Active, Ended)
- [ ] Create Arena button visible

### Flow 3: Dev Wallet Connect
- [ ] 🔧 button visible next to "Connect Wallet"
- [ ] Clicking opens popover with key input
- [ ] Pasting valid key shows address preview
- [ ] Pasting invalid key shows error
- [ ] Submit connects wallet, shows ⚠️ DEV badge
- [ ] Address displays correctly in header

### Flow 4: Create Game (P1)
- [ ] Click "Create Arena" in lobby
- [ ] Modal opens with fee + max players settings
- [ ] Set entry fee to 0 (free game for testing)
- [ ] Set max players to 2
- [ ] Click Deploy Arena
- [ ] Transaction submits and confirms
- [ ] Game appears in lobby as "WAITING"

### Flow 5: Join Game (P1)
- [ ] Navigate to /game/<id>
- [ ] Game page loads, shows "Waiting" phase
- [ ] Click "Join Game" button
- [ ] ZK position_commit proof generates in browser
- [ ] Transaction submits with commitment
- [ ] UI shows "You've joined this game"
- [ ] Map grid appears with player position

### Flow 6: Join Game (P2) → Auto-Start
- [ ] P2 connects different dev wallet
- [ ] P2 navigates to same game page
- [ ] P2 clicks "Join Game"
- [ ] ZK proof generates
- [ ] Transaction submits
- [ ] With maxPlayers=2, game auto-starts
- [ ] Game phase changes to "LIVE"

### Flow 7: Submit Move (P1)
- [ ] Movement controls visible (WASD pad + arrow keys)
- [ ] Click direction button or press WASD
- [ ] ZK valid_move proof generates
- [ ] Transaction submits with new commitment + proof
- [ ] Player position updates on grid
- [ ] Move event appears in Combat Log

### Flow 8: Advance Turn
- [ ] After turn timer expires (60s)
- [ ] "Advance Turn" button becomes effective
- [ ] Click advances to next turn
- [ ] Turn counter increments

### Flow 9: Claim Artifact
- [ ] Move player to a treasure cell (amber/gold cell on grid)
- [ ] "✦ Claim Artifact" button appears
- [ ] Click generates ZK claim_artifact proof
- [ ] Transaction claims the artifact
- [ ] Player stats update

### Flow 10: Forfeit
- [ ] Click "Forfeit" button
- [ ] Transaction submits
- [ ] Player status changes to Forfeited
- [ ] If only 1 player remains, game resolves
- [ ] Winner receives prize pool

### Flow 11: Game Resolution
- [ ] Game resolves after forfeit or max turns
- [ ] Winner displayed
- [ ] Prize pool paid out
- [ ] Game shows "ENDED" status

## Issues Found
(Agents will document issues here)
