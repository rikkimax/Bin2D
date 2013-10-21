Bin2D
=====

A tool that enables files to be compiled into an executable and extracted at startup.

## Basic usage:
Basic usage is as follows
Bin2D <output file>[=<module name>] <files or directories...>

**Example**

$ ./Bin2D output.d=awsome.app.resources.output resources/images/logo.png resources/images/pretty.jpg resources/models/animated_logo.obj
Will create a file called output.d with a model name of awsome.app.resources.output and will have:

* resources/images/logo.png
* resources/images/pretty.jpg
* resources/models/animated_logo.obj

Stored in mangled named arrays of that.

## But what if I don't know the name at compile time?
To get access to *all* the values with names you need to iterate over two seperate arrays.
The first assetNames will give you the mangled names. The second assetValues will give you the values based upon the index in assetNames.

## So how do you extract?

This will extract any files given to it. With specific output directory.
It returns an array of the file systems names with the original extension. Directories have been encoded away however.
```D
import modulename;
outputBin2D2FS("output/stored/here");
```

**And for a temporary directories?**
```D
import modulename;
outputBin2D2FS();
```
It does return the same result as output outputBin2D2FS(string) does.
