# This is just a file to declare the PICS array. Making it separate from content
# allows us to have a large file or maybe a programmatically-generated file.
# Yes, it could have been a text file.
#
# I prefer this method of manually inputing image paths because it allows to
# add captions to them. Some image bots just post all image files they can find
# in a folder. That is also a valid idea. I think you can make something that
# generates this file out of a folder, but with empty captions. I think.
#
# Note that letter d is a jpg it works just fine! Any image format supported
# by twitter should be allowed. Yes, that means GIFs.
#
# In most OSes the file paths are most likely CASE SENSITIVE.

PICS = [
    ["./images/a.png", "The letter A." ],
    ["./images/b.png", "The letter B." ],
    ["./images/c.png", "The letter C." ],
    ["./images/d.jpg", "The letter D." ],
    ["./images/x.png", "The letter X." ],
    ["./images/y.png", "The letter Y." ],
    ["./images/z.png", "The letter Z." ],
]
