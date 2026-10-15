# Buzz (Nostr relay) channel UUIDs, by name - so agent configs reference
# a channel by name instead of repeating an opaque UUID at every call site.
# Channel UUIDs themselves come from Buzz's own channel admin, not from
# Nix - this is just a name -> id lookup table.
#
# Don't import this file by relative path from a deeply-nested consumer
# (e.g. a per-agent Home Manager module several directories under
# modules/hosts/) - every lib/mk*.nix builder already passes it through as
# the plain `buzzChannels` module arg (see lib/mkNixosHost.nix et al.), the
# same mechanism `genebeanLib` uses. Reach for `{ buzzChannels, ... }:`
# first; only fall back to a relative import for code that for some reason
# isn't one of this repo's own module-system modules.
{
  news-editors = "4c1462b1-fc3b-4567-9b43-5f5e75e11635";
  oval-office = "8a05dee5-ad45-4492-a68c-d5497be47a1f";
  press-room = "a100215b-9a61-4e58-b8bf-47542cd20b78";
  senior-staff = "3abc3d5f-9460-41d8-a26a-e9b50abf7da2";
  the-paper = "381f80a4-7398-47a5-ac60-78401a73e1a8";
  tradecraft = "36536f8b-0d3e-44fb-af89-32af588b901b";
}
