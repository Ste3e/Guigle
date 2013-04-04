module Guigle.FileSaverSingle;

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
import Guigle.EditField;
import Guigle.Button;
import Guigle.Ding;
import Guigle.DropMenu;
import Guigle.MenuBloc;

import Guigle.Global;
import Guigle.Cursor;

class FileSaver{
	private Global dat;
	private string[] drives, items, dirs, files;
	private TextField textField;
	private EditField editField;
	private Button ok;
	private Ding up, scrolld, scrollu;
	private MenuBloc bloc;
	private DropMenu driveMenu;
	private Cursor cursor;
	private void delegate(int a, string b) dgExt;
	private int eId;
	private int offset, offx, offy;
	private bool hidden = true;
	private uint vao;
	private string style;
	private float sx, sy, sw, sh;
	private int wx, wy, ww, wh, xoff, yoff;
	private int minx, maxx, miny, maxy;
	private uint tid;
	private string eText, sufix, filename;
	private float[] v, c;
	private bool virgin = true;
	private enum e {ok, drives, up, bloc, scrolld, scrollu, edit, toggleCursor }
	
	
	public void build(void delegate(int a, string b) dg, int eId, string style, string sufix, Cursor cursor){
		this.dgExt = dg;
		this.eId = eId;
		this.cursor = cursor;
		this.sufix = sufix;
		hidden = false;
		filename = "";
		
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
		
		eText = dat.path;
		getList();
		
		//TEXT FIELD
		offx = wx + 50; 
		offy = wy + wh - 50;
		style=format("x:%s y:%s w:100 h:20 xoff:0 yoff:0", to!string(offx), to!string(offy));
		textField = new TextField(eText, 0, style);

		//GO UP
		offx = wx + 50;
		offy = wy + wh - 75;
		style = format("text:h x:%s y:%s w:20 h:20 xoff:2 yoff:2", to!string(offx), to!string(offy));
		up = new Ding(&handleEvent, e.up, style);

		//EDIT FIELD
		offx = wx + ww - 200; 
		offy = wy + wh - 75;
		style=format("x:%s y:%s w:150 h:20 xoff:5 yoff:2", to!string(offx), to!string(offy));
		editField = new EditField(&handleEvent, e.edit, style);
		
		//MENU BLOC
		offx = wx + 50;
		offy = wy + wh - 320;
		int bwide = ww - 100;
		int bhigh = 10 * dat.fontHeight + 20;
		style = format("x:%s y:%s w:%s h:%s xoff:2 yoff:2", to!string(offx), to!string(offy), to!string(bwide), to!string(bhigh));
		bloc = new MenuBloc(&handleEvent, e.bloc, style);
		bloc.build(items);
		
		//SCROLL DOWN
		offx = wx + bwide + 50;
		style = format("text:b x:%s y:%s w:20 h:20 xoff:0 yoff:2", to!string(offx), to!string(offy));
		scrolld = new Ding(&handleEvent, e.scrolld, style);
		
		//SCROLL DOWN
		offx = wx + bwide + 50;
		offy = offy = wy + wh - 110;
		style = format("text:c x:%s y:%s w:20 h:20 xoff:0 yoff:2", to!string(offx), to!string(offy));
		scrollu = new Ding(&handleEvent, e.scrollu, style);
		
		//DROP MENU
		offx = wx + 50;
		offy = wy + 20;
		style = format("x:%s y:%s w:100 h:20 xoff:5 yoff:0", to!string(offx), to!string(offy));
		driveMenu = new DropMenu(&handleEvent, e.drives, style, drives); 
		
		//BUTTON
		offx = wx + ww - 150;
		offy = wy + 20;
		style = format("text:OK x:%s y:%s w:100 h:20 xoff:30 yoff:2", to!string(offx), to!string(offy));
		ok = new Button(&handleEvent, e.ok, style);
		
		doVao();
		getTexture(); 		
	}
	
	private void getList(){
		if(!endsWith(eText, "\\")){
			eText ~= "\\";
		}
		string[] list=listDir(eText);
		string[] f, d;
		
		foreach(string s; list){
			if(startsWith(s, ".")) continue;
			try{if(isDir(eText ~ s)) d ~= s ~ "d";}catch(FileException e){}finally{}
			try{
				if(isFile(eText ~ s)){
					if(sufix == "" || sufix == " "){
						f ~= s ~ "f";
					}else if(endsWith(s, sufix)){
						f ~= s ~ "f";	
					}
				} 	
			}catch(FileException e){}finally{}
		}
		
		dirs=d.dup;
		files=f.dup;
		items.clear();
		items~=dirs ~ files;
	}
	private void getTexture(){
		tid = 0;
		glDeleteTextures(1, &tid);
		
		SDL_Surface *base=SDL_CreateRGBSurface(0, ww, wh, 32, 0, 0, 0, 0);
		assert(base);
		SDL_FillRect(base, null, SDL_MapRGBA(dat.fmt, dat.bgColor.r, dat.bgColor.g, dat.bgColor.b, dat.bgColor.unused));
		
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
		up.getData( v, c, offset);
		editField.getData( v, c, offset);
		driveMenu.getData(v, c, offset);
		ok.getData( v, c, offset);
		bloc.getData( v, c, offset);
		scrolld.getData( v, c, offset);
		scrollu.getData( v, c, offset);
		
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

	public void dummyTip(int event){}
	public void handleEvent(int event, int element, string data){
		switch(event){
			case e.ok:
				string toret = "";
				if(filename.length > 0){
					toret = eText ~ filename;
				}
				dgExt(eId, toret);
				break;
			case e.drives:
				hidden = true;
				eText = data;
				offx = wx + 50; 
				offy = wy + wh - 50;
				style=format("x:%s y:%s w:100 h:20 xoff:0 yoff:0", to!string(offx), to!string(offy));
				textField = new TextField(eText, 0, style);
				getList();
				bloc.build(items);
				doVao();
				hidden = false;
				break;
			case e.up:
				if(eText.length == 3){
					return;
				}
				hidden = true;
				while(eText.length > 3){
					eText=chop(eText);
					if(endsWith(eText, "\\")){
						break;
					}
				}
				if(eText.length > 3){
					eText=chop(eText);
				}
				offx = wx + 50; 
				offy = wy + wh - 50;
				style=format("x:%s y:%s w:100 h:20 xoff:0 yoff:0", to!string(offx), to!string(offy));
				textField = new TextField(eText, 0, style);
				getList();
				bloc.build(items);
				doVao();
				hidden = false;
				break;
			case e.scrolld:
				bloc.scrollDown();
				break;
			case e.scrollu:
				bloc.scrollUp();
				break;
			case e.bloc:
				if(endsWith(data, "d")){
					eText ~= chop(data) ~ "\\";
					offx = wx + 50; 
					offy = wy + wh - 50;
					style=format("x:%s y:%s w:100 h:20 xoff:0 yoff:0", to!string(offx), to!string(offy));
					textField = new TextField(eText, 0, style);
					getList();
					bloc.build(items);
					doVao();
					hidden = false;
					return;
				}else{
					dgExt(eId, chop(data));
				}
				break;
			case e.edit:
				cursor.togleCursor();
				break;
			case e.toggleCursor:
				cursor.togleCursor();
				break;
			default:
				break;
		}
	}
	public void draw(int mousex, int mousey, bool clicked){
		if(hidden) return;
		if(!cursor.text){
			driveMenu.isOver(mousex, mousey, clicked);
			up.isOver(mousex, mousey, clicked);
			ok.isOver(mousex, mousey, clicked);
			bloc.isOver(mousex, mousey, clicked);
			scrolld.isOver(mousex, mousey, clicked);
			scrollu.isOver(mousex, mousey, clicked);
		}
		editField.isOver(mousex, mousey, clicked);
		
		glBindVertexArray(vao);
		glActiveTexture(GL_TEXTURE0); 
		
		glBindTexture(GL_TEXTURE_2D, tid);
		glDrawArrays(GL_TRIANGLES, 0, 6);
		glBindTexture(GL_TEXTURE_2D, 0); 
		
		glBindTexture(GL_TEXTURE_2D, textField.tid);
		glDrawArrays(GL_TRIANGLES, textField.vertStart, textField.vertCount);
		glBindTexture(GL_TEXTURE_2D, 0); 
		
		glBindTexture(GL_TEXTURE_2D, up.tid);
		glDrawArrays(GL_TRIANGLES, up.vertStart, up.vertCount);
		glBindTexture(GL_TEXTURE_2D, 0); 

		glBindTexture(GL_TEXTURE_2D, editField.tid);
		glDrawArrays(GL_TRIANGLES, editField.vertStart, editField.vertCount);
		glBindTexture(GL_TEXTURE_2D, 0); 
		
		glBindTexture(GL_TEXTURE_2D, driveMenu.tid);
		glDrawArrays(GL_TRIANGLES, driveMenu.vertStart, driveMenu.vertCount);
		glBindTexture(GL_TEXTURE_2D, 0); 
		
		glBindTexture(GL_TEXTURE_2D, ok.tid);
		glDrawArrays(GL_TRIANGLES, ok.vertStart, ok.vertCount);
		glBindTexture(GL_TEXTURE_2D, 0); 
		
		glBindTexture(GL_TEXTURE_2D, bloc.tid);
		glDrawArrays(GL_TRIANGLES, bloc.vertStart, bloc.vertCount);
		glBindTexture(GL_TEXTURE_2D, 0); 
		
		glBindTexture(GL_TEXTURE_2D, scrolld.tid);
		glDrawArrays(GL_TRIANGLES, scrolld.vertStart, scrolld.vertCount);
		glBindTexture(GL_TEXTURE_2D, 0); 
		
		glBindTexture(GL_TEXTURE_2D, scrollu.tid);
		glDrawArrays(GL_TRIANGLES, scrollu.vertStart, scrollu.vertCount);
		glBindTexture(GL_TEXTURE_2D, 0); 
		
		glBindVertexArray(0);
	}
	public void close(){
		hidden = true;
	}
	public void updateText(string newText){
		if(!cursor.text) return;
		if(newText == "space"){
			newText = " ";
		}
		if(newText == "enter"){
			return;
		}
		if(newText=="backspace"){
			if(filename.length > 1){
				filename.popBack();
			}else{
				filename = " ";
			}	
		}else{
			if(newText=="period"){
				filename = filename ~ ".";
			}else{
				filename = filename ~ newText;
			}			
		}		
		editField.displayText(filename);
	}
	public void quit(){
		hidden = true;
		
	}
	//INSTANCE
	private static FileSaver instance;
	private this(){
		dat = Global.getInstance();
		string[] tmp;
		try{ isDir("a:\\"); tmp~="a:\\"; }catch(FileException e){}finally{}
		try{ isDir("b:\\"); tmp~="b:\\"; }catch(FileException e){}finally{} 
		try{ isDir("c:\\"); tmp~="c:\\"; }catch(FileException e){}finally{} 
		try{ isDir("d:\\"); tmp~="d:\\"; }catch(FileException e){}finally{}
		try{ isDir("e:\\"); tmp~="e:\\"; }catch(FileException e){}finally{}
		try{ isDir("f:\\"); tmp~="f:\\"; }catch(FileException e){}finally{}
		try{ isDir("g:\\"); tmp~="g:\\"; }catch(FileException e){}finally{}
		try{ isDir("h:\\"); tmp~="h:\\"; }catch(FileException e){}finally{}
		
		drives=tmp.dup;
	}
	
	package static FileSaver getInstance(){
		if(instance is null){
			instance = new FileSaver();
		}
		return instance;
	} 
}

