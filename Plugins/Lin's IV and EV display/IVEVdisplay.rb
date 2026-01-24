#===============================================================================
# * IV and EV display
#===============================================================================

class PokemonSummary_Scene
  def drawPageThree
    overlay = @sprites["overlay"].bitmap
    base   = Color.new(248, 248, 248)
    shadow = Color.new(104, 104, 104)
    # Determine which stats are boosted and lowered by the Pokémon's nature
    statshadows = {}
    GameData::Stat.each_main { |s| statshadows[s.id] = shadow }
    if !@pokemon.shadowPokemon? || @pokemon.heartStage <= 3
      @pokemon.nature_for_stats.stat_changes.each do |change|
        statshadows[change[0]] = Color.new(136, 96, 72) if change[1] > 0
        statshadows[change[0]] = Color.new(64, 120, 152) if change[1] < 0
      end
    end
    # Write various bits of text
    textpos = [
      [_INTL("IV"), 428, 52, 2, base, shadow],
      [_INTL("EV"), 466, 52, 2, base, shadow],
      [_INTL("HP"), 292, 82, 2, base, statshadows[:HP]],
      [sprintf("%d/%d", @pokemon.hp, @pokemon.totalhp), 408, 82, 1, Color.new(64, 64, 64), Color.new(176, 176, 176)],
        [sprintf("%d", @pokemon.iv[:HP]), 440, 82, 1, Color.new(64, 64, 64), Color.new(176, 176, 176)],
        [sprintf("%d", @pokemon.ev[:HP]), 484, 82, 1, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [_INTL("Attack"), 248, 126, 0, base, statshadows[:ATTACK]],
      [sprintf("%d", @pokemon.attack), 408, 126, 1, Color.new(64, 64, 64), Color.new(176, 176, 176)],
        [sprintf("%d", @pokemon.iv[:ATTACK]), 440, 126, 1, Color.new(64, 64, 64), Color.new(176, 176, 176)],
        [sprintf("%d", @pokemon.ev[:ATTACK]), 484, 126, 1, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [_INTL("Defense"), 248, 158, 0, base, statshadows[:DEFENSE]],
      [sprintf("%d", @pokemon.defense), 408, 158, 1, Color.new(64, 64, 64), Color.new(176, 176, 176)],
        [sprintf("%d", @pokemon.iv[:DEFENSE]), 440, 158, 1, Color.new(64, 64, 64), Color.new(176, 176, 176)],
        [sprintf("%d", @pokemon.ev[:DEFENSE]), 484, 158, 1, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [_INTL("Sp. Atk"), 248, 190, 0, base, statshadows[:SPECIAL_ATTACK]],
      [sprintf("%d", @pokemon.spatk), 408, 190, 1, Color.new(64, 64, 64), Color.new(176, 176, 176)],
        [sprintf("%d", @pokemon.iv[:SPECIAL_ATTACK]), 440, 190, 1, Color.new(64, 64, 64), Color.new(176, 176, 176)],
        [sprintf("%d", @pokemon.ev[:SPECIAL_ATTACK]), 484, 190, 1, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [_INTL("Sp. Def"), 248, 222, 0, base, statshadows[:SPECIAL_DEFENSE]],
      [sprintf("%d", @pokemon.spdef), 408, 222, 1, Color.new(64, 64, 64), Color.new(176, 176, 176)],
        [sprintf("%d", @pokemon.iv[:SPECIAL_DEFENSE]), 440, 222, 1, Color.new(64, 64, 64), Color.new(176, 176, 176)],
        [sprintf("%d", @pokemon.ev[:SPECIAL_DEFENSE]), 484, 222, 1, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [_INTL("Speed"), 248, 254, 0, base, statshadows[:SPEED]],
      [sprintf("%d", @pokemon.speed), 408, 254, 1, Color.new(64, 64, 64), Color.new(176, 176, 176)],
        [sprintf("%d", @pokemon.iv[:SPEED]), 440, 254, 1, Color.new(64, 64, 64), Color.new(176, 176, 176)],
        [sprintf("%d", @pokemon.ev[:SPEED]), 484, 254, 1, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [_INTL("Ability"), 224, 290, 0, base, shadow]
    ]
    # Draw ability name and description
    ability = @pokemon.ability
    if ability
      textpos.push([ability.name, 350, 290, 0, Color.new(64, 64, 64), Color.new(176, 176, 176)])
      drawTextEx(overlay, 224, 322, 282, 2, ability.description, Color.new(64, 64, 64), Color.new(176, 176, 176))
    end
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
    # Draw HP bar
    if @pokemon.hp > 0
      w = @pokemon.hp * 96 / @pokemon.totalhp.to_f
      w = 1 if w < 1
      w = ((w / 2).round) * 2
      hpzone = 0
      hpzone = 1 if @pokemon.hp <= (@pokemon.totalhp / 2).floor
      hpzone = 2 if @pokemon.hp <= (@pokemon.totalhp / 4).floor
      imagepos = [
        ["Graphics/Pictures/Summary/overlay_hp", 360, 110, 0, hpzone * 6, w, 6]
      ]
      pbDrawImagePositions(overlay, imagepos)
    end
  end
end