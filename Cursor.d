module Guigle.Cursor;

//          Copyright Stephen Jones 2013.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

import std.stdio;
import std.string;
import std.conv;
import std.file;
import std.array;
import derelict.sdl2.sdl; 
import derelict.sdl2.image; 
import derelict.opengl3.gl3; 

import Guigle.GuiShader;
import Guigle.Global;

class Cursor{
	private Global dat;
	private GuiShader shader;
	private float sizew, sizeh;
	private float posx = 0.0, posy = 0.0;
	private uint vao;
	private uint stdCursor, textCursor, cursor;
	private bool hide=false;
	private int minx, maxx, miny, maxy;

	public bool text = false;
	public int mousex = 0, mousey = 0;
	public int vertStart = 0, vertCount = 6;


	public this(int size, GuiShader shader){
		this.shader = shader;
		this.dat = Global.getInstance();
		this.sizew = dat.unitw * size;
		this.sizeh = dat.unith * size;
		int halfwidth = cast(int)(dat.width / 2);
		int halfheight = cast(int)(dat.height / 2);
		this.minx = -halfwidth;
		this.maxx = halfwidth - cast(int)(size / 2);
		this.miny = -halfheight;
		this.maxy = halfheight - cast(int)(size / 2);
		stdCursor = getTexture("blackPoint.png");
		textCursor = getTexture("blackText.png");
		cursor = stdCursor;
		buildCursor();
	}

	public uint getTexture(string img){
		string filepath=dat.imgPath ~ img;
		assert(exists(filepath));
		SDL_Surface *base=IMG_Load(filepath.ptr);
		assert(base);
		
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
		SDL_FreeSurface(base);
		
		return tid;
	}

	private void buildCursor(){
		int x=0, y=0;
		float[] v, c;
		v~=x; v~=y; v~=-1.0;
		v~=x + sizew; v~=y; v~=-1.0;
		v~=x + sizew; v~=y + sizeh; v~=-1.0;
		
		v~=x; v~=y; v~=-1.0;
		v~=x + sizew; v~=y + sizeh; v~=-1.0;
		v~=x; v~=y + sizeh; v~=-1.0;
		
		c~=0.0; c~=1.0;
		c~=1.0; c~=1.0;
		c~=1.0; c~=0.0;
		
		c~=0.0; c~=1.0;
		c~=1.0; c~=0.0;
		c~=0.0; c~=0.0;
		
		uint vbov, vboc;
		
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
	public void hideCursor(bool status){
		hide=status;
	}
	public void togleCursor(){
		if(cursor == stdCursor){
			cursor = textCursor;
			text = true;
		}else{
			cursor = stdCursor;
			text = false;
		}	
	}
	public void update(int xm, int ym){
		int newx = this.mousex - xm;
		if(newx > minx && newx < maxx){
			this.mousex = newx;
			posx -= xm * dat.unitw;
		}

		int newy = this.mousey + ym;
		if(newy > miny && newy < maxy){
			this.mousey = newy;
			posy += ym * dat.unith;
		}
	}
	public void quit(){
		glDeleteTextures(1, &stdCursor);
		glDeleteTextures(1, &textCursor);
		glDeleteVertexArrays(1, &vao);
	}

	public void draw(){
		if(hide) return;
		glBindVertexArray(vao);
		glActiveTexture(GL_TEXTURE0); 
		
		glUniform3f(shader.datLoc, posx, posy, 1.0);
		glBindTexture(GL_TEXTURE_2D, cursor);
		glDrawArrays(GL_TRIANGLES, vertStart, vertCount); 
		glBindTexture(GL_TEXTURE_2D, 0);
		
		glUniform3f(shader.datLoc, posx, posy, 0.0);
		glBindVertexArray(0);
	}
}
