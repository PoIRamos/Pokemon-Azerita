#===============================================================================
# Pokémon Azerita - IA de Obliterar
#===============================================================================

#-------------------------------------------------------------------------------
# La IA estima la potencia triple de Obliterar contra objetivos congelados.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveBasePower.add("TriplePowerIfTargetFrozen",
  proc { |power, move, user, target, ai, battle|
    next power if target.battler.status != :FROZEN

    # Obliterar no obtiene el multiplicador si hay un Sustituto
    # que impide que el movimiento alcance al objetivo.
    next power if target.effects[PBEffects::Substitute] > 0

    next power * 3
  }
)

#-------------------------------------------------------------------------------
# Pequeña bonificación por ser un movimiento característico para priorizarlo en caso de empate.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add(
  "TriplePowerIfTargetFrozen",
  proc { |score, move, user, target, ai, battle|
    next score if target.battler.status != :FROZEN

    score += 5
    next score
  }
)