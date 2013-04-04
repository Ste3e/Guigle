module Guigle.GuiShader;

//          Copyright Stephen Jones 2013.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

import std.stdio;
import std.string;
import std.math;

import derelict.opengl3.gl3;

class GuiShader{
	package int shad;
	package int datLoc;
	package int cMapLoc;

	package this(){
		const string vcode="
		#version 330
		layout(location = 0) in vec3 pos;
		layout(location = 1) in vec2 coord;

		uniform vec3 dat;

		out vec2 coords;

		void main(void)
		{
			coords=coord.st;
			vec3 position=pos;
			if(dat.z==1.0){
				position.x+=dat.x;
				position.y+=dat.y;
			}
			
			gl_Position = vec4(position, 1.0);

		}
		";
		const string fcode="
		#version 330

		uniform sampler2D colMap;
		
		in vec2 coords;

		void main(void)
		{
			vec4 col=texture2D(colMap, coords.st);
						
			gl_FragColor=col;
		}

		";

		shad = glCreateProgram();
		assert(shad > 0);

		bool ok = true;
		int vshad = glCreateShader(GL_VERTEX_SHADER);
		assert(vshad > 0);
		const char *vptr = toStringz(vcode);
		glShaderSource(vshad, 1, &vptr, null);
		glCompileShader(vshad);
		int status, len;
		glGetShaderiv(vshad, GL_COMPILE_STATUS, &status);
		if(status == GL_FALSE){
			glGetShaderiv(vshad, GL_INFO_LOG_LENGTH, &len);
			char[] error = new char[len];
			glGetShaderInfoLog(vshad, len, null, cast(char*)error);
			writeln(error);
			ok = false;
		}
		
		int fshad = glCreateShader(GL_FRAGMENT_SHADER);
		assert(fshad > 0);
		const char *fptr = toStringz(fcode);
		glShaderSource(fshad, 1, &fptr, null);
		glCompileShader(fshad);
		glGetShaderiv(fshad, GL_COMPILE_STATUS, &status);
		if(status == GL_FALSE){
			glGetShaderiv(fshad, GL_INFO_LOG_LENGTH, &len);
			char[] error = new char[len];
			glGetShaderInfoLog(fshad, len, null, cast(char*)error);
			writeln(error);
			ok = false;
		}
		
		glAttachShader(shad, vshad);
		glAttachShader(shad, fshad);
		glLinkProgram(shad);
		glGetShaderiv(shad, GL_LINK_STATUS, &status);
		if(status == GL_FALSE){
			glGetShaderiv(shad, GL_INFO_LOG_LENGTH, &len);
			char[] error = new char[len];
			glGetShaderInfoLog(shad, len, null, cast(char*)error);
			writeln(error);
			ok = false;
		}
		assert(ok);

		datLoc = glGetUniformLocation(shad, "dat");
		if(datLoc == -1) writeln("datLoc not got");

		cMapLoc = glGetUniformLocation(shad, "cMap");
		if(cMapLoc == -1) writeln("cMapLoc not got");
		
		glUseProgram(shad);
		glUniform1i(cMapLoc, 0);
		glUseProgram(0);
	}
}

