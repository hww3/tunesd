inherit Fins.Application;
inherit "dmap";

// the default music path if one isn't specified.
#define MUSICPATH "$HOME/Music/iTunes/iTunes Media/Music"

// the default network port to listen on if one isn't specified.
#define SERVERPORT 3689

#define DBURL "sqlite://tunesd.sqlite3"

string musicpath;
string version = "0.1";

mapping locks = ([]);

mapping sessions = ([]);
int revision_num = 1;

object db;
object check = ((program)"check")();

object port;
int default_port = SERVERPORT;
Protocols.DNS_SD.Service bonjour;

int main(int argc, array(string) argv) { 
  int my_port = default_port; 
  if(argc>2) my_port=(int)argv[2];


  write("Music stored in " + musicpath + ".\n");
  write("FinServe starting on port " + my_port + "...\n");

  start();

  port = Protocols.HTTP.Server.Port(handle_request, my_port); 
/*
  bonjour = Protocols.DNS_SD.Service(db->get_name(),
                     "_daap._tcp", "", (int)my_port);
*/
  log->info("Advertising this application via Bonjour.");
    
  return -1; 
}

void start()
{
  musicpath = replace(config["music"]["path"], "$HOME", getenv()["HOME"]);
werror("********\n*******\n");  
  // the db is actually loaded by fins into "model", but for the sake of code already written, we keep db as an alias.
  db = model;
  model->start();
//  db = ((program)"db")(DBURL, server_did_revise);
  call_out(register_bonjour, 1);
  check->check(musicpath, model);
}

void register_bonjour()
{
  db = model;

// we might also use avahi:
// avahi-publish -s tunesd _daap._tcp 3689
//  bonjour = Protocols.DNS_SD.Service(db->get_name(),
////                   "_daap._tcp", "", (int)8001);
//                   "_daap._tcp", "", (int)__fin_serve->my_port);

  log->info("Advertising tunesd/DAAP via Bonjour.");

}

void server_did_revise(int revision)
{
  log->debug("change recieved.");
  revision_num = revision;
  foreach(locks;mixed sessionid;object lock)
  {
    m_delete(locks, sessionid);
    if(!objectp(lock)) continue;
    mixed response = create_update(lock, 1);
    lock->response_and_finish(create_response(response, 200));
  }    
}

mixed handle_http(Protocols.HTTP.Server.Request request)
{
  array|mapping response;
  
  werror("request: %O\n", request);
  if(has_prefix(request->not_query, "daap://"))
  {
   // werror("rewriting...");
    object uri = Standards.URI(request->not_query);
    request->not_query=uri->path;
    request->query = uri->get_http_query();
    //werror(" " + request->not_query + "\n");
  }

werror("request: %O\n", request);
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
  
  response = ::handle_http(request);
  
  if(response) return response;
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
  string song = db->get_song_path(songid);

  object s = file_stat(song);
  werror("song file is %s: %O\n", song, s);

  db->bump(songid);
  
  if(song)
    return (["type": "audio/" + db->get_song(songid)["format"]/*"application/x-dmap-tagged"*/, "extra_heads": (["DAAP-Server": "tunesd/" + version]), "file": Stdio.File(song)]);  
  else 
    return (["type": "text/plain", "error": 404, "extra_heads": (["DAAP-Server": "tunesd/" + version]),  "data": "song not found."]);
}

mapping auth_required(string realm)
{
  mapping hauth = ([]);
  string type;
  int code = 401;
  type="text/plain";
  string data = "authentication required.";
  hauth["WWW-Authenticate"] = "Basic realm=\"webserver\"";
  
  return (["server": "tunesd/" + version, "type": type, 
    "extra_heads": (["Accept-Ranges": "bytes", "DAAP-Server": "tunesd/" + version]) + hauth, 
    "error": code, "data": data]);
}
mapping create_response(array|mapping data, int code)
{
  if(mappingp(data)) 
    return data;
  else  
    return (["server": "tunesd/" + version, "type": "application/x-dmap-tagged", 
      "extra_heads": (["Accept-Ranges": "bytes", "DAAP-Server": "tunesd/" + version]), 
      "error": code, "data": encode_dmap(data)]);
}

//! 
array create_items(object id, string dbid)
{
  array x = 
       ({
          ({"dmap.status", 200}),
          ({"dmap.updatetype", db->has_removed_in_revision((int)(id->variables["revision-number"]))?1:0}),
          ({"dmap.specifiedtotalcount", get_song_count()}),
          ({"dmap.returnedcount", get_song_count()}),
          ({"dmap.listing", 
                generate_song_list(id)
          })
  //        ({"dmap.deletedidlisting", ({  ({"dmap.itemid", id) }) });
       });
  
  if(db->has_removed_in_revision((int)(id->variables["revision-number"])))
  {
    werror("have removed items...\n");
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
        ({"dmap.specifiedtotalcount", get_playlist_count() + 1}),
        ({"dmap.returnedcount", get_playlist_count() + 1}),
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
  werror("playlist " + playlist_id + "\n");

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
  if(!locks[id->variables->sessionid||1] || is_revised)
  {
    locks[id->variables->sessionid||1] = 1;
    return 
      ({"dmap.updateresponse",
        ({
          ({"dmap.status", 200}),
          ({"dmap.serverrevision", revision_num})
        })
      });
  } 
  else
  {
    werror("locking till change.\n");
    locks[id->variables->sessionid||1] = id;
    return (["_is_pipe_response": 1]);
//    return 0;
  }
}

//!
array create_server_info(object id)
{
//  werror("%O", mkmapping(indices(id), values(id)));

  m_delete(locks, id->variables->sessionid||1);
  
  return
  ({"dmap.serverinforesponse", 
    ({
      	({"dmap.status", 200}),
      	({"daap.protocolversion", "3.0"}),
	      ({"dmap.protocolversion", "2.0"}),
      	({"dmap.itemname", db->get_name()}),
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

  sessions[session_id] = ([]);
werror("session_id:" + session_id);

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
        ({"dmap.itemid", db->get_id()}),
        ({"dmap.persistentid", db->get_pid()}),
        ({"dmap.itemname", db->get_name()}),
        ({"dmap.itemcount", db->get_song_count()}),
        ({"dmap.containercount", db->get_playlist_count()}),
    });
}

array generate_deleted_ids(int revision)
{
  array x = db->get_removed_in_revision(revision);
  array y = allocate(sizeof(x));
  foreach(x;int i; int id)
  {
    y[i] = ({"dmap.itemid", id});
  }
  
  return y;
}

int get_song_count()
{  
  return db->get_song_count();
}

int get_playlist_count()
{  
  return db->get_playlist_count();
}

mapping get_playlist(string dbid, string plid)
{
  if(plid == "39")
  {
    return (["items": db->get_songs()]);
  }
  else return db->get_playlist(plid);
}

array generate_song_list(object id)
{
  
//  werror("looking for %O\n", id->variables->meta/",");

  if(id->variables->type != "music")
    return 0; // will probably throw an error as a result.
  
  array songs;
  
  if(id->variables["delta"])
    songs = db->get_songs((int)id->variables["revision-number"], (int)id->variables["delta"]);
  else
    songs = db->get_songs();
    
  array list = allocate(sizeof(songs));
  foreach(songs;int i; mapping song)
  {
     list[i] = ({"dmap.listingitem", 
           ({
             ({"dmap.itemkind", 2}),
             ({"dmap.itemid", (int)song["id"]}),
             ({"dmap.itemname", song["title"]||"---"}),
              ({"dmap.persistentid", (int)song["id"]}),
              ({"dmap.mediakind", 1}),
              ({"daap.songartist", song["artist"]||""}),
              ({"daap.songalbum", song["album"]||""}),
              ({"daap.songtracknumber", (int)song["track"]||0}),
              ({"daap.songtrackcount", (int)song["trackcount"]||0}),
              ({"daap.songgenre", song["genre"]||"Unknown"}),
              ({"daap.songyear", ((int)song["year"]) || 0}),
              ({"daap.songtime", ((int)song["length"] || 0)}),
              ({"daap.songformat", song["format"]}),
              ({"daap.songdatakind", 0})
           })
       });
  }
  return list;
}

array generate_playlist_list()
{
  array playlists = db->get_playlists();
  array list = allocate(db->get_playlist_count() +1 );

//
// protocol note:
// the first playlist is always the full library.
//
  list[0] = ({"dmap.listingitem", 
        ({
          ({"dmap.itemid", 39}),
          ({"dmap.persistentid",13950142391337751524}),
          ({"dmap.itemname", db->get_name()}),
           ({"com.apple.itunes.smart-playlist",0}),
           ({"dmap.itemcount", get_song_count()}),
        })
    });

  foreach(playlists;int i; mapping playlist)
  {
     list[i+1] = ({"dmap.listingitem", 
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
  werror("getting playlist items for " + plid + "\n");
  mapping playlist;
  playlist = get_playlist(dbid, plid);
  
  array list = allocate(sizeof(playlist->items));

  foreach(playlist->items;int i; mapping song)
  {
     list[i] = ({"dmap.listingitem", 
           ({
             ({"dmap.itemkind", 2}),
             ({"dmap.itemid", (int)song["id"]}),
             ({"dmap.containeritemid", (int)song["id"]}),
           })
       });
  }
//  werror("list: %O\n", list);
  return list;
}
