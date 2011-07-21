require 'json'

class Battlefield
   attr_reader :width
   attr_reader :height
   attr_reader :robots
   attr_reader :teams
   attr_reader :bullets
   attr_reader :explosions
   attr_reader :time
   attr_reader :seed
   attr_reader :timeout  # how many ticks the match can go before ending.
   attr_reader :game_over
   attr_reader :history

  def initialize width, height, timeout, seed
    @width, @height = width, height
    @seed = seed
    @time = 0
    @robots = []
    @teams = Hash.new{|h,k| h[k] = [] }
    @bullets = []
    @explosions = []
    @timeout = timeout
    @game_over = false
    @history = []
    srand @seed
  end

  def << object
    case object
    when RobotRunner
      @robots << object
      @teams[object.team] << object
    when Bullet
      @bullets << object
    when Explosion
      @explosions << object
    end
  end

  def tick
    explosions.delete_if{|explosion| explosion.dead}
    explosions.each{|explosion| explosion.tick}

    bullets.delete_if{|bullet| bullet.dead}
    bullets.each{|bullet| bullet.tick}

    robots.each do |robot|
      begin
        robot.send :internal_tick unless robot.dead
      rescue Exception => bang
        puts "#{robot} made an exception:"
        puts "#{bang.class}: #{bang}", bang.backtrace
        robot.instance_eval{@energy = -1}
      end
    end

    @time += 1
    live_robots = robots.find_all{|robot| !robot.dead}
    @game_over = (  (@time >= timeout) or # timeout reached
                    (live_robots.length == 0) or # no robots alive, draw game
                    (live_robots.all?{|r| r.team == live_robots.first.team})) # all other teams are dead
    history << state(false)
    not @game_over
  end

  def state(include_dead = true)
    {:explosions => explosions.map{|e| e.state unless !include_dead && e.dead }.flatten,
     :bullets    => bullets.map{|b| b.state.merge(:name => 'Bullet_' + bullets.index(b).to_s) unless !include_dead && b.dead}.flatten,
     :robots     => robots.map{|r| r.state.merge(:name => r.robot.class.name) unless !include_dead && r.dead}.flatten}
  end

end
