# twitter-image-bot

This is a twitter bot that just periodically posts random pictures from a preset list.

This is basically the source code for [@LegoSpaceBot](https://twitter.com/LegoSpaceBot) but without the set pictures. Enjoy the placeholder letter pictures.

# twitter-bot-template

This is based on another project: [The twitter-bot-template](https://github.com/vexorian/twitter-bot-template). Most of the twitter-related work is done by that. In fact, the only difference between this project and the twitter-bot-template is in content.rb and the provided images.

# Picking a random image

This project turned out to be notably non-trivial. The simple idea of just picking a random image from the list and posting it had an issue: If you pick N random numbers from a set that is not very large, there will most likely be many repetitions. [The birthday paradox](https://en.wikipedia.org/wiki/Birthday_problem) teaches us that with a set of 365 numbers (which is about 1.5 times larger than the number of available pictures for LegoSpaceBot), even in a sample as small as 23 people, the probability that some will share the picked numbers is 50%. Merely picking a random picture for each tweet would give the impression there are many repeated images.

The solution couldn't be to just use a database to keep track of which images were recently added - It would require extra resources for what is just a silly bot. Instead, the twitter account's tweet count is used as state. The tweet count is used as the index for the next image.

Then we also need a way to convert index into a picked image. Once the bot runs out of pictures, it needs to start all over again, but with a different order of pictures. This introduces new issues. The first one is how can you keep multiple orders when all we have to identify the next picture is its index? The answer to this was to divide the index i / N and round it down. With this we can identify which number of random permutation it is. What the bot does is to determine a random seed for the shuffle using i / N as base.

The second issue is that if we do this and always shuffle the sequence, there are still chances of repetitions. For example, we have two consecutive permutations and because of luck the last image in one is exactly the first image in the second one. This results in the bot having duplicates. To fix this, it actually splits the image list in two random halves and alternates what half to use depending on (i / N) / 2- This way we can guarantee a minimum N/2 distance between  two repeated pictures but without sacrificing the sensation of randomness.

Find the relevant source in content.rb.






