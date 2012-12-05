#
# purpose:
# In a proper setuped xterm..  this code renders a box.
#
# setting up UTF-8:
#   xset +fp ~/local/lib/X11/fonts
#   setenv LANG da_DK.UTF-8
#   xterm +u8 -fa '-misc-*-*-*-*-*-20-*-*-*-*-*-iso10646-1' &
#   ruby xterm_utf8.rb
#
puts [0x250c, 0x2510, 10, 0x2514, 0x2518].pack("U*")
