require "scorched/helpers"
require "scorched/terrain"
require "scorched/player"
require "scorched/shot"
require "scorched/color_palette"

module Scorched
  class GameScene < Ray::Scene
    include Helpers

    attr_reader :color_palette, :entities, :players, :terrain

    def register
      add_hook :key_press, key(:escape), method(:exit!)
      add_hook :mouse_release,           method(:mouse_release)
      add_hook :mouse_press,             method(:mouse_press)

      always do
        update
      end
    end

    def setup
      width, height  = *window.size
      @color_palette = ColorPalette.new(Ray::Color.red, Ray::Color.yellow, Ray::Color.white)
      @entities      = []
      @players       = 2.times.map { |index| Player.new rand(width), color_palette.get("player_#{index}") }
      @terrain       = Terrain.new width, height, rand(10), color_palette.get("terrain")
    end

    def update
      @entities.each { |entity| entity.update 1.0 / frames_per_second }
      @entities, @dead = *@entities.partition { |entity| entity.y > terrain.fetch(entity.x, 0) }
      @dead.each do |entity|
        radius = 50
        terrain.bite(entity.x, radius)
        @players.each do |player|
          if inside_radius?(entity.x - player.x, 0, radius * 2)
            pop_scene
            push_scene @scene_name
          end
        end
      end
    end

    def render(win)
      win.clear color_palette.get("sky")

      players.each do |player|
        player.draw win, terrain[player.x]
      end

      terrain.draw win

      entities.each do |entity|
        entity.draw win
      end
    end

    attr_reader :mouse_press_at

    def current_player
      players.first
    end

    def next_player
      players.rotate!
    end

    def mouse_release
      delta         = (Time.now - mouse_press_at) * 1000 + 1000
      width, height = *window.size
      x1, y1        = *mouse_pos
      x2, y2        = current_player.x, height - terrain[current_player.x]
      degrees       = angle(y2 - y1, x2 - x1) + 180
      velocity_x    = offset_x(degrees, delta)
      velocity_y    = offset_y(degrees, delta)

      @entities << Shot.new(current_player.x, terrain[current_player.x], velocity_x, velocity_y, Ray::Color.white)

      next_player
    end

    def mouse_press
      @mouse_press_at = Time.now
    end
  end
end
