# NIOSwiftMUD

This is the code repository for the tutorial series where we're using Swift and NIO to create a MUD game.

You can find the playlist for the tutorials here: https://www.youtube.com/playlist?list=PLhUrOtMlcKDAa0_WYh_J4vQ6Lzw0DvLLK 

Note: changes have been made after the YouTube series. In particular:
* Commands are no longer enum based, and no longer parsed in switch statements. Commands are now a protocol that specific commands can adhere to. In other words, we now use polymorphism to steer behaviour.
* `Session` is now a Protocol, whereas the `MudSession` is a specific implementation (that keeps track of channels). This way, the model is no longer dependant on knowledge about NIO, offering the option of stand alone testing.
* `SessionStorage` is now part of the model and works on generic instances of the `Session` protocol instead of concrete type.   

Feel free to create issues if you find any bugs.

## Episodes:

* Ep 01: Echo Server: basic setup of a NIO project.
* Ep 02: Pipeline: create a channel pipeline, fit for use with a MUD game.
* Ep 03: User database: create a generic, asynchronous backend to persist data in the game. And let players create users.
* Ep 04: Small cleanup (1): create a welcome message and add password hashing.
* Ep 05: Sessions: associate players with sessions and allow players to log in.
* Ep 06: Rooms: add rooms to the game and let players look around.
* Ep 07: Small cleanup (2): project organization
* Ep 08: Movement: allow players to move from room to room.
* Ep 09: Notifications: notify other (logged in) players (in a room) of actions by the player.
* Ep 10: Speak: let players speak out loud.
* Ep 11: Whisper: let players say something to another player.
* EP 12: Conclusion: where to go from here?  
* EP 13: Use SSH instead of Telnet