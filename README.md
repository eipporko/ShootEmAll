# ShootEmAll

## Instructions

The goal of the game is to survive as long as you can.  
When you kill a monster you can obtain cash and buy power ups or buildings.

## Controls
* W: Forward
* S: Back
* A: Left
* D: Right
* Left Mouse Button: Fire Weapon
* P: Debug mode
* 1-2: Set zoom
* Esc: Exit


## Before to have fun - *Dependencies*.

You should install [LÖVE](https://love2d.org/) a framework to make 2D games in Lua. Depending your operating system the way to install it can change.

### Ubuntu 12.04, 14.04–15.04

Run the next command lines in a terminal window.

```
sudo add-apt-repository ppa:bartbes/love-stable
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install love2d
```

### Mac OS X 10.6+

Download löve from the project's [website](https://love2d.org/) and place it in your *Applications* folder.

With the help of an adult, open a terminal and modify (if it's needed create one) the file `.bash_profile` in your home folder.

Add the next alias:

```
alias love="/Applications/love.app/Contents/MacOS/love"
```

### Windows XP+

Download löve from the project's [website](https://love2d.org/) and execute the installer provided.

## Play to ShootEmAll


### Ubuntu / Os X
```
git clone https://github.com/eipporko/ShootEmAll.git
cd ShootEmAll
love .
```

### Windows
Download ShootEmAll source code and you will have two ways of running:

a. Running *LOVE* and drag *ShootEmAll* folder on it.

b. Opening a CMD terminal:
```
"C:\Program Files\LOVE\love.exe" "C:\games\ShootEmAll"
```
