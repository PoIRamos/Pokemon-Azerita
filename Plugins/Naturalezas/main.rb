# ================================================================
# Traducción de las naturalezas al castellano para Pokemon Azerita
# ================================================================
module AzeritaSpanishNatures
  NAMES = {
    HARDY:   "Fuerte",
    LONELY:  "Huraña",
    BRAVE:   "Audaz",
    ADAMANT: "Firme",
    NAUGHTY: "Pícara",
    BOLD:    "Osada",
    DOCILE:  "Dócil",
    RELAXED: "Plácida",
    IMPISH:  "Agitada",
    LAX:     "Floja",
    TIMID:   "Miedosa",
    HASTY:   "Activa",
    SERIOUS: "Seria",
    JOLLY:   "Alegre",
    NAIVE:   "Ingenua",
    MODEST:  "Modesta",
    MILD:    "Afable",
    QUIET:   "Mansa",
    BASHFUL: "Tímida",
    RASH:    "Alocada",
    CALM:    "Serena",
    GENTLE:  "Amable",
    SASSY:   "Grosera",
    CAREFUL: "Cauta",
    QUIRKY:  "Rara"
  }

  NAMES.each do |id, name|
    GameData::Nature.get(id).instance_variable_set(:@real_name, name)
  end
end