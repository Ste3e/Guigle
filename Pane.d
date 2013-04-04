module Guigle.Pane;

//          Copyright Stephen Jones 2013.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

import std.stdio;
import std.algorithm;
import derelict.opengl3.gl3;
import derelict.sdl2.sdl;
import derelict.sdl2.ttf;

import Guigle.Cursor;
import Guigle.Panel;
import Guigle.Button;
import Guigle.EditField;
import Guigle.TextField;
import Guigle.TextArea;
import Guigle.EditArea;
import Guigle.DropMenu;
import Guigle.CheckBox;
import Guigle.MsgBox;
import Guigle.EntryBox;
import Guigle.FileChooser;
import Guigle.FileSaver;

class Pane{
	private Cursor cursor;
	private void delegate(int event, int id, string arg) dgExt;
	private void delegate(int event) dgTip;
	private bool hidden = true, fixed = false;
	private int vcount = 0;
	private Panel[] panels;
	private Button[] buttons;
	private EditField[] editFields;
	private TextField[] textFields;
	private TextArea[] textAreas;
	private EditArea[] editAreas;
	private DropMenu[] dropMenus; 
	private CheckBox[] checkBoxes;
	private EntryBox entryBox;
	private FileChooser fileChooser;
	private FileSaver fileSaver;
	private uint vao;
	private float[] v, c;
	private int edit, area;
	private enum to { none, edit, area, entryBox, fileSaver };
	private to keys = to.none; 

	public this(Cursor cursor, void delegate(int event, int id, string arg) dg, void delegate(int event) dgTip){
		this.cursor = cursor;
		this.dgExt = dg;
		this.dgTip = dgTip;
		entryBox = EntryBox.getInstance();
		fileChooser = FileChooser.getInstance();
		fileSaver = FileSaver.getInstance();
	}
	public void addPanel(string style){
		panels ~= new Panel(style);
	}
	public void addButton(int eId, string style){
		buttons ~= new Button(dgExt, eId, style);
		vcount += 6;
	}
	public void addTextField(string text, int eId, string style){
		textFields~=new TextField(text, eId, style);
		vcount+=6;
	}
	public void addEditField(int eventId, string style){
		editFields~=new EditField(&fieldEventHandler, eventId, style);
		vcount+=6;
	}
	public void addTextArea(int eventId, string style){
		textAreas~=new TextArea(&areaEventHandler, eventId, style);
		vcount+=6;
	}
	public void updateTextArea(int eId, string text){
		foreach(TextArea t; textAreas){
			if(t.eId == eId){
				t.updateText(text);
			}
		}
	}
	public void addEditArea(int eventId, string style){
		editAreas~=new EditArea(&areaEventHandler, eventId, style);
		vcount+=6;
	}
	public void addDropMenu(int eId, string style, string[] items){
		dropMenus ~= new DropMenu(dgExt, eId, style, items);
		vcount += 12;
	}
	public void addCheckBox(int eId, string style, string label){
		checkBoxes ~= new CheckBox(dgExt, eId, style, label);
		vcount += 6;
	}
	public void addMsgBox(string msg, string style){
		fixed = true;
		MsgBox.getInstance().build(&msgBoxEventHandler, msg, style);
	}
	public void addEntryBox(string msg, int eId, string style){
		fixed = true;
		keys = to.entryBox;
		entryBox.build(&entryBoxEventHandler, eId, msg, style, cursor);
	}
	public void addFileChooser(int eId, string style, string sufix){
		fixed = true;
		fileChooser.build(&fileChooserEventHandler, eId, style, sufix, cursor);
	}
	public void addFileSaver(int eId, string style, string sufix){
		fixed = true;
		fileSaver.build(&fileSaverEventHandler, eId, style, sufix, cursor);
		keys = to.fileSaver;
	}

	public void closePanels(){
		hidden = true;

		foreach(Panel p; panels){
			p.quit();
		}
		panels.clear();

		setVao();
		hidden = false;
	}

	public void closeButton(int eId){
		bool ok = false;
		hidden = true;
		int bid = 0;
		Button[] tmp;
		foreach(Button b; buttons){
			if(b.eId == eId){
				ok = true;
				b.close();
			}else{
				bid++;
				tmp ~= b;
			}
		}
		if(ok){
			buttons = tmp;
			vcount -= 6;
		}
		setVao();
		hidden = false;
	}
	public void closeTextField(int eId){
		bool ok = false;
		hidden = true;
		int bid = 0;
		TextField[] tmp;
		foreach(TextField b; textFields){
			if(b.eId == eId){
				ok = true;
				b.close();
			}else{
				bid++;
				tmp ~= b;
			}
		}
		if(ok){
			textFields = tmp;
			vcount -= 6;
		}
		setVao();
		hidden = false;
	}
	public void closeEditField(int eId){
		bool ok = false;
		hidden = true;
		int bid = 0;
		EditField[] tmp;
		foreach(EditField b; editFields){
			if(b.eId == eId){
				ok = true;
				b.close();
			}else{
				bid++;
				tmp ~= b;
			}
		}
		if(ok){
			editFields = tmp;
			vcount -= 6;
		}
		setVao();
		hidden = false;
	}
	public void closeTextArea(int eId){
		bool ok = false;
		hidden = true;
		int bid = 0;
		TextArea[] tmp;
		foreach(TextArea b; textAreas){
			if(b.eId == eId){
				ok = true;
				b.close();
			}else{
				bid++;
				tmp ~= b;
			}
		}
		if(ok){
			textAreas = tmp;
			vcount -= 6;
		}
		setVao();
		hidden = false;
	}
	public void closeEditArea(int eId){
		bool ok = false;
		hidden = true;
		int bid = 0;
		EditArea[] tmp;
		foreach(EditArea b; editAreas){
			if(b.eId == eId){
				ok = true;
				b.close();
			}else{
				bid++;
				tmp ~= b;
			}
		}
		if(ok){
			editAreas = tmp;
			vcount -= 6;
		}
		setVao();
		hidden = false;
	}
	public void closeDropMenu(int eId){
		bool ok = false;
		hidden = true;
		int bid = 0;
		DropMenu[] tmp;
		foreach(DropMenu b; dropMenus){
			if(b.eId == eId){
				ok = true;
				b.close();
			}else{
				bid++;
				tmp ~= b;
			}
		}
		if(ok){
			dropMenus = tmp;
			vcount -= 6;
		}
		setVao();
		hidden = false;
	}
	public void closeCheckBox(int eId){
		bool ok = false;
		hidden = true;
		int bid = 0;
		CheckBox[] tmp;
		foreach(CheckBox b; checkBoxes){
			if(b.eId == eId){
				ok = true;
				b.close();
			}else{
				bid++;
				tmp ~= b;
			}
		}
		if(ok){
			checkBoxes = tmp;
			vcount -= 6;
		}
		setVao();
		hidden = false;
	}

	public void setVao(){
		v.clear();
		c.clear();
		glDeleteVertexArrays(1, &vao);
		uint vbov, vboc;
		int offset=0;
		foreach(Panel p; panels){
			p.getData( v, c, offset);
		}
		foreach(Button b; buttons){
			b.getData( v, c, offset);
		}
		foreach(TextField tf; textFields){
			tf.getData( v, c, offset);
		}
		foreach(EditField e; editFields){
			e.getData( v, c, offset);
		}
		foreach(TextArea t; textAreas){
			t.getData( v, c, offset);
		}
		foreach(EditArea t; editAreas){
			t.getData( v, c, offset);
		}
		foreach(DropMenu dm; dropMenus){
			dm.getData( v, c, offset);
		}
		foreach(CheckBox cb; checkBoxes){
			cb.getData( v, c, offset);
		}
				
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
	public void show(){
		setVao();
		hidden=false;
	}
	public void hide(){
		hidden=true;
	}
	public void update(bool clicked){
		if(hidden) return;
		if(fixed) return;
		int ret = 0;
		foreach(Button b; buttons){
			ret = b.isOver(cursor.mousex, cursor.mousey, clicked);
			if(ret == 1) dgTip(b.eId);
		}
		foreach(EditField e; editFields){
			e.isOver(cursor.mousex, cursor.mousey, clicked);
		}
		foreach(EditArea t; editAreas){
			t.isOver(cursor.mousex, cursor.mousey, clicked);
		}
		foreach(DropMenu dm; dropMenus){
			dm.isOver(cursor.mousex, cursor.mousey, clicked);
		}
		foreach(CheckBox cb; checkBoxes){
			cb.isOver(cursor.mousex, cursor.mousey, clicked);
		}
	}
	public void updateKey(string key){
		switch(keys){
			case to.edit:
				editFields[edit].updateText(key);
				break;
			case to.area:
				editAreas[area].updateText(key);
				break;
			case to.entryBox:
				entryBox.updateText(key);
				break;
			case to.fileSaver:
				fileSaver.updateText(key);
				break;
			default:
				break;
		}
	}


	public void fileSaverEventHandler(int eId, string data){
		fixed = false;
		fileSaver.quit();
		if(data.length > 0){
			dgExt(eId, 0, data);
		}
	}
	public void fileChooserEventHandler(int eId, string data){
		fixed = false;
		fileChooser.quit();
		if(data.length > 0){
			dgExt(eId, 0, data);
		}
	}
	public void entryBoxEventHandler(int eId, string data){
		fixed = false;
		keys = to.none;
		dgExt(eId, 0, data);
	}
	public void msgBoxEventHandler(){
		fixed = false;
	}
	public void fieldEventHandler(int event, int element, string data){
		if(data.length == 0){
			cursor.togleCursor();
			edit = element;
			keys = to.edit;
		}else{
			cursor.togleCursor();
			keys = to.none;
			dgExt(event, element, data);
		}
	}
	public void areaEventHandler(int event, int element, string data){
		if(data.length == 0){
			cursor.togleCursor();
			area = element;
			keys = to.area;
		}else{
			cursor.togleCursor();
			keys = to.none;
			dgExt(event, element, data);
		}
	}

	public void draw(){
		glBindVertexArray(vao);
		glActiveTexture(GL_TEXTURE0); 

		foreach(Panel p; panels){
			glBindTexture(GL_TEXTURE_2D, p.tid);
			glDrawArrays(GL_TRIANGLES, p.vertStart, p.vertCount);
			glBindTexture(GL_TEXTURE_2D, 0); 
		}
		foreach(Button b; buttons){
			glBindTexture(GL_TEXTURE_2D, b.tid);
			glDrawArrays(GL_TRIANGLES, b.vertStart, b.vertCount);
			glBindTexture(GL_TEXTURE_2D, 0); 
		}
		foreach(TextField tf; textFields){
			glBindTexture(GL_TEXTURE_2D, tf.tid);
			glDrawArrays(GL_TRIANGLES, tf.vertStart, tf.vertCount);
			glBindTexture(GL_TEXTURE_2D, 0); 
		}
		foreach(EditField e; editFields){
			glBindTexture(GL_TEXTURE_2D, e.tid);
			glDrawArrays(GL_TRIANGLES, e.vertStart, e.vertCount);
			glBindTexture(GL_TEXTURE_2D, 0); 
		}
		foreach(TextArea t; textAreas){
			glBindTexture(GL_TEXTURE_2D, t.tid);
			glDrawArrays(GL_TRIANGLES, t.vertStart, t.vertCount);
			glBindTexture(GL_TEXTURE_2D, 0); 
		}
		foreach(EditArea t; editAreas){
			glBindTexture(GL_TEXTURE_2D, t.tid);
			glDrawArrays(GL_TRIANGLES, t.vertStart, t.vertCount);
			glBindTexture(GL_TEXTURE_2D, 0); 
		}
		foreach(DropMenu dm; dropMenus){
			glBindTexture(GL_TEXTURE_2D, dm.tid);
			glDrawArrays(GL_TRIANGLES, dm.vertStart, dm.vertCount);
			glBindTexture(GL_TEXTURE_2D, 0); 
		}
		foreach(CheckBox cb; checkBoxes){
			glBindTexture(GL_TEXTURE_2D, cb.tid);
			glDrawArrays(GL_TRIANGLES, cb.vertStart, cb.vertCount);
			glBindTexture(GL_TEXTURE_2D, 0); 
		}

		glBindVertexArray(0);
	}
}

