#!/usr/bin/env rdmd
module Bin2D;
import std.file : exists, isFile, isDir, dirEntries, SpanMode;
import std.stdio : writeln, File, SEEK_CUR, write, stdout;
import std.string : indexOf, lastIndexOf, tr;
import std.path : baseName;
import std.math : ceil;

static ubyte[4096] buffer;

int main(string[] args) {
	import std.getopt : getopt, defaultGetoptPrinter, config;
	import std.format : formattedWrite;
	import std.array : Appender;
	
	string[] originalArgs = args;
	
	string outputFile;
	string modulename;
	
	if (args.length > 2) {
		outputFile = args[1];
		if (outputFile.indexOf("=") > 0) {
			modulename = outputFile[outputFile.indexOf("=") + 1 .. $];
			outputFile = outputFile[0 .. outputFile.indexOf("=")];
		}
		
		args = args[0] ~ args[2 .. $];
	} else
		args = [args[0]];

	bool usePackage;
	bool useUnittest;
	bool useEnum;

	auto procArgs = getopt(
		args,
		"onlyPackage", "Limits the embedded files using package modifier", &usePackage,
		"onlyUnittest", "Limits the embedded files using version(unittest)", &useUnittest,
		"useEnum", "Use enum instead of const(ubyte[]) to store the data. Allows for usage at compile time but memory increase for runtime.", &useEnum
	);
	args = args[1 .. $];
	
	if (args.length > 0 && !procArgs.helpWanted) {
		File output = File(outputFile, "w");
		scope(exit) output.close;
		
		output.write("/**\n * Generated_By $(WEB, github.com/rikkimax/bin2d, Bin2D)\n",
				" * Copyright: Richard (Rikki) Andrew Cattermole 2014 - 2015\n * \n",
				" * Using_Command: ");
		foreach(arg; originalArgs) {
			output.write(arg ~ " ");
		}
		
		output.seek(-1, SEEK_CUR);
		output.write("\n * \n * Do $(I not) modify this file directly.\n");
		
		output.write(" */\nmodule ", modulename, ";\n");
		
		if (usePackage && useUnittest)
			output.write("version(unittest) package:\n");
		else if (usePackage)
			output.write("package:\n");
		else if (useUnittest)
			output.write("version(unittest):\n");

		output.write("""
import std.file : write, isDir, exists, mkdirRecurse, rmdirRecurse, tempDir;
import std.path : buildPath;
import std.process : thisProcessID;
import std.conv : text;

deprecated(\"Use outputFilesToFileSystem instead\")
alias outputBin2D2FS = outputFilesToFileSystem;

deprecated(\"Use names instead\")
alias assetNames = names;

deprecated(\"Use values instead\")
alias assetValues = values;

deprecated(\"Use originalNames instead\")
alias assetOriginalNames = originalNames;

string[string] outputFilesToFileSystem() {
	return outputBin2D2FS(buildPath(tempDir(), text(thisProcessID())));
}

string[string] outputFilesToFileSystem(string dir)
in {
	if (exists(dir)) {
		if (isDir(dir)) {
			rmdirRecurse(dir);
			mkdirRecurse(dir);
		} else {
			mkdirRecurse(dir);
		}
	} else {
		mkdirRecurse(dir);
	}
} body {
	string[string] files;
	foreach(i, name; names) {
		string realname = originalNames[i];
		files[cast(string)realname] ~= cast(string)buildPath(dir, realname);
		write(buildPath(dir, realname), *values[i]);
	}
	return files;
}\n\n""");
			
		string[] files;
		string[] filesWithoutScanDir;
		foreach (file; args) {
			if (file[$-1] == '/' || file[$-1] == '\\')
				file.length--;
			file = file.tr("\\", "/");
		
			if (exists(file)) {
				if (isFile(file)) {
					files ~= file;
					filesWithoutScanDir ~= baseName(file);
				} else if (isDir(file)) {
					foreach (entry; dirEntries(file, SpanMode.breadth)) {
						if (isFile(entry)) {
							files ~= entry.tr("\\", "/");
							filesWithoutScanDir ~= entry[file.length + 1 .. $].tr("\\", "/");
						}
					}
				}
			}
		}
		
		ushort longestFileName;
		string[] filenames;
		foreach(file; files){
			string t = file;
			if (lastIndexOf(t, "/") > 0)
				t = t[lastIndexOf(t, "/") + 1.. $];
			t = t.tr(".", "_").tr("-", "_");
			filenames ~= t;
			
			if (file.length > longestFileName)
				longestFileName = cast(ushort)file.length;
		}
		
		// write report heading
		ushort lenNames = cast(ushort)(longestFileName + 2);
		
		write("|");
		foreach(i; 0 .. (lenNames * 2) + 1)
			write("-");
		writeln("|");
		write("|");
		foreach(i; 0 .. lenNames-3)
			write(" ");
		write("REPORT");
		foreach(i; 0 .. lenNames-2)
			write(" ");
		writeln("|");
		
		write("|");
		foreach(i; 0 .. lenNames)
			write("-");
		write("|");
		foreach(i; 0 .. lenNames)
			write("-");
		writeln("|");
		stdout.flush;
		
		Appender!(char[]) dfout;
		// giant chunk of memory that should be able to hold exactly one chunk read
		// is reused, so memory use of program shouldn't be all that high
		dfout.reserve(buffer.length * 3);
		
		foreach(i, file; files) {	
			// output file contents
			if (useEnum)
				output.write("enum ubyte[] ", filenames[i] , " = x\"");
			else
				output.write("const(ubyte[]) ", filenames[i] , " = cast(const(ubyte[]))x\"");
			
			File readFrom = File(file, "rb");
			
			foreach(bytes; readFrom.byChunk(buffer)) {
				foreach(b; bytes) {
					formattedWrite(dfout, "%02x ", b);
				}
				
				output.write(dfout.data());
				dfout.clear();
			}
			
			output.seek(-1, SEEK_CUR);
			output.write("\";\n");
			
			// output report for file
			string replac = filenames[i];
			
			write('|');
			if (file.length > lenNames-2)
				write(' ', file[0 .. lenNames-2], ' ');
			else {
				foreach(j; 0 .. lenNames/2 - cast(uint)ceil(file.length / 2f) + 1)
					write(' ');
				write(file);
				foreach(j; 0 .. lenNames/2 - (file.length / 2))
					write(' ');
			}
			write('|');
			if (replac.length > lenNames - 2)
				write(' ', replac[0 .. lenNames-2], ' ');
			else {
				foreach(j; 0 .. lenNames/2 - cast(uint)ceil(replac.length / 2f) + 1)
					write(' ');
				write(replac);
				foreach(j; 0 .. lenNames/2 - (replac.length / 2))
					write(' ');
			}
			writeln('|');
			
			stdout.flush;
		}
		
		// close report table
		
		write("|");
		foreach(i; 0 .. lenNames)
			write("-");
		write("|");
		foreach(i; 0 .. lenNames)
			write("-");
		writeln("|");
		stdout.flush;
		
		// write names/originalNames/values out
		
		output.write("\n\n");
		
		if (useEnum)
			output.write("enum string[] names = [");
		else
			output.write("const(string[]) names = [");
		
		foreach(name; filenames) {
			output.write("\"", name, "\", ");
		}
		output.seek(-2, SEEK_CUR);
		output.write("];\n");
		
		if (useEnum)
			output.write("enum string[] originalNames = [");
		else
			output.write("const(string[]) originalNames = [");
		
		foreach(name; files) {
			output.write("\"", name, "\", ");
		}
		output.seek(-2, SEEK_CUR);
		output.write("];\n");
		
		if (useEnum)
			output.write("enum ubyte[]*[] values = [");
		else
			output.write("const(ubyte[]*[]) values = [");
		
		foreach(name; filenames) {
			output.write("&", name, ", ");
		}
		output.seek(-2, SEEK_CUR);
		output.write("];");
		
		return 0;
	} else {
		defaultGetoptPrinter("""
Usage: Bin2D <output file>[=<module name>] [switches] <files or directories...>
Bin2D is a resource compiler for the D programming language.
It compiles resources down to D source code.
For inclusion into a build. Later accessible given an optional module name.

Switches:"""[1 .. $], procArgs.options);

		return -1;
	}
}