Bin2D
=====

A Command line application that produces D module files, which can be compiled into an executable and extracted at startup.

## Features:

- Limit code generated by:
	- package modifier
	- ``version(unittest)``
- Option for enum for usage at compile time, instead of ``const(ubyte[])``
- Automatic finding/inclusion of files in folders.
- Outputs included files at runtime to a specified directory or temporary directory
    - __Warning extra files in specified folder will be removed__

## Known limitations
- Does not allow for filenames used in different directories

## Basic usage:
Basic usage is as follows
```Bin2D <output file>[=<module name>] <files or directories...>```

**Example**
I have a tkd project that I want to pack up into a single executable.
I need some files and dll's for it to work.

Folder of needed stuff:

![Folder of needed stuff](images/ProjectFolder1.PNG)

I added the Bin2d.exe to my path for convience.

![The process](images/Bin2D_example.gif)

```Bin2D MODULE.d=Resource_Reference library tk86t.dll tcl86t.dll "my tkd app.exe" ```

Create this(MAIN.d) file and added to my C:\temp folder.
```D
import std.stdio;
import std.process;
import PKG = Resource_Reference;

void main() {
    string[string] FILE_LOCATIONS = PKG.outputFilesToFileSystem();
    
    foreach(string key; PKG.originalNames){
          writeln("extracting: ", key , " : " , FILE_LOCATIONS[key] );
    }
    execute(FILE_LOCATIONS["my tkd app.exe"]);
    PKG.cleanup();
}
```
Compile with:

```dmd MAIN.d MODULE.d```

If you want to do what I did with a gui app you might want to link to windows:subsystem.
## But what if I don't know the name at compile time?
To get access to *all* the values with names you need to iterate over two seperate arrays.
The first ``names`` will give you the mangled names. The second ``values`` will give you the values based upon the index in assetNames.

## So how do you extract?

This will extract any files given to it. With specific output directory.
It returns an array of the file systems names with the original extension. Directories have been encoded away however.
```D
import modulename;
outputFilesToFileSystem("output/stored/here");
```

**And for a temporary directories?**
```D
import modulename;
outputFilesToFileSystem();
```
It does return the same result as output outputBin2D2FS(string) does.

## Why not string imports?
- String mixins at least on Windows are bugged. They cannot use subdirectories.
    In newer versions this should be fixed.
- Assets do not change often so regeneration process can be manual.
- Easy export to file system.
