module Guigle.CheckBox;

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

class CheckBox{
	private static buttonCount = 0;
	private Global dat;
	private int id, event;
	private void delegate(int event, int id, string arg) dgExt;
	private bool over=false;
	private string eText = "";
	private float sx, sy, sw, sh;
	private int wx, wy, ww, wh, xoff, yoff;
	private int minx, maxx, miny, maxy;
	private uint unchecked, checked;  
	
	package int eId;
	package int vertStart, vertCount=6;
	package uint tid;
	
	package this(void delegate(int event, int id, string arg) dg, int eId, string style, string label){
		this.id = buttonCount++;
		this.dgExt = dg;
		this.eId = eId;
		this.event = -1;
		this.eText = label;
		dat = Global.getInstance();

		int w, h;
		TTF_SizeText(dat.font, eText.toStringz, &w, &h);
		ww = w + 30;
		wh = dat.fontHeight;
		int xorig, yorig;
		string[] data = split(style);
		foreach(string s; data){
			if(startsWith(s, "x:"))wx = to!(int)(text(chompPrefix(s, "x:")));
			if(startsWith(s, "y:"))wy = to!(int)(text(chompPrefix(s, "y:")));
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
		
		unchecked = getTexture(false);
		checked = getTexture(true);
		tid = unchecked;
	}
	
	private uint getTexture(bool isChecked){
		SDL_Surface *base=SDL_CreateRGBSurface(0, ww, wh, 32, 0, 0, 0, 0);
		assert(base);
		SDL_FillRect(base, null, SDL_MapRGBA(dat.fmt, dat.bgColor.r, dat.bgColor.g, dat.bgColor.b, dat.bgColor.unused));
				
		string ding = "";
		if(isChecked) ding = "e";
		else ding = "d";

		SDL_Surface *chec = TTF_RenderText_Blended(dat.dings, ding.toStringz, dat.fontColor);
		assert(chec!=null);		
		SDL_Rect r;
		r.x=0;
		r.y=yoff;
		r.w=chec.w;
		r.h=chec.h;
		SDL_BlitSurface(chec, null, base, &r);
		SDL_BlitSurface(chec, null, base, &r);		
		
		if(eText == "") eText = " ";
		SDL_Surface *stext = TTF_RenderText_Blended(dat.font, eText.toStringz, dat.fontColor);
		assert(stext!=null);		
		r.x=xoff + chec.w;
		r.y=yoff;
		r.w=stext.w;
		r.h=stext.h;
		SDL_BlitSurface(stext, null, base, &r);
		SDL_BlitSurface(stext, null, base, &r);		
		
		glPixelStorei(GL_UNPACK_ALIGNMENT, 4);
		uint tid=0;
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
		
		return tid;
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
	
	public void isOver(int x, int y, bool clicked){
		if(!clicked) return;
		if((x < minx) || (y < miny) || (x > maxx) || (y > maxy)){//not in
			return;
		}else{
			if(tid == unchecked){
				tid = checked;
				id = 1;
			}else{
				tid = unchecked;
				id = 0;
			}
			dgExt(eId, id, eText);
		}
	}	
	
	public void close(){
		glDeleteTextures(1, &unchecked);
		glDeleteTextures(1, &checked);
		tid = 0;
	}
}

