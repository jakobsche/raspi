#raspi - Lazarus package

This package was made for and particularly tested on Raspberry Pi. The easiest way to program on Raspberry Pi with Lazarus is to install FPC and Lazarus from the packages of your distribution. 

Because such packages are often older than what I use, something might be incompatible. To get the most recent versions of the tools, learn to install them from the sources. I was successfully with downloading the sources the binaries of FPC and the sources from the original websites (freepascal.org, lazarus-ide.org) and following the instructions in the contained documents.

The easiest way to use the package is to add it to your project and use it in your source code. 

To use it in the form designer, you must install it in Lazarus. This requires to compile the Lazarus-IDE. after adding the package. After my experience that is possible, if you use a Raspberry Pi with at least 1 GB RAM and a Linux, that is not bigger than necessary, especially in RAM. I use Raspbian Lite without to start an X server or other unnecessary services for the development. Then I forward the X server of my network client with "ssh -Y ..." to run Lazarus and the produced GUI applications over the network. You can run your compiled GUI applications on every other Raspberry Pi, if it has the necessary ressources, locally or via SSH. The easiest way to check for the ressources is

- copying your compiled application to the target Raspberry Pi
- run it via SSH or in a x-terminal to see messages, if something goes wrong
- patch your Raspberry Pi to solve the problems.

If you got one application running this way, most other applications being created the same way, will run without to repeat this expense.

By the way: The package is hardware independent. So you should also be able to compile it and your applications for all computers with Linux and the necessary peripheral devices, if you can get a Free Pascal Compiler for your target system.

Good luck!
