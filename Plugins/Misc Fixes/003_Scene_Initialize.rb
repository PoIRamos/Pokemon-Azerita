class Battle::Scene
  #=============================================================================
  # Create the battle scene and its elements
  #=============================================================================
  def initialize
    @battle     = nil
    @abortable  = false
    @aborted    = false
    @battleEnd  = false
    @animations = []
  end

  # Called whenever the battle begins.
  def pbStartBattle(battle)
    @battle   = battle
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @lastCmd  = Array.new(@battle.battlers.length, 0)
    @lastMove = Array.new(@battle.battlers.length, 0)
    pbInitSprites
    pbBattleIntroAnimation
  end

  def pbInitSprites
    @sprites = {}
    # The background image and each side's base graphic
    pbCreateBackdropSprites
    # Create message box graphic
    messageBox = pbAddSprite("messageBox", 0, Graphics.height - 96,
                             "Graphics/UI/Battle/overlay_message", @viewport)
    messageBox.z = 195
    # Create message window (displays the message)
    msgWindow = Window_AdvancedTextPokemon.newWithSize(
      "", 16, Graphics.height - 96 + 2, Graphics.width - 32, 96, @viewport
    )
    msgWindow.z              = 200
    msgWindow.opacity        = 0
    msgWindow.baseColor      = MESSAGE_BASE_COLOR
    msgWindow.shadowColor    = MESSAGE_SHADOW_COLOR
    msgWindow.letterbyletter = true
    @sprites["messageWindow"] = msgWindow
    # [DBK] Midbattle Scripting: name window and speaker sprite
    nameWindow = Window_AdvancedTextPokemon.new
    nameWindow.baseColor      = MESSAGE_BASE_COLOR
    nameWindow.shadowColor    = MESSAGE_SHADOW_COLOR
    nameWindow.viewport       = @viewport
    nameWindow.letterbyletter = false
    nameWindow.visible        = false
    nameWindow.x              = 16
    nameWindow.y              = Graphics.height - 158
    nameWindow.z              = 200
    @sprites["nameWindow"]   = nameWindow

    @speaker     = $player
    @showSpeaker = false
    @showWindows = false

    defaultFile = GameData::TrainerType.front_sprite_filename($player.trainer_type)
    spriteX, spriteY = Battle::Scene.pbTrainerPosition(1)
    sprite = pbAddSprite("midbattle_speaker", spriteX, spriteY, defaultFile, @viewport)

    if sprite.bitmap
      sprite.z = 7
      sprite.ox = sprite.src_rect.width / 2
      sprite.oy = sprite.bitmap.height
      sprite.visible = false
    end
    # Create command window
    @sprites["commandWindow"] = CommandMenu.new(@viewport, 200)
    # Create fight window
    @sprites["fightWindow"] = FightMenu.new(@viewport, 200)
    # Create targeting window
    @sprites["targetWindow"] = TargetMenu.new(@viewport, 200, @battle.sideSizes)
    pbShowWindow(MESSAGE_BOX)
    # The party lineup graphics (bar and balls) for both sides
    2.times do |side|
      partyBar = pbAddSprite("partyBar_#{side}", 0, 0,
                             "Graphics/UI/Battle/overlay_lineup", @viewport)
      partyBar.z       = 120
      partyBar.mirror  = true if side == 0   # Player's lineup bar only
      partyBar.visible = false
      NUM_BALLS.times do |i|
        ball = pbAddSprite("partyBall_#{side}_#{i}", 0, 0, nil, @viewport)
        ball.z       = 121
        ball.visible = false
      end
      # Ability splash bars
      if USE_ABILITY_SPLASH
        @sprites["abilityBar_#{side}"] = AbilitySplashBar.new(side, @viewport)
      end
    end
    # Player's and partner trainer's back sprite
    @battle.player.each_with_index do |p, i|
      pbCreateTrainerBackSprite(i, p.trainer_type, @battle.player.length)
    end
    # Opposing trainer(s) sprites
    if @battle.trainerBattle?
      @battle.opponent.each_with_index do |p, i|
        pbCreateTrainerFrontSprite(i, p.trainer_type, @battle.opponent.length)
      end
    end
    # Data boxes and Pokémon sprites
    @battle.battlers.each_with_index do |b, i|
      next if !b
      @sprites["dataBox_#{i}"] = PokemonDataBox.new(b, @battle.pbSideSize(i), @viewport)
      pbCreatePokemonSprite(i)
    end
    # Wild battle, so set up the Pokémon sprite(s) accordingly
    if @battle.wildBattle?
      @battle.pbParty(1).each_with_index do |pkmn, i|
        index = (i * 2) + 1
        pbChangePokemon(index, pkmn)
        pkmnSprite = @sprites["pokemon_#{index}"]
        pkmnSprite.tone    = Tone.new(-80, -80, -80)
        pkmnSprite.visible = true
      end
    end

    # [DBK] Enhanced Battle UI
    if !pbInSafari?
      @path = Settings::BATTLE_UI_GRAPHICS_PATH
      @enhancedUIToggle = nil

      @sprites["enhancedUIPrompts"] = EnhancedUIPrompt.new(
        nil, @battle, COMMAND_BOX, @viewport
      )

      @sprites["enhancedUI"] = BitmapSprite.new(
        Graphics.width, Graphics.height, @viewport
      )
      @sprites["enhancedUI"].z = 300
      @sprites["enhancedUI"].visible = false
      pbSetSmallFont(@sprites["enhancedUI"].bitmap)
      @enhancedUIOverlay = @sprites["enhancedUI"].bitmap

      @sprites["leftarrow"] = AnimatedSprite.new(
        "Graphics/UI/left_arrow", 8, 40, 28, 2, @viewport
      )
      @sprites["leftarrow"].x = -2
      @sprites["leftarrow"].y = 71
      @sprites["leftarrow"].z = 300
      @sprites["leftarrow"].play
      @sprites["leftarrow"].visible = false

      @sprites["rightarrow"] = AnimatedSprite.new(
        "Graphics/UI/right_arrow", 8, 40, 28, 2, @viewport
      )
      @sprites["rightarrow"].x = Graphics.width - 38
      @sprites["rightarrow"].y = 71
      @sprites["rightarrow"].z = 300
      @sprites["rightarrow"].play
      @sprites["rightarrow"].visible = false

      @battle.allBattlers.each do |b|
        @sprites["info_icon#{b.index}"] = PokemonIconSprite.new(
          b.pokemon, @viewport
        )
        @sprites["info_icon#{b.index}"].setOffset(PictureOrigin::CENTER)
        @sprites["info_icon#{b.index}"].visible = false
        @sprites["info_icon#{b.index}"].z = 300

        pbAddSpriteOutline([
          "info_icon#{b.index}",
          @viewport,
          b.pokemon,
          PictureOrigin::CENTER
        ])
      end

      ballY = @sprites["messageBox"].y - 58

      5.times do |i|
        case i
        when 0 then ballX = 64
        when 1 then ballX = 146
        when 2 then ballX = 256
        when 3 then ballX = 366
        when 4 then ballX = 448
        end

        @sprites["ball_icon#{i}"] = ItemIconSprite.new(
          ballX, ballY, nil, @viewport
        )
        @sprites["ball_icon#{i}"].visible = false
        @sprites["ball_icon#{i}"].z = 300

        pbAddSpriteOutline([
          "ball_icon#{i}",
          @viewport,
          nil,
          PictureOrigin::CENTER
        ])
      end
    end

  end

  def pbCreateBackdropSprites
    case @battle.time
    when 1 then time = "eve"
    when 2 then time = "night"
    end
    # Put everything together into backdrop, bases and message bar filenames
    backdropFilename = @battle.backdrop
    baseFilename = @battle.backdrop
    baseFilename = sprintf("%s_%s", baseFilename, @battle.backdropBase) if @battle.backdropBase
    messageFilename = @battle.backdrop
    if time
      trialName = sprintf("%s_%s", backdropFilename, time)
      if pbResolveBitmap(sprintf("Graphics/Battlebacks/%s_bg", trialName))
        backdropFilename = trialName
      end
      trialName = sprintf("%s_%s", baseFilename, time)
      if pbResolveBitmap(sprintf("Graphics/Battlebacks/%s_base0", trialName))
        baseFilename = trialName
      end
      trialName = sprintf("%s_%s", messageFilename, time)
      if pbResolveBitmap(sprintf("Graphics/Battlebacks/%s_message", trialName))
        messageFilename = trialName
      end
    end
    if !pbResolveBitmap(sprintf("Graphics/Battlebacks/%s_base0", baseFilename)) &&
       @battle.backdropBase
      baseFilename = @battle.backdropBase
      if time
        trialName = sprintf("%s_%s", baseFilename, time)
        if pbResolveBitmap(sprintf("Graphics/Battlebacks/%s_base0", trialName))
          baseFilename = trialName
        end
      end
    end
    # Finalise filenames
    battleBG   = "Graphics/Battlebacks/" + backdropFilename + "_bg"
    playerBase = "Graphics/Battlebacks/" + baseFilename + "_base0"
    enemyBase  = "Graphics/Battlebacks/" + baseFilename + "_base1"
    messageBG  = "Graphics/Battlebacks/" + messageFilename + "_message"
    # Apply graphics
    bg = pbAddSprite("battle_bg", 0, 0, battleBG, @viewport)
    bg.z = 0
    bg = pbAddSprite("battle_bg2", -Graphics.width, 0, battleBG, @viewport)
    bg.z      = 0
    bg.mirror = true
    2.times do |side|
      baseX, baseY = Battle::Scene.pbBattlerPosition(side)
      if side == 0
        baseY += 100
      else
        baseY -= 18
      end
      base = pbAddSprite("base_#{side}", baseX, baseY,
                         (side == 0) ? playerBase : enemyBase, @viewport)
      base.z = 3
      if base.bitmap
        base.ox = base.bitmap.width / 2
        base.oy = (side == 0) ? base.bitmap.height : base.bitmap.height / 2
      end
    end
    cmdBarBG = pbAddSprite("cmdBar_bg", 0, Graphics.height - 96, messageBG, @viewport)
    cmdBarBG.z = 180
  end

  def pbCreateTrainerBackSprite(idxTrainer, trainerType, numTrainers = 1)
    if idxTrainer == 0   # Player's sprite
      trainerFile = GameData::TrainerType.player_back_sprite_filename(trainerType)
    else   # Partner trainer's sprite
      trainerFile = GameData::TrainerType.back_sprite_filename(trainerType)
    end
    spriteX, spriteY = Battle::Scene.pbTrainerPosition(0, idxTrainer, numTrainers)
    trainer = pbAddSprite("player_#{idxTrainer + 1}", spriteX, spriteY, trainerFile, @viewport)
    return if !trainer.bitmap
    # Alter position of sprite
    trainer.z = 80 + idxTrainer
    if trainer.bitmap.width > trainer.bitmap.height * 2
      trainer.src_rect.x     = 0
      trainer.src_rect.width = trainer.bitmap.width / 5
    end
    trainer.ox = trainer.src_rect.width / 2
    trainer.oy = trainer.bitmap.height
  end

  def pbCreateTrainerFrontSprite(idxTrainer, trainerType, numTrainers = 1)
    trainerFile = GameData::TrainerType.front_sprite_filename(trainerType)
    spriteX, spriteY = Battle::Scene.pbTrainerPosition(1, idxTrainer, numTrainers)
    trainer = pbAddSprite("trainer_#{idxTrainer + 1}", spriteX, spriteY, trainerFile, @viewport)
    return if !trainer.bitmap
    # Alter position of sprite
    trainer.z  = 7 + idxTrainer
    trainer.ox = trainer.src_rect.width / 2
    trainer.oy = trainer.bitmap.height
  end

  def pbCreatePokemonSprite(idxBattler)
    sideSize = @battle.pbSideSize(idxBattler)
    batSprite = BattlerSprite.new(@viewport, sideSize, idxBattler, @animations)
    @sprites["pokemon_#{idxBattler}"] = batSprite
    shaSprite = BattlerShadowSprite.new(@viewport, sideSize, idxBattler)
    shaSprite.visible = false
    @sprites["shadow_#{idxBattler}"] = shaSprite
  end
end

