require 'io/console'

class Drop
  attr_accessor :x, :y, :emoji
  SUSHI = "\u{1F363}"
  BEER = "\u{1F37A}"
  PIZZA = "\u{1F355}"
  ONIGIRI = "\u{1F359}"
  EMOJIS = [SUSHI, BEER, PIZZA, ONIGIRI]

  def initialize(x)
    @x = x
    @y = 0
    @emoji = EMOJIS.sample
  end
end

class Ochimono
  ROWS = 12
  COLS = 6

  Y_VELOCITY = 0.3

  def initialize
    @drops = [Drop.new(2), Drop.new(3)]
    @fixed_drops = []
    @commands = []
  end

  def clear_screen
    puts "\e[H\e[2J"
  end

  def draw_boarders
    print "\e[0;0H#{'*' * ((COLS + 1)* 2)}\e[0;0H"
    print "\e[#{ROWS + 3};0H#{'*' * ((COLS + 1) * 2)}\e[0;0H"

    (ROWS + 3).times do |r|
      print "\e[#{r};0H*\e[0;0H"
      print "\e[#{r};#{(COLS + 1) * 2}H*\e[0;0H"
    end
  end

  def can_fall?(drop)
    @fixed_drops.each do |fixed_drop|
      next if drop == fixed_drop
      return false if drop.x == fixed_drop.x && (drop.y + 1 == fixed_drop.y || drop.y.ceil == fixed_drop.y)
    end

    drop.y < ROWS
  end

  def fall_drops
    landing = @drops.select { |drop| !can_fall?(drop) }.count != 0
    if landing
      @fixed_drops.concat(@drops)
      @drops = []
    end

    (@drops + @fixed_drops).each do |drop|
      drop.y += Y_VELOCITY if can_fall?(drop)
      drop.y = drop.y.floor unless can_fall?(drop)
    end
  end

  def remove_connected_drops
    drops_to_remove = []

    @fixed_drops.each do |drop|
      connected_drops = find_connected_drops(drop, [])
      if connected_drops.size >= 4
        drops_to_remove += connected_drops
      end
    end

    drops_to_remove.each do |drop|
      @fixed_drops.delete(drop)
    end
  end

  def find_connected_drops(origin_drop, connected_drops)
    connected_drops << origin_drop
    x = origin_drop.x
    y = origin_drop.y

    [[0, -1], [1, 0], [0, 1], [-1, 0]].each do |dx, dy|
      if next_drop = @fixed_drops.find { |drop| drop.x == x + dx && drop.y == y + dy && drop.emoji == origin_drop.emoji }
        next if connected_drops.include?(next_drop)
        connected_drops = find_connected_drops(next_drop, connected_drops)
      end
    end

    connected_drops
  end

  def fixed?
    @fixed_drops.select { |drop| can_fall?(drop) }.count == 0
  end

  def get_command
    command = nil
    if @commands.include?(:left)
      command = :left
    elsif @commands.include?(:right)
      command = :right
    end
    @commands = []

    command
  end

  def main_loop
    loop do
      clear_screen

      case get_command
      when :left
        left_drop = @drops.sort_by(&:x)[0]
        if left_drop.x - 1 >= 0
          @drops.each { |drop| drop.x -= 1}
        end
      when :right
        right_drop = @drops.sort_by(&:x).reverse[0]
        if right_drop.x + 1 < COLS
          @drops.each { |drop| drop.x += 1}
        end
      end

      fall_drops
      remove_connected_drops if fixed?

      if @drops.empty? && fixed?
        @drops = [Drop.new(2), Drop.new(3)]
      end

      draw_boarders

      (@drops + @fixed_drops).each do |drop|
        x = drop.x
        y = drop.y.floor
        print "\e[#{y + 2};#{(x + 1)* 2}H#{drop.emoji} \e[0;0H"
      end

      sleep 0.1
    end
  end

  def start
    Thread.new do
      begin
        main_loop
      rescue => e
        puts e
        puts e.backtrace
        exit
      end
    end

    loop do
      command = STDIN.getch.chr
      case command
      when 'l'
        @commands << :right
      when 'h'
        @commands << :left
      when 'q'
        exit
      end
    end
  end
end

Ochimono.new.start
