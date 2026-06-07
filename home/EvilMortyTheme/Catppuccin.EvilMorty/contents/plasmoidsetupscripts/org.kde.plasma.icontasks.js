function firstExisting(candidates) {
    for (var i = 0; i < candidates.length; i++) {
        if (applicationExists(candidates[i])) {
            return "applications:" + candidates[i]
        }
    }
    return ""
}

var launchers = [
    firstExisting(["org.kde.konsole.desktop"]),
    firstExisting(["org.kde.dolphin.desktop"]),
    firstExisting([
        "firefox.desktop",
        "firefox_firefox.desktop",
        "org.mozilla.firefox.desktop",
        "opera-gx.desktop",
        "com.opera.Opera.desktop",
        "opera.desktop",
        "com.google.Chrome.desktop",
        "chrome.desktop"
    ]),
    firstExisting(["spotify.desktop", "com.spotify.Client.desktop"]),
    firstExisting(["discord.desktop", "com.discordapp.Discord.desktop", "vesktop.desktop"]),
    firstExisting(["steam.desktop", "com.valvesoftware.Steam.desktop"]),
    firstExisting(["systemsettings.desktop", "org.kde.systemsettings.desktop"])
].filter(function(launcher) {
    return launcher !== ""
})

applet.currentConfigGroup = []
applet.writeConfig("launchers", "")
applet.currentConfigGroup = ["General"]
applet.writeConfig("indicateAudioStreams", "false")
applet.writeConfig("iconSpacing", "4")
applet.writeConfig("launchers", launchers.join(","))
applet.writeConfig("maxStripes", "1")
