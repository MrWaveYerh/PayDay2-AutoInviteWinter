--Don't do setup twice
if _G.InviteWinters then
    return
end

_G.InviteWinters = _G.InviteWinters or {}
InviteWinters._mod_path = ModPath

local lang_key = SystemInfo:language():key()
local languages = {
    [Idstring("english"):key()] = "english",
    [Idstring("french"):key()] = "french",
    [Idstring("russian"):key()] = "russian",
    [Idstring("dutch"):key()] = "dutch",
    [Idstring("german"):key()] = "german",
    [Idstring("italian"):key()] = "italian",
    [Idstring("spanish"):key()] = "spanish",
    [Idstring("japanese"):key()] = "japanese",
    [Idstring("schinese"):key()] = "schinese",
    [Idstring("korean"):key()] = "korean"
}

Hooks:Add("LocalizationManagerPostInit", "invite_winters_hook_LocalizationManagerPostInit", function(loc)
    loc:load_localization_file(InviteWinters._mod_path.."loc/"..languages[lang_key]..".txt")
end)