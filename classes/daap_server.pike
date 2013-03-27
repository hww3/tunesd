inherit Fins.FinsBase;

inherit "dmap";

object log = Tools.Logging.get_logger("daap");

mixed handle_request(Protocols.HTTP.Server.Request request)
{
  mixed response;

 // werror("request: %O\n", request);
  if(has_prefix(request->not_query, "daap://"))
  {
   // werror("rewriting...");
    object uri = Standards.URI(request->not_query);
    request->not_query=uri->path;
    request->query = uri->get_http_query();
    request->misc->is_daap = 1;
    //werror(" " + request->not_query + "\n");
  }
  

//werror("request: %O\n", request);
  switch(request->not_query)
  {
     case "/server-info":
       response = create_server_info(request);
       break;
     case "/content-codes":
       if(request->not_query != "/server-info" && !request["request_headers"]->authorization) response = auth_required("tunesd");
       else response = create_content_codes(request);
       break;
     case "/login":
       response = create_login(request);
       break;
       case "/logout":
         response = create_logout(request);
         break;
     case "/update":
       if(request->not_query != "/server-info" && !request["request_headers"]->authorization) response = auth_required("tunesd");
       else response = create_update(request);
       break;
     case "/databases":
       if(request->not_query != "/server-info" && !request["request_headers"]->authorization) response = auth_required("tunesd");
       else response = create_databases(request);
       break;
     default:
       response = handle_sub_request(request);
  }
      
  if(response)
  {
//    werror("response: %O\n", create_response(response, 200));
//    request->response_and_finish(create_response(response, 200));
    return (create_response(response, 200)) + (["request": request]);
  }

  else
    return 0;
}
  

array|mapping handle_sub_request(object request)
{
    string dbid, plid, song;
    int songid;
    // need to handle the following:
    // /databases/<dbid>/items
    // /databases/<dbid>/containers
    // /databases/<dbid>/containers/<plid>/items
    // /databases/<dbid>/items/<songid>.mp3

    if(sscanf(request->not_query, "/databases/%s/items/%s", dbid, song) == 2)
    {
      sscanf(song, "%d.%s", songid, song);
      return stream_audio(request, dbid, songid);
    }
    else if(sscanf(request->not_query, "/databases/%s/containers/%s/items", dbid, plid) == 2)
    {
      if(request->not_query != "/server-info" && !request["request_headers"]->authorization) return auth_required("tunesd");
      return create_container_items(request, dbid, plid);
    }
    else if(sscanf(request->not_query, "/databases/%s/items", dbid) == 1)
    {
      if(request->not_query != "/server-info" && !request["request_headers"]->authorization) return auth_required("tunesd");
      return create_items(request, dbid);
    }
    else if(sscanf(request->not_query, "/databases/%s/containers", dbid) == 1)
    {
      if(request->not_query != "/server-info" && !request["request_headers"]->authorization) return auth_required("tunesd");
      return create_containers(request, dbid);      
    }
    else
    {
//      werror("yikes! a request we don't understand: %O\n", request);
//      return (["error": 500, "data": "we don't know how to handle " + request->not_query + "!"]);
      return 0;
    }
}
  
mapping stream_audio(object id, string dbid, int songid)
{
  // Protocols.HTTP.Server takes care of simple Range requests for us... how nice!
  string song = app->db->get_song_path(songid);

  object s = file_stat(song);
  log->debug("song file is %s: %O\n", song, s);

  app->db->bump(songid);
  
  if(song)
    return (["type": "audio/" + app->db->get_song(songid)["format"]/*"application/x-dmap-tagged"*/, "extra_heads": (["DAAP-Server": "tunesd/" + app->version]), "file": Stdio.File(song)]);  
  else 
    return (["type": "text/plain", "error": 404, "extra_heads": (["DAAP-Server": "tunesd/" + app->version]),  "data": "song not found."]);
}

mapping auth_required(string realm)
{
  mapping hauth = ([]);
  string type;
  int code = 401;
  type="text/plain";
  string data = "authentication required.";
  hauth["WWW-Authenticate"] = "Basic realm=\"webserver\"";
  
  return (["server": "tunesd/" + app->version, "type": type, 
    "extra_heads": (["Accept-Ranges": "bytes", "DAAP-Server": "tunesd/" + app->version]) + hauth, 
    "error": code, "data": data]);
}
mapping create_response(array|mapping data, int code)
{
  if(mappingp(data)) 
    return data;
  else  
    return (["server": "tunesd/" + app->version, "type": "application/x-dmap-tagged", 
      "extra_heads": (["Accept-Ranges": "bytes", "DAAP-Server": "tunesd/" + app->version]), 
      "error": code, "data": encode_dmap(data)]);
}

//! 
array create_items(object id, string dbid)
{
  array x = 
       ({
          ({"dmap.status", 200}),
          ({"dmap.updatetype", app->db->has_removed_in_revision((int)(id->variables["revision-number"]))?1:0}),
          ({"dmap.specifiedtotalcount", get_song_count()}),
          ({"dmap.returnedcount", get_song_count()}),
          ({"dmap.listing", 
                generate_song_list(id)
          })
  //        ({"dmap.deletedidlisting", ({  ({"dmap.itemid", id) }) });
       });
  
  if(app->db->has_removed_in_revision((int)(id->variables["revision-number"])))
  {
    log->info("have removed items...\n");
    x +=({({"dmap.deletedidlisting",  generate_deleted_ids((int)id->variables["revision-number"]) }) });
  }
  
  return 
  ({ "daap.databasesongs",
    x
  });
}

//! 
array create_containers(object id, string dbid)
{
  // there is always at least 1 playlist: the 'full' library.
  return 
  ({  "daap.databaseplaylists",
     ({
        ({"dmap.status", 200}),
        ({"dmap.updatetype", 0}),
        ({"dmap.specifiedtotalcount", get_playlist_count() + 2}),
        ({"dmap.returnedcount", get_playlist_count() + 2}),
        ({"dmap.listing", 
              generate_playlist_list()
        }),
     })
  });
}

//! 
array create_container_items(object id, string dbid, string playlist_id)
{
  mapping playlist = get_playlist(dbid, playlist_id);

  if(!playlist) return ({});
    
  return 
  ({  "daap.playlistsongs",
     ({
        ({"dmap.status", 200}),
        ({"dmap.updatetype", 0}),
        ({"dmap.specifiedtotalcount", sizeof(playlist->items)}),
        ({"dmap.returnedcount", sizeof(playlist->items)}),
        ({"dmap.listing", 
              generate_playlist_items(dbid, playlist_id)
        }),
     })
  });
}
//!
array create_databases(object id)
{
  return 
  ({ "daap.serverdatabases", 
     ({
        ({"dmap.status", 200}),
        ({"dmap.updatetype", 0}),
        ({"dmap.specifiedtotalcount", 1}),
        ({"dmap.returnedcount", 1}),
        ({"dmap.listing", 
            ({ ({
               "dmap.listingitem",
               get_db_info()
               })
            })
         })
     })
  });
}

//!
array|mapping create_update(object id, int|void is_revised)
{
  if(!app->locks[id->variables->sessionid||1] || is_revised)
  {
    app->locks[id->variables->sessionid||1] = 1;
    return 
      ({"dmap.updateresponse",
        ({
          ({"dmap.status", 200}),
          ({"dmap.serverrevision", app->revision_num})
        })
      });
  } 
  else
  {
    id->send_timeout_delay = 60*60*24; // 1 day.
    
    log->debug("locking till change.");
    app->locks[id->variables->sessionid||1] = id;
    return (["_is_pipe_response": 1]);
//    return 0;
  }
}

//!
array create_server_info(object id)
{
//  werror("%O", mkmapping(indices(id), values(id)));

  m_delete(app->locks, id->variables->sessionid||1);
  
  return
  ({"dmap.serverinforesponse", 
    ({
      	({"dmap.status", 200}),
      	({"daap.protocolversion", "3.0"}),
	      ({"dmap.protocolversion", "2.0"}),
	      ({"com.apple.itunes.music-sharing-version", 196617}),
      	({"dmap.itemname", app->db->get_name()}),
        ({"dmap.authenticationschemes", 2}),
      	({"dmap.timeoutinterval", 1800}),
      	({"dmap.supportsextensions", 1}),
	      ({"dmap.supportsindex", 1}),
      	({"dmap.supportsbrowse", 1}),
      	({"dmap.supportsquery", 1}),
	      ({"dmap.supportsupdate", 0}),
	      ({"dmap.databasescount", 1})
    })
  });
}

mapping create_logout(object id)
{
  return (["error": 200, "type": "application/x-dmap-tagged", "data": ""]);
}

//!
array create_login(object id)
{
  int session_id = (int)Crypto.Random.random(1<<31);

  app->sessions[session_id] = ([]);
log->info("session_id:" + session_id);

  return 
  ({  "dmap.loginresponse", 
    ({
       ({"dmap.status", 200}),
       ({"dmap.sessionid",  session_id})
    })
  });
}

//!
array create_content_codes(object id)
{
  array codes = make_content_tag_codes_array();
  codes = ({ ({"dmap.status", 200}) }) + codes;
  ({ "dmap.contentcodesresponse",
	codes
  });
}

array make_content_tag_codes_array()
{
  array codes = ({});

  foreach(content_types;;mapping ce)
  {
        codes += ({ ({"dmap.dictionary",
           ({
             ({"dmap.contentcodesname", ce["name"]}),
             ({"dmap.contentcodesnumber", ce["code"] }),
             ({"dmap.contentcodestype", ce["type"]}),
           })
        })
       });
  }

  return codes;
}

array get_db_info()
{
  return 
    ({  
        ({"dmap.itemid", app->db->get_id()}),
        ({"dmap.persistentid", app->db->get_pid()}),
        ({"dmap.itemname", app->db->get_name()}),
        ({"dmap.itemcount", app->db->get_song_count()}),
        ({"dmap.containercount", app->db->get_playlist_count() + 2}),
    });
}

array generate_deleted_ids(int revision)
{
  array x = app->db->get_removed_in_revision(revision);
  array y = allocate(sizeof(x));
  foreach(x;int i; int id)
  {
    y[i] = ({"dmap.itemid", id});
  }
  
  return y;
}

int get_song_count()
{  
  return app->db->get_song_count();
}

int get_playlist_count()
{  
  return app->db->get_playlist_count();
}

mapping get_playlist(string dbid, string plid)
{
  if(plid == "1035" || plid == "743")
  {
    return (["items": app->db->get_songs()]);
  }
  else return app->db->get_playlist(plid);
}

array generate_song_list(object id)
{
  
//  werror("looking for %O\n", id->variables->meta/",");

  if(id->variables->type != "music")
    return 0; // will probably throw an error as a result.
  
  array songs;
  
  if(id->variables["delta"])
    songs = app->db->get_songs((int)id->variables["revision-number"], (int)id->variables["delta"]);
  else
    songs = app->db->get_songs();
    
  array list = allocate(sizeof(songs));
  foreach(songs;int i; mapping song)
  {
     list[i] = ({"dmap.listingitem", 
           ({
             ({"dmap.itemkind", 2}),
             ({"dmap.itemid", song["id"]}),
             ({"dmap.itemname", song["title"]||"---"}),
              ({"dmap.persistentid", song["id"]}),
              ({"dmap.mediakind", 1}),
              ({"daap.songartist", song["artist"]||""}),
              ({"daap.songalbum", song["album"]||""}),
              ({"daap.songtracknumber", (int)song["track"]||0}),
              ({"daap.songtrackcount", (int)song["trackcount"]||0}),
              ({"daap.songgenre", song["genre"]||"Unknown"}),
              ({"daap.songyear", ((int)song["year"]) || 0}),
              ({"daap.songtime", ((int)song["length"] || 0)}),
              ({"daap.songsize", ((int)song["size"] || 0)}),
              ({"daap.songdatemodified", ((int)song["modified"] || 0)}),
              ({"daap.songformat", song["format"]}),
              ({"daap.songdatakind", 0})
           })
       });
  }
  
  //werror("list: %O\n", list);
  return list;
}

array generate_playlist_list()
{
  array playlists = app->db->get_playlists();
  array list = allocate(app->db->get_playlist_count() + 2);

//
// protocol note:
// the first playlist is always the full library.
//


list[0] = ({"dmap.listingitem", 
      ({
        
        ({"dmap.itemid", 743}),
        ({"dmap.persistentid",13950142391337751524}),
        ({"dmap.itemname", app->db->get_name()}),
        ({"daap.baseplaylist", 1}),
        ({"dmap.parentcontainerid", 0}),
        ({"com.apple.itunes.smart-playlist",1}),
        ({"dmap.itemcount", get_song_count()}),
      })
  });

  list[1] = ({"dmap.listingitem", 
        ({
          ({"dmap.itemid", 1035}),
          ({"dmap.persistentid",11114120178827494565}),
          ({"dmap.itemname", "Music"}),
          ({"com.apple.itunes.smart-playlist",1}),
          ({"dmap.parentcontainerid", 0}),
          ({"com.apple.itunes.special-playlist",6}),
          ({"dmap.itemcount", get_song_count()}),
        })
    });

  foreach(playlists;int i; mapping playlist)
  {
     list[i+2] = ({"dmap.listingitem", 
           ({
             ({"dmap.itemid", playlist["id"]}),
             ({"dmap.persistentid", playlist["persistentid"] || playlist["id"]}),
             ({"dmap.itemname", playlist["name"]}),
              ({"com.apple.itunes.smart-playlist", playlist["smart"]}),
              ({"dmap.itemcount", sizeof(playlist["items"])}),
           })
       });
  }
  return list;
}

array generate_playlist_items(string dbid, string plid)
{
  log->info("getting playlist items for " + plid + "\n");
  mapping playlist;
  playlist = get_playlist(dbid, plid);
  
  array list = allocate(sizeof(playlist->items));

  foreach(playlist->items;int i; mapping song)
  {
     list[i] = ({"dmap.listingitem", 
           ({
             ({"dmap.itemkind", 2}),
             ({"dmap.itemid", song["id"]}),
             ({"dmap.containeritemid", song["id"]}),
           })
       });
  }
 //werror("list: %O\n", list);
  return list;
}
