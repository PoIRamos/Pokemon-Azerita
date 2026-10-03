#===============================================================================
# Pokémon Azerita - Compatibilidad con "[LBDSKY] [Plugin] Mostrar tipos en combate"
#
# Este parche restaura la integración del plugin de tipos después de que
# Misc Fixes/007_Battle_Scene_Objects.rb redefine PokemonDataBox.
#
# No sustituye PokemonDataBox completo ni modifica el plugin original.
#===============================================================================

class Battle::Scene::PokemonDataBox

  #---------------------------------------------------------------------------
  # Crear los sprites de tipos después de que Azerita cree los gráficos propios
  # del DataBox.
  #---------------------------------------------------------------------------
  alias __azerita_types_initializeOtherGraphics initializeOtherGraphics
  def initializeOtherGraphics(viewport)
    # IMPORTANTE:
    # Los sprites de tipos deben existir ANTES de llamar al initialize original.
    # De esta forma, el initialize de PokemonDataBox pasa por x=, y=, z= y
    # visible= cuando crea/configura el DataBox, y los tipos reciben exactamente
    # las mismas coordenadas, visibilidad y profundidad.
    @types_x = (@battler.opposes?(0)) ? 200 : -40
    @types_bitmap = AnimatedBitmap.new("Graphics/UI/Battle/types_ico")
    @types_sprite = Sprite.new(viewport)


    @height_per_icon = @types_bitmap.height / GameData::Type.count
    @icon_spacing = 2
    @max_types = 3

    total_height = (@height_per_icon + @icon_spacing) * @max_types

    begin
      @types_sprite.bitmap = Bitmap.new(@databoxBitmap.width - @types_x, total_height)
    rescue
      @types_sprite.dispose if @types_sprite && !@types_sprite.disposed?
      @types_sprite = nil
    end

    reset_type_cache if @types_sprite
    @sprites["types_sprite"] = @types_sprite if @types_sprite

    # Ahora dejamos que Azerita termine de inicializar el DataBox.
    # Como los métodos x=, y=, z= y visible= ya están parcheados, el sprite
    # de tipos queda sincronizado con el resto del DataBox desde el principio.
    __azerita_types_initializeOtherGraphics(viewport)
  end

  #---------------------------------------------------------------------------
  # Liberar los gráficos de tipos.
  #---------------------------------------------------------------------------
  alias __azerita_types_dispose dispose
  def dispose(*args)
    @types_bitmap.dispose if @types_bitmap && !@types_bitmap.disposed?
    __azerita_types_dispose(*args)
  end

  #---------------------------------------------------------------------------
  # Posición X del sprite de tipos.
  #---------------------------------------------------------------------------
  alias __azerita_types_set_x x=
  def x=(value)
    __azerita_types_set_x(value)

    return if !@types_sprite || @types_sprite.disposed?

    extra_x = (@battler.opposes?(0)) ? 10 : 0
    name_width = self.bitmap.text_size(@battler.name).width

    if name_width > 116
      extra_x += @battler.opposes?(0) ? 14 : 0
    else
      extra_x += @battler.opposes?(0) ? 2 : 0
    end

    @types_sprite.x = value + 10 + extra_x + @types_x
  end

  #---------------------------------------------------------------------------
  # Posición Y del sprite de tipos.
  #---------------------------------------------------------------------------
  alias __azerita_types_set_y y=
  def y=(value)
    __azerita_types_set_y(value)

    return if !@types_sprite || @types_sprite.disposed?

    @types_sprite.y = value + 5
  end

  #---------------------------------------------------------------------------
  # Z del sprite de tipos.
  #---------------------------------------------------------------------------
  alias __azerita_types_set_z z=
  def z=(value)
    __azerita_types_set_z(value)

    return if !@types_sprite || @types_sprite.disposed?

    @types_sprite.z = value + 1
  end

  #---------------------------------------------------------------------------
  # Actualizar los iconos de tipos después del refresh de Azerita.
  #---------------------------------------------------------------------------
  alias __azerita_types_refresh refresh
  def refresh
    __azerita_types_refresh
    update_type_icons_if_needed
  end

  #---------------------------------------------------------------------------
  # Estado/cache de los tipos mostrados.
  #---------------------------------------------------------------------------
  private

  def reset_type_cache
    @cached_pokemon_id = nil
    @cached_types = nil
    @cached_illusion_pokemon_id = nil
  end

  def get_current_pokemon_state
    illusion_pokemon = @battler.effects[PBEffects::Illusion]

    hash = {
      pokemon_id: @battler.pokemon.personalID,
      types: illusion_pokemon ? illusion_pokemon.types : @battler.pbTypes(true),
      illusion_id: illusion_pokemon ? illusion_pokemon.personalID : nil
    }

    if illusion_pokemon
      if @battler && @battler.effects[PBEffects::ExtraType]
        extra_type = @battler.effects[PBEffects::ExtraType]
        hash[:types] << extra_type if extra_type
      end

      if @battler.effects[PBEffects::BurnUp] && hash[:types].include?(:FIRE)
        hash[:types].delete(:FIRE)
      end

      if @battler.effects[PBEffects::DoubleShock] && hash[:types].include?(:ELECTRIC)
        hash[:types].delete(:ELECTRIC)
      end

      if @battler.effects[PBEffects::Roost]
        hash[:types].delete(:FLYING)
        hash[:types] << :NORMAL if hash[:types].empty?
      end
    end

    hash[:types] = [:QMARKS] if hash[:types].empty?

    return hash
  end

  def cache_changed?(current_state)
    pokemon_changed = @cached_pokemon_id != current_state[:pokemon_id]
    types_changed = @cached_types != current_state[:types]
    illusion_changed = @cached_illusion_pokemon_id != current_state[:illusion_id]
    illusion_ended = @cached_illusion_pokemon_id && current_state[:illusion_id].nil?

    return pokemon_changed || types_changed || illusion_changed || illusion_ended
  end

  def update_cache(current_state)
    @cached_pokemon_id = current_state[:pokemon_id]
    @cached_types = current_state[:types].dup
    @cached_illusion_pokemon_id = current_state[:illusion_id]
  end

  def update_type_icons_if_needed
    return if !@battler || !@battler.pokemon
    return if !@types_sprite || @types_sprite.disposed?
    return if !@types_sprite.bitmap || @types_sprite.bitmap.disposed?

    current_state = get_current_pokemon_state

    if cache_changed?(current_state)
      draw_type_icons
      update_cache(current_state)
    end
  end

  def draw_type_icons
    return if !@types_sprite || @types_sprite.disposed?
    return if !@types_sprite.bitmap || @types_sprite.bitmap.disposed?

    types = get_current_pokemon_state[:types].uniq
    @types_sprite.bitmap.clear

    actual_height = types.size * @height_per_icon +
                    (types.size - 1) * @icon_spacing
    y_offset = -actual_height + 68

    @types_sprite.x = @types_x
    @types_sprite.y = y_offset

    name_width = self.bitmap.text_size(@battler.name).width

    if name_width <= 116
      x_offset = @battler.opposes?(0) ? 0 : 40
    else
      x_offset = @battler.opposes?(0) ? 0 : 40
    end

    if @battler.level >= 100 && @battler.opposes?(0)
      x_offset += 8
    end

    icon_width = @types_bitmap.width

    types.each_with_index do |type, index|
      type_data = GameData::Type.get(type)

      source_rect = Rect.new(
        0,
        type_data.icon_position * @height_per_icon,
        icon_width,
        @height_per_icon
      )

      dest_y = index * (@height_per_icon + @icon_spacing) + 5

      @types_sprite.bitmap.blt(
        x_offset,
        dest_y,
        @types_bitmap.bitmap,
        source_rect
      )
    end
  end

  public

  #---------------------------------------------------------------------------
  # Fuerza la actualización cuando otro sistema necesite refrescar los tipos.
  #---------------------------------------------------------------------------
  def force_type_icons_refresh
    return if !@types_sprite || @types_sprite.disposed?
    return if !@types_sprite.bitmap || @types_sprite.bitmap.disposed?

    reset_type_cache
    update_type_icons_if_needed
  end
end
