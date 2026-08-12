# HANDOFF — macOS SMB reconnect fix (2026-08-12T2100Z, al8960ofc/codex)

## 0. ⚠️ DECISIONS ONLY THE OWNER CAN MAKE

### BLOCKING

- None. The next technical step is a real test on Liz Parkin's Mac. No design or access choice is needed first.

### RECOVERABLE

- If the test fails because `mount_smbfs -N` cannot reuse the password saved by Finder, choose whether employees should see one prompt at every login or whether POP should distribute a managed Mac configuration. Recommendation: first capture the test logs and make the script work with the existing Keychain login; do not distribute passwords in a script.

### NOT PART OF THIS WORK, AND NOBODY IS ON IT

- None found.

### Already settled — do NOT re-ask

- 2026-08-12: Network drives must use SMB over Tailscale to Synology at `100.107.131.35`; the script must not create repeated Finder/password popups.
- 2026-08-12: Do not delete employee or NAS files while repairing SMB setup.

Section-0 sweep: sections 1–9 contain one future choice about the Keychain fallback. It is listed above. No other owner decision is present.

## 1. What this application is

`u2giants/techsupport` is a small support repository for POP Creations internal computer setup files. It has no deployed application. The relevant folder is `setup home computer on SMB/`. Its setup text file is copied into an employee's macOS Terminal to connect desktop shortcuts called `POP Network Drives` to Synology SMB shares over the Tailscale private network.

GitHub repository: https://github.com/u2giants/techsupport. The current branch is `main`.

## 2. What we set out to do this session, and why

Employees reported relentless password and folder popups on their Macs. Fabi's screenshots showed aliases with red minus badges, meaning the desktop shortcuts led to shares that were not mounted. Liz reported a folder popup and a repeated password dialog for server `100.107.131.35`.

The goal was to change the setup script so it removes the old reconnect job, makes desktop shortcuts only after a share is mounted, checks reachability before trying SMB, and reconnects quietly without opening Finder every five minutes.

## 3. Current state — what is true right now

- The current setup file is `setup home computer on SMB/paste this into terminal.txt`, committed and pushed on `main` as `668c4b1ae47193d1f3cfb721ad91624d037afe60` (`Mount POP shares in user folder`).
- It removes two known old LaunchAgent jobs and scripts at lines 29–38. This work does not delete employee files or NAS files.
- It creates a new per-user LaunchAgent at lines 97–124. Its label is `com.popcreations.smb-reconnect`. It starts at login and repeats every 300 seconds, lines 111–115.
- Its reconnect program now tests TCP port 445 first (lines 54–57) and uses `/sbin/mount_smbfs -N`, lines 59–80. `-N` is intended to avoid a password dialog by using a password already saved in macOS Keychain.
- The latest repair moves mount folders away from the protected `/Volumes` folder to `~/Library/Scripts/POP-SMB/mounts`, lines 49 and 82–91. This directly addresses Liz's screenshot, which showed `mkdir: /Volumes/POP-...: Permission denied` and `mount_smbfs: could not find mount point` for every share.
- The script asks Finder for a password once during setup at lines 127–130. The employee must check “Remember this password in my keychain.” It then runs the quiet reconnect program and opens the shortcut folder at lines 133–157.
- The implementation has not been proven on a Mac after commit `668c4b1`. Liz must restart to clear frozen old SMB drives, then run this newest script.
- Local checkout has an untracked `.codex-remote-attachments/` directory containing user screenshots. It must not be committed.

## 4. Everything we tried that did NOT work

1. The original script called `open -g "smb://..."` for every unmounted share every five minutes, then waited five seconds, and opened the `POP Network Drives` Finder folder every run. It seemed like a simple reconnect method, but Finder displayed password dialogs whenever Tailscale/the NAS was unavailable or Keychain credentials were not usable. It also made aliases even when the target mount did not exist, creating broken shortcut badges.
2. The first changed version tried to unmount old shares such as `/Volumes/files` during cleanup. On Liz's Mac that command froze waiting on a stale network drive. The setup appeared stuck in Terminal. This was removed in commit `2ce133a`; restart is now the safe way to clear frozen old shares.
3. The next version used new folders such as `/Volumes/POP-files` as SMB mount points. Liz's screenshot proved macOS denied `mkdir` permission under `/Volumes`, so `mount_smbfs` failed for all shares. Commit `668c4b1` changed the mount point to the employee's own Library folder.
4. Earlier pasted scripts were run directly under macOS `zsh`, causing harmless but confusing `zsh: command not found: #` messages for comment lines. The current text wraps itself in `bash <<'POP_SMB_SETUP'` at lines 1 and 158, so pasting the entire file should run as Bash.

## 5. Root causes and key findings

- The repeated dialog was caused by Finder-based reconnects, not an employee clicking a shortcut. The old reconnection job ran automatically every five minutes and repeatedly used Finder's `open` command.
- A red minus badge on a macOS alias means the target is unavailable. It is a symptom of an unmounted share, not missing NAS data.
- A frozen SMB drive can block `umount`. A Mac restart clears it without deleting local or NAS data.
- `/Volumes` is not a reliable place for this user-level script to create custom mount folders on modern macOS. Liz's actual Terminal output showed permission denied. Use a user-owned folder instead.
- The private SMB server address is `100.107.131.35`; TCP port 445 is checked before a mount attempt. This avoids a mount attempt when Tailscale or the NAS is offline.
- The shortcuts are symlinks created only after a successful mount at lines 78–79. `POP-SharedLic` is created only if the `files` share mounted, lines 89–92.

## 6. Exact next steps

1. On Liz Parkin's Mac, restart macOS. This clears any frozen old SMB mounts. You will know it worked when the Mac restarts normally and no old mount is blocking Terminal.
2. Download the raw current `paste this into terminal.txt` from the repository, not a previously saved copy. Change only line 5 to `SMB_LOGIN='iml\lparkin'`. You will know it is the current file when its first line is `bash <<'POP_SMB_SETUP'` and it contains `MOUNT_ROOT`.
3. Paste the whole file into Terminal. When the single Finder password window appears, enter Liz's SMB password and leave “Remember this password in my keychain” checked, then click Connect. When Finder opens the `users` share, return to Terminal and press Enter. You will know setup finished when Terminal prints `Done.` and returns to a prompt.
4. Confirm the Desktop `POP Network Drives` folder has working aliases by opening `POP-users`, `POP-shared`, and one other allowed share. You will know it worked when each opens real NAS contents with no red minus badge.
5. Wait at least six minutes without opening any shortcut. You will know repeated password popups are fixed when no Finder password dialog appears despite the five-minute reconnect interval.
6. If any share fails, do not run old scripts and do not use `umount` on a frozen share. Copy these files from the Mac into the next support report: `~/Library/Logs/pop-smb-reconnect.log` and `~/Library/Logs/pop-smb-reconnect-error.log`, plus the exact Terminal output. You will know evidence was captured when the report identifies the affected share and whether the port-445 check or `mount_smbfs` failed.
7. If no popup appears but no share mounts, check whether Tailscale is connected on that Mac and whether `nc -z -w 3 100.107.131.35 445` returns success. You will know the network path works when the command exits with no error.

## 7. Constraints and gotchas in force

- Work only on `main` for this `u2giants` repository.
- Never put an SMB password in the script, Git history, log, handoff, or chat. Passwords belong in the employee's macOS Keychain and, if necessary, in the `vibe_coding` 1Password vault only.
- Do not delete employee files or NAS content. Script cleanup may remove only the old local POP scripts and user LaunchAgent files listed in section 3.
- Do not run `umount` against a frozen old SMB drive during setup. Restart the Mac instead.
- Do not commit `.codex-remote-attachments/`; it holds photos supplied during this chat.
- The script currently has a sample `SMB_LOGIN` at line 5. The technician must replace that value for each employee before pasting it.

## 8. Access and environment

- Local repository: `C:\repos\techsupport` on machine `al8960ofc` (Windows 11).
- Remote: `origin` is `https://github.com/u2giants/techsupport.git`; authenticated `git` and `gh` were available in this session.
- Git author was verified as `Albert Hazan <u2giants@users.noreply.github.com>`.
- Employee Mac environment: macOS Terminal, Bash and zsh available; Tailscale must be connected; SMB endpoint is `100.107.131.35` on TCP 445.
- No credentials were read, created, or stored during this work. The password source is each employee's existing SMB/network password, saved into the local macOS Keychain during the one-time Finder prompt.

## 9. Open questions and risks

- The latest script is not yet validated on Liz's Mac. The changes are based on actual failure output, but a live test is required before this can be considered resolved.
- It is unproven whether a Finder-saved SMB password matches exactly what `mount_smbfs -N` looks up for the domain-qualified URL. The six-minute no-popup test and logs will settle this.
- Existing frozen drives should be cleared with a restart before retesting. They may leave old aliases visible until the script replaces them; this is harmless if the new aliases work.
- Employees may have different share permissions. A failed single share after Tailscale is confirmed could be a NAS permission issue rather than a script issue.

## Self-audit

1. Could a street-newcomer continue without questions? **Yes.** Sections 1–3 identify the repo, file, goal, current commit, and unverified state; section 6 has exact employee test steps and evidence to collect.
2. Could they continue as effectively as this session? **Yes.** Sections 4–5 preserve every failed approach, actual Liz output, root causes, and why each code change exists.
3. Are failures included? **Yes.** Section 4 records the Finder popup loop, frozen `umount`, protected `/Volumes` error, and zsh comment errors.
4. Are next steps concrete and verifiable? **Yes.** Each numbered step in section 6 ends with a clear success signal.
5. Are paths, commits, server details, and terms explained? **Yes.** Sections 1, 3, 5, 6, and 8 define them and give exact locations.
6. Did the section-0 sweep capture every owner decision? **Yes.** Section 0 includes the only conditional future choice found in section 9, with a recommendation. No other section asks for owner judgment.

Final synthesis:

1. Is this handoff comprehensive enough for a brand-new developer to continue without skipping a beat? **Yes.** Sections 1–9 and the audit above provide application context, history, current state, instructions, evidence, and constraints.
2. Is it detailed enough to continue as well as this session? **Yes.** The actual screenshots' diagnostic outputs and all changes through `668c4b1` are preserved in sections 3–5.
3. Is every relevant detail needed for flawless execution present? **Yes.** The remaining live-Mac verification is explicitly scoped in section 6, including its pass/fail evidence and follow-up logs.
4. If Albert read only section 0, would he see every decision needed from him? **Yes.** The only contingent decision, a Keychain fallback after testing, is in section 0. Sections 1–8 require no decision; section 9's risk is duplicated in section 0.
