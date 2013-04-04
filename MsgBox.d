module Guigle.MsgBoxSingle;

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

import Guigle.TextField;
import Guigle.Button;

import Guigle.Global;

class MsgBox{
	private Global dat;
	private TextField textField;
	private Button button;
	private void delegate() dgExt;
	private int offset;
	private bool hidden = true;
	private uint vao;
	private float sx, sy, sw, sh;
	private int wx, wy, ww, wh, xoff, yoff;
	private int minx, maxx, miny, maxy;
	private uint tid;
	private string eText;
	private float[] v, c;

	public void build(void delegate() dg, string msg, string style){
		this.dgExt = dg;
		this.eText = msg;
		hidden = false;

		int xorig, yorig;
		string[] data = split(style);
		foreach(string s; data){
			if(startsWith(s, "x:"))wx = to!(int)(text(chompPrefix(s, "x:")));
			if(startsWith(s, "y:"))wy = to!(int)(text(chompPrefix(s, "y:")));
			if(startsWith(s, "w:"))ww = to!(int)(text(chompPrefix(s, "w:")));
			if(startsWith(s, "h:"))wh = to!(int)(text(chompPrefix(s, "h:")));
			if(startsWith(s, "xoff:"))xoff = to!(int)(text(chompPrefix(s, "xoff:")));
			if(startsWith(s, "yoff:"))yoff = to!(int)(text(chompPrefix(s, "yoff:")));
		}
		xorig = wx - cast(int)(dat.halfw);
		yorig = wy - cast(int)(dat.halfh);
		minx = xorig - 10;
		maxx = xorig + ww -10;
		miny = yorig - 25;
		maxy = yorig + wh - 25;
		sx = xorig * dat.unitw;
		sy = yorig * dat.unith;
		sw = ww * dat.unitw;
		sh = wh * dat.unith;

		//TEXT FIELD
		int tx = wx + 50;
		int ty = wy + wh - 50;
		style=format("x:%s y:%s w:100 h:20 xoff:0 yoff:0", to!string(tx), to!string(ty));
		textField = new TextField(eText, 0, style);

		//BUTTON
		int bx = wx + ww - 150;
		int by = wy + 50;
		style = format("text:close x:%s y:%s w:100 h:20 xoff:30 yoff:0", to!string(bx), to!string(by));
		button = new Button(&handleEvent, 0, style);

		doVao();
		getTexture(); 

	}
	private void getTexture(){
		tid = 0;
		glDeleteTextures(1, &tid);
		
		SDL_Surface *base=SDL_CreateRGBSurface(0, ww, wh, 32, 0, 0, 0, 0);
		assert(base);
		SDL_FillRect(base, null, SDL_MapRGBA(dat.fmt, dat.editColor.r, dat.editColor.g, dat.editColor.b, dat.editColor.unused));
		
		SDL_Surface *frm=SDL_CreateRGBSurface(0, ww, wh, 32, 0, 0, 0, 0);
		assert(frm);
		SDL_FillRect(frm, null, SDL_MapRGBA(dat.fmt, dat.frameColor.r, dat.frameColor.g, dat.frameColor.b, dat.frameColor.unused));
		SDL_Rect fr;
		fr.x=0; fr.y=0; fr.w=dat.frameWidth; fr.h=frm.h;
		SDL_BlitSurface(frm,&fr, base, null);
		fr.w=frm.w; fr.h=dat.frameWidth;
		SDL_BlitSurface(frm, &fr, base, null);		

		glPixelStorei(GL_UNPACK_ALIGNMENT, 4);
		glGenTextures(1, &tid);
		assert(tid > 0);
		glBindTexture(GL_TEXTURE_2D, tid);
		
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
		
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, base.w, base.h, 0, GL_RGBA, GL_UNSIGNED_BYTE, base.pixels);
		
		glBindTexture(GL_TEXTURE_2D, 0);
		SDL_FreeSurface(base);
	}
	private void doVao(){
		vao = 0;
		glDeleteVertexArrays(1, &vao);
		v.clear();
		c.clear();
		uint vbov, vboc;
		
		v~=sx; v~=sy; v~=-1.0;
		v~=sx + sw; v~=sy; v~=-1.0;
		v~=sx + sw; v~=sy + sh; v~=-1.0;
		
		v~=sx; v~=sy; v~=-1.0;
		v~=sx + sw; v~=sy + sh; v~=-1.0;
		v~=sx; v~=sy + sh; v~=-1.0;
		
		c~=0.0; c~=1.0;
		c~=1.0; c~=1.0;
		c~=1.0; c~=0.0;
		
		c~=0.0; c~=1.0;
		c~=1.0; c~=0.0;
		c~=0.0; c~=0.0;

		offset = 6;
		textField.getData( v, c, offset);
		button.getData( v, c, offset);
		
		glGenVertexArrays(1, &vao); assert(vao > 0);
		glBindVertexArray(vao);
		
		glGenBuffers(1, &vbov); assert(vbov > 0);
		glGenBuffers(1, &vboc); assert(vboc > 0);
		
		glBindBuffer(GL_ARRAY_BUFFER, vbov);
		glBufferData(GL_ARRAY_BUFFER, v.length * GL_FLOAT.sizeof, v.ptr, GL_STATIC_DRAW);
		glEnableVertexAttribArray(0);
		glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, null);	
		
		glBindBuffer(GL_ARRAY_BUFFER, vboc);
		glBufferData(GL_ARRAY_BUFFER, c.length * GL_FLOAT.sizeof, c.ptr, GL_STATIC_DRAW);
		glEnableVertexAttribArray(1);
		glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 0, null);
		
		glBindBuffer(GL_ARRAY_BUFFER, 0);
		glBindVertexArray(0);
	}

	public void handleEvent(int event, int element, string data){
		hidden = true;
		dgExt();
	}
	public void draw(int mousex, int mousey, bool clicked){
		if(hidden) return;
		button.isOver(mousex, mousey, clicked);
		
		glBindVertexArray(vao);
		glActiveTexture(GL_TEXTURE0); 
		
		glBindTexture(GL_TEXTURE_2D, tid);
		glDrawArrays(GL_TRIANGLES, 0, 6);
		glBindTexture(GL_TEXTURE_2D, 0); 

		glBindTexture(GL_TEXTURE_2D, textField.tid);
		glDrawArrays(GL_TRIANGLES, textField.vertStart, textField.vertCount);
		glBindTexture(GL_TEXTURE_2D, 0); 

		glBindTexture(GL_TEXTURE_2D, button.tid);
		glDrawArrays(GL_TRIANGLES, button.vertStart, button.vertCount);
		glBindTexture(GL_TEXTURE_2D, 0); 
		
		glBindVertexArray(0);
	}
	public void close(){
		hidden = true;
	}
	public void dummyTip(int event){}

	//INSTANCE
	private static MsgBox instance;
	private this(){
		dat = Global.getInstance();
	}
	
	package static MsgBox getInstance(){
		if(instance is null){
			instance = new MsgBox();
		}
		return instance;
	} 
}

