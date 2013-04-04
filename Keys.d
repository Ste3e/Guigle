module Guigle.Keys;

//          Copyright Stephen Jones 2013.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

import std.stdio;

import derelict.sdl2.sdl;

static class Keys{
	package static string getKey(uint sym, bool caps){
		string s;
		switch(sym){
			case SDLK_0: if(caps) s=")"; else s="0"; break;
			case SDLK_1: if(caps) s="!"; else s="1"; break;
			case SDLK_2: if(caps) s="@"; else s="2"; break;
			case SDLK_3: if(caps) s="#"; else s="3"; break;
			case SDLK_4: if(caps) s="$"; else s="4"; break;
			case SDLK_5: if(caps) s="%"; else s="5"; break;
			case SDLK_6: if(caps) s="^"; else s="6"; break;
			case SDLK_7: if(caps) s="&"; else s="7"; break;
			case SDLK_8: if(caps) s="*"; else s="8"; break;
			case SDLK_9: if(caps) s="("; else s="9"; break;
				
			case SDLK_a: if(caps) s="A"; else s="a"; break;
			case SDLK_b: if(caps) s="B"; else s="b"; break;
			case SDLK_c: if(caps) s="C"; else s="c"; break;
			case SDLK_d: if(caps) s="D"; else s="d"; break;
			case SDLK_e: if(caps) s="E"; else s="e"; break;
			case SDLK_f: if(caps) s="F"; else s="f"; break;
			case SDLK_g: if(caps) s="G"; else s="g"; break;
			case SDLK_h: if(caps) s="H"; else s="h"; break;
			case SDLK_i: if(caps) s="I"; else s="i"; break;
			case SDLK_j: if(caps) s="J"; else s="j"; break;
			case SDLK_k: if(caps) s="K"; else s="k"; break;
			case SDLK_l: if(caps) s="L"; else s="l"; break;
			case SDLK_m: if(caps) s="M"; else s="m"; break;
			case SDLK_n: if(caps) s="N"; else s="n"; break;
			case SDLK_o: if(caps) s="O"; else s="o"; break;
			case SDLK_p: if(caps) s="P"; else s="p"; break;
			case SDLK_q: if(caps) s="Q"; else s="q"; break;
			case SDLK_r: if(caps) s="R"; else s="r"; break;
			case SDLK_s: if(caps) s="S"; else s="s"; break;
			case SDLK_t: if(caps) s="T"; else s="t"; break;
			case SDLK_u: if(caps) s="U"; else s="u"; break;
			case SDLK_v: if(caps) s="V"; else s="v"; break;
			case SDLK_w: if(caps) s="W"; else s="w"; break;
			case SDLK_x: if(caps) s="X"; else s="x"; break;
			case SDLK_y: if(caps) s="Y"; else s="y"; break;
			case SDLK_z: if(caps) s="Z"; else s="z"; break;
				
				//case SDLK_ENTER: s="enter"; break;
			case SDLK_BACKSPACE: s="backspace"; break;
			case SDLK_BACKSLASH: s="\\"; break;
			case SDLK_SPACE: s="space"; break;
			case SDLK_LEFTPAREN: s="["; break;
			case SDLK_RIGHTPAREN: s="]"; break;
			case SDLK_ASTERISK: s="*"; break;
			case SDLK_PLUS: s="+"; break;
			//case SDLK_COMMA: s=","; break;
			case SDLK_MINUS: s="-"; break;
			//case SDLK_PERIOD: if(caps) s=">"; else s="period"; break; 
			//case SDLK_SLASH: s="/"; break;
			case SDLK_COLON: s=":"; break;
			case SDLK_LESS: s="<"; break;
			case SDLK_GREATER: s=">"; break;
			case SDLK_QUESTION: s="?"; break;
			case SDLK_AT: s="@"; break;
			//case SDLK_LEFTBRACKET: s="["; break;
			//case SDLK_RIGHTBRACKET: s="]"; break;
			case SDLK_CARET: s="^"; break;
				
			case SDLK_KP_0: s="0"; break;
			case SDLK_KP_1: s="1"; break;
			case SDLK_KP_2: s="2"; break;
			case SDLK_KP_3: s="3"; break;
			case SDLK_KP_4: s="4"; break;
			case SDLK_KP_5: s="5"; break;
			case SDLK_KP_6: s="6"; break;
			case SDLK_KP_7: s="7"; break;
			case SDLK_KP_8: s="8"; break;
			case SDLK_KP_9: s="9"; break;
			case SDLK_KP_PERIOD: s="period"; break;
			case SDLK_KP_DIVIDE: s="/"; break;
			case SDLK_KP_MULTIPLY: s="*"; break;
			case SDLK_KP_MINUS: s="-"; break;
			case SDLK_KP_PLUS: s="+"; break;
			case SDLK_KP_ENTER: s="enter"; break;
			case SDLK_KP_EQUALS: s="="; break;
				
			case 46: if(caps) s=">"; else s="period"; break;
			case 44: if(caps) s="<"; else s=","; break;
			case 47: if(caps) s="?"; else s="/"; break;
			case 13: s="enter"; break;
			case 61: if(caps) s="+"; else s="="; break;
			case 96: if(caps) s="~"; else s="`"; break;
			case 59: if(caps) s=":"; else s=";"; break;
			case 91: if(caps) s="{"; else s="["; break;
			case 93: if(caps) s="}"; else s="]"; break;
			case 39: if(caps) s="\""; else s="'"; break;
				//case 27: s="period"; break;
				
			default:
				break;
		}
		
		return s;
	}
}