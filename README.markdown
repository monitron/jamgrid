jamgrid
=======

Jamgrid is a work in progress. The goal is to create a web app allowing friends and/or strangers to collaboratively make music online. I'm aiming for a casual interface; it should be enjoyable for non-musicians and reward experimentation.

It's currently evolving from a prototype to a node.js/socket.io-based service allowing semi-real-time "jamming" between multiple browsers on the same song.

This project was inspired by [tonematrix](http://lab.andre-michelle.com/tonematrix).

Dependencies
------------

* node.js
* mongodb
* mongoose
* mongoose-auth
* express
* jade
* socket.io

Try it out
----------

* Install node.js
* Install npm
* Install mongodb
* cd to jamgrid's root and `npm install`
* `node server.js`
* Visit `http://localhost:5000/`

Jamgrid works excellently in **Firefox 4+**. It works pretty well in **Chrome** too, though Chrome's HTML 5 `<audio>` tag support seems to be less robust; it flakes out after playing a strenuous song.

Once the page loads, click Edit next to an instrument name, click to fill in some squares and press Play. Try live-editing the patterns while they play, layering multiple instruments, etc.

Contribute
----------

I very much welcome collaboration on this project. All you need to work on it right now is [the CoffeeScript compiler](http://jashkenas.github.com/coffee-script/). Feel free to send pull requests. If you're feeling especially social I'd love an [email](mailto:monitron@gmail.com) to discuss your thoughts and plans for the project.