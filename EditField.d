module Guigle.EditField;

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

class EditField{
	private static editCount = 0;
	private Global dat;
	private int id, event;
	private void delegate(int event, int id, string arg) dgExt;
	private bool typing = false;
	private float x, y, w, h;
	private int width, height, xoff, yoff;
	private int minx, maxx, miny, maxy;

	package string eText = "";
	package int eId;
	package int vertStart, vertCount=6;
	package uint tid;
	
	package this(void delegate(int event, int id, string arg) dg, int eId, string style){
		this.id = editCount++;
		this.dgExt = dg;
		this.eId = eId;
		this.event = -1;
		dat = Global.getInstance();
		
		int xorig, yorig;
		string[] data = split(style);
		foreach(string s; data){
			if(startsWith(s, "x:"))xorig=to!(int)(text(chompPrefix(s, "x:")));
			if(startsWith(s, "y:"))yorig=to!(int)(text(chompPrefix(s, "y:")));
			if(startsWith(s, "w:"))width=to!(int)(text(chompPrefix(s, "w:")));
			if(startsWith(s, "h:"))height=to!(int)(text(chompPrefix(s, "h:")));
			if(startsWith(s, "xoff:"))xoff=to!(int)(text(chompPrefix(s, "xoff:")));
			if(startsWith(s, "yoff:"))yoff=to!(int)(text(chompPrefix(s, "yoff:")));
		}
		xorig -= dat.halfw;
		yorig -= dat.halfh;
		minx = xorig - 10;
		maxx = xorig + width -10;
		miny = yorig - 25;
		maxy = yorig + height - 25;
		x = xorig * dat.unitw;
		y = yorig * dat.unith;
		w = width * dat.unitw;
		h = height * dat.unith;
		
		tid=getTexture();
	}
	
	private uint getTexture(){
		SDL_Surface *base=SDL_CreateRGBSurface(0, width, height, 32, 0, 0, 0, 0);
		assert(base);
		SDL_FillRect(base, null, SDL_MapRGBA(dat.fmt, dat.editColor.r, dat.editColor.g, dat.editColor.b, dat.editColor.unused));
		
		SDL_Surface *frm=SDL_CreateRGBSurface(0, width, height, 32, 0, 0, 0, 0);
		assert(frm);
		SDL_FillRect(frm, null, SDL_MapRGBA(dat.fmt, dat.frameColor.r, dat.frameColor.g, dat.frameColor.b, dat.frameColor.unused));
		SDL_Rect fr;
		fr.x=0; fr.y=0; fr.w=dat.frameWidth; fr.h=frm.h;
		SDL_BlitSurface(frm,&fr, base, null);
		fr.w=frm.w; fr.h=dat.frameWidth;
		SDL_BlitSurface(frm, &fr, base, null);

		if(eText == "") { eText = " "; }//TTF don't building nothing 
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
		
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, base.w, base.h, 0, GL_RGBA, GL_UNSIGNED_BYTE, flip(base).pixels);
		
		glBindTexture(GL_TEXTURE_2D, 0);
		SDL_FreeSurface(stext);
		SDL_FreeSurface(base);
		
		return tid;
	}
	private SDL_Surface* flip(SDL_Surface* sfc)
	{
		SDL_Surface* result = SDL_CreateRGBSurface(sfc.flags, sfc.w, sfc.h,
		                                           sfc.format.BytesPerPixel * 8, sfc.format.Rmask, sfc.format.Gmask,
		                                           sfc.format.Bmask, sfc.format.Amask);
		ubyte* pixels = cast(ubyte*) sfc.pixels;
		ubyte* rpixels = cast(ubyte*) result.pixels;
		uint pitch = sfc.pitch;
		uint pxlength = pitch*sfc.h;
		assert(result != null);
		
		for(uint line = 0; line < sfc.h; ++line) {
			uint pos = line * pitch;
			rpixels[pos..pos+pitch] = 
				pixels[(pxlength-pos)-pitch..pxlength-pos];
		}
		
		return result;
	}
	
	public void getData(ref float[] v, ref float[] c, ref int offset){
		vertStart=offset;
		offset+=vertCount;	
		
		v~=x; v~=y; v~=-1.0;
		v~=x + w; v~=y; v~=-1.0;
		v~=x + w; v~=y + h; v~=-1.0;
		
		v~=x; v~=y; v~=-1.0;
		v~=x + w; v~=y + h; v~=-1.0;
		v~=x; v~=y + h; v~=-1.0;
		
		c~=0.0; c~=0.0;
		c~=1.0; c~=0.0;
		c~=1.0; c~=1.0;
		
		c~=0.0; c~=0.0;
		c~=1.0; c~=1.0;
		c~=0.0; c~=1.0;
	}
	
	public void isOver(int x, int y, bool clicked){
		if((x < minx) || (y < miny) || (x > maxx) || (y > maxy)){//not in
			if(typing && clicked){
				typing = false;
				dgExt(eId, id, strip(eText));
				return;
			}
		}else if(clicked && !typing){
			typing = true;
			dgExt(eId, id, ""); 	
		}
	}
	public void updateText(string newText){
		if(newText == "space"){
			newText = " ";
		}
		if(newText == "enter"){
			typing = false;
			eText = strip(eText);
			dgExt(eId, id, eText);
			return;
		}
		if(newText=="backspace"){
			if(eText.length > 1){
				eText.popBack();
			}else{
				eText=" ";
			}	
		}else{
			if(newText=="period"){
				eText = eText ~ ".";
			}else{
				eText = eText ~ newText;
			}			
		}		
		glDeleteTextures(1, &tid);
		tid = getTexture();
	}
	public void displayText(string text){
		eText = text;
		glDeleteTextures(1, &tid);
		tid = getTexture();
	}
	public void close(){
		glDeleteTextures(1, &tid);
		tid = 0;
	}
}

