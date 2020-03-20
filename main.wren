import "input" for Keyboard, Mouse, GamePad
import "graphics" for Canvas, Color, ImageData, Point
import "audio" for AudioEngine
import "random" for Random
import "dome" for Process, Window
import "io" for FileSystem

// Game
class Game {
  static init() {
      System.print("Welcome player one!")
      Window.title = "Pole Position"

      __state = MainGame
      __state.init()
  }

  static update() {
      __x = Mouse.x
      __y = Mouse.y

     __state.update()
     if (__state.next) {
        __state = __state.next
        __state.init()
      }
      Mouse.hidden = Mouse.isButtonPressed("right")
  }

  static draw(alpha) {
      __state.draw(alpha)
      if (Mouse.isButtonPressed("right")) {
        Canvas.pset(__x, __y, Color.red)
      }
  }

}

//
// Types
//

class Box {
  construct new(x1, y1, x2, y2) {
    _p1 = Point.new(x1, y1)
    _p2 = Point.new(x2, y2)
  }

  x1 { _p1.x }
  y1 { _p1.y }
  x2 { _p2.x }
  y2 { _p2.y }
}

class Car {
     construct new() {
        _x = Canvas.width / 2
        _y = Canvas.height - 120
        _t = 0
        _car = [
          ImageData.loadFromFile("res/car.png"),
          ImageData.loadFromFile("res/car.png")
        ]
      }

    x { _x }
    y { _y }
    h { 8 }
    w { 6 }

    move(x, y) {
        _x = _x + x
        _y = _y + y
        _t = _t + 1
        if (_imm && _t > 30) {
          _imm = false
        }
    }

    draw(t) {
         var frame = (t / 5).floor % 2
         if (!_imm || (_t/4).floor % 2 == 0) {
           Canvas.draw(_car[frame], _x, _y)
         }
    }

    crash(centre) {
         _x = centre
         _y = Canvas.height - 120
    }
}

class Road {
    construct new() {
        _centre = Canvas.width / 2
        _sections = []
        _width = 60
        _leftLimit = centre-50
        _rightLimit = centre+50
        _movingLeft = true
      }

       centre { _centre }
       sections { _sections }
       width { _width }
       leftLimit { _leftLimit }
       rightLimit { _rightLimit }
       movingLeft { _movingLeft }

      init() {
          for (i in 0...Canvas.height) {
             _sections.add(RoadSection.new(Canvas.width/2, i))
          }
      }

      update() {
        for (i in (Canvas.height-2)...0) {
            _sections[i].update(width, _sections[i-1].x)
        }
        if (_movingLeft) {
           _sections[0].update(width, sections[0].x - 1)
          } else {
           _sections[0].update(width, sections[0].x + 1)
        }

        if (_sections[0].x  <= _leftLimit) {
          _movingLeft = false
          _leftLimit = centre - OurRandom.int(60)
        }
        if (_sections[0].x  >= _rightLimit) {
          _movingLeft = true
          _rightLimit = centre + OurRandom.int(60)
        }

        if (_width > 20) {
           _width = _width - 0.05
        }
      }

      reset() {
         _width = 60
      }

      draw(dt) {
        _sections.each {|edge| edge.draw(dt, _width) }
      }

}

class RoadSection {
 construct new(x, y) {
    _x = x
    _y = y
    _width = 60
  }

  x { _x }
  y { _y }


 update(width, x) {
    _width = width
    _x = x
 }

  draw(dt, width) {
     var color = Color.red
     if ( (_x % 2) == 0) {
        color = Color.white
     }
     Canvas.rectfill(_x-width, _y, 2, 2, color)
     Canvas.rectfill(_x+width, _y, 2, 2, color)
  }

}

class Explosion {
  construct new(x, y) {
    _x = x + OurRandom.int(6)-3
    _y = y + OurRandom.int(6)-3
    _c = [Color.red, Color.orange][OurRandom.int(2)]
    _t = 0
  }

  x { _x }
  y { _y }
  done { _t > 5 }

  update() {
    _t = _t + 1
  }

  draw() {
    Canvas.circlefill(_x, _y, _t, _c)
  }
}

class Tree {

  construct new() {
    _left = [true, false][OurRandom.int(2)]
    setX()
    _y = OurRandom.int(Canvas.height)
    _image = ImageData.loadFromFile("res/tree.png")
  }

  x { _x }
  y { _y }

  update() {
    _y = _y + 1
    if (_y > Canvas.height) {
      setX()
      _y = 0
    }
  }

  setX() {
    var left = [true, false][OurRandom.int(2)]
    if (left) {
        _x = OurRandom.int(40)
      } else {
        _x = Canvas.width - 40
      }
  }

  draw(dt) {
    Canvas.draw(_image, _x, _y + dt)
  }
}

class Rival {

  construct new() {
    _x = Canvas.width / 2
    _y = 1
    _image = ImageData.loadFromFile("res/rival.png")
  }

  x { _x }
  y { _y }
  h { 8 }
  w { 6 }

  update(x) {
    _x = x
    _y = _y + 0.5
    if (_y > Canvas.height) {
      _y = 0
    }
  }

  draw(dt) {
    Canvas.draw(_image, _x, _y + dt)
  }
}

var OurRandom = Random.new(12345)

class MainGame {
  static next { __next}

   static init() {
      __next = null
      __w = 5
      __h = 5
      __t = 0
      __points = 0
      __hiScore = 0
      __roadUpdateLimit = 0

      __car = Car.new()
      __rival = Rival.new()
      __explosions = []
      __trees = []
      __road = Road.new()
      __road.init()


      for (i in 0...4) {
        __trees.add(Tree.new())
      }

      AudioEngine.load("engine", "res/f1.wav")
      AudioEngine.load("explosion", "res/crash.wav")

      __channel = AudioEngine.play("engine", 1, true, -0.5)
   }

   static update() {
    __t = __t + 1
    var x = 0
    var y = 0

    var gamepad = GamePad.next

    ///////// Car move
        if (Keyboard.isKeyDown("u")) {
          AudioEngine.unload("music")
        }
      if (Keyboard.isKeyDown("left")) {
        x = -1
      }
      if (Keyboard.isKeyDown("right")) {
        x = 1
      }
      if (Keyboard.isKeyDown("up")) {
        y = -1
      }
      if (Keyboard.isKeyDown("down")) {
        y = 1
      }
      if (Keyboard.isKeyDown("escape")) {
        Process.exit()
      }

    __car.move(x, y)

   __road.update()

    __points = __points + 1

    /// Trees
    for (tree in __trees) {
      tree.update()
    }
    var rivalRoadPos = __road.sections[__rival.y.round-1].x
    __rival.update(rivalRoadPos)

    /// Crashed?
    var currentRoadPos = __road.sections[__car.y].x
    if (__car.x <= (currentRoadPos - __road.width) ||
        __car.x >= (currentRoadPos + __road.width) ||
        colliding(__car, __rival)) {
       for (i in 1..5) {
           __explosions.add(Explosion.new(__car.x, __car.y))
       }
        __car.crash(currentRoadPos)
        AudioEngine.play("explosion")
        if (__points > __hiScore) {
           __hiScore = __points
        }
        __points = 0
       __road.reset()
        __rival = Rival.new()
    }


    // Explosions
    __explosions = __explosions.where {|explosion|
      explosion.update()
      return !explosion.done
    }.toList

   }

   static draw(dt) {
       Canvas.print("Ready Player One...", 40, 40, Color.blue)
       Canvas.cls()
       __car.draw(__t)
      __road.draw(dt)
      __rival.draw(dt)
       __trees.each {|tree| tree.draw(dt) }
       __explosions.each {|explosion| explosion.draw() }
       Canvas.rectfill(0,0, 320,10, Color.black)
       Canvas.print("Score: %(__points)", 3, 3, Color.yellow)
       Canvas.print("High Score: %(__hiScore)", 3, 12, Color.red)
       Canvas.print("Super Grand Prix", Canvas.width - 150, 3, Color.white)
     }

      static colliding(o1, o2) {
         var box1 = Box.new(o1.x, o1.y, o1.x + o1.w, o1.y+o1.h)
         var box2 = Box.new(o2.x, o2.y, o2.x + o2.w, o2.y+o2.h)
         return box1.x1 < box2.x2 &&
           box1.x2 > box2.x1 &&
           box1.y1 < box2.y2 &&
           box1.y2 > box2.y1
       }

}





