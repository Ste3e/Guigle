module Guigle.MenuItemSingle;

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

class MenuItem{
	private Global dat;
	private void delegate(string arg) dg;
	private bool hidden = true, virgin = true;
	private uint vao;
	private int wx, wy, ww, wh, xoff, yoff;
	private int minx, maxx, miny, maxy;
	private float sx, sy, sw, sh; 
	private enum iss { bl, br, tr, tl };
	private iss corner;
	private uint tid;
	private string[] items;
	private float[] v, c;


	public void build(void delegate(string arg) dg, int wx, int ww, int wy, int wh, string[] items){
		this.dg = dg;
		this.wx = wx; this.wy = wy; this.ww = ww; this.wh = wh;
		this.xoff = xoff; this.yoff = yoff;
		this.items = items;

		setCorners();
		doVao();
		getTexture(); 
		hidden = false;
	}

	private void setCorners(){
		int w, h;
		string longest = "";

		foreach(string s; items){
			if(s.length > longest.length){
				longest = s;
			}
		}
		TTF_SizeText(dat.font, longest.toStringz, &w, &h);

		wh = dat.fontHeight * items.length;
		if(w > ww) ww = w;
		if(wx < dat.halfw) wx = wx + ww;
		if(wx > dat.halfw) wx = wx - ww;
		if(wy > dat.halfh) wy = wy - wh + dat.fontHeight;
		wy = wy - cast(int)(dat.halfh);
		wx = wx - cast(int)(dat.halfw);

		minx = wx;
		maxx = wx + ww;
		miny = wy;
		maxy = wy + wh;

		sx = wx * dat.unitw;
		sy = wy * dat.unith;
		sw = ww * dat.unitw;
		sh = wh * dat.unith;
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
		
		
		SDL_Surface *stext;
		SDL_Rect r;
		int xoff = 1;
		int yoff = 0;
		int lineNo = 0;
		foreach(string l; items){
			l.strip();
			stext = TTF_RenderText_Blended(dat.font, l.toStringz, dat.fontColor);
			assert(stext!=null);
			r.x=5;
			r.y=yoff + (dat.fontHeight * lineNo++);
			r.w=stext.w;
			r.h=stext.h;
			SDL_BlitSurface(stext, null, base, &r);
			SDL_BlitSurface(stext, null, base, &r);	
			
			SDL_FreeSurface(stext);
		}
				
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
		v.clear();
		c.clear();
		vao = 0;
		glDeleteVertexArrays(1, &vao);
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
	private void pick(int x, int y){
		if((x < minx) || (y < miny - dat.fontHeight) || (x > maxx) || (y > maxy)){//not in
			return;
		}
		int yloc = y - miny + dat.fontHeight;
		int idx = (items.length - 1) - cast(int)(yloc / dat.fontHeight);

		dg(items[idx]);
	}

	public void draw(int mousex, int mousey, bool clicked){
		if(hidden) return;
		if((mousex < minx) || (mousey < miny - 20) || (mousex > maxx) || (mousey > maxy - 20)){//not in
			if(!virgin){
				virgin = true;
				hidden = true;
			}
		}else{
			virgin = false;
		}
		if(clicked) pick(mousex, mousey);

		glBindVertexArray(vao);
		glActiveTexture(GL_TEXTURE0); 

		glBindTexture(GL_TEXTURE_2D, tid);
		glDrawArrays(GL_TRIANGLES, 0, 6);
		glBindTexture(GL_TEXTURE_2D, 0); 

		glBindVertexArray(0);
	}
	public void close(){
		hidden = true;
	}
	//INSTANCE
	private static MenuItem instance;
	private this(){
		dat = Global.getInstance();
	}

	package static MenuItem getInstance(){
		if(instance is null){
			instance = new MenuItem();
		}
		return instance;
	} 


}

