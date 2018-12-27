# VGA-2

An interative improvement of VGA-1. It draws multiple balls to the playfield, and introduces sub-pixel movement so that non-integer frame velocities of the balls can be introduced. It slightly changes the shape of the ball to be ever so slightly more ball-like, though calling these shapes "balls" really is an insult to noble octagons everywhere.

Since I'm now performing sub-pixel movements, you'll notice that the x-axis movement looks much more "jerky" than in VGA-1. This is because I'm limited to blitting around whole bytes of data, when that data corresponds to 8 pixels at a time. To solve this, I'll need to make the ball two bytes wide, and pre-shift the ball bits around like I were animating an 8x8 ball sliding across a 16x8 frame. Then I'd treat the ball like it was two bytes wide instead of 1 byte wide, except on the special case where the ball is perfectly aligned on a byte boundary.

Apparently, this is how a lot of old games used to solve this problem. That, or they'd limit their sprite movement to 8-pixel boundaries (an idea which certainly makes a lot of sense in grid-based games, such as board games, JRPGs, Planet X-3 by David Murray, etc).