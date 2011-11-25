#charset utf8 

constant id3v2_map = ([
    "TALB": "album",
    "TIT2": "title",
    "TPE1": "artist",
    "TYER": "year",
    "TRCK": "track",
    "COMM": "comment",
    "TCON": "genre",
    "TLEN": "length",
    "TT2": "title",
    "TP1": "artist",
    "TAL": "album",
    "TRK": "track",
    "TCO": "genre"
  ]);

constant id3_genres = ([
0 : "Blues",
1 : "Classic Rock",
2 : "Country",
3 : "Dance",
4 : "Disco",
5 : "Funk",
6 : "Grunge",
7 : "Hip-Hop",
8 : "Jazz",
9 : "Metal",
10: "New Age",
11: "Oldies",
12: "Other",
13: "Pop",
14: "R&B",
15: "Rap",
16: "Reggae",
17: "Rock",
18: "Techno",
19: "Industrial",
20: "Alternative",
21: "Ska",
22: "Death Metal",
23: "Pranks",
24: "Soundtrack",
25: "Euro-Techno",
26: "Ambient",
27: "Trip-Hop",
28: "Vocal",
29: "Jazz+Funk",
30: "Fusion",
31: "Trance",
32: "Classical",
33: "Instrumental",
34: "Acid",
35: "House",
36: "Game",
37: "Sound Clip",
38: "Gospel",
39: "Noise",
40: "Alternative Rock",
41: "Bass",
42: "Soul",
43: "Punk",
44: "Space",
45: "Meditative",
46: "Instrumental Pop",
47: "Instrumental Rock",
48: "Ethnic",
49: "Gothic",
50: "Darkwave",
51: "Techno-Industrial",
52: "Electronic",
53: "Pop-Folk",
54: "Eurodance",
55: "Dream",
56: "Southern Rock",
57: "Comedy",
58: "Cult",
59: "Gangsta",
60: "Top 40",
61: "Christian Rap",
62: "Pop/Funk",
63: "Jungle",
64: "Native US",
65: "Cabaret",
66: "New Wave",
67: "Psychadelic",
68: "Rave",
69: "Showtunes",
70: "Trailer",
71: "Lo-Fi",
72: "Tribal",
73: "Acid Punk",
74: "Acid Jazz",
75: "Polka",
76: "Retro",
77: "Musical",
78: "Rock & Roll",
79: "Hard Rock",
80: "Folk",
81: "Folk-Rock",
82: "National Folk",
83: "Swing",
84: "Fast Fusion",
85: "Bebob",
86: "Latin",
87: "Revival",
88: "Celtic",
89: "Bluegrass",
90: "Avantgarde",
91: "Gothic Rock",
92: "Progressive Rock",
93: "Psychedelic Rock",
94: "Symphonic Rock",
95: "Slow Rock",
96: "Big Band",
97: "Chorus",
98: "Easy Listening",
99: "Acoustic",
100: "Humour",
101: "Speech",
102: "Chanson",
103: "Opera",
104: "Chamber Music",
105: "Sonata",
106: "Symphony",
107: "Booty Bass",
108: "Primus",
109: "Porn Groove",
110: "Satire",
111: "Slow Jam",
112: "Club",
113: "Tango",
114: "Samba",
115: "Folklore",
116: "Ballad",
117: "Power Ballad",
118: "Rhythmic Soul",
119: "Freestyle",
120: "Duet",
121: "Punk Rock",
122: "Drum Solo",
123: "Acapella",
124: "Euro-House",
125: "Dance Hall",
126: "Goa",
127: "Drum & Bass",
128: "Club & House",
129: "Hardcore",
130: "Terror",
131: "Indie",
132: "BritPop",
133: "Negerpunk",
134: "Polsk Punk",
135: "Beat",
136: "Christian Gangsta Rap",
137: "Heavy Metal",
138: "Black Metal",
139: "Crossover",
140: "Contemporary Christian",
141: "Christian Rock",
142: "Merengue",
143: "Salsa",
144: "Thrash Metal",
145: "Anime",
146: "JPop",
147: "Synthpop"
]);

constant atom_map = 
  ([
     "©alb": "album",
     "©ART": "artist",
     "©day": "year",
     "©nam": "title",
     "©gen": "genre",
     "gnre": "genre",
     "trkn": "track",
     "©wrt": "composer",
     "©cmt": "comment",
     "disk": "disk",
     "cpil": "compilation"
  ]);

class ID3 {
     inherit ADT.Struct;
     Item head = Chars(3);
     Item title = Chars(30);
     Item artist = Chars(30);
     Item album = Chars(30);
     Item year = Chars(4);
     Item comment = Chars(30);
     Item genre = Byte();
   }

class mon
{
  inherit Filesystem.Monitor.symlinks;

   ADT.Queue delete_queue = ADT.Queue();
   ADT.Queue create_queue = ADT.Queue();
   ADT.Queue exists_queue = ADT.Queue();
   
   object db; 
   
   Pike.Backend check_backend;
   Pike.Backend process_backend;

   int should_quit = 0;
   
   // our filesystem monitor uses 2 threads:
   //   1 - a thread to run the actual filesystem check
   //   2 - a thread to process the changes to the filesystem
   //
   //  1 exists in order to prevent the main thread from getting bogged
   //  down when a large number of files exist to monitor and the second
   //  thread is used to minimise the amount of time spent initializing 
   //  the monitor, as the monitor won't see changes until it finishes 
   //  flagging all existing files.
   static void create(mixed ... args)
   {
     ::create(@args);
    check_backend = Pike.Backend();
    process_backend = Pike.Backend();
    set_backend(check_backend);
    Thread.Thread(run_check_thread);
    Thread.Thread(run_process_thread);
    set_nonblocking(3);
  }
   
   void run_check_thread()
   {
     while(!should_quit)
     {
       check_backend(10.0);
     }
   }

   void run_process_thread()
   {
     while(!should_quit)
     {
       sleep(10);
       catch(m->process_entries());
     }
   }

  mapping read_id3(string path, object f)
  {
    mapping m;
    object t;
    if(catch(t = Standards.ID3.Tag(Stdio.File(path))))
      return 0;
    
    m = t->friendly_values();
    if(!sizeof(m))
      m->title = (basename(path)/".")[0];
//werror("t: %O\n", t);    
    if(t->frame_map && t->frame_map["TLEN"])
    {
//      werror("%O\n", t->frame_map["TLEN"][0]->data->value);
      m->length = t->frame_map["TLEN"][0]->data->value;
    }
    if(t->frame_map && t->frame_map["TP1"])
    {
    //      werror("%O\n", t->frame_map["TLEN"][0]->data->value);
      m->artist = (t->frame_map["TP1"][0]->data->data)-"\0";
    }

    m = map(m, lambda(mixed v){return (stringp(v)?String.trim_whites(v):v);});

    // genres seem to be either a string containing the genre name, an integer or an integer 
    // surrounded by parens. we try to sort out this insanity here.
    if(m && has_index(m, "genre")){
 //     werror("genre: %O\n", m->genre);
      int genre;
      if(sscanf(m->genre, "%*[\(]%d)", genre))
        m->genre = id3_genres[(int)m->genre] || "Unknown Genre";
    }
    return m;
  }
  
  void process_entries()
  {
    while(!delete_queue->is_empty())
    {
      low_file_deleted(@delete_queue->read());
    }
    
    while(!exists_queue->is_empty())
    {
      low_file_exists(@exists_queue->read());      
    }
    
    while(!create_queue->is_empty())
    {
      low_file_created(@create_queue->read());      
    }
  }

  void file_deleted(string p, Stdio.Stat s)
  {
      delete_queue->write(({p, s}));
  }
  
  void file_created(string p, Stdio.Stat s)
  {
    create_queue->write(({p, s}));
    
  }
  
  void file_exists(string p, Stdio.Stat s)
  {
    exists_queue->write(({p, s}));
    
  }
  
  void low_file_deleted(string p, Stdio.Stat s)
  {
    werror("file deleted: %O\n", p);
    db->remove(p);
  }
  
  void low_file_created(string p, Stdio.Stat s)
  {
    werror("file created: %O\n", p);
    file_exists(p, s);
  }

  void low_file_exists(string p, Stdio.Stat s)
  {
    mapping atts = ([]);
    if(!s->isdir && s->isreg)
    {
   //   werror("file exists: %O\n", p);
      mapping a;
      if(a = read_id3(p, s))
      {
        atts = atts + a;
     //   werror("got id3: %O\n", a);
      }
      else if(a = read_atoms(p, s))
      {
        string field;
        if(a->moov && a->moov->udta && a->moov->udta->meta)
        {
          a = a->moov->udta->meta;
        }
        foreach(a->ilst||([]);string key; mixed val)
        {
          
          if(field = atom_map[key])
            atts[field] = val;
   //     else werror("unknown atom %O\n", atom);
        }
        
//werror("atts: %O\n", atts);
      }
      
      if(sizeof(atts))
      {  
        if(atts->track && stringp(atts->track))
        {
          int tracknum, trackcount;
          sscanf(atts->track, "%d of %d", tracknum, trackcount);
          if(tracknum)
            atts->track = (string)tracknum;
          if(trackcount)
            atts->trackcount = (string)trackcount;
        }
        else if(atts->track && arrayp(atts->track))
        {
          if(sizeof(atts->track) > 1)
            atts->trackcount = (string)atts->track[1];
          atts->track = (string)atts->track[0];
        }
      //  werror("metadata: %O\n", atts);
      }
    }
    if(sizeof(atts))
    {
      atts["path"] = p;
      if(db) 
        db->add(atts);      
    }
//    else werror("SCAN ERROR: %s\n", p);
  }
}

mapping read_atoms(string p, object s)
{
   object atomsmasher = (object)"atoms";
   
   mapping m;
   catch(m = atomsmasher->parse(p));
   //werror("%O\n", m);
   return m;
}

object m;

void check(string path, object db)
{
  m = mon(Filesystem.Monitor.basic.MF_RECURSE);
  m->db = db;
  m->monitor(path, Filesystem.Monitor.basic.MF_RECURSE);
  werror("registering music path " + path  + "\n");
}

int main()
{
  m = mon(Filesystem.Monitor.basic.MF_RECURSE);
  m->monitor("/Users/hww3/Music/iTunes/iTunes Media/Music", Filesystem.Monitor.basic.MF_RECURSE);

  m->set_nonblocking();

  return -1;  
}
