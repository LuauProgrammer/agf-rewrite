### ⚠️ WARNING ⚠️ 
I highly advise against using this. It was created solely to replace AGF on an already aging game as we needed to expand the framework features. See [sleitnick's reason why you shouldn's use AGF anymore.](https://github.com/Sleitnick/AeroGameFramework/blob/master/README.md) Also, my design choices for this framework were not exactly *smart* (don't write code at 3 AM kids).

# agf-rewrite
A rewrite of the now outdated framework Aero Game Framework. Simply expands and adds new features onto the framework.

Fully backwards compatible with old AGF (caching is currently non-functional).

## Getting Started
Download a release (sometimes i'll publish one, if its an old release/no release there just clone this repo and do it on your own), move everything into their according folder. I provide you with a client loader and a server loader for the framework but feel free to create your own loader (ex: load something else before the framework).

## Documentation
See [AGF Documentation](https://sleitnick.github.io/AeroGameFramework/) for instructions on how to use this. The most notable difference between sleitnick's AGF and this version is that I utilize BridgeNet for networking, FastNet for Bindable Events.

As previously stated, this expands new features onto the framework. The features are as follows.

- FireMultipleClients method.
- FireAllClientsInRange method.
- FireOtherClientsInRange method.
- Bindable Middleware implementations.
- Remote Middleware implementations.
- Ability to choose how and when to start the framework (via your own scripts).

More to come if I truly need to add more features. It should be noted that I have yet to figure out how to handle creating client events in modules and how to implement middleware onto remote functions. Another very important thing, caching does not exist yet. I plan to add it in the future, just not now


I will not provide further documentation on anything. It's recommended you just read my code to understand how to use something.
