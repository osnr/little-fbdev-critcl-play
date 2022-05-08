package require critcl
critcl::ccode {
    #include <sys/stat.h>
    #include <fcntl.h>
    #include <sys/mman.h>
    unsigned short* fbmem;
}
critcl::cproc mmapFb {int width int height} void {
    int fb = open("/dev/fb0", O_RDWR);
    fbmem = mmap(NULL, width * height * 2, PROT_WRITE, MAP_SHARED, fb, 0);
}
critcl::cproc fillRectImpl {int width int x0 int y0 int x1 int y1 bytes color} void {
    // I bet you can make this faster.
    unsigned short colorShort = (color.s[1] << 8) | color.s[0];
    for (int y = y0; y < y1; y++) {
        for (int x = x0; x < x1; x++) {
            fbmem[(y * width) + x] = colorShort;
        }
    }
}

regexp {mode "(\d+)x(\d+)"} [exec fbset] -> ::WIDTH ::HEIGHT

# assumes /dev/fb0 is set up with BGR 5:6:5 bit layout
set black [binary format b16 [join {00000 000000 00000} ""]]
set blue  [binary format b16 [join {11111 000000 00000} ""]]
set green [binary format b16 [join {00000 111111 00000} ""]]
set red   [binary format b16 [join {00000 000000 11111} ""]]

mmapFb $::WIDTH $::HEIGHT
proc fillRect {x0 y0 x1 y1 color} {
    fillRectImpl $::WIDTH $x0 $y0 $x1 $y1 $color
}
proc fillScreen {color} {
    fillRect 0 0 $::WIDTH $::HEIGHT $color
}

fillScreen $green
