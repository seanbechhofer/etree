System.security.allowInsecureDomain("*");
/*
Copyright (c) 2005, Fabricio Zuardi
All rights reserved.

Revisions by Lacy Morrow [ 2007, 2008 ] denoted by //TBB comments, and //LM

Redistribution and use in source and binary forms, with or without modification, 
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, 
  this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, 
  this list of conditions and the following disclaimer in the documentation 
  and/or other materials provided with the distribution.
    * Neither the name of the author nor the names of its contributors may be 
  used to endorse or promote products derived from this software without 
  specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT 
NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF 
THE POSSIBILITY OF SUCH DAMAGE.

Esteban Sagrero @ www.xspf-player.com

XSPF Player Bug Fixes

[Updated 02/09/2007] [VERSION 3.5]

** Fixed problem with player not stopping at last track.
** Disabled Video Playback. Can be reinstated.
** Added 2 Filters plus Color Option
** Added AutoScroll to Playlist area.
** Fixed the Resize bug. Could be customized more.
** Added Download Option via "on" and "off"

[Updated 02/23/2007] [VERSION 3.6]

** Fixed alignment of bottom controls - was off by 20 pixels
** Added ability to download or NOT download album covers 
   according to the player's mode (Slim Mode, Tall Mode, etc. . .)
   to save bandwidth that can be better used towards loading 
   audio tracks.
** Added ability to turn on or off the "Time Counter" area.
** Fixed alignment of text on bottom control area - was not centered correctly.
** Added ability to turn off album area in the URL commands, but this option is 
   only needed for when the player is set at 400 width and 170, yet the user 
   wishes not to use the album area anyways. Option does not affect automatic 
   album area removal when the player is set smaller than 334 in width via HTML, 
   less than 170 in height via HTML, and larger than 389 in height via HTML.
** Fixed a few issues with shuffle and repeat button graphics. Altered both a bit, 
   and added "ON" text to both.
** Fixed the overlay option, colors weren't showing up right.
** Adjusted the volume system to lessen distortion in Mp3s. Instead of 1 to 100 
   grading system, it will now be 1 to 50.
** Added ability to change the player's colors; this includes buttons, background, 
   and text. User might get unfavorable results using these color options with blend.
   Combine at your own artistic risk. :P
** Fixed alpha parameter interaction with bg_color parameter, also blend parameter.
** Corrected problem with Artist Info button. 
** Player can now be used in another flash document via movie container while being able 
   to adjust player height and width. See Appendix Page for details. A big thanks to 
   howard.s for pointing out the kinks.
** Tweaked time display to now show up after playlist is fully loaded.
** Corrected a problem with display_time code. Fixed a few bugs in width and height code
   for use with Flash within Flash mode.
   
[Updated 02/10/2008] [VERSION 3.7]
** Scrolling text now conforms to width of time display (saves up white space in Slim Mode).
   Time totals such as 104:00/150:04 now fit correctly.
** Added ability for player to read PHP playlist generator data such as "album" and "image" 
   straight from the mp3's ID tag. 
** Player now has ability to autoresume play after web page change or reload.
** Player can now autoscroll playlist.
** Player now uses an alternative way to buffer audio stream. Helps eliminate skipping. 
** Shuffle function has been updated. Repeat button now can repeat one track or repeat whole playlist.
** Added one second delay to begining of scrolling track text
** Changed the way the load bar and time bar appear after successful playlist loading
** Added the skin_mode feature which allows the user to make any skin for the player's HTML background
** Altered Shuffle and Repeat buttons, plus the text displayed when they are turned on
** Restored the default volume setting for player from 50, back to 100
** Player now has three modes to choose from, Normal, Small, and Mini
** Tweaked a few things with the time display and playlist counters
** Player now has more options to turn various components off such as, volume control, shuffle & repeat buttons, album, etc
** Tweaked bottom limit on scroll bar to accomadate skin option
** Fixed a bug in loading graphics, time_count bar was getting ahead of time_total and load_bar_mc

[Updated 04/05/2010] [VERSION 3.9]
** Fixed a few issues with autoresume function. Autoresume now remembers repeat & shuffle & volume status, updates more quickly, and 
   remembers pause status correctly.
** Fixed issue with loading bar not "stretching" correctly.
** Player is now pointing to new site's download location and default playlist.
** Amazon Image loader was not working due to new restrictions by Amazon. I am using last.fm image loader now.
   
[Updated 04/23/2011] [VERSION 4.0]
** Corrected info button function and display.
 
[Updated 06/04/2011] [VERSION 4.1]
** Album/Info area can now be changed to any user input text. Instead of say "Artist Info", one can replace it with "Buy CD".
** Autoplay option was not working with autoresume. Corrected autoresume functions to allow autoplay to run once during recent session.
   
*/
resumeTimeout = 60*1000;
stop();
DEFAULT_WELCOME_MSG = "XSPF MP3 Player v4.1 [06.04.11]";
local_data = null;
function defaultSettings() {
	DEFAULT_PLAYLIST_URL = "http://xspf-player.com/music/default.xspf";
	LOADING_PLAYLIST_MSG = "Loading music ... ";
	DEFAULT_LOADED_PLAYLIST_MSG = "Playlist loaded";
	DEFAULT_INFO_URL = "http://www.xspf-player.com/";
	shuffle_index = 0;
	shuffle_array = [];
	// playlists have priority over songs, if a playlist_url parameter is found the song_url is ignored
	// default playlist if none is passed through query string
	if (!playlist_url) {
		if (!song_url) {
			playlist_url = DEFAULT_PLAYLIST_URL;
		} else {
			single_music_playlist = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><playlist version=\"1\" xmlns = \"http://xspf.org/ns/0/\"><trackList>";
			single_music_playlist += "<track><location>"+song_url+"</location><annotation>"+song_title+"</annotation></track>";
			single_music_playlist += "</trackList></playlist>";
		}
	}
	// options that can be activated via url string in HTML setup                                                                                                                                                                                                                          
	if (!main_image) {
	}
	if (!info_text) {
	}
	if (!mainurl) {
		mainurl = DEFAULT_MAIN_URL;
	}
	//TBB                   
	if (autoresume == 1) {
		local_data = SharedObject.getLocal("xspf_player_data");
		local_data_good = true;
		if (!local_data.data.is_set) {
			local_data_good = false;
		}
		// One-minute limit for autoresume. Prevents autoresuming from occurring                                                         
		// when you come back to the site as part of an entirely separate
		// visit, which doesn't feel natural. Autoresume is meant as a way
		// to bridge clicks on links within the site.
		when = new Date();
		now = when.getTime();
		if (now-local_data.data.stopped_at>resumeTimeout) {
			local_data_good = false;
			local_data = null;
		} else {
			if (!playlist_url) {
				if (song_url != local_data.data.song_url) {
					local_data_good = false;
				}
			} else if (playlist_url != local_data.data.playlist_url) {
				local_data_good = false;
			}
		}
		if (local_data_good) {
			repeat = local_data.data.repeat_status;
			shuffle = local_data.data.shuffle_status;
			shuffle_index = local_data.data.shuffle_index;
			shuffle_array = local_data.data.shuffle_array;
			start_track = local_data.data.stop_track;
			start_time = local_data.data.stop_time;
			_root.volume_level = local_data.data.volume_level;
			autoresumed = true;
			// turns off autoplay after first run.
			autoplay = 1;
			songClick = 1;
		}
	}
	if (repeat === "all" || repeat == 2) {
		repeat = 2;
		information_mc.settings_mc.repeat_btn.gotoAndStop(3);
	} else if (repeat === "one" || repeat == 1) {
		repeat = 1;
		information_mc.settings_mc.repeat_btn.gotoAndStop(2);
	} else {
		repeat = 0;
		information_mc.settings_mc.repeat_btn.gotoAndStop(1);
	}
	if (shuffle == 1) {
		shuffle = 1;
		information_mc.settings_mc.shuffle_btn.gotoAndStop(1);
	} else {
		shuffle = 0;
		information_mc.settings_mc.shuffle_btn.gotoAndStop(2);
	}
	if (!start_track) {
		start_track = 1;
	} else {
		songClick = 1;
	}
	if (!volume_level) {
		volume_level = 100;
	}
	if (!buffer) {
		buffer = 1;
	}
	if (!no_info == 0) {
		information_mc.info_text_mc._visible = false;
	}
	track_index = start_track-1;
	playlist_xml = new XML();
	playlist_xml.ignoreWhite = true;
	playlist_xml.onLoad = playlistLoaded;
}
// Variables Initialization 
label_prefix = 0;
playlist_array = [];
playlist_mc.track_count = 0;
pause_position = 0;
mouseListener = new Object();
top_section_mc.time_mc._visible = false;
playlist_mc.tracks_mc._visible = false;
cover_mc.photo_load_mc._visible = false;
top_section_mc.info_mc._visible = false;
mysound = new Sound();
xmlData = new XML();
xmlData.ignoreWhite = true;
xmlData.onLoad = loadimage;
playlist_listener = new Object();
playlist_list.addEventListener("change", playlist_listener);
//
//
// Playlist Function - Loads playlist and preps data
function playlistLoaded(success) {
	if (success) {
		var root_node = this.firstChild;
		for (var node = root_node.firstChild; node != null; node=node.nextSibling) {
			if (node.nodeName == "trackList") {
				var tracks_array = [];
				var counter_array = [];
				for (var track_node = node.firstChild; track_node != null; track_node=track_node.nextSibling) {
					var track_obj = new Object();
					var counter_obj = new Object();
					// track attributes
					for (var track_child = track_node.firstChild; track_child != null; track_child=track_child.nextSibling) {
						if (track_child.nodeName == "location") {
							track_obj.location = track_child.firstChild.nodeValue;
						}
						if (track_child.nodeName == "image") {
							track_obj.image = track_child.firstChild.nodeValue;
						}
						if (track_child.nodeName == "creator") {
							track_obj.creator = track_child.firstChild.nodeValue;
						}
						if (track_child.nodeName == "title") {
							track_obj.title = track_child.firstChild.nodeValue;
						}
						if (track_child.nodeName == "annotation") {
							track_obj.annotation = track_child.firstChild.nodeValue;
						}
						if (track_child.nodeName == "type") {
							track_obj.type = track_child.firstChild.nodeValue;
						}
						if (track_child.nodeName == "info") {
							track_obj.info = track_child.firstChild.nodeValue;
						}
						if (track_child.nodeName == "playtime") {
							track_obj.counter = track_child.firstChild.nodeValue;
							counter_obj.counter = track_child.firstChild.nodeValue;
						}
					}
					track_obj.label = "";
					counter_obj.label = "";
					if (track_obj.title) {
						if (track_obj.creator) {
							track_obj.label += track_obj.creator+' - ';
						}
						track_obj.label += track_obj.title;
						counter_obj.label += counter_obj.counter;
					} else {
						track_obj.label += track_obj.annotation;
					}
					tracks_array.push(track_obj);
					counter_array.push(counter_obj);
				}
			}
		}
		if (alphabetize == 1 || alphabetize == true) {
			tracks_array.sortOn(["label"], 17);
		}
		for (i=0; i<tracks_array.length; i++) {
			addTrack(tracks_array[i].label, counter_array[i].label);
		}
		playlist_array = tracks_array;
		if (shuffle_array.length == 0) {
			for (i=0; i<playlist_array.length; i++) {
				shuffle_array.push(i);
			}
			shuffle_array = randomizeArray("shuffle_array");
		}
		if (!playlist_size) {
			playlist_size = playlist_array.length;
		}
		if (autoplay == 1) {
			mediaCheck();
		} else if (autoload == 1) {
			// will load first album cover if autoload option is on
			preloadalbum();
		}
		// make playlist visible                                                                                                                                                                                                                       
		playlist_mc.tracks_mc._visible = true;
	} else {
		top_section_mc.track_display_mc.track_text_mc.display_txt.text = "Error opening "+playlist_url;
		checkTextwidth();
	}
}
function loadimage(loaded) {
	if (loaded) {
		XMLimageURL = this.firstChild.firstChild.childNodes[9].childNodes[5].firstChild;
		if (XMLimageURL) {
			cover_mc.content_mc.createEmptyMovieClip("photo", track_index);
			cover_mc.content_mc["photo"].loadMovie(XMLimageURL);
			cover_mc.photo_load_mc.imageloadMC._visible = false;
		} else {
			cover_mc.photo_load_mc.imageloadMC.text = "IMAGE NOT FOUND";
			cover_mc.photo_load_mc.imageloadMC._visible = true;
		}
	}
}
playlist_listener.change = function(eventObject) {
	annotation_txt.text = playlist_list.selectedItem.annotation;
	location_txt.text = playlist_list.selectedItem.location;
};
//
function remItem(source, index) {
	var before = this[source].slice(0, index);
	var after = this[source].slice(index+1, this[source].length);
	this[source] = before.concat(after);
}
function randomizeArray(source) {
	var tmpArray = [];
	var arrayLength = this[source].length;
	for (var i = 0; i<arrayLength; i++) {
		var index = Math.floor(Math.random()*this[source].length);
		tmpArray[i] = this[source][index];
		remItem(source, index);
	}
	return tmpArray;
}
//
//Checks File For Data Format
function mediaCheck() {
	clearInterval(timeInterval);
	if (shuffle == 1 and repeat != 1 and songClick != 1) {
		track_index = shuffle_array[shuffle_index];
	}
	if (playlist_array[track_index].type) {
		if (playlist_array[track_index].type == "music") {
			loadTrack();
		} else if (playlist_array[track_index].type == "playlist") {
			mysound.stop();
			mysound.start();
			mysound.stop();
			playlist_url = playlist_array[track_index].location;
			for (i=0; i<playlist_mc.track_count; ++i) {
				removeMovieClip(playlist_mc.tracks_mc.track_0_mc["track_"+i+"_mc"]);
			}
			playlist_mc.track_count = 0;
			playlist_size = 0;
			track_index = 0;
			loadPlaylist();
			return (0);
		} else if (playlist_array[track_index].type == "link") {
			_root.getURL(playlist_array[track_index].location, "_blank");
		} else {
			noType();
		}
	} else {
		noType();
	}
}
//Checks File Via Extensions
function noType() {
	if (playlist_array[track_index].location.indexOf(".mp3") != -1) {
		loadTrack();
	} else if (playlist_array[track_index].location.indexOf(".xspf") != -1 or playlist_array[track_index].location.indexOf(".xml") != -1) {
		mysound.stop();
		mysound.start();
		mysound.stop();
		playlist_url = playlist_array[track_index].location;
		for (i=0; i<playlist_mc.track_count; ++i) {
			removeMovieClip(playlist_mc.tracks_mc.track_0_mc["track_"+i+"_mc"]);
		}
		playlist_mc.track_count = 0;
		playlist_size = 0;
		track_index = 0;
		loadPlaylist();
		return (0);
	} else if (gotoany == 1 || gotoany == true) {
		_root.getURL(playlist_array[track_index].location, "_blank");
	} else {
		loadTrack();
	}
}
//Loads Mp3 And Various Funtions To Player
function loadTrack() {
	// autoscroll playlist              
	autoScroll();
	// makes playlist visible after loading is done
	playlist_mc.tracks_mc._visible = true;
	// makes cover text visible after loading is done
	cover_mc.photo_load_mc._visible = true;
	// makes info icon visible in Slim Mode only
	mysound.stop();
	mysound.start();
	mysound.stop();
	songClick = 0;
	playlist_mc.tracks_mc.track_0_mc["track_"+track_index+"_mc"].bg_mc.gotoAndStop(2);
	// sets user auto color for playlist area
	auto_color();
	start_btn_mc.start_btn._visible = false;
	// sets buffer to zero, in order to use alternate buffer method
	_soundbuftime = 0;
	mysound.loadSound(playlist_array[track_index].location, true);
	mysound.stop();
	// alternate buffering method, eliminates skipping
	total_time = null;
	//
	//
	top_section_mc.play_mc.gotoAndStop(2);
	top_section_mc.time_mc.onEnterFrame = function() {
		if (total_time<(buffer+4) && Math.round(total_time)>buffer) {
			// buffering . . . 
			if (autoresumed == true) {
				if (local_data.data.stopped == false) {
					mysound.start(start_time);
					start_time = 0;
				} else {
					stopTrack();
					start_time = 0;
				}
				if (local_data.data.paused) {
					pause_position = local_data.data.pause_position;
					mysound.stop();
					top_section_mc.play_mc.gotoAndStop(1);
					start_time = 0;
				}
				delete top_section_mc.time_mc.onEnterFrame;
			} else {
				local_data.data.stopped = false;
				mysound.start();
				delete top_section_mc.time_mc.onEnterFrame;
			}
		} else if (total_time>(buffer+4)) {
			//buffered
			if (autoresumed == true) {
				if (local_data.data.stopped == false) {
					mysound.start(start_time);
					start_time = 0;
				} else {
					stopTrack();
					start_time = 0;
				}
				if (local_data.data.paused) {
					pause_position = local_data.data.pause_position;
					mysound.stop();
					top_section_mc.play_mc.gotoAndStop(1);
					start_time = 0;
				}
				delete top_section_mc.time_mc.onEnterFrame;
			} else {
				local_data.data.stopped = false;
				// allows autoplay to be used once during current session
				mysound.start();
				delete top_section_mc.time_mc.onEnterFrame;
			}
		}
	};
	cover_mc.photo_load_mc.imageloadMC.text = "LOADING ALBUM COVER";
	cover_mc.photo_load_mc.imageloadMC._visible = true;
	if (main_image) {
		cover_mc.content_mc.createEmptyMovieClip("photo", track_index);
		cover_mc.content_mc["photo"].loadMovie(main_image);
	} else {
		cover_mc.content_mc["photo"].removeMovieClip();
		// get image info from file or seek image from last.fm
		if (playlist_array[track_index].image != undefined) {
			cover_mc.content_mc.createEmptyMovieClip("photo", track_index);
			cover_mc.content_mc["photo"].loadMovie(playlist_array[track_index].image);
		} else if (album_xml_jpg_data == false) {
		} else {
			xmlData.load("http://ws.audioscrobbler.com/2.0/?method=track.getinfo&api_key=b25b959554ed76058ac220b7b2e0a026&artist="+playlist_array[track_index].creator+"&track="+playlist_array[track_index].title+"");
		}
	}
	// info button                             
	if (playlist_array[track_index].info != undefined) {
		if (info_text) {
			information_mc.info_text_mc.player_info_text.text = info_text;
		} else {
			information_mc.info_text_mc.player_info_text.text = "ARTIST INFO";
		}
	} else {
		information_mc.info_text_mc.player_info_text.text = "";
	}
	timeInterval = setInterval(timeDisplay, 200);
	if (autoresume == 1) {
		clearInterval(resumeInterval);
		resumeInterval = setInterval(resumeCheck, 10);
	}
	_root.onEnterFrame = function() {
		mysound.setVolume(volume_level);
		var load_percent = (mysound.getBytesLoaded()/mysound.getBytesTotal())*100;
		top_section_mc.track_display_mc.loader_mc.load_bar_mc.load_bar._xscale = load_percent;
		var time_percent = (mysound.position/mysound.duration)*100;
		top_section_mc.track_display_mc.mouse_mc.mouse_bar_mc.mouse_bar._xscale = load_percent;
		top_section_mc.track_display_mc.time_bar.time_bar_mc.time_count._xscale = time_percent;
		var image_load_percent = (cover_mc.content_mc["photo"].getBytesLoaded()/cover_mc.content_mc["photo"].getBytesTotal())*100;
		// image load
		if ((cover_mc.content_mc["photo"].getBytesLoaded()>4) && (image_load_percent == 100)) {
			// make image fit album cover area
			cover_mc.photo_load_mc.imageloadMC._visible = false;
			if (skin_mode === "on") {
				cover_mc.content_mc["photo"]._width = 125;
				cover_mc.content_mc["photo"]._height = 125;
				cover_mc.content_mc["photo"]._x = 2;
				cover_mc.content_mc["photo"]._y = 2;
			} else {
				cover_mc.content_mc["photo"]._width = cover_mc.load_bar_mc._width;
				cover_mc.content_mc["photo"]._height = cover_mc.load_bar_mc._height;
			}
		}
		if (mysound.getBytesLoaded()>1) {
			top_section_mc.track_display_mc.time_bar._height = 13;
		}
	};
	top_section_mc.track_display_mc.onEnterFrame = function() {
		if (total_time>0) {
			top_section_mc.track_display_mc.track_text_mc.display_txt.text = playlist_array[track_index].label;
			checkTextwidth();
			delete top_section_mc.track_display_mc.onEnterFrame;
		}
	};
}
function preloadalbum() {
	playlist_mc.tracks_mc._visible = true;
	cover_mc.photo_load_mc._visible = true;
	cover_mc.photo_load_mc.imageloadMC.text = "LOADING ALBUM COVER";
	cover_mc.photo_load_mc.imageloadMC._visible = true;
	if (main_image) {
		cover_mc.content_mc.createEmptyMovieClip("photo", track_index);
		cover_mc.content_mc["photo"].loadMovie(main_image);
	} else {
		cover_mc.content_mc["photo"].removeMovieClip();
		if (playlist_array[track_index].image != undefined) {
			cover_mc.content_mc.createEmptyMovieClip("photo", track_index);
			cover_mc.content_mc["photo"].loadMovie(playlist_array[track_index].image);
		} else if (album_xml_jpg_data == false) {
		} else {
			xmlData.load("http://ws.audioscrobbler.com/2.0/?method=track.getinfo&api_key=b25b959554ed76058ac220b7b2e0a026&artist="+playlist_array[track_index].creator+"&track="+playlist_array[track_index].title+"");
		}
	}
	_root.onEnterFrame = function() {
		var image_load_percent = (cover_mc.content_mc["photo"].getBytesLoaded()/cover_mc.content_mc["photo"].getBytesTotal())*100;
		cover_mc.load_bar_mc._xscale = image_load_percent;
		if ((cover_mc.content_mc["photo"].getBytesLoaded()>4) && (image_load_percent == 100)) {
			cover_mc.photo_load_mc.imageloadMC._visible = false;
			if (skin_mode === "on") {
				cover_mc.content_mc["photo"]._width = 125;
				cover_mc.content_mc["photo"]._height = 125;
				cover_mc.content_mc["photo"]._x = 2;
				cover_mc.content_mc["photo"]._y = 2;
			} else {
				cover_mc.content_mc["photo"]._width = cover_mc.load_bar_mc._width;
				cover_mc.content_mc["photo"]._height = cover_mc.load_bar_mc._height;
			}
		}
	};
	top_section_mc.track_display_mc.track_text_mc.display_txt.text = playlist_array[track_index].label;
	//load status of artist info
	if (playlist_array[track_index].info != undefined) {
		if (info_text) {
			information_mc.info_text_mc.player_info_text.text = info_text;
		} else {
			information_mc.info_text_mc.player_info_text.text = "ARTIST INFO";
		}
	} else {
		information_mc.info_text_mc.player_info_text.text = "";
	}
}
//
//
// information button and info button
information_mc.information_btn.onRollOver = top_section_mc.info_mc.info_or_artist_btn.onRollOver=function () {
	holderText = top_section_mc.track_display_mc.track_text_mc.display_txt.text;
	//if artist info exists
	if (playlist_array[track_index].info != undefined) {
		top_section_mc.track_display_mc.track_text_mc.display_txt.text = playlist_array[track_index].info;
		checkTextwidth();
	} else {
		// else display default message
		top_section_mc.track_display_mc.track_text_mc.display_txt.text = "No Artist Info";
		checkTextwidth();
	}
};
information_mc.information_btn.onPress = function() {
	if (playlist_array[track_index].info != undefined) {
		getURL(playlist_array[track_index].info, "_blank");
		top_section_mc.track_display_mc.track_text_mc.display_txt.text = holderText;
	} else {
		//Do nothing
	}
};
// lower buttons
information_mc.settings_mc.shuffle_btn.onRollOver = function() {
	holderText = top_section_mc.track_display_mc.track_text_mc.display_txt.text;
	top_section_mc.track_display_mc.track_text_mc.display_txt.text = "Shuffle";
};
information_mc.settings_mc.repeat_btn.onRollOver = function() {
	holderText = top_section_mc.track_display_mc.track_text_mc.display_txt.text;
	top_section_mc.track_display_mc.track_text_mc.display_txt.text = "Repeat";
};
information_mc.settings_mc.repeat_btn.onRollOut = information_mc.settings_mc.shuffle_btn.onRollOut=information_mc.information_btn.onRollOut=top_section_mc.info_mc.info_or_artist_btn.onRollOut=function () {
	top_section_mc.track_display_mc.track_text_mc.display_txt.text = holderText;
};
// play/stop buttons plus misc buttons
top_section_mc.buttons_mc.stop_btn.onRelease = stopTrack;
top_section_mc.play_mc.play_btn.onRelease = playTrack;
top_section_mc.buttons_mc.next_btn.onRelease = nextTrack;
top_section_mc.buttons_mc.prev_btn.onRelease = prevTrack;
information_mc.settings_mc.shuffle_btn.onRelease = shuffleClick;
information_mc.settings_mc.repeat_btn.onRelease = repeatClick;
if (no_continue != 1 || no_continue != true) {
	mysound.onSoundComplete = nextTrack;
}
top_section_mc.track_display_mc.mouse_mc.mouse_bar_mc.mouse_bar.useHandCursor = false;
top_section_mc.track_display_mc.mouse_mc.mouse_bar_mc.mouse_bar.onPress = timeChange;
top_section_mc.track_display_mc.mouse_mc.mouse_bar_mc.mouse_bar.onRelease = top_section_mc.track_display_mc.mouse_mc.mouse_bar_mc.mouse_bar.onReleaseOutside=function () {
	this._parent.onMouseMove = this._parent.onMouseUp=null;
};
top_section_mc.volume_mc.volume_btn.useHandCursor = false;
top_section_mc.volume_mc.volume_btn.onPress = volumeChange;
top_section_mc.volume_mc.volume_btn.onRelease = top_section_mc.volume_mc.volume_btn.onReleaseOutside=function () {
	this._parent.onMouseMove = null;
};
//
//
// Function To Allow For User To Seek Track On Tracklist Bar
function timeChange() {
	if (top_section_mc.play_mc._currentframe == 2) {
		var percent = (this._parent._xmouse/this._width);
		if (percent>100) {
			percent = 100;
		}
		if (percent<0) {
			percent = 0;
		}
		timePlace = (mysound.duration*percent)/1000;
		mysound.start(timePlace);
		this._parent.onMouseMove = function() {
			var percent = (this._parent._xmouse/this._width);
			if (percent>100) {
				percent = 100;
			}
			if (percent<0) {
				percent = 0;
			}
			timePlace = (mysound.duration*percent)/1000;
			mysound.start(timePlace);
		};
	}
}
//Volume Function
function volumeChange() {
	this._parent.onMouseMove = function() {
		var percent = (this._xmouse/this._width)*150;
		if (percent>100) {
			percent = 100;
		}
		if (percent<0) {
			percent = 0;
		}
		this.gray_mc._xscale = percent;
		var max_level = percent;
		_root.volume_level = max_level;
	};
}
function resumeCheck() {
	local_data = null;
	local_data = SharedObject.getLocal("xspf_player_data");
	//updating data quickly
	local_data.data.is_set = true;
	local_data.data.repeat_status = repeat;
	local_data.data.shuffle_status = shuffle;
	local_data.data.shuffle_index = shuffle_index;
	local_data.data.shuffle_array = shuffle_array;
	local_data.data.playlist_url = playlist_url;
	local_data.data.song_url = song_url;
	local_data.data.stop_track = track_index+1;
	var when;
	when = mysound.position/1000;
	local_data.data.stop_time = when;
	local_data.data.volume_level = volume_level;
	when = new Date();
	local_data.data.stopped_at = when.getTime();
}
// Time Display Function
function timeDisplay() {
	top_section_mc.time_mc.time_txt.autoSize = "right";
	// countup
	time = mysound.position/1000;
	total_time = mysound.duration/1000;
	// time calculations  
	min = Math.floor(time/60);
	sec = Math.floor(time%60);
	sec = (sec<10) ? "0"+sec : sec;
	// determines if time info will be shown from playlist data, or the mp3 itself while it's loading.
	if (playlist_array[track_index].counter != undefined) {
		// if no user input is detected, playlist data will be used as default
		play_time = playlist_array[track_index].counter;
		top_section_mc.time_mc.time_txt.text = min+":"+sec+"/"+play_time;
	} else {
		// total time update via audio file
		minT = Math.floor(total_time/60);
		secT = Math.floor(total_time%60);
		secT = (secT<10) ? "0"+secT : secT;
		full_time = minT+":"+secT;
		top_section_mc.time_mc.time_txt.text = min+":"+sec+"/"+full_time;
	}
	// Scrolling text conforms in relation to time text, and varies depending on features turned on or off
	if (counter === "off" && volume_btn === "off") {
		top_section_mc.track_display_mc.track_text_mc.mask_mc._width = p_width-(67+(top_section_mc.track_display_mc._x-62));
	} else if (counter === "off") {
		top_section_mc.track_display_mc.track_text_mc.mask_mc._width = p_width-(90+(top_section_mc.track_display_mc._x-62));
	} else if (volume_btn === "off") {
		top_section_mc.track_display_mc.track_text_mc.mask_mc._width = p_width-(70+(top_section_mc.track_display_mc._x-62))-(top_section_mc.time_mc.time_txt.textWidth);
	} else {
		top_section_mc.track_display_mc.track_text_mc.mask_mc._width = p_width-(93+(top_section_mc.track_display_mc._x-62))-(top_section_mc.time_mc.time_txt.textWidth);
	}
	return total_time;
}
//Stop Function
function stopTrack() {
	if (autoresume == 1) {
		clearInterval(resumeInterval);
		local_data.data.stopped = true;
	}
	mysound.stop();
	top_section_mc.play_mc.gotoAndStop(1);
	mysound.stop();
	mysound.start();
	mysound.stop();
	_root.pause_position = 0;
	clearInterval(timeInterval);
}
//Play Function
function playTrack() {
	if (top_section_mc.play_mc._currentframe == 1) {
		if (autoresume == 1) {
			local_data.data.paused = false;
			local_data.data.stopped = false;
		}
		mysound.stop();
		mysound.start(int((pause_position)/1000), 1);
		top_section_mc.play_mc.gotoAndStop(2);
		if (autoresume == 1) {
			resumeInterval = setInterval(resumeCheck, 100);
		}
		timeInterval = setInterval(timeDisplay, 200);
	} else if (top_section_mc.play_mc._currentframe == 2) {
		pause_position = mysound.position;
		mysound.stop();
		if (autoresume == 1) {
			local_data.data.paused = true;
			local_data.data.pause_position = pause_position;
		}
		top_section_mc.play_mc.gotoAndStop(1);
	}
}
function nextTrack() {
	local_data.data.paused = false;
	playlist_mc.tracks_mc.track_0_mc["track_"+track_index+"_mc"].bg_mc.gotoAndStop(1);
	// sets user auto color for playlist area
	auto_color();
	if (shuffle == 0) {
		// shuffle off
		if (track_index<playlist_size-1) {
			if (repeat == 1) {
				// repeat one track
			} else {
				track_index++;
			}
			mediaCheck();
		} else {
			if (repeat == 1) {
				// repeat last track
				mediaCheck();
			}
			if (repeat == 2) {
				// repeat whole playlist
				track_index = 0;
				mediaCheck();
			}
		}
	} else {
		// shuffle on
		if (shuffle_index<shuffle_array.length-1) {
			if (repeat == 1) {
				// repeat current shuffle track
			} else {
				shuffle_index++;
			}
			mediaCheck();
		} else {
			if (repeat == 1) {
				// repeat last shuffle track
				mediaCheck();
			}
			if (repeat == 2) {
				shuffle_index = 0;
				mediaCheck();
				// repeat whole shuffle playlist
			}
		}
	}
	// set track index
	last_track_index = track_index;
}
// Previous Track Function
function prevTrack() {
	local_data.data.paused = false;
	playlist_mc.tracks_mc.track_0_mc["track_"+track_index+"_mc"].bg_mc.gotoAndStop(1);
	auto_color();
	if (repeat != 1) {
		if (track_index>0) {
			track_index--;
		} else {
			track_index = playlist_size-1;
		}
		if (shuffle_index>0) {
			shuffle_index--;
		} else {
			shuffle_index = shuffle_array.length-1;
		}
	}
	last_track_index = track_index;
	mediaCheck();
}
/*
***********************************************************************
oooooooooo
o
ooooooo
o
o
o
oo
o
**************************************************************************
/*/
// Dimensions For Graphics via HTML/URL line
function resizeUI() {
	if (!player_width) {
		var player_w = Stage.width;
	} else {
		var player_w = player_width;
	}
	if (!player_height) {
		var player_h = Stage.height;
	} else {
		var player_h = player_height;
	}
	if (player_mode === "mini") {
		album_xml_jpg_data = false;
		cover_mc._visible = false;
		scrollbar_mc._visible = false;
		information_mc._visible = false;
		playlist_mc._visible = false;
		top_section_mc.buttons_mc.prev_btn._visible = false;
		top_section_mc.buttons_mc.stop_btn._visible = false;
		top_section_mc.track_display_mc._x = top_section_mc.track_display_mc._x-27;
		top_section_mc.play_mc._x = 6;
		top_section_mc.buttons_mc.next_btn._x = top_section_mc.buttons_mc.next_btn._x-28;
		//SMALL MODE
	} else if (player_mode === "small") {
		cover_mc._width = 67;
		cover_mc._height = 67;
		information_mc._y = 85;
		information_mc.info_text_mc._visible = false;
		information_mc.information_btn._visible = false;
		information_mc.info_bg._width = 67;
		playlist_mc._x = cover_mc._width+3;
	}
	//FEATURE OPTIONS                                                                                                                                  
	if (volume_btn === "off") {
		top_section_mc.volume_mc._visible = false;
		top_section_mc.time_mc._x = player_w-65;
		top_section_mc.track_display_mc.mouse_mc._width = player_w-top_section_mc.track_display_mc._x-2;
		top_section_mc.track_display_mc.time_bar._width = player_w-top_section_mc.track_display_mc._x-2;
		top_section_mc.track_display_mc.loader_mc.load_bar_mc._width = player_w-top_section_mc.track_display_mc._x-2;
	} else {
		top_section_mc.time_mc._x = player_w-89;
		top_section_mc.track_display_mc.mouse_mc._width = player_w-top_section_mc.track_display_mc._x-25;
		top_section_mc.track_display_mc.time_bar._width = player_w-top_section_mc.track_display_mc._x-25;
		top_section_mc.track_display_mc.loader_mc.load_bar_mc._width = player_w-top_section_mc.track_display_mc._x-25;
	}
	if (counter === "off") {
		top_section_mc.time_mc._visible = false;
	} else {
		top_section_mc.time_mc._visible = true;
	}
	if (album === "off") {
		cover_mc._width = 0;
		playlist_mc._x = cover_mc._width+1;
		album_xml_jpg_data = false;
		information_mc.info_bg._width = player_w-12;
		information_mc._y = player_h-18;
		playlist_mc.bg_mc._height = player_h-36;
		playlist_mc.mask_mc._height = player_h-38;
	} else {
		playlist_mc.mask_mc._height = player_h-22;
		playlist_mc.bg_mc._height = player_h-19;
	}
	if (bottom_controls === "off") {
		information_mc._visible = false;
		playlist_mc.mask_mc._height = player_h-22;
		playlist_mc.bg_mc._height = player_h-19;
	}
	//REGULAR MODE                                                              
	top_section_mc.volume_mc.gray_mc._xscale = volume_level;
	start_btn_mc._xscale = player_w;
	top_section_mc.volume_mc._x = player_w-23;
	scrollbar_mc._x = player_w-10;
	scrollbar_mc.bg_mc._height = player_h-19;
	playlist_mc.mask_mc._width = player_w-(playlist_mc._x+10);
	playlist_mc.bg_mc._width = player_w-(playlist_mc._x+11);
	playlist_mc.tracks_mc.track_0_mc.bg_mc._width = player_w-(playlist_mc._x+15);
	top_section_mc.top_bg_mc._width = player_w;
	information_mc.settings_mc.repeat_btn._x = information_mc.info_bg._width-32;
	information_mc.info_text_mc._x = (information_mc.info_bg._width/2)-31;
	information_mc.information_btn._x = (information_mc.info_bg._width/2)-31;
	top_section_mc.track_display_mc.track_text_mc.mask_mc._width = top_section_mc.track_display_mc.loader_mc._width;
}
//
//
// Function To Create Playlist Area And Fill With Tracks
function addTrack(track_label, counter_label) {
	playlist_mc.tracks_mc.track_0_mc.attachMovie("track_item", "track_"+playlist_mc.track_count+"_mc", playlist_mc.track_count);
	// adds glowing effect to each track background to smooth out graphic 
	import flash.filters.GlowFilter;
	var myGlow:GlowFilter = new GlowFilter(0x000000, 1, 0, 10, 0, 30);
	if (blend == 1 || blend == 2 || skin_mode === "on") {
		//playlist_mc.tracks_mc.track_0_mc["track_"+playlist_mc.track_count+"_mc"].bg_mc.filters = [myGlow];
	}
	// sets user auto color for playlist area                                                                                                                                                                                                   
	auto_color2();
	// space between playlist tracks                
	playlist_mc.tracks_mc.track_0_mc["track_"+playlist_mc.track_count+"_mc"]._y += playlist_mc.track_count*16;
	// if user has play_time data in their Mp3's, counters will be enabled and mask will be streched to show each tracks total play time
	if (counter_label == "undefined" || playlist_counter == "off") {
		// if user does not have play_time data in their Mp3's, counters will be removed and mask will be streched to show full track text
		playlist_mc.tracks_mc.track_0_mc["track_"+playlist_mc.track_count+"_mc"].track_display_text.mask_mc._width = scrollbar_mc._x-10-playlist_mc._x;
	} else {
		playlist_mc.tracks_mc.track_0_mc["track_"+playlist_mc.track_count+"_mc"].track_display_text.counter_txt._x = scrollbar_mc._x-playlist_mc._x-52;
		playlist_mc.tracks_mc.track_0_mc["track_"+playlist_mc.track_count+"_mc"].track_display_text.counter_txt.autoSize = "right";
		playlist_mc.tracks_mc.track_0_mc["track_"+playlist_mc.track_count+"_mc"].track_display_text.counter_txt.text = counter_label;
		playlist_mc.tracks_mc.track_0_mc["track_"+playlist_mc.track_count+"_mc"].track_display_text.mask_mc._width = scrollbar_mc._x-playlist_mc.tracks_mc.track_0_mc["track_"+playlist_mc.track_count+"_mc"].track_display_text.counter_txt.textWidth-14-playlist_mc._x;
	}
	// sets track label
	label_prefix += 1;
	playlist_mc.tracks_mc.track_0_mc["track_"+playlist_mc.track_count+"_mc"].track_display_text.display_txt.autoSize = "left";
	// option for turning off label prefix
	if (playlist_number === "off") {
		playlist_mc.tracks_mc.track_0_mc["track_"+playlist_mc.track_count+"_mc"].track_display_text.display_txt.text = track_label;
	} else {
		playlist_mc.tracks_mc.track_0_mc["track_"+playlist_mc.track_count+"_mc"].track_display_text.display_txt.text = label_prefix+". "+track_label;
	}
	// sets user text color
	text_color();
	playlist_mc.tracks_mc.track_0_mc["track_"+playlist_mc.track_count+"_mc"].bg_mc._width = p_width-(playlist_mc._x+15);
	playlist_mc.tracks_mc.track_0_mc["track_"+playlist_mc.track_count+"_mc"].bg_mc.index = playlist_mc.track_count;
	// on track click move to that track
	playlist_mc.tracks_mc.track_0_mc["track_"+playlist_mc.track_count+"_mc"].bg_mc.select_btn.onPress = function() {
		playlist_mc.tracks_mc.track_0_mc["track_"+track_index+"_mc"].bg_mc.gotoAndStop(1);
		local_data.data.paused = false;
		// sets user auto color for playlist area
		auto_color();
		last_track_index = track_index;
		track_index = this._parent.index;
		songClick = 1;
		mediaCheck();
	};
	playlist_mc.track_count++;
}
// scroll
mouseListener.onMouseWheel = function(wheel) {
	scrollbar_mc.v = (wheel/-3);
	scrollTracks();
};
scrollbar_mc.up_btn.onPress = function() {
	_root.scrollbar_mc.v = -1;
	_root.scrollbar_mc.onEnterFrame = scrollTracks;
};
scrollbar_mc.down_btn.onPress = function() {
	_root.scrollbar_mc.v = 1;
	_root.scrollbar_mc.onEnterFrame = scrollTracks;
};
scrollbar_mc.up_btn.onRelease = scrollbar_mc.down_btn.onRelease=function () {
	_root.scrollbar_mc.onEnterFrame = null;
};
scrollbar_mc.handler_mc.drag_btn.onPress = function() {
	var scroll_top_limit = 19;
	var scroll_bottom_limit = scrollbar_mc.bg_mc._height-scrollbar_mc.handler_mc._height-4;
	this._parent.startDrag(false, this._parent._x, scroll_top_limit, this._parent._x, scroll_bottom_limit);
	this._parent.isdragging = true;
	this._parent.onEnterFrame = scrollTracks;
};
scrollbar_mc.handler_mc.drag_btn.onRelease = scrollbar_mc.handler_mc.drag_btn.onReleaseOutside=function () {
	stopDrag();
	this._parent.isdragging = false;
	this._parent.onEnterFrame = null;
};
function scrollTracks() {
	track_height = playlist_size;
	var scroll_top_limit = 19;
	var scroll_bottom_limit = scrollbar_mc.bg_mc._height-scrollbar_mc.handler_mc._height-2;
	var list_bottom_limit = 1;
	var list_top_limit = (1-Math.round(playlist_mc.tracks_mc._height))+(playlist_mc.mask_mc._height/track_height)*track_height;
	if (playlist_mc.tracks_mc._height>playlist_mc.mask_mc._height) {
		if (scrollbar_mc.handler_mc.isdragging) {
			var percent = (scrollbar_mc.handler_mc._y-scroll_top_limit)/(scroll_bottom_limit-2-scroll_top_limit);
			playlist_mc.tracks_mc._y = (list_top_limit-list_bottom_limit)*percent+list_bottom_limit;
		} else {
			if (_root.scrollbar_mc.v == -1) {
				if (playlist_mc.tracks_mc._y+track_height<list_bottom_limit) {
					playlist_mc.tracks_mc._y += track_height;
				} else {
					playlist_mc.tracks_mc._y = list_bottom_limit;
				}
			} else if (_root.scrollbar_mc.v == 1) {
				if (playlist_mc.tracks_mc._y-track_height>list_top_limit) {
					playlist_mc.tracks_mc._y -= track_height;
				} else {
					playlist_mc.tracks_mc._y = list_top_limit;
				}
			}
			var percent = (playlist_mc.tracks_mc._y-1)/(list_top_limit-1);
			scrollbar_mc.handler_mc._y = (percent*(scroll_bottom_limit-2-scroll_top_limit)+scroll_top_limit);
		}
	}
}
//
function autoScroll() {
	if (playlist_mc.tracks_mc._height<playlist_mc.mask_mc._height) {
	} else {
		if (playlist_mc.tracks_mc.track_0_mc["track_"+track_index+"_mc"]._y<(playlist_mc.tracks_mc._height-playlist_mc.mask_mc._height)) {
			// autoscroll enabled
			holdit = -(playlist_mc.tracks_mc.track_0_mc["track_"+track_index+"_mc"]._y-1);
		} else {
			// end of playlist
			holdit = -(playlist_mc.tracks_mc._height-playlist_mc.mask_mc._height);
		}
		var i = playlist_mc.tracks_mc._y;
		playlist_mc.onEnterFrame = function() {
			playlist_mc.tracks_mc._y -= ((playlist_mc.tracks_mc._y+0.1-holdit)/2.5);
			if (playlist_mc.tracks_mc._y == 1) {
				scrollbar_mc.handler_mc._y = 19+((Math.floor(playlist_mc.tracks_mc._y-1)/16)*(((scrollbar_mc.bg_mc._height)-37)/((playlist_mc.mask_mc._height-playlist_mc.tracks_mc._height)/(16))));
			} else {
				scrollbar_mc.handler_mc._y = 19+((Math.floor(playlist_mc.tracks_mc._y)/16)*(((scrollbar_mc.bg_mc._height)-37)/((playlist_mc.mask_mc._height-playlist_mc.tracks_mc._height)/(16))));
			}
			if (playlist_mc.tracks_mc._y === i) {
				delete playlist_mc.onEnterFrame;
			}
			i = playlist_mc.tracks_mc._y;
		};
	}
}
function shuffleClick() {
	if (information_mc.settings_mc.shuffle_btn._currentframe == 2) {
		shuffle = 1;
		shuffle_index = 0;
		shuffle_array = randomizeArray("shuffle_array");
		information_mc.settings_mc.shuffle_btn.gotoAndStop(1);
		top_section_mc.track_display_mc.track_text_mc.display_txt.text = "Shuffle On";
	} else if (information_mc.settings_mc.shuffle_btn._currentframe == 1) {
		shuffle = 0;
		information_mc.settings_mc.shuffle_btn.gotoAndStop(2);
		top_section_mc.track_display_mc.track_text_mc.display_txt.text = "Shuffle Off";
	}
}
function repeatClick() {
	if (information_mc.settings_mc.repeat_btn._currentframe == 1) {
		repeat = 1;
		information_mc.settings_mc.repeat_btn.gotoAndStop(2);
		top_section_mc.track_display_mc.track_text_mc.display_txt.text = "Repeat One";
	} else if (information_mc.settings_mc.repeat_btn._currentframe == 2) {
		repeat = 2;
		information_mc.settings_mc.repeat_btn.gotoAndStop(3);
		top_section_mc.track_display_mc.track_text_mc.display_txt.text = "Repeat All";
	} else if (information_mc.settings_mc.repeat_btn._currentframe == 3) {
		repeat = 0;
		information_mc.settings_mc.repeat_btn.gotoAndStop(1);
		top_section_mc.track_display_mc.track_text_mc.display_txt.text = "Repeat Off";
	}
}
function loadPlaylist() {
	top_section_mc.track_display_mc.track_text_mc.display_txt.text = LOADING_PLAYLIST_MSG;
	// load playlist URL
	if (playlist_url) {
		playlist_xml.load(unescape(playlist_url));
	} else {
		// if not load single item or track
		playlist_xml.parseXML(single_music_playlist);
		playlist_xml.onLoad(true);
	}
}
function checkTextwidth() {
	if (top_section_mc.track_display_mc.track_text_mc.display_txt.textWidth>top_section_mc.track_display_mc.track_text_mc.mask_mc._width) {
		//reset for next item
		top_section_mc.track_display_mc.track_text_mc.display_txt._x = 0;
		delete top_section_mc.track_display_mc.track_text_mc.onEnterFrame;
		//Add one second delay to beginning of scrolling txt
		var delay = 0;
		top_section_mc.onEnterFrame = function() {
			delay += 1;
			if (delay>20) {
				top_section_mc.track_display_mc.track_text_mc.onEnterFrame = scrollTitle;
				delete top_section_mc.onEnterFrame;
			}
		};
	} else {
		top_section_mc.track_display_mc.track_text_mc.onEnterFrame = null;
		top_section_mc.track_display_mc.track_text_mc.display_txt._x = 0;
	}
}
//Function to scroll title if track info does not fit in "currently playing track" display
function scrollTitle() {
	// speed of scrolling text across track area
	top_section_mc.track_display_mc.track_text_mc.display_txt._x -= 1;
	// looping                                             
	if (top_section_mc.track_display_mc.track_text_mc.display_txt._x+top_section_mc.track_display_mc.track_text_mc.display_txt._width<0) {
		top_section_mc.track_display_mc.track_text_mc.display_txt._x = top_section_mc.track_display_mc.track_text_mc.mask_mc._width;
	}
}
// On First Click Start Player                         
start_btn_mc.start_btn.onPress = function() {
	if (autoload == 1) {
		mediaCheck();
	} else {
		loadPlaylist();
	}
	autoplay = 1;
};
// Change Color of Player
if (button_color) {
	button_color = button_color.toUpperCase();
	hexChars = "0123456789ABCDEF";
	red = "0x"+button_color.charAt(0)+button_color.charAt(1);
	grn = "0x"+button_color.charAt(2)+button_color.charAt(3);
	blu = "0x"+button_color.charAt(4)+button_color.charAt(5);
	/*Exact color from user input*/
	var mybuttonColorTransform:Object = {ra:0, rb:red, ga:0, gb:grn, ba:0, bb:blu, aa:100, ab:0};
	/*Lighter variation of color from user input*/
	var mybuttonColorTransformLight:Object = {ra:+15, rb:red, ga:0+15, gb:grn, ba:0+15, bb:blu, aa:100, ab:0};
	shuffle_repeat_Color = new Color(information_mc.settings_mc);
	shuffle_repeat_Color.setTransform(mybuttonColorTransform);
	volume_button1 = new Color(top_section_mc.volume_mc.gray_mc);
	volume_button1.setTransform(mybuttonColorTransform);
	volume_button2 = new Color(top_section_mc.volume_mc.light_gray);
	volume_button2.setTransform(mybuttonColorTransformLight);
	track_buttons = new Color(top_section_mc.buttons_mc);
	track_buttons.setTransform(mybuttonColorTransform);
	play_button = new Color(top_section_mc.play_mc);
	play_button.setTransform(mybuttonColorTransform);
	scrollbar_button1 = new Color(scrollbar_mc.handler_mc);
	scrollbar_button1.setTransform(mybuttonColorTransform);
	scrollbar_button2 = new Color(scrollbar_mc.down_btn);
	scrollbar_button2.setTransform(mybuttonColorTransform);
	scrollbar_button3 = new Color(scrollbar_mc.up_btn);
	scrollbar_button3.setTransform(mybuttonColorTransform);
	if (skin_mode === "on") {
		tracklist_skin1 = new Color(top_section_mc.track_display_mc.loader_mc.load_bar_mc);
		tracklist_skin1.setTransform(mybuttonColorTransform);
		tracklist_skin2 = new Color(top_section_mc.track_display_mc.time_bar);
		tracklist_skin2.setTransform(mybuttonColorTransform);
		top_section_mc.track_display_mc.loader_mc.load_bar_mc._alpha = 20;
		top_section_mc.track_display_mc.time_bar._alpha = 30;
	}
}
if (skin_mode === "on") {
	top_section_mc.top_bg_mc._alpha = 0;
	top_section_mc.volume_mc.bg_mc._alpha = 0;
	scrollbar_mc.bg_mc._alpha = 0;
	playlist_mc.bg_mc._alpha = 0;
	cover_mc.border_mc._alpha = 0;
	information_mc.info_bg._alpha = 0;
	playlist_mc.tracks_mc.track_0_mc.bg_mc.track_dark_mc._alpha = 0;
	playlist_mc.tracks_mc.track_0_mc.bg_mc.track_light_mc._alpha = 0;
}
if (bg_color) {
	bg_color = bg_color.toUpperCase();
	hexChars = "0123456789ABCDEF";
	red = "0x"+bg_color.charAt(0)+bg_color.charAt(1);
	grn = "0x"+bg_color.charAt(2)+bg_color.charAt(3);
	blu = "0x"+bg_color.charAt(4)+bg_color.charAt(5);
	// exact color from user input
	var myColorTransform:Object = {ra:0, rb:red, ga:0, gb:grn, ba:0, bb:blu, aa:100, ab:0};
	// lighter shade
	var myColorTransform2:Object = {ra:+16, rb:red, ga:+16, gb:grn, ba:+16, bb:blu, aa:100, ab:0};
	// darker shade
	var myColorTransform3:Object = {ra:-10, rb:red, ga:-10, gb:grn, ba:-10, bb:blu, aa:100, ab:0};
	// darker shadex2
	var myColorTransform4:Object = {ra:-30, rb:red, ga:-30, gb:grn, ba:-30, bb:blu, aa:100, ab:0};
	// backgrounds
	// button color, off or on
	if (button_color) {
		// change colors according to user input
	} else {
		// change colors to match background color
		tracklist_D = new Color(top_section_mc.play_mc);
		tracklist_D.setTransform(myColorTransform4);
		tracklist_E = new Color(top_section_mc.buttons_mc);
		tracklist_E.setTransform(myColorTransform4);
		volume_btn_2 = new Color(top_section_mc.volume_mc.gray_mc);
		volume_btn_2.setTransform(myColorTransform4);
		volume_btn_3 = new Color(top_section_mc.volume_mc.light_gray);
		volume_btn_3.setTransform(myColorTransform2);
		scrollbar_btn1Color = new Color(scrollbar_mc.handler_mc);
		scrollbar_btn1Color.setTransform(myColorTransform4);
		scrollbar_btn2Color = new Color(scrollbar_mc.down_btn);
		scrollbar_btn2Color.setTransform(myColorTransform4);
		scrollbar_btn3Color = new Color(scrollbar_mc.up_btn);
		scrollbar_btn3Color.setTransform(myColorTransform4);
		information_buttonsColor = new Color(information_mc.settings_mc);
		information_buttonsColor.setTransform(myColorTransform4);
	}
	tracklist_A = new Color(top_section_mc.track_display_mc.loader_mc.load_bar_mc);
	tracklist_A.setTransform(myColorTransform3);
	tracklist_B = new Color(top_section_mc.track_display_mc.time_bar);
	tracklist_B.setTransform(myColorTransform2);
	tracklist_C = new Color(top_section_mc.top_bg_mc);
	tracklist_C.setTransform(myColorTransform);
	volume_btn_1 = new Color(top_section_mc.volume_mc.bg_mc);
	volume_btn_1.setTransform(myColorTransform);
	scrollbar_bgColor = new Color(scrollbar_mc.bg_mc);
	scrollbar_bgColor.setTransform(myColorTransform);
	playlist_bg = new Color(playlist_mc.bg_mc);
	playlist_bg.setTransform(myColorTransform);
	cover_bgColor = new Color(cover_mc.border_mc);
	cover_bgColor.setTransform(myColorTransform);
	information_bgColor = new Color(information_mc.info_bg);
	information_bgColor.setTransform(myColorTransform);
	// text
	if (txt_color) {
	} else {
		top_section_mc.track_display_mc.track_text_mc.blendMode = 3;
		top_section_mc.time_mc.blendMode = 3;
		information_mc.info_text_mc.blendMode = 3;
		cover_mc.photo_load_mc.blendMode = 3;
	}
}
if (txt_color) {
	txt_color = txt_color.toUpperCase();
	hexChars = "0123456789ABCDEF";
	red = "0x"+txt_color.charAt(0)+txt_color.charAt(1);
	grn = "0x"+txt_color.charAt(2)+txt_color.charAt(3);
	blu = "0x"+txt_color.charAt(4)+txt_color.charAt(5);
	/*Exact color from user input*/
	var myTxtColor:Object = {ra:0, rb:red, ga:0, gb:grn, ba:0, bb:blu, aa:100, ab:0};
	information_txtColor = new Color(information_mc.info_text_mc.player_info_text);
	information_txtColor.setTransform(myTxtColor);
	track_txtColor = new Color(top_section_mc.track_display_mc.track_text_mc.display_txt);
	track_txtColor.setTransform(myTxtColor);
	time_txtColor = new Color(top_section_mc.time_mc.time_txt);
	time_txtColor.setTransform(myTxtColor);
	load_album_txtColor = new Color(cover_mc.photo_load_mc.imageloadMC);
	load_album_txtColor.setTransform(myTxtColor);
}
if (blend == 1) {
	// multiply blend
	top_section_mc.blendMode = 3;
	playlist_mc.blendMode = 3;
	cover_mc.blendMode = 3;
	information_mc.blendMode = 3;
	scrollbar_mc.blendMode = 3;
	top_section_mc.volume_mc.blendMode = 3;
}
if (blend == 2) {
	// overlay blend
	top_section_mc.blendMode = 13;
	playlist_mc.blendMode = 13;
	cover_mc.blendMode = 13;
	information_mc.blendMode = 13;
	scrollbar_mc.blendMode = 13;
}
if (album_blend == 1) {
	cover_mc.content_mc.blendMode = 3;
}
if (album_blend == 2) {
	cover_mc.content_mc.blendMode = 13;
}
if (alpha) {
	// alpha level
	top_section_mc._alpha = alpha;
	playlist_mc._alpha = alpha;
	playlist_mc.tracks_mc.track_0_mc.bg_mc.track_light_mc._alpha = 0;
	playlist_mc.tracks_mc.track_0_mc.bg_mc.track_dark_mc._alpha = 0;
	if (blend == 1 || blend == 2) {
	} else {
		top_section_mc.track_display_mc.time_bar._alpha = alpha-(alpha-70);
	}
	cover_mc._alpha = alpha;
	information_mc._alpha = alpha;
	scrollbar_mc._alpha = alpha;
	volume_mc._alpha = alpha;
}
// Function(s) To Adjust User Color To Match Background                                                                                                                                                                                                                                                                                                             
function auto_color() {
	if (skin_mode === "on") {
		playlist_skin1 = new Color(playlist_mc.tracks_mc.track_0_mc["track_"+track_index+"_mc"].bg_mc.track_light_mc);
		playlist_skin1.setTransform(mybuttonColorTransform);
		playlist_mc.tracks_mc.track_0_mc["track_"+track_index+"_mc"].bg_mc.track_light_mc._alpha = 20;
		playlist_mc.tracks_mc.track_0_mc["track_"+track_index+"_mc"].bg_mc.track_dark_mc._alpha = 0;
	} else {
		playlist_l = new Color(playlist_mc.tracks_mc.track_0_mc["track_"+track_index+"_mc"].bg_mc.track_light_mc);
		playlist_l.setTransform(myColorTransform2);
		playlist_d = new Color(playlist_mc.tracks_mc.track_0_mc["track_"+track_index+"_mc"].bg_mc.track_dark_mc);
		playlist_d.setTransform(myColorTransform3);
	}
}
function auto_color2() {
	if (skin_mode === "on") {
		playlist_skin1 = new Color(playlist_mc.tracks_mc.track_0_mc["track_"+playlist_mc.track_count+"_mc"].bg_mc.track_light_mc);
		playlist_skin1.setTransform(mybuttonColorTransformLight);
		playlist_mc.tracks_mc.track_0_mc["track_"+playlist_mc.track_count+"_mc"].bg_mc.track_light_mc._alpha = 10;
		playlist_mc.tracks_mc.track_0_mc["track_"+playlist_mc.track_count+"_mc"].bg_mc.track_dark_mc._alpha = 0;
	} else {
		playlist_l = new Color(playlist_mc.tracks_mc.track_0_mc["track_"+playlist_mc.track_count+"_mc"].bg_mc.track_light_mc);
		playlist_l.setTransform(myColorTransform2);
		playlist_d = new Color(playlist_mc.tracks_mc.track_0_mc["track_"+playlist_mc.track_count+"_mc"].bg_mc.track_dark_mc);
		playlist_d.setTransform(myColorTransform3);
	}
}
function text_color() {
	if (txt_color) {
		playlist_txtColor = new Color(playlist_mc.tracks_mc.track_0_mc["track_"+playlist_mc.track_count+"_mc"].track_display_text.display_txt);
		playlist_txtColor.setTransform(myTxtColor);
		playlist_txtColor2 = new Color(playlist_mc.tracks_mc.track_0_mc["track_"+playlist_mc.track_count+"_mc"].track_display_text.counter_txt);
		playlist_txtColor2.setTransform(myTxtColor);
	} else {
		if (bg_color) {
			playlist_mc.tracks_mc.track_0_mc["track_"+playlist_mc.track_count+"_mc"].track_display_text.blendMode = 3;
		}
	}
}
//**********  XSPF FLASH MP3 ***********// 
//		  PLAYER BASIC SETTINGS			//
//										//
//										//
//**************************************//
Stage.scaleMode = "noScale";
Stage.align = "LT";
this.onResize = resizeUI;
Stage.addListener(this);
Mouse.addListener(mouseListener);
if (!player_title) {
	player_title = DEFAULT_WELCOME_MSG;
}
// fixes width of player componants when used within another flash doc                                                                                               
if (!player_width) {
	var p_width = Stage.width;
} else {
	var p_width = player_width;
}
top_section_mc.track_display_mc.track_text_mc.display_txt.autoSize = "left";
top_section_mc.track_display_mc.track_text_mc.display_txt.text = player_title;
top_section_mc.track_display_mc.time_bar._height = 0;
//customized menu                                                               
var my_cm:ContextMenu = new ContextMenu();
my_cm.customItems.push(new ContextMenuItem("Stop", stopTrack));
my_cm.customItems.push(new ContextMenuItem("Play!", playTrack));
my_cm.customItems.push(new ContextMenuItem("Next", nextTrack));
my_cm.customItems.push(new ContextMenuItem("Previous", prevTrack));
if (dl == "off") {
} else {
	my_cm.customItems.push(new ContextMenuItem("Download Track", function () {
		getURL(playlist_array[track_index].location), "_blank";
	}, true));
}
my_cm.customItems.push(new ContextMenuItem("Download XSPF Player v4.1", function () {
	getURL("http://www.xspf-player.com", "_blank");
}, true));
my_cm.hideBuiltInItems();
this.menu = my_cm;
defaultSettings();
resizeUI();
if (autoplay == 1 || autoload == 1) {
	loadPlaylist();
}
