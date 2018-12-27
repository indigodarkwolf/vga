# VGA-1

After frustrating myself with attempts to directly convert listing 23-1 from Michael Abrash's Graphics Programming Black Book, I decided to try and recreate the demo from scratch, starting with the most basic features of VGA and working up from there. This was my first working example of a single bouncing ball.

# Differences from Abrash's example: 

No panning or pel-panning. Look to VGA-3 for that.

It uses the physical screen size as its logical screen size, because I'm not doing any VGA panning or pel-panning, and felt that it didn't make sense to draw things off-screen if I couldn't/wouldn't pan to see it. This means the boundary boxes around the edge don't quite perfectly fit the play area, as they are 8x8 boxes drawn in pairs, whereas a 350 scanline display is not evenly divisible by 8, much less 16.

Also, in DOSBox 0.74-2, the technique of enabling certain VGA bit planes via the Sequence Controller's map mask function didn't work. Instead of limiting writes the enabled bit planes, it cleared the disabled bit planes when data was written at overlapping addresses. Since I don't have native hardware as of this writing, I don't know if this is a failing of DOSBox, the assembly in listing 23-1, or my interpretation of that code.

Instead of control strings, I'm doing a fairly typical box collision of the ball against the boundaries of the screen.

The ball is also 1 byte wide, instead of 3 bytes, because I wanted to keep my drawing code as simple as possible. It's also really more of a "diamond" than a ball.