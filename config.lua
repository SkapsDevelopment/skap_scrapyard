Config = {}


Config.Zone = vec3(2349.9993, 3133.7136, 48.2087)
Config.ZoneSize = vec3(5.0, 5.0, 3.0)
Config.ZoneColor = {r = 128, g = 0, b = 128, a = 100} --RGBA format

Config.ProgressTime = 15000 --min 10s (cuz protections)

Config.Parts = {
    hood = {label = "Kapota", bone = "bonnet", item = "scrap_metal"},
    trunk = {label = "Kufr", bone = "boot", item = "scrap_metal"},
    door_rf = {label = "Přední pravé dveře", bone = "door_pside_f", item = "scrap_metal"},
    door_lf = {label = "Přední levé dveře", bone = "door_dside_f", item = "scrap_metal"},
    door_rr = {label = "Zadní pravé dveře", bone = "door_pside_r", item = "scrap_metal"},
    door_lr = {label = "Zadní levé dveře", bone = "door_dside_r", item = "scrap_metal"},
    crush = {label = "Sešrotovat vozidlo", item = "scrap_metal", min = 5, max = 10}
}
