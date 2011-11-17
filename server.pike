inherit "dmap";

mapping sessions = ([]);
int revision_num = time();
object db = ((program)"db")();

object port;
int default_port = 3689;
Protocols.DNS_SD.Service bonjour;

int main(int argc, array(string) argv) { 
  int my_port = default_port; 
  if(argc>1) my_port=(int)argv[1];

  write("FinServe starting on port " + my_port + "...");

  port = Protocols.HTTP.Server.Port(handle_request, my_port); 

  bonjour = Protocols.DNS_SD.Service("tunesd",
                     "_daap._tcp", "", (int)my_port);

  write("Advertising this application via Bonjour.");

  return -1; 
}

void handle_request(Protocols.HTTP.Server.Request request)
{
  array|mapping response;

  if(has_prefix(request->not_query, "daap://"))
  {
    object uri = Standards.URI(request->not_query);
    request->not_query=uri->path;
    request->query = uri->get_http_query();
  }

werror("request: %O\n", request);
  switch(request->not_query)
  {
     case "/server-info":
       response = create_server_info(request);
       break;
     case "/content-codes":
       response = create_content_codes(request);
       break;
     case "/login":
       response = create_login(request);
       break;
       case "/logout":
         response = create_logout(request);
         break;
     case "/update":
       response = create_update(request);
       break;
     case "/databases":
       response = create_databases(request);
       break;
     default:
       response = handle_sub_request(request);
  }
  
  //werror("response: %O\n", create_response(response, 200));
  request->response_and_finish(create_response(response, 200));
}

array|mapping handle_sub_request(object request)
{
    string dbid, plid, songid;
    // need to handle the following:
    // /databases/<dbid>/items
    // /databases/<dbid>/containers
    // /databases/<dbid>/containers/<plid>/items
    // /databases/<dbid>/items/<songid>.mp3

    if(sscanf(request->not_query, "/databases/%s/items/%s.mp3", dbid, songid) == 2)
    {
      
    }
    else if(sscanf(request->not_query, "/databases/%s/items", dbid) == 1)
    {
      return create_items(request);
    }
    else if(sscanf(request->not_query, "/databases/%s/containers/%s/items", dbid, plid) == 2)
    {
      
    }
    else if(sscanf(request->not_query, "/databases/%s/containers", dbid) == 1)
    {
      return create_containers(request);      
    }
    else
    {
      werror("yikes! a request we don't understand: %O\n", request);
      return (["error": 500, "data": "we don't know how to handle " + request->not_query + "!"]);
    }
    
}

mapping create_response(array|mapping data, int code)
{
  if(mappingp(data)) 
    return data;
  else
    return (["server": "tunesd/0.1", "type": "application/x-dmap-tagged", "error": code, "data": encode_dmap(data)]);
}

//! 
array create_items(object id)
{
  return 
  ({ "daap.databasesongs",
     ({
        ({"dmap.status", 200}),
        ({"dmap.updatetype", 0}),
        ({"dmap.specifiedtotalcount", get_song_count()}),
        ({"dmap.returnedcount", get_song_count()}),
        ({"dmap.listing", 
              generate_song_list()
        }),
     })
  });

}

//! 
array create_containers(object id)
{
  return 
  ({  "daap.databaseplaylists",
     ({
        ({"dmap.status", 200}),
        ({"dmap.updatetype", 0}),
        ({"dmap.specifiedtotalcount", get_playlist_count()}),
        ({"dmap.returnedcount", get_playlist_count()}),
        ({"dmap.listing", 
              generate_playlist_list()
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
array create_update(object id)
{
  return 
  ({"dmap.updateresponse",
     ({
        ({"dmap.status", 200}),
        ({"dmap.serverrevision", 77})
     })
  });
}

//!
array create_server_info(object id)
{
//  werror("%O", mkmapping(indices(id), values(id)));
  return
  ({"dmap.serverinforesponse", 
    ({
      	({"dmap.status", 200}),
	({"daap.protocolversion", id->request_headers["client-daap-version"]}),
	({"dmap.supportsindex", 1}),
//	({"dmap.supportsextensions", 0}),
//	({"dmap.supportsupdate", 1}),
	({"dmap.supportsuatologout", 1}),
	({"dmap.timeoutinterval", 1800}),
	({"dmap.loginrequired", 1}),
//	({"dmap.supportsquery", 0}),
	({"dmap.itemname", "tunesd"}),
//	({"dmap.supportsresolve", 0}),
	({"dmap.supportsbrowse", 1}),
	({"dmap.supportspersistentids", 1}),
	({"dmap.protocolversion", "2.0"}),
	({"dmap.databasescount", 2})
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

int get_song_count()
{  
  return db->get_song_count();
}

int get_playlist_count()
{  
  return db->get_playlist_count();
}

array generate_song_list()
{
  array songs = db->get_songs();
  array list = allocate(db->get_song_count());
  foreach(songs;int i; mapping song)
  {
     list[i] = ({"dmap.listingitem", 
           ({
              ({"dmap.itemkind", 2}),
              ({"dmap.itemid", song["id"]}),
              ({"dmap.itemname", song["name"]}),
              ({"daap.songtime", song["length"] * 1000})
           })
       });
  }
  return list;
}

array generate_playlist_list()
{
  array playlists = db->get_playlists();
  array list = allocate(db->get_playlist_count());
  foreach(playlists;int i; mapping playlist)
  {
     list[i] = ({"dmap.listingitem", 
           ({
              ({"dmap.itemkind", 2}),
              ({"dmap.itemid", playlist["id"]}),
              ({"dmap.itemname", playlist["name"]}),
              ({"daap.songtime", playlist["length"] * 1000})
           })
       });
  }
  return list;
}