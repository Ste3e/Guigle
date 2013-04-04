module Guigle.Editor;

//          Copyright Stephen Jones 2013.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

import std.stdio;
import std.string;
import std.conv;
import std.file;
import std.array;
import derelict.opengl3.gl3;
import derelict.sdl2.sdl;
import derelict.sdl2.image;
import derelict.sdl2.ttf;

import Guigle.Global;

class Editor{
	private Global dat;
	private int maxWidth;
	private string current;
	private int wordPtr = 0, charPtr = 0, linePtr = 0;

	package string eText = "";
	package string[] lines;

	package this(Global dat, int maxWidth){
		this.dat = dat;
		this.maxWidth = maxWidth;
	}

	public void add(string s){
		if(s == "enter"){
			eText.strip();
			lines ~= eText;
			eText = "";
			wordPtr = charPtr = 0;
			return;
		}
		if(s == "space"){
			int w, h;
			TTF_SizeText(dat.font, eText.toStringz, &w, &h);
			if(w > maxWidth){
				string line = (eText[0..wordPtr]);
				line.strip();
				lines ~= line;
				eText = eText[wordPtr .. eText.length];
				eText.strip();
				eText ~= " ";
				wordPtr = charPtr = eText.length;
				return;
			}

			eText ~= " ";
			wordPtr = charPtr;
			charPtr ++;
			return;
		}
		if(s == "backspace"){
			if(eText.length > 1){
				eText.popBack();
				charPtr --;
				return;
			}else{
				if(lines.length == 0) return;
				eText = lines[lines.length - 1];
				eText.popBack();
				wordPtr = charPtr = eText.length;
				lines = lines[0 .. lines.length -1];
				return;
			}
		}
		if(s == "period"){
			eText ~= ".";
		
		}else{
			eText ~= s;
		}
		charPtr ++;
	}
	public void addWord(string s){
		string tmp = eText ~ " " ~ s;
		int w, h;
		TTF_SizeText(dat.font, tmp.toStringz, &w, &h);
		if(w > maxWidth){
			string line = eText;
			line.strip();
			lines ~= line;
			eText = s;
		}else{
			eText = tmp;
		}

	}

	public string getText(){
		string toret;

		foreach(string s; lines){
			toret ~= s ~= " ";
		}
		toret ~= eText;

		return strip(toret);
	}
}

