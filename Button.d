module Guigle.Button;

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

class Button{
	private static buttonCount = 0;
	private Global dat;
	private int id, event;
	private void delegate(int event, int id, string arg) dgExt;
	private bool over=false;
	private string eText = "";
	private float sx, sy, sw, sh;
	private int wx, wy, ww, wh, xoff, yoff;
	private int minx, maxx, miny, maxy;
	private uint col, colOver;  

	package int eId;
	package int vertStart, vertCount=6;
	package uint tid;

	package this(void delegate(int event, int id, string arg) dg, int eId, string style){
		this.id = buttonCount++;
		this.dgExt = dg;
		this.eId = eId;
		this.event = -1;
		dat = Global.getInstance();

		int xorig, yorig;
		string[] data = split(style);
		foreach(string s; data){
			if(startsWith(s, "text:"))eText = to!(string)(text(chompPrefix(s, "text:")));
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

		col=getTexture(false);
		colOver=getTexture(true);
		tid = col;
	}

	private uint getTexture(bool isOver){
		SDL_Surface *base=SDL_CreateRGBSurface(0, ww, wh, 32, 0, 0, 0, 0);
		assert(base);
		if(isOver){
			SDL_FillRect(base, null, SDL_MapRGBA(dat.fmt, dat.overColor.r, dat.overColor.g, dat.overColor.b, dat.overColor.unused));
		}else{
			SDL_FillRect(base, null, SDL_MapRGBA(dat.fmt, dat.buttonColor.r, dat.buttonColor.g, dat.buttonColor.b, dat.buttonColor.unused));
		}	
		
		SDL_Surface *frm=SDL_CreateRGBSurface(0, ww, wh, 32, 0, 0, 0, 0);
		assert(frm);
		SDL_FillRect(frm, null, SDL_MapRGBA(dat.fmt, dat.frameColor.r, dat.frameColor.g, dat.frameColor.b, dat.frameColor.unused));
		SDL_Rect fr;
		fr.x=0; fr.y=0; fr.w=dat.frameWidth; fr.h=frm.h;
		SDL_BlitSurface(frm,&fr, base, null);
		fr.w=frm.w; fr.h=dat.frameWidth;
		SDL_BlitSurface(frm, &fr, base, null);

		if(eText == "") eText = " ";
		SDL_Surface *stext = TTF_RenderText_Blended(dat.font, eText.toStringz, dat.fontColor);
		assert(stext!=null);

		SDL_Rect r;
		r.x=xoff;
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

	public int isOver(int x, int y, bool clicked){
		if((x < minx) || (y < miny) || (x > maxx) || (y > maxy)){//not in
			if(over){
				over=false;
				tid=col;
			}
			return 0;
		}	
		//is over
		if(!over){
			over=true;
			tid=colOver;
			return 1;
		}		
		if(over){
			if(clicked){
				dgExt(eId, id, eText);
			}
		}
		return 0;
	}	

	public void close(){
		glDeleteTextures(1, &col);
		glDeleteTextures(1, &colOver);
		tid = 0;
	}
}

