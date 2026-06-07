/*******EvilMorty Colors*********/
function writeKdeglobalsGroup(group, entries) {
    const config = ConfigFile("kdeglobals")
    config.group = group
    for (const key in entries) {
        config.writeEntry(key, entries[key])
    }
}

function applyEvilMortyColors() {
    writeKdeglobalsGroup("General", {
        AccentColor: "0,255,102",
        ColorScheme: "EvilMorty",
        Name: "EvilMorty",
        accentActiveTitlebar: "false",
        accentColorFromWallpaper: "false",
        shadeSortColumn: "true"
    })
    writeKdeglobalsGroup("Colors:Header", {
        BackgroundAlternate: "10,30,13",
        BackgroundNormal: "5,18,8",
        DecorationFocus: "121,220,76",
        DecorationHover: "143,238,86",
        ForegroundActive: "143,238,86",
        ForegroundInactive: "93,145,70",
        ForegroundLink: "121,220,76",
        ForegroundNegative: "255,80,96",
        ForegroundNeutral: "191,224,78",
        ForegroundNormal: "142,229,101",
        ForegroundPositive: "121,220,76",
        ForegroundVisited: "84,166,55"
    })
    writeKdeglobalsGroup("Colors:Button", {
        BackgroundAlternate: "16,43,18",
        BackgroundNormal: "10,30,13",
        DecorationFocus: "121,220,76",
        DecorationHover: "143,238,86",
        ForegroundActive: "143,238,86",
        ForegroundInactive: "93,145,70",
        ForegroundLink: "121,220,76",
        ForegroundNegative: "255,80,96",
        ForegroundNeutral: "191,224,78",
        ForegroundNormal: "142,229,101",
        ForegroundPositive: "121,220,76",
        ForegroundVisited: "84,166,55"
    })
    writeKdeglobalsGroup("Colors:Complementary", {
        BackgroundAlternate: "8,23,10",
        BackgroundNormal: "3,13,5",
        DecorationFocus: "121,220,76",
        DecorationHover: "143,238,86",
        ForegroundActive: "143,238,86",
        ForegroundInactive: "82,126,63",
        ForegroundLink: "121,220,76",
        ForegroundNegative: "255,80,96",
        ForegroundNeutral: "191,224,78",
        ForegroundNormal: "142,229,101",
        ForegroundPositive: "121,220,76",
        ForegroundVisited: "84,166,55"
    })
    writeKdeglobalsGroup("Colors:Selection", {
        BackgroundAlternate: "75,142,43",
        BackgroundNormal: "111,196,69",
        DecorationFocus: "143,238,86",
        DecorationHover: "143,238,86",
        ForegroundActive: "2,10,4",
        ForegroundInactive: "5,18,8",
        ForegroundLink: "2,10,4",
        ForegroundNegative: "255,80,96",
        ForegroundNeutral: "38,58,13",
        ForegroundNormal: "2,10,4",
        ForegroundPositive: "2,10,4",
        ForegroundVisited: "5,18,8"
    })
    writeKdeglobalsGroup("Colors:Tooltip", {
        BackgroundAlternate: "10,30,13",
        BackgroundNormal: "3,13,5",
        DecorationFocus: "121,220,76",
        DecorationHover: "143,238,86",
        ForegroundActive: "143,238,86",
        ForegroundInactive: "93,145,70",
        ForegroundLink: "121,220,76",
        ForegroundNegative: "255,80,96",
        ForegroundNeutral: "191,224,78",
        ForegroundNormal: "142,229,101",
        ForegroundPositive: "121,220,76",
        ForegroundVisited: "84,166,55"
    })
    writeKdeglobalsGroup("Colors:View", {
        BackgroundAlternate: "10,30,13",
        BackgroundNormal: "3,13,5",
        DecorationFocus: "121,220,76",
        DecorationHover: "143,238,86",
        ForegroundActive: "143,238,86",
        ForegroundInactive: "93,145,70",
        ForegroundLink: "121,220,76",
        ForegroundNegative: "255,80,96",
        ForegroundNeutral: "191,224,78",
        ForegroundNormal: "142,229,101",
        ForegroundPositive: "121,220,76",
        ForegroundVisited: "84,166,55"
    })
    writeKdeglobalsGroup("Colors:Window", {
        BackgroundAlternate: "8,23,10",
        BackgroundNormal: "3,13,5",
        DecorationFocus: "121,220,76",
        DecorationHover: "143,238,86",
        ForegroundActive: "143,238,86",
        ForegroundInactive: "93,145,70",
        ForegroundLink: "121,220,76",
        ForegroundNegative: "255,80,96",
        ForegroundNeutral: "191,224,78",
        ForegroundNormal: "142,229,101",
        ForegroundPositive: "121,220,76",
        ForegroundVisited: "84,166,55"
    })
    writeKdeglobalsGroup("KDE", { contrast: "7" })
}

applyEvilMortyColors()

/*******Panel Top*********/
paneltop = new Panel
paneltop.hiding = "none"
paneltop.location = "top"
paneltop.floating = true
paneltop.height = 32
paneltop.lengthMode = "fill"
/****conociendo la resolucion de pantalla*/
const width = screenGeometry(paneltop.screen).width
/**/
let localerc;
try {
    localerc = ConfigFile('plasma-localerc');
    localerc.group = "Formats";
} catch (e) {
    // Si no se puede abrir el archivo, establecer leng a "en"
    localerc = null;
}

let leng = "en"; // Valor por defecto
if (localerc) {
    let langEntry = localerc.readEntry("LANG");
    if (langEntry !== "") {
        leng = langEntry;
    }
}

let textlengu = leng.substring(0, 2);

function desktoptext(languageCode) {
    const translations = {
        "es": "Escritorio",         // Spanish
        "en": "Desktop",            // English
        "hi": "डेस्कटॉप",           // Hindi
        "fr": "Bureau",             // French
        "de": "Desktop",            // German
        "it": "Desktop",            // Italian
        "pt": "Área de trabalho",   // Portuguese
        "ru": "Рабочий стол",       // Russian
        "zh": "桌面",               // Chinese (Mandarin)
        "ja": "デスクトップ",        // Japanese
        "ko": "데스크톱",            // Korean
        "nl": "Bureaublad",         // Dutch
        "ny": "Detskyopi",          // Chichewa
        "mk": "Десктоп"             // Macedonian
    };

    // Return the translation for the language code or default to English if not found
    return translations[languageCode] || translations["en"];
}
/*kapple*/

apptitle = paneltop.addWidget("org.kde.windowtitle.Fork")
apptitle.currentConfigGroup = ["General"]
apptitle.writeConfig("customText", "true")
apptitle.writeConfig("showIcon", "false")
apptitle.writeConfig("textDefault", "Citadel")

paneltop.addWidget("org.kde.plasma.appmenu")

paneltop.addWidget("org.kde.plasma.panelspacer")

clock = paneltop.addWidget("org.kde.plasma.digitalclock")
clock.currentConfigGroup = ["Appearance"]
clock.writeConfig("customDateFormat", "ddd d MMM")
clock.writeConfig("dateFormat", "custom")
clock.writeConfig("dateDisplayFormat", "BesideTime")
clock.writeConfig("fontStyleName", "bold")
clock.writeConfig("autoFontAndSize", "false")
clock.writeConfig("boldText", "true")
clock.writeConfig("fontWeight", 700)
clock.writeConfig("use24hFormat", "2")

paneltop.addWidget("org.kde.plasma.panelspacer")

systraprev = paneltop.addWidget("org.kde.plasma.systemtray")
/*/
SystrayContainmentId = systraprev.readConfig("SystrayContainmentId")
const systray = desktopById(SystrayContainmentId)
systray.currentConfigGroup = ["General"]
systray.writeConfig("iconSpacing", "0")/*/

controlHub = paneltop.addWidget("Plasma.Flex.Hub")
controlHub.currentConfigGroup = ["General"]
controlHub.writeConfig("elements", "19,20,10,9,2,25,8,23,21")
controlHub.writeConfig("xElements", "0,1,2,2,0,0,1,3,2")
controlHub.writeConfig("yElements", "1,1,1,2,0,3,3,3,3")
controlHub.writeConfig("selected_theme", "Custom")


/****************************/
panelbottom = new Panel
panelbottom.location = "bottom"
panelbottom.height = 72
panelbottom.offset = 24
panelbottom.floating = 1
panelbottom.alignment = "center"
panelbottom.hiding = "dodgewindows"
panelbottom.lengthMode = "fit"

panelbottom.addWidget("org.kde.plasma.icontasks")

panelColorizer = panelbottom.addWidget("luisbocanegra.panel.colorizer")
panelColorizer.currentConfigGroup = ["General"]
panelColorizer.writeConfig("hideWidget", "true")
panelColorizer.writeConfig("isEnabled", "true")
panelColorizer.writeConfig("configureFromAllWidgets", "true")
panelColorizer.writeConfig("globalSettings", JSON.stringify({
    panel: {
        normal: {
            enabled: true,
            blurBehind: false,
            backgroundClipping: true,
            flattenOnDeFloat: false,
            backgroundColor: {
                enabled: true,
                sourceType: 0,
                custom: "#050f08",
                alpha: 0.58
            },
            radius: {
                enabled: true,
                corner: {
                    topLeft: 14,
                    topRight: 14,
                    bottomRight: 14,
                    bottomLeft: 14
                }
            },
            margin: {
                enabled: true,
                side: {
                    right: 0,
                    left: 0,
                    top: 0,
                    bottom: 0
                }
            },
            padding: {
                enabled: true,
                side: {
                    right: 18,
                    left: 18,
                    top: 0,
                    bottom: 0
                }
            },
            border: {
                enabled: true,
                width: 1,
                color: {
                    enabled: true,
                    sourceType: 0,
                    custom: "#00ff66",
                    alpha: 0.30
                }
            },
            shadow: {
                background: {
                    enabled: false
                },
                foreground: {
                    enabled: false
                }
            }
        }
    },
    widgets: {
        normal: {
            enabled: false,
            backgroundClipping: false,
            backgroundColor: { enabled: false },
            foregroundColor: { enabled: false },
            border: { enabled: false },
            borderSecondary: { enabled: false },
            shadow: {
                background: { enabled: false },
                foreground: { enabled: false }
            }
        }
    },
    trayWidgets: {
        normal: {
            enabled: false,
            backgroundClipping: false,
            backgroundColor: { enabled: false },
            foregroundColor: { enabled: false },
            border: { enabled: false },
            borderSecondary: { enabled: false },
            shadow: {
                background: { enabled: false },
                foreground: { enabled: false }
            }
        }
    },
    nativePanel: {
        background: {
            enabled: true,
            opacity: 0,
            shadow: false
        },
        floatingDialogs: false,
        floatingDialogsAllowOverride: false,
        fillAreaOnDeFloat: false,
        hideWhenNoWidgetsAreVisible: false
    },
    stockPanelSettings: {
        alignment: {
            enabled: true,
            value: "center"
        },
        lengthMode: {
            enabled: true,
            value: "fit"
        },
        opacity: {
            enabled: true,
            value: "translucent"
        },
        floating: {
            enabled: true,
            value: true
        },
        thickness: {
            enabled: true,
            value: 72
        }
    }
}))

/******************************/
/*Cambiando configuracion Dolphin*/
const IconsStatic_dolphin = ConfigFile('dolphinrc')
IconsStatic_dolphin.group = 'KFileDialog Settings'
IconsStatic_dolphin.writeEntry('Places Icons Static Size', 16)
const PlacesPanel = ConfigFile('dolphinrc')
PlacesPanel.group = 'PlacesPanel'
PlacesPanel.writeEntry('IconSize', 16)
/*Breeze window decoration buttons*/
Buttons = ConfigFile("kwinrc")
Buttons.group = "org.kde.kdecoration2"
Buttons.writeEntry("ButtonsOnLeft", "IAX")
Buttons.writeEntry("ButtonsOnRight", "")
Buttons.writeEntry("library", "org.kde.breeze")
Buttons.writeEntry("theme", "Breeze")
/******************************/
/* accent color config*/
ColorAccetFile = ConfigFile("kdeglobals")
ColorAccetFile.group = "General"
ColorAccetFile.writeEntry("accentColorFromWallpaper", "false")
ColorAccetFile.writeEntry("AccentColor", "0,255,102")
ColorAccetFile.writeEntry("LastUsedCustomAccentColor", "0,255,102")
ColorAccetFile.writeEntry("ColorScheme", "EvilMorty")

GeneralGlobals = ConfigFile("kdeglobals")
GeneralGlobals.group = "General"
GeneralGlobals.writeEntry("TerminalApplication", "kitty")
