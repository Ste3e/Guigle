module Guigle.DropMenu;

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
import Guigle.MenuItem;

class DropMenu{
	private static menuCount = 0;
	private Global dat;
	private MenuItem menuItem;
	private int id, event;
	private void delegate(int event, int id, string arg) dgExt;
	private void delegate(string arg) dgLocal;
	private float sx, sy, sw, sh;
	private int wx, wy, ww, wh, xoff, yoff;
	private int minx, maxx, miny, maxy;
	private uint col, colOver;  
	private bool empty = true;

	package string eText;
	package string[] items;
	package int eId;
	package int vertStart, vertCount=6;
	package uint tid;
	
	package this(void delegate(int event, int id, string arg) dg, int eId, string style, string[] items){
		this.id = menuCount++;
		this.dgExt = dg;
		this.eId = eId;
		this.event = -1;
		this.items = items;
		dat = Global.getInstance();
		menuItem = MenuItem.getInstance();

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

		getTexture();
	}
	
	private void getTexture(){
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

		string a = "a";
		SDL_Surface *arrow = TTF_RenderText_Blended(dat.dings, a.toStringz, dat.fontColor);
		assert(arrow!=null);
		SDL_Rect r;
		r.x=base.w - arrow.w;
		r.y=yoff;
		r.w=arrow.w;
		r.h=arrow.h;
		SDL_BlitSurface(arrow, null, base, &r);
		SDL_BlitSurface(arrow, null, base, &r);
		
		if(eText == "") eText = " ";
		SDL_Surface *stext = TTF_RenderText_Blended(dat.font, eText.toStringz, dat.fontColor);
		assert(stext!=null);
		r.x=xoff;
		r.y=yoff;
		r.w=stext.w;
		r.h=stext.h;
		SDL_BlitSurface(stext, null, base, &r);
		SDL_BlitSurface(stext, null, base, &r);
	

		glPixelStorei(GL_UNPACK_ALIGNMENT, 4);
		tid=0;
		glGenTextures(1, &tid);
		assert(tid > 0);
		glBindTexture(GL_TEXTURE_2D, tid);
		
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
		
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, base.w, base.h, 0, GL_RGBA, GL_UNSIGNED_BYTE, base.pixels);
		
		glBindTexture(GL_TEXTURE_2D, 0);
		SDL_FreeSurface(stext);
		SDL_FreeSurface(base);
	}
	
	public void getData(ref float[] v, ref float[] c, ref int offset){
		vertStart=offset;
		offset+=vertCount;	
		
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
	}
	public void handlePick(string selected){
		eText = selected;
		getTexture();
		dgExt(eId, id, eText);
	}
	public void isOver(int x, int y, bool clicked){
		if((x < minx) || (y < miny) || (x > maxx) || (y > maxy)){

		}else{
			if(clicked){
				menuItem.build(&handlePick, wx, ww, wy, wh, items);
			}
		}

	}	
	public void close(){
		tid = 0;
		glDeleteTextures(1, &tid);
	}
	

}

