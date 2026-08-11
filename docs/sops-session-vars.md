# sops secrets missing from the shell (stale `__HM_SESS_VARS_SOURCED`)

`home.sessionVariables` points `OPENROUTER_API_KEY` at the decrypted sops
file (`home.nix:333`):

```nix
home.sessionVariables = {
  OPENROUTER_API_KEY = "$(cat ${config.sops.secrets.OPENROUTER_API_KEY.path})";
};
```

This lands in `~/.zshenv` → `/etc/profiles/per-user/bhavnick/etc/profile.d/hm-session-vars.sh`:

```sh
# Only source this once.
if [ -n "$__HM_SESS_VARS_SOURCED" ]; then return; fi
export __HM_SESS_VARS_SOURCED=1
...
export OPENROUTER_API_KEY="$(cat /home/bhavnick/.config/sops-nix/secrets/OPENROUTER_API_KEY)"
```

## Symptom

Fresh shell, no key:

```sh
echo $OPENROUTER_API_KEY   # empty
echo $__HM_SESS_VARS_SOURCED   # 1
```

...even though `cat ~/.config/sops-nix/secrets/OPENROUTER_API_KEY` works and
`sops-nix.service` reports success.

## Root cause

`hm-session-vars.sh` is a **one-time snapshot**, not a per-shell export:

1. Some login/session shell sourced it *before* the sops-nix user service had
   decrypted the secret (or before the age key existed), so it set
   `__HM_SESS_VARS_SOURCED=1` with an empty value.
2. The flag is exported, so it propagates to every descendant.
3. Every later `exec zsh` / new terminal inherits the flag, hits the `return`,
   and never re-evaluates the key — even after the secret file appears.

The build-time path exists regardless (it's a fixed path), so nothing fails;
the empty value just silently sticks around for the life of the session.

## Fix (immediate)

```sh
unset __HM_SESS_VARS_SOURCED
exec zsh
```

## Fix (permanent)

Skip the snapshot mechanism entirely and source the secret directly from the
zsh config, where it is re-evaluated on every shell start:

```nix
programs.zsh.initExtra = ''
  export OPENROUTER_API_KEY="$(cat ${config.sops.secrets.OPENROUTER_API_KEY.path})"
'';
```

Then delete the `home.sessionVariables.OPENROUTER_API_KEY` line. This is
immune to the stale-flag problem (no guard, evaluated fresh per shell), at the
cost of living in `initExtra` rather than the declarative
`home.sessionVariables`.

## Notes

- The value only ever gets captured when a *new* shell starts. Branches,
  daemons, and editors opened earlier keep their old (possibly empty) copy.
- On reboot the race can recur if the login shell sources `hm-session-vars.sh`
  before the sops-nix user service finishes decrypting — one more reason to use
  the `initExtra` form.