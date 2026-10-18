## genebean\.kiosk-hardware\.enable

Whether to enable shared NixOS-level config for small headless kiosk boxes\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/kiosk-hardware\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/kiosk-hardware.nix)



## genebean\.kiosk-hardware\.wirelessInterface



Wireless interface name (e\.g\. wlan0, wlp3s0)\. Feeds networking\.wireless\.interfaces directly\. genebean\.services\.chromium-kiosk has its own wirelessInterface option for its wpa_supplicant dependency - set that to config\.genebean\.kiosk-hardware\.wirelessInterface at the call site rather than duplicating the value\.



*Type:*
string

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/kiosk-hardware\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/kiosk-hardware.nix)



## genebean\.plasma\.enable



Whether to enable KDE Plasma desktop\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/plasma\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/plasma.nix)



## genebean\.programs\.angry-ip-scanner\.enable



Whether to enable Angry IP Scanner network scanner\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/angry-ip-scanner\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/angry-ip-scanner.nix)



## genebean\.programs\.askpass\.enable



Whether to enable SSH askpass helper\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/askpass\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/askpass.nix)



## genebean\.programs\.atuin-client\.enable



Whether to enable Atuin shell history client\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/atuin-client\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/atuin-client.nix)



## genebean\.programs\.audacity\.enable



Whether to enable Audacity audio editor\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/audacity\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/audacity.nix)



## genebean\.programs\.bat\.enable



Whether to enable bat, a cat clone with syntax highlighting\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/bat\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/bat.nix)



## genebean\.programs\.boinc\.enable



Whether to enable BOINC distributed computing client\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/boinc\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/boinc.nix)



## genebean\.programs\.caffeine\.enable



Whether to enable screen/sleep inhibitor\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/caffeine\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/caffeine.nix)



## genebean\.programs\.claude-code\.enable



Whether to enable Claude Code AI coding assistant\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/claude-code\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/claude-code.nix)



## genebean\.programs\.diff\.enable



Whether to enable diff tools (colordiff, diff-so-fancy)\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/diff\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/diff.nix)



## genebean\.programs\.discord\.enable



Whether to enable Discord\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/discord\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/discord.nix)



## genebean\.programs\.element\.enable



Whether to enable Element Matrix client\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/element\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/element.nix)



## genebean\.programs\.element\.linuxInstallMethod



This option has no description\.



*Type:*
one of “flatpak”, “nixpkgs”, “none”



*Default:*

```nix
"flatpak"
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/element\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/element.nix)



## genebean\.programs\.filezilla\.enable



Whether to enable FileZilla FTP client\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/filezilla\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/filezilla.nix)



## genebean\.programs\.firefox\.enable



Whether to enable Firefox browser\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/firefox\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/firefox.nix)



## genebean\.programs\.fractal\.enable



Whether to enable Fractal Matrix client\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/fractal\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/fractal.nix)



## genebean\.programs\.ghostty\.enable



Whether to enable Ghostty terminal\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/ghostty\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/ghostty.nix)



## genebean\.programs\.ghostty\.enableSystemd



This option has no description\.



*Type:*
boolean



*Default:*

```nix
false
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/ghostty\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/ghostty.nix)



## genebean\.programs\.ghostty\.installViaHomebrew



This option has no description\.



*Type:*
boolean



*Default:*

```nix
false
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/ghostty\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/ghostty.nix)



## genebean\.programs\.ghostty\.installViaNix



This option has no description\.



*Type:*
boolean



*Default:*

```nix
false
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/ghostty\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/ghostty.nix)



## genebean\.programs\.git\.enable



Whether to enable Git version control\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/git\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/git.nix)



## genebean\.programs\.gitkraken\.enable



Whether to enable GitKraken Git client\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/gitkraken\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/gitkraken.nix)



## genebean\.programs\.gitkraken\.linuxInstallMethod



This option has no description\.



*Type:*
one of “nixpkgs”, “none”



*Default:*

```nix
"nixpkgs"
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/gitkraken\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/gitkraken.nix)



## genebean\.programs\.handbrake\.enable



Whether to enable HandBrake video transcoder\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/handbrake\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/handbrake.nix)



## genebean\.programs\.hexchat\.enable



Whether to enable HexChat IRC client\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/hexchat\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/hexchat.nix)



## genebean\.programs\.home-assistant-companion\.enable



Whether to enable Home Assistant companion app\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/home-assistant-companion\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/home-assistant-companion.nix)



## genebean\.programs\.kopiaui\.enable



Whether to enable KopiaUI backup browser\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/kopiaui\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/kopiaui.nix)



## genebean\.programs\.kopiaui\.linuxInstallMethod



This option has no description\.



*Type:*
one of “flatpak”, “nixpkgs”, “none”



*Default:*

```nix
"flatpak"
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/kopiaui\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/kopiaui.nix)



## genebean\.programs\.libreoffice\.enable



Whether to enable LibreOffice suite\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/libreoffice\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/libreoffice.nix)



## genebean\.programs\.libreoffice\.linuxInstallMethod



This option has no description\.



*Type:*
one of “flatpak”, “nixpkgs”, “none”



*Default:*

```nix
"flatpak"
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/libreoffice\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/libreoffice.nix)



## genebean\.programs\.localsend\.enable



Whether to enable LocalSend file sharing\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/localsend\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/localsend.nix)



## genebean\.programs\.localsend\.linuxInstallMethod



This option has no description\.



*Type:*
one of “flatpak”, “nixpkgs”, “none”



*Default:*

```nix
"flatpak"
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/localsend\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/localsend.nix)



## genebean\.programs\.logseq\.enable



Whether to enable Logseq knowledge base\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/logseq\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/logseq.nix)



## genebean\.programs\.logseq\.linuxInstallMethod



This option has no description\.



*Type:*
one of “flatpak”, “nixpkgs”, “none”



*Default:*

```nix
"flatpak"
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/logseq\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/logseq.nix)



## genebean\.programs\.mcp-nixos\.enable



Whether to enable mcp-nixos MCP server for NixOS/Home Manager/nix-darwin\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/mcp-nixos\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/mcp-nixos.nix)



## genebean\.programs\.meld\.enable



Whether to enable Meld diff viewer\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/meld\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/meld.nix)



## genebean\.programs\.meld\.linuxInstallMethod



This option has no description\.



*Type:*
one of “nixpkgs”, “none”



*Default:*

```nix
"nixpkgs"
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/meld\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/meld.nix)



## genebean\.programs\.mkvtoolnix\.enable



Whether to enable MKVToolNix Matroska tools\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/mkvtoolnix\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/mkvtoolnix.nix)



## genebean\.programs\.mqtt-explorer\.enable



Whether to enable MQTT Explorer\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/mqtt-explorer\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/mqtt-explorer.nix)



## genebean\.programs\.mumble\.enable



Whether to enable Mumble VoIP client\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/mumble\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/mumble.nix)



## genebean\.programs\.nextcloud-client\.enable



Whether to enable Nextcloud desktop client\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/nextcloud-client\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/nextcloud-client.nix)



## genebean\.programs\.nixdiff\.enable



Whether to enable nixdiff system diff tool\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/nixdiff\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/nixdiff.nix)



## genebean\.programs\.obs\.enable



Whether to enable OBS Studio\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/obs\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/obs.nix)



## genebean\.programs\.onepassword\.enable



Whether to enable 1Password password manager\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/onepassword\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/onepassword.nix)



## genebean\.programs\.onlyoffice\.enable



Whether to enable OnlyOffice document suite\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/onlyoffice\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/onlyoffice.nix)



## genebean\.programs\.onlyoffice\.linuxInstallMethod



This option has no description\.



*Type:*
one of “flatpak”, “none”



*Default:*

```nix
"flatpak"
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/onlyoffice\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/onlyoffice.nix)



## genebean\.programs\.pidgin\.enable



Whether to enable Pidgin IM client\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/pidgin\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/pidgin.nix)



## genebean\.programs\.powershell\.enable



Whether to enable PowerShell\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/powershell](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/powershell)



## genebean\.programs\.signal\.enable



Whether to enable Signal messenger\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/signal\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/signal.nix)



## genebean\.programs\.signal\.linuxInstallMethod



This option has no description\.



*Type:*
one of “flatpak”, “nixpkgs”, “none”



*Default:*

```nix
"flatpak"
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/signal\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/signal.nix)



## genebean\.programs\.slack\.enable



Whether to enable Slack messaging\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/slack\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/slack.nix)



## genebean\.programs\.sops\.enable



Whether to enable sops secrets tooling\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/sops\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/sops.nix)



## genebean\.programs\.tea\.enable



Whether to enable tea, the official Gitea/Forgejo CLI client\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/tea\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/tea.nix)



## genebean\.programs\.telegram\.enable



Whether to enable Telegram messenger\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/telegram\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/telegram.nix)



## genebean\.programs\.telegram\.linuxInstallMethod



This option has no description\.



*Type:*
one of “flatpak”, “nixpkgs”, “none”



*Default:*

```nix
"flatpak"
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/telegram\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/telegram.nix)



## genebean\.programs\.thunderbird\.enable



Whether to enable Thunderbird email client\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/thunderbird\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/thunderbird.nix)



## genebean\.programs\.tilix\.enable



Whether to enable Tilix terminal emulator\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/tilix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/tilix)



## genebean\.programs\.tmux\.enable



Whether to enable tmux terminal multiplexer\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/tmux\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/tmux.nix)



## genebean\.programs\.transmission\.enable



Whether to enable Transmission BitTorrent client\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/transmission\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/transmission.nix)



## genebean\.programs\.ungoogled-chromium\.enable



Whether to enable Ungoogled Chromium browser\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/ungoogled-chromium\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/ungoogled-chromium.nix)



## genebean\.programs\.ungoogled-chromium\.linuxInstallMethod



This option has no description\.



*Type:*
one of “flatpak”, “nixpkgs”, “none”



*Default:*

```nix
"flatpak"
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/ungoogled-chromium\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/ungoogled-chromium.nix)



## genebean\.programs\.vim\.enable



Whether to enable Vim text editor\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/vim\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/vim.nix)



## genebean\.programs\.vivaldi\.enable



Whether to enable Vivaldi browser\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/vivaldi\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/vivaldi.nix)



## genebean\.programs\.vivaldi\.linuxInstallMethod



This option has no description\.



*Type:*
one of “flatpak”, “nixpkgs”, “none”



*Default:*

```nix
"flatpak"
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/vivaldi\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/vivaldi.nix)



## genebean\.programs\.vlc\.enable



Whether to enable VLC media player with Blu-ray decoding support\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/vlc\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/vlc.nix)



## genebean\.programs\.vscode\.enable



Whether to enable Visual Studio Code\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/vscode\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/vscode.nix)



## genebean\.programs\.waybar\.enable



Whether to enable Waybar status bar\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/waybar](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/waybar)



## genebean\.programs\.wezterm\.enable



Whether to enable WezTerm terminal\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/wezterm](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/wezterm)



## genebean\.programs\.wezterm\.installViaHomebrew



This option has no description\.



*Type:*
boolean



*Default:*

```nix
false
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/wezterm](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/wezterm)



## genebean\.programs\.wezterm\.installViaNix



This option has no description\.



*Type:*
boolean



*Default:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/wezterm](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/wezterm)



## genebean\.programs\.xfce4-terminal\.enable



Whether to enable xfce4-terminal\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/xfce4-terminal](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/xfce4-terminal)



## genebean\.programs\.zoom\.enable



Whether to enable Zoom video conferencing\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/zoom\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/zoom.nix)



## genebean\.programs\.zoom\.linuxInstallMethod



This option has no description\.



*Type:*
one of “nixpkgs”, “none”



*Default:*

```nix
"nixpkgs"
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/zoom\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/programs/zoom.nix)



## genebean\.services\.chromium-kiosk\.enable



Whether to enable chromium kiosk pointed at a Home Assistant dashboard\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/chromium-kiosk\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/chromium-kiosk.nix)



## genebean\.services\.chromium-kiosk\.dashboardUrl



URL chromium opens in --app/–kiosk mode\.



*Type:*
string



*Example:*

```nix
"http://192.168.22.22:8123/kiosk-entryway/immich?kiosk"
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/chromium-kiosk\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/chromium-kiosk.nix)



## genebean\.services\.chromium-kiosk\.extraCommandLineArgs



Extra chromium flags appended after the common kiosk set\.



*Type:*
list of string



*Default:*

```nix
[ ]
```



*Example:*

```nix
[
  "--hide-scrollbars"
]
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/chromium-kiosk\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/chromium-kiosk.nix)



## genebean\.services\.chromium-kiosk\.rotate



wlr-randr --transform value (e\.g\. “90”, “flipped-90”)\. null = no --transform flag\.



*Type:*
null or string



*Default:*

```nix
null
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/chromium-kiosk\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/chromium-kiosk.nix)



## genebean\.services\.chromium-kiosk\.wirelessInterface



Wireless interface name (e\.g\. wlan0, wlp3s0) - the NixOS side depends on wpa_supplicant-\<interface>\.service before starting the kiosk\. Normally set to config\.genebean\.kiosk-hardware\.wirelessInterface at the call site rather than duplicated\.



*Type:*
string



*Example:*

```nix
"wlan0"
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/chromium-kiosk\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/chromium-kiosk.nix)



## genebean\.services\.chromium-kiosk\.wlrRandrOutput



wlr-randr output name cage’s compositor targets\.



*Type:*
string



*Default:*

```nix
"HDMI-A-1"
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/chromium-kiosk\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/chromium-kiosk.nix)



## genebean\.services\.flatpak\.enable



Whether to enable Flatpak package manager\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/flatpak\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/flatpak.nix)



## genebean\.services\.hermesAgents



Hermes agent containers (systemd-nspawn, one per agent, running
services\.hermes-agent in native mode as that container’s only
profile)\. Each attribute name is the agent’s own name - matches
the container name and, by extension, container@\<name>\.service\.
Declared here (not in nixos/) per this repo’s own convention - see
modules/genebean/README\.md - even though the actual effect is
entirely NixOS-side; the nixos/ companion does all the real work\.



*Type:*
attribute set of (submodule)



*Default:*

```nix
{ }
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents.nix)



## genebean\.services\.hermesAgents\.\<name>\.enableGit



Add pkgs\.git to this agent’s extraPackages\.



*Type:*
boolean



*Default:*

```nix
false
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents.nix)



## genebean\.services\.hermesAgents\.\<name>\.agentsFile



AGENTS\.md for this agent\.



*Type:*
absolute path

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents.nix)



## genebean\.services\.hermesAgents\.\<name>\.environment



Non-secret environment variables, merged over the shared defaults\.



*Type:*
attribute set of string



*Default:*

```nix
{ }
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents.nix)



## genebean\.services\.hermesAgents\.\<name>\.extraContainerModules



Extra NixOS modules merged into this agent’s own
containers\.\<name>\.config\.imports - for agent-specific
functionality (a companion systemd timer/service, extra
networking\.hosts entries, etc\.) that isn’t itself a
first-class hermesAgents option\. Promote a pattern into a
real option here once a second agent needs the same thing,
not before\.



*Type:*
list of raw value



*Default:*

```nix
[ ]
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents.nix)



## genebean\.services\.hermesAgents\.\<name>\.extraHermesHomeFiles



One-off HERMES_HOME files that don’t fit managedSkills (a
private data file, a template, etc\.) - “\<relpath>” -> source
path, merged alongside SOUL\.md and every managedSkills entry\.



*Type:*
attribute set of absolute path



*Default:*

```nix
{ }
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents.nix)



## genebean\.services\.hermesAgents\.\<name>\.extraPackages



Extra packages on this agent’s PATH\.



*Type:*
list of package



*Default:*

```nix
[ ]
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents.nix)



## genebean\.services\.hermesAgents\.\<name>\.extraReadOnlyPaths



Container-internal paths hermes-agent\.service may read beyond /var/lib/hermes\.



*Type:*
list of string



*Default:*

```nix
[ ]
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents.nix)



## genebean\.services\.hermesAgents\.\<name>\.forgejoLogin



When set, generates an idempotent (delete-then-add) tea-login-
setup service - registers a persistent ` tea ` login from the
named secret before hermes-agent starts\. Idempotent from the
start: always delete-then-add, never gated on the config file
already existing (that shape has a known bug -
hermes-agent-fleet-plan\#51 - a credential rotation silently
has no effect once the file exists once)\.



*Type:*
null or (submodule)



*Default:*

```nix
null
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents.nix)



## genebean\.services\.hermesAgents\.\<name>\.forgejoLogin\.tokenSecretName



Name of an entry in this agent’s own ` secrets ` option holding
the Forgejo token\. Expected content: either a bare token, or a
FORGEJO_TOKEN=\<value> line (both are tolerated, matching every
existing agent’s secret today)\.



*Type:*
string

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents.nix)



## genebean\.services\.hermesAgents\.\<name>\.forgejoLogin\.url



Forgejo instance URL to log in against\.



*Type:*
string



*Default:*

```nix
"https://git.home.technicalissues.us"
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents.nix)



## genebean\.services\.hermesAgents\.\<name>\.githubApps



GitHub Apps this agent mints short-lived installation tokens
from\. Each entry gets its own self-rescheduling root-run
minting service + OnCalendar backstop timer, writing only the
derived, already-scoped, hour-lived token to a container-local
tmpfs path readable by ` hermes ` - the agent’s own process
never touches the App’s private key\. Self-reschedule uses
` systemctl restart ` (not ` start ` - a no-op on an already-
active Type=oneshot+RemainAfterExit=true unit) with a PID-
suffixed transient unit name (avoids a same-named collision
being silently swallowed) - both confirmed-necessary live,
dots issues 797/798\.



*Type:*
attribute set of (submodule)



*Default:*

```nix
{ }
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents.nix)



## genebean\.services\.hermesAgents\.\<name>\.githubApps\.\<name>\.appId



GitHub App ID (not secret - same tier as a channel ID)\.



*Type:*
string

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents.nix)



## genebean\.services\.hermesAgents\.\<name>\.githubApps\.\<name>\.gitCredentialHelper



Whether raw ` git ` operations against github\.com HTTPS remotes
should use this entry’s token via a global credential helper\.
At most one githubApps entry per agent should set this true\.



*Type:*
boolean



*Default:*

```nix
false
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents.nix)



## genebean\.services\.hermesAgents\.\<name>\.githubApps\.\<name>\.keySecretName



Name of an entry in this agent’s own ` secrets ` option holding
the App’s private key (PEM)\. Never read by the agent’s own
process - only by this entry’s own root-run minting service\.



*Type:*
string

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents.nix)



## genebean\.services\.hermesAgents\.\<name>\.githubApps\.\<name>\.refreshIntervalSeconds



Self-reschedule interval for minting a fresh installation token\.



*Type:*
signed integer



*Default:*

```nix
2700
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents.nix)



## genebean\.services\.hermesAgents\.\<name>\.githubApps\.\<name>\.wrapperName



Name of the generated wrapper command (pkgs\.writeShellScriptBin)
that sets GH_TOKEN from this entry’s freshly-minted installation
token and execs ` gh `\. Example: “sam-gh”\.



*Type:*
string

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents.nix)



## genebean\.services\.hermesAgents\.\<name>\.hermesSettings



Merged over the shared services\.hermes-agent\.settings defaults\.



*Type:*
attribute set of anything



*Default:*

```nix
{ }
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents.nix)



## genebean\.services\.hermesAgents\.\<name>\.managedSkills

Declarative skill materialization\. Each attribute name becomes
the skill’s directory under HERMES_HOME (skills/\<name>/…),
recursively listed from its own ` source ` - a file added to the
skill later is picked up automatically, no Nix change needed\.



*Type:*
attribute set of (submodule)



*Default:*

```nix
{ }
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents.nix)



## genebean\.services\.hermesAgents\.\<name>\.managedSkills\.\<name>\.installMode



“seed-once” (default): installed only if the live path doesn’t
already exist, so the agent can edit its own copy durably
across deploys\. A root-owned, read-only reference copy is also
materialized at /etc/hermes-skills/\<name>/ inside the
container, and the weekly rules-file-reconciliation skill
(agents-beads-collaboration-62h) diffs every seed-once skill
an agent has - one shared weekly session per agent, not one
per skill - against that reference and reports drift to
\#tradecraft\.

“overwrite”: materialized fresh from the Nix store on every
activation; any live edit the agent makes to its own copy is
lost on the next deploy that touches this container\. Default
until 2026-10-17, now the deliberate exception rather than the
default: hermes-agent’s own self-editing tools
(skill_manage et al\.) work on any file under
$HERMES_HOME/skills/ regardless of how it got there, so
“overwrite” doesn’t actually prevent an agent from editing a
skill - it just means that edit gets silently destroyed on
the next deploy with no record, instead of being preserved
and surfaced for review like seed-once does\. Reach for this
only when the reconciliation cost itself is the problem (a
skill whose official source changes often enough that weekly
drift review would be pure noise), not merely because a
skill “shouldn’t” need editing\.



*Type:*
one of “overwrite”, “seed-once”



*Default:*

```nix
"seed-once"
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents.nix)



## genebean\.services\.hermesAgents\.\<name>\.managedSkills\.\<name>\.source



Directory this skill’s files are recursively listed from\.



*Type:*
absolute path

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents.nix)



## genebean\.services\.hermesAgents\.\<name>\.mcpServers



Passed through verbatim to this agent’s own
services\.hermes-agent\.mcpServers inside its container - see
hermes-agent’s own option for the full per-server schema (url,
headers, tools\.include/exclude, etc)\. Not validated here -
attrsOf types\.anything, same passthrough treatment as
hermesSettings\.



*Type:*
attribute set of anything



*Default:*

```nix
{ }
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents.nix)



## genebean\.services\.hermesAgents\.\<name>\.reconciliationSchedule



Cron schedule (same syntax as ` hermes cron create `’s own
schedule argument) for this agent’s weekly skill-
reconciliation job - only registered at all if this agent has
at least one seed-once skill (managedSkills or sharedSkills)\.
Override per agent to stagger reconciliation across the
fleet deliberately, rather than letting every agent’s weekly
session land at the same moment and overlap\.

Only affects *newly* registered jobs: the registration
service is a one-time, skip-if-present setup (matches
daily-report-cron\.nix’s own idempotent pattern) - changing
this value does not update a schedule an agent already has
registered\. Delete the existing ` reconcile-skills ` cron job
on that agent directly (` hermes cron delete <id> `) and
redeploy to pick up a new schedule\.



*Type:*
string



*Default:*

```nix
"0 17 * * 4"
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents.nix)



## genebean\.services\.hermesAgents\.\<name>\.secrets



Secrets this agent needs\. Each one gets: a host-side
sops\.secrets\.\<name> declaration (restartUnits auto-set to this
agent’s container@\<name>\.service), a bind mount at
/run/secrets/\<name> inside the container, and - if
toEnvironmentFile is set - an entry in
services\.hermes-agent\.environmentFiles\.



*Type:*
attribute set of (submodule)



*Default:*

```nix
{ }
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents.nix)



## genebean\.services\.hermesAgents\.\<name>\.secrets\.\<name>\.envFileAs



For a secret whose raw value is a bare token (not already
KEY=value shaped) that still needs to land in the agent’s
environment under a specific variable name - e\.g\. shared as-is
with some other service’s own secret\. When set, a
sops\.templates entry is generated that wraps the raw value into
a single “\<envFileAs>=\<value>” line, and that template’s path
(not the raw secret) is bind-mounted into the container and
added to services\.hermes-agent\.environmentFiles\. Mutually
exclusive with toEnvironmentFile in practice (the raw secret
isn’t itself env-shaped), though nothing enforces that here\.



*Type:*
null or string



*Default:*

```nix
null
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents.nix)



## genebean\.services\.hermesAgents\.\<name>\.secrets\.\<name>\.sopsFile



sops file this secret lives in\.



*Type:*
absolute path



*Default:*

```nix
/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/shared/secrets.yaml
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents.nix)



## genebean\.services\.hermesAgents\.\<name>\.secrets\.\<name>\.toEnvironmentFile



Whether to add this secret’s bind-mounted path to
services\.hermes-agent\.environmentFiles (merged into the agent’s
own \.env)\. Secrets consumed some other way (e\.g\. by a
forgejoLogin or githubApps setup script, read directly from
/run/secrets/\<name>) should leave this false\.



*Type:*
boolean



*Default:*

```nix
false
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents.nix)



## genebean\.services\.hermesAgents\.\<name>\.sharedSkills



Fleet-wide skills this agent should have, by name - opt in
here rather than pointing ` managedSkills.<name>.source ` at
modules/genebean/nixos/services/hermes-skills/\<name>
yourself\. The whole point of the genebean/ namespace is that
a host-specific file (this one) never needs to know that
module’s internal directory layout; the NixOS companion
resolves each name to its own actual source path internally\.
Always seed-once (matches the default for managedSkills
itself) - these are meant to be self-correctable the same
way as anything else, not special-cased as unconditionally
overwritten official content\.



*Type:*
list of (one of “buzz-multipart-delivery”, “newspaper-access”, “scheduled-publication-workflows”)



*Default:*

```nix
[ ]
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents.nix)



## genebean\.services\.hermesAgents\.\<name>\.soulFile



SOUL\.md for this agent\.



*Type:*
absolute path

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents.nix)



## genebean\.services\.hermesAgents\.\<name>\.stateHostPath



Host path bind-mounted to the guest’s /var/lib/hermes\.



*Type:*
string



*Default:*

```nix
"/var/lib/hermes-containers/‹name›"
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents.nix)



## genebean\.services\.hermesAgents\.\<name>\.stateVersion



system\.stateVersion for this agent’s nested NixOS evaluation\.



*Type:*
string

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/hermes-agents.nix)



## genebean\.services\.kiosk-backups\.enable



Whether to enable restic-based disaster-recovery backups for kiosk state (chromium profile, atuin session, tailscale identity)\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/kiosk-backups\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/kiosk-backups.nix)



## genebean\.services\.kiosk-backups\.paths



Paths to back up daily and make available to kiosk-restic-full-restore\. Must NOT include a /persist prefix - the NixOS side (modules/genebean/nixos/services/kiosk-backups\.nix) adds that automatically when the host uses impermanence (environment\.persistence\.“/persist”\.enable)\. A path already starting with /persist is a configuration error - see that module’s assertions\.



*Type:*
list of string



*Default:*

```nix
[
  "/home/gene/.config/chromium"
  "/home/gene/.local/share/atuin"
  "/var/lib/tailscale"
]
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/kiosk-backups\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/kiosk-backups.nix)



## genebean\.services\.restic\.enable



Whether to enable shared restic backup infrastructure (backup + cheap per-host forget)\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/restic\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/restic.nix)



## genebean\.services\.restic\.enablePruneJob



Run the expensive, fleet-wide restic prune (data reclaim) job on this host\. Must be true on EXACTLY ONE host across the whole fleet - prune is a whole-repository operation (it has to know what data every host’s remaining snapshots still reference), so running it on more than one host wastes redundant work and running it on zero means space is never reclaimed\. Enforced by a pre-commit check (scripts/check-restic-prune-singleton\.sh)\.



*Type:*
boolean



*Default:*

```nix
false
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/restic\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/restic.nix)



## genebean\.services\.tailscale\.enable



Whether to enable Tailscale VPN\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/tailscale\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/tailscale.nix)



## genebean\.services\.tailscale\.advertiseExitNode



This option has no description\.



*Type:*
boolean



*Default:*

```nix
false
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/tailscale\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/tailscale.nix)



## genebean\.services\.tailscale\.advertiseRoutes



This option has no description\.



*Type:*
list of string



*Default:*

```nix
[ ]
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/tailscale\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/tailscale.nix)



## genebean\.services\.tailscale\.useRoutingFeatures



Routing features to enable (client for desktops, both for exit nodes/routers)



*Type:*
one of “none”, “client”, “server”, “both”



*Default:*

```nix
"client"
```

*Declared by:*
 - [/nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/tailscale\.nix](file:///nix/store/qd5z36m7chgv78qykky0drdrcbqgvw8a-source/modules/genebean/home/services/tailscale.nix)


