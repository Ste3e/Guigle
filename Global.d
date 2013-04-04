module Guigle.Global;

//          Copyright Stephen Jones 2013.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)
// With the exception of code for finding the path as indicated with PATH START/END which is attributed to:
// Nick Sabalausky: http://forum.dlang.org/thread/bohuvfiuavsvcooocgym@forum.dlang.org
// Talha Zekeriya Durmuş: https://github.com/Rhodeus/Script/blob/master/Script.d

//PATH START
version(Win32)
	import std.c.windows.windows;
else version(OSX)
	private extern(C) int _NSGetExecutablePath(char* buf, uint* bufsize);
else
	import std.c.linux.linux;
//PATH END

import std.stdio;
import std.path;
import std.file;
import std.string;
import std.conv;
import std.array;
import derelict.sdl2.sdl;
import derelict.sdl2.image;
import derelict.sdl2.ttf;

class Global{
	private static Global instance;
	package string path, imgPath, fontPath, menuPath;
	package int width, height;
	package float unitw, unith, halfw, halfh;
	package int menuShuntx, menuShunty;
	package TTF_Font *font;
	package TTF_Font *dings;
	package int fontHeight;
	package SDL_PixelFormat *fmt;
	package SDL_Color bgColor, fontColor, buttonColor, overColor, editColor, frameColor;
	package int frameWidth;

	private this(){
		//PATH START
		assert(instance is null);
		auto file = new char[4*1024];
		size_t filenameLength;
		//
		version (Win32)
			filenameLength = GetModuleFileNameA(null, file.ptr, file.length-1);
		else version(OSX)
		{
			filenameLength = file.length-1;
			_NSGetExecutablePath(file.ptr, &filenameLength);
		}
		else
			filenameLength = readlink(toStringz(selfExeLink), file.ptr, file.length-1);
		//PATH END
		
		foreach(char c; file){
			path ~= c;	
		}
		while(true){
			path=chop(path);
			if(endsWith(path, "\\")){
				break;	
			}	
		}
		//this should sort out where most IDEs place their executables 
		if(endsWith(path, "bin\\Debug\\")){
			path = chomp(path, "bin\\Debug\\");	
		}else if(endsWith(path, "bin\\Release")){
			path = chomp(path, "bin\\Release\\");	
		}else if(endsWith(path, "bin\\")){
			path = chomp(path, "bin\\");	
		}

		imgPath = path ~ "Guigle\\images\\";
		fontPath = path ~ "Guigle\\fonts\\";
		menuPath = path ~ "Guigle\\images\\menuColy.png";
		assert(TTF_Init() != -1);	
		SDL_Surface *s; 
		string img=imgPath ~ "blackPoint.png";
		s=IMG_Load(img.ptr);
		assert(s);
		fmt=s.format;

		string ini = path ~ "Guigle\\layout.ini";
		string fileString = cast(string)read(ini);
		string[] lines = splitLines(fileString);
		string fontFile;
		foreach(string ing; lines){
			string str, tmp;
			str = strip(ing);
			if(startsWith(str, "font:")){
				tmp = text(chompPrefix(str, "font:"));
				fontFile = fontPath ~ tmp;
				fontFile = strip(fontFile);
				assert(exists(fontFile));
			}
			if(startsWith(str, "fontSize:")){
				tmp = text(chompPrefix(str, "fontSize:"));
				tmp = strip(tmp);
				int fontSize = to!(int)(tmp);
				font = TTF_OpenFont(fontFile.ptr, fontSize);
				assert(font !is null);
				fontHeight = TTF_FontHeight(font) + 2;
				fontFile = fontPath ~ "dings.ttf";
				dings = TTF_OpenFont(fontFile.ptr, fontSize);
				assert(dings !is null);
			}
			if(startsWith(str, "fontColor:")){
				tmp = text(chompPrefix(str, "fontColor:"));
				string[] cols = split(tmp);
				ubyte r = to!(ubyte)(cols[2]);
				ubyte g = to!(ubyte)(cols[1]);
				ubyte b = to!(ubyte)(cols[0]);
				ubyte a = 255;
				fontColor=SDL_Color(r, g, b, a);
			}
			if(startsWith(str, "buttonColor:")){
				tmp = text(chompPrefix(str, "buttonColor:"));
				string[] cols = split(tmp);
				ubyte r = to!(ubyte)(cols[0]);
				ubyte g = to!(ubyte)(cols[1]);
				ubyte b = to!(ubyte)(cols[2]);
				ubyte a = to!(ubyte)(cols[3]);
				buttonColor=SDL_Color(r, g, b, a);
			}
			if(startsWith(str, "overColor:")){
				tmp = text(chompPrefix(str, "overColor:"));
				string[] cols = split(tmp);
				ubyte r = to!(ubyte)(cols[0]);
				ubyte g = to!(ubyte)(cols[1]);
				ubyte b = to!(ubyte)(cols[2]);
				ubyte a = to!(ubyte)(cols[3]);
				overColor=SDL_Color(r, g, b, a);
			}
			if(startsWith(str, "editColor:")){
				tmp = text(chompPrefix(str, "editColor:"));
				string[] cols = split(tmp);
				ubyte r = to!(ubyte)(cols[0]);
				ubyte g = to!(ubyte)(cols[1]);
				ubyte b = to!(ubyte)(cols[2]);
				ubyte a = to!(ubyte)(cols[3]);
				editColor=SDL_Color(r, g, b, a);
			}
			if(startsWith(str, "frameColor:")){
				tmp = text(chompPrefix(str, "frameColor:"));
				string[] cols = split(tmp);
				ubyte r = to!(ubyte)(cols[0]);
				ubyte g = to!(ubyte)(cols[1]);
				ubyte b = to!(ubyte)(cols[2]);
				ubyte a = to!(ubyte)(cols[3]);
				frameColor=SDL_Color(r, g, b, a);
			}
			if(startsWith(str, "frameWidth:")){
				tmp = text(chompPrefix(str, "frameWidth:"));
				tmp = strip(tmp);
				frameWidth = to!(int)(tmp);
			}
		}
	}

	package static Global getInstance(){
		if(instance is null){
			instance = new Global();
		}
		return instance;
	}

}

