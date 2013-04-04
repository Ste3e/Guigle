module Guigle.MenuBloc;

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

class MenuBloc{
	private static editCount = 0;
	private void delegate(int event, int id, string arg) dgExt;
	private Global dat;
	private int id, event;
	private bool typing = false;
	private float sx, sy, sw, sh;
	private int wx, wy, ww, wh, xoff, yoff;
	private int minx, maxx, miny, maxy;
	private uint[] texs;
	private string[] items;
	private int page = 0;

	package string eText = "";
	package int eId;
	package int vertStart, vertCount=6;
	package uint tid;

	package this(void delegate(int event, int id, string arg) dg, int eId, string style){
		this.dgExt = dg;
		this.id = editCount++;
		this.dgExt = dg;
		this.eId = eId;
		dat = Global.getInstance();
		
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
	}

	public void build(string[] items){
		this.items = items;
		tid = page = 0;
		foreach(uint i; texs){
			glDeleteTextures(1, &i);
		}
		texs.clear();
		int pageCount = items.length / 10;

		uint tex;
		for(int i = 0; i <= pageCount; i++){
			glGenTextures(1, &tex);
			assert(tex > 0);

			if(i == pageCount){//last page
				string[] tmp = items[page * 10 .. $];
				getTex(tmp, tex);
			}else{
				string[] tmp = items[page * 10 .. page * 10 + 10];
				getTex(tmp, tex);
			}
			page++;
		}
		page = 0;
		tid = texs[page];
	}

	private void getTex(string[] items, uint tex){
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
		
	  	SDL_Surface *stext;
		SDL_Rect r;
		int xoff = 1;
		int yoff = 0;
		int lineNo = 0;
		foreach(string l; items){
			string dir = "k";
			string label = "";
			if(endsWith(l, "f")){
				dir = "j";
				label = chop(l);
			}else{
				label = chop(l);
			}

			stext = TTF_RenderText_Blended(dat.dings, dir.toStringz, dat.fontColor);
			assert(stext!=null);
			r.x=5;
			r.y=yoff + (dat.fontHeight * lineNo);
			r.w=stext.w;
			r.h=stext.h;
			SDL_BlitSurface(stext, null, base, &r);
			SDL_FreeSurface(stext);

			label.strip();
			stext = TTF_RenderText_Blended(dat.font, label.toStringz, dat.fontColor);
			assert(stext!=null);
			r.x=30;
			r.y=yoff + (dat.fontHeight * lineNo++);
			r.w=stext.w;
			r.h=stext.h;
			SDL_BlitSurface(stext, null, base, &r);
			SDL_BlitSurface(stext, null, base, &r);	
				
			SDL_FreeSurface(stext);
		}
		
		glPixelStorei(GL_UNPACK_ALIGNMENT, 4);
		glBindTexture(GL_TEXTURE_2D, tex);

		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);

		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, base.w, base.h, 0, GL_RGBA, GL_UNSIGNED_BYTE, base.pixels);

		glBindTexture(GL_TEXTURE_2D, 0);
		SDL_FreeSurface(base);

		texs ~= tex;
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

	public void isOver(int mousex, int mousey, bool clicked){
		if(!clicked) return;
		if((mousex < minx) || (mousey < miny - dat.fontHeight) || (mousex > maxx) || (mousey > maxy)){//not in
			return;
		}
		int yloc = mousey;
		int idx = (9) - cast(int)(yloc / dat.fontHeight);

		if(idx < 10){
			int end = items.length - page * 10;
			if(idx < end){
				int i = page * 10 + idx;
			 	dgExt(eId, id, items[i]);
			}
		}
	}
	public void scrollDown(){
		if(page < texs.length - 1){
			page++;
			tid = texs[page];
		}
	}
	public void scrollUp(){
		if(page > 0){
			page--;
			tid = texs[page];
		}
	}
}
