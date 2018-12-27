# vga

Old-school VGA programming, in assembly. Learn as I learn, see the stupid things I do, tell me what I'm doing wrong.

27 Dec 2018

All code has been written to compile with NASM 2.14 (https://nasm.us/), and tested on DOSBox 0.74-2 (https://www.dosbox.com/). It is written to assemble into 16-bit DOS .com binaries for x86 processors. If you want .exes, you're on your own. For now. Or teach me.

Each numbered directory contains an iterative feature to the previous directory, in no particular order except the order in which I tackled learning any partiulcar part of the VGA beast, or built on that knowledge to make the demo a little fancier.

I've installed NASM to D:\Program Files\NASM. If you install/ed elsewhere, and are using Visual Studio Code, you'll want to edit tasks.json accordingly. Fine, yes, I'm a Microsoft sell-out/lamer/whatever pejorative is considered on fleek these days. And I'm a dinosaur, so get off my lawn.

# Credits/Links

In general, I have been following the examples of Michael Abrash in his Graphics Programming Black Book (https://github.com/jagregory/abrash-black-book), as well as Michael Abrash's long history of articles on VGA programming published on Dr. Dobb's (http://www.drdobbs.com/architecture-and-design/256-color-vga-animation/184408626, among many other articles and series I will try to link to as I rediscover them).

Since I'm learning X86 assembly as I go, Wikibooks' articles on X86 architecture have also been invaluable (https://en.wikibooks.org/wiki/X86_Assembly/X86_Architecture), along with the following reference on the Intel Pentium X86 Instruction Set (http://faydoc.tripod.com/cpu/index.htm), to whom I have no idea how to credit, as many of the links out of the documentation have rotted. And finally, OSDev.org's wiki on VGA Hardware (https://wiki.osdev.org/VGA_Hardware).

In the realm of troubleshooting, debug.com couldn't have been more helpful. One can find reasonable documentation at https://thestarman.pcministry.com/asm/debug/debug.htm, and Google turned up a copy of the binary itself at http://capp-sysware.com/misc/DEBUG.COM, which may be a dubious source but it was either that or losing my goddamn mind as I made every possible mistake that can be made, from banal access violations to forgetting that I needed to start my .text section at 100h in a com file. Most mistakes, you'll learn, result in DOSBox hanging. And I suspect it would be the same result on native hardware.

# FAQ

Why Assembly? And 16-bit DOS?

I blame Youtube content creators like The 8-bit Guy (https://www.youtube.com/channel/UC8uT9cgJorJPWu7ITLGo9Ww), and puzzle game developers like Zachtronics (http://www.zachtronics.com/). Basically, I'm fascinated by how these things used to work, and wanted to learn more by doing.

Why NASM?

It's here, now. It appears that NASM is being actively maintained, while Microsoft's Macro Assembler appears to be on the way out. When I went hunting for MASM, it appeared that it wasn't installed with Visual Studio 2017, and MS was last including it with Visual Studio 2005 (this is the prerequisite install for MASM 8.0, which is the latest version I found on Microsoft's website as of this writing). Maybe the tool name has changed -- knowing that would have saved me a lot of work, but I probably would not have learned half as much without having to author so much assembly on my own.

It's popular on OSDev and other forums. That hopefully gives NASM staying power and makes the code more likely to be useful to other people who want to learn about VGA programming in the future.

Legacy can be needlessly difficult to setup. I had bad experiences trying to cobble together legacy Microsoft toolchains before Monogame finished replicating their own data pipeline, so I am predisposed towards tools that "are", rather than "were".

If the original is going away, I might as well convert entirely to a tool everyone will have. There are assemblers that try to be compatible with MASM assembly, which is no surprise because there is a lot of MASM assembly out there. But for how long will these compatible tools be maintained? And what happens if I run into compatibility problems? Maybe these are "easy questions" and I'm just "too lazy" to answer them. I'd rather just learn NASM assembly and work in that. It all boils down to machine code in the end, and NASM has all the power in the world to author binary files.

Why DOSBox?

This is largely because I don't have native hardware anymore that I can test 16-bit DOS .com files with. I'm working on that, but not quite willing to shell out 300USD + shipping for an ebay 486 mid tower. DOSBox has good emulation, and until I have native hardware to use to "prove" places where DOSBox's emulation is weak (though this could also just be a "VGA-compatible" chipset that isn't fully compatible with IBM's VGA), I may as well work in a popular emulator that has been used with many, many VGA applications in the past.

Who are you?

I'm a AAA programming hack, 13 years into the industry as of 2019. I work mostly on bit-twiddly problems in networking code, and tools that help my coworkers write better, safer, more reliable multiplayer code. Apparently, I have a "problem" and can't stop programming, so when I have breaks and holidays, I try to do dumb stuff like this.