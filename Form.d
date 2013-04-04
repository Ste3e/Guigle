module Guigle.Form;

//          Copyright Stephen Jones 2013.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

import derelict.sdl2.sdl; 
import derelict.sdl2.image; 
import derelict.sdl2.ttf;
import derelict.opengl3.gl3;


pragma(lib, "DerelictUtil.lib"); 
pragma(lib, "DerelictSDL2.lib"); 
pragma(lib, "DerelictGL3.lib"); 

import std.stdio;

import Guigle.Keys;
import Guigle.Global;
import Guigle.GuiShader;
import Guigle.Cursor;
import Guigle.Pane;
import Guigle.MenuItemSingle;
import Guigle.MsgBoxSingle;
import Guigle.EntryBoxSingle;
import Guigle.FileChooserSingle;
import Guigle.FileSaverSingle;

class Form{
	private MenuItem menuItem;
	private MsgBox msgBox;
	private EntryBox entryBox;
	private FileChooser fileChooser;
	private FileSaver fileSaver;
	private Keys keys;
	private int width, height, halfw, halfh;
	private static SDL_Window *win;
	private static SDL_GLContext context;
	private bool running=true;
	private GLVersion glVersion;
	private int mousex, mousey;
	private float red, green, blue;
	private GuiShader shader;
	private bool leftMouse=false;

	protected Cursor cursor;
	protected Global global;
	public Pane pane;

	public this(int width, int height, ubyte r, ubyte g, ubyte b, void delegate() start){
		this.width = width;
		this.height = height;
		this.halfw = cast(int)(width * 0.5);
		this.halfh = cast(int)(height * 0.5);
		this.red = cast(float)(r) / 255f; 
		this.green = cast(float)(g) / 255f; 
		this.blue = cast(float)(b) / 255f;
		bool ok = true;

		try{ 
			DerelictSDL2.load(); 
		}catch(Exception e){ 
			writeln("Error loading SDL2 lib", e); 
			ok = false;
		} 
		try{ 
			DerelictGL3.load(); 
		}catch(Exception e){ 
			writeln("Error loading GL3 lib", e); 
			ok = false;
		} 
		try{ 
			DerelictSDL2Image.load(); 
		}catch(Exception e){ 
			writeln("Error loading SDL image lib ", e); 
			ok = false;
		}
		try{
			DerelictSDL2ttf.load();
		}catch(Exception e){
			writeln("Error loading TTF lib", e); 
			ok = false;
		}
		assert(ok);//SDL 2 and GL3 must load!

		buildWindow();

		global = Global.getInstance();
		global.width = width;
		global.height = height;
		global.unitw = 2.0 / cast(float)width;
		global.unith = 2.0 / cast(float)height;
		global.halfw = cast(float)(width * 0.5);
		global.halfh = cast(float)(height * 0.5);
		global.bgColor = SDL_Color(r, g, b, 255);
		menuItem = MenuItem.getInstance();
		msgBox = MsgBox.getInstance();
		entryBox = EntryBox.getInstance();
		fileChooser = FileChooser.getInstance();
		fileSaver = FileSaver.getInstance();
		keys = new Keys();

		shader = new GuiShader();
		cursor = new Cursor(24, shader); 

		SDL_WarpMouseInWindow(win, halfw, halfh);
		SDL_ShowCursor(SDL_DISABLE);
		start();


		while(running){
			glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
			draw();
			pollEvents();

			cursor.update(mousex, mousey);

			glEnable(GL_BLEND);
			glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
			glUseProgram(shader.shad);

			pane.update(leftMouse);
			pane.draw();

			entryBox.draw(cursor.mousex, cursor.mousey, leftMouse);
			fileChooser.draw(cursor.mousex, cursor.mousey, leftMouse);
			fileSaver.draw(cursor.mousex, cursor.mousey, leftMouse);
			menuItem.draw(cursor.mousex, cursor.mousey, leftMouse);
			msgBox.draw(cursor.mousex, cursor.mousey, leftMouse);
			cursor.draw();
			
			glUseProgram(0);
			glDisable(GL_BLEND);

			SDL_WarpMouseInWindow(win, halfw, halfh);
			SDL_GL_SwapWindow(win);
			leftMouse = false;
		}
		SDL_GL_DeleteContext(context);
		SDL_DestroyWindow(win);
		SDL_Quit();
	}
	public void dummyBackground(ubyte r, ubyte g, ubyte b){
		global.bgColor = SDL_Color(r, g, b, 255);
	}
	private void buildWindow(){
		assert(SDL_Init(SDL_INIT_VIDEO) > -1);	
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 2);
		SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);
		SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 2);
		SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
		
		resize(width, height);
	}
	private void resize(int w, int h){
		glViewport(0, 0, w, h);
		
		int flags=SDL_WINDOW_OPENGL | SDL_WINDOW_BORDERLESS | SDL_WINDOW_SHOWN;
		win=SDL_CreateWindow("3Doodle", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, w, h, flags);
		if(!win){
			writefln("Error creating SDL window");
			SDL_Quit();
		}
		
		context=SDL_GL_CreateContext(win);
		SDL_GL_SetSwapInterval(1);
		
		glVersion=DerelictGL3.reload();
		glEnable(GL_DEPTH_TEST);
		glEnable(GL_CULL_FACE);
		
		glDepthFunc(GL_LEQUAL);
		
		glClearColor(red, green, blue, 1.0);
		glClearDepth(1.0);
		
		glCullFace(GL_BACK);
		glFrontFace(GL_CCW);	
	}
	public void quit(){
		running = false;
	}
	protected void draw(){}
	private void pollEvents(){
		SDL_Event e;
		bool caps = false;

		while(SDL_PollEvent(&e) == 1){
			switch(e.type){
				case SDL_KEYDOWN:
					if(e.key.keysym.mod == KMOD_CAPS || e.key.keysym.mod == KMOD_RSHIFT || e.key.keysym.mod == KMOD_LSHIFT){
						caps = true;
					}
					if(e.key.keysym.sym == SDLK_ESCAPE) running=false;
					pane.updateKey(keys.getKey(e.key.keysym.sym, caps));
					break;
				case SDL_MOUSEBUTTONDOWN:
					if(e.button.button==SDL_BUTTON_LEFT) leftMouse=true;
					if(e.button.button==SDL_BUTTON_RIGHT) writeln("Using an object");
					break;
				case SDL_MOUSEMOTION:
					mousex=halfw - e.motion.x;
					mousey=halfh - e.motion.y;
					break;
				default:
					break;
			}
		}
	}
}

