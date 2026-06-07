function firstExisting(candidates) {
    for (var i = 0; i < candidates.length; i++) {
        if (applicationExists(candidates[i])) {
            return "applications:" + candidates[i]
        }
    }
    return ""
}

var launchers = [
    firstExisting(["com.mitchellh.ghostty.desktop", "ghostty.desktop"]),
    firstExisting(["opera-gx.desktop", "com.opera.Opera.desktop", "opera.desktop"]),
    firstExisting(["discord.desktop", "com.discordapp.Discord.desktop", "vesktop.desktop"]),
    firstExisting(["org.kde.dolphin.desktop"]),
    firstExisting(["systemsettings.desktop", "org.kde.systemsettings.desktop"]),
    firstExisting(["code-oss.desktop", "code.desktop", "visual-studio-code.desktop"])
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
