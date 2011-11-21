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
     "©art": "artist",
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

   object db; 
   
  mapping read_id3(string path)
  {
    mapping m;
    
    if(!(m = read_id3v2(path)))
      m = read_id3v1(path);
    
    if(m)
    {
      // massage the data
      
      if(m->genre)
      {
        int genre;
        sscanf(m->genre, "(%d)", genre);
        if(genre) m->genre = id3_genres[genre];
      }  
    }
    
    return m;  
      
  }
  mapping read_id3v2(string path)
  {
    string atom, value;
    mapping atts = ([]);
    array x = Process.popen("/opt/local/bin/id3info \"" + path + "\"")/"\n";
     foreach(x;;string line)
      {
        if(sscanf(line, "=== %4[A-Z0-9] (%*s): %s", atom, value))
        {
          string field;
          if((field = id3v2_map[utf8_to_string(atom)]) && !atts[field])
            atts[field] = value;
//          else werror("unknown atom %O\n", atom);
        }
      }
    
    if(sizeof(atts))
      return atts;
    else return 0;
  }
  
  mapping read_id3v1(string path)
  {

   Stdio.File f = Stdio.File(path);
   f->seek(-128);
   ADT.Struct tag = ID3(f);
   if(tag->head=="TAG") {
     mapping m = ([]);
     mixed err;
     err = catch(m = map(map((["title": (string)tag->title,
         "artist": (string) tag->artist,
         "album": (string) tag->album,
         "year": (string) tag->year,
         "comment": (string) tag->comment,
         "genre": id3_genres[tag->genre]
       ]), String.trim_all_whites), lambda(string a){return a-"\0";}));
  
     if(err) 
     {
      werror("failed to extract metadata from %O.\n");
       return ([]);
     }     
     return m;
     
   }
   else return 0;
  }

  void file_created(string p, Stdio.Stat s)
  {
    werror("file created: %O\n", p);
  }

  void file_exists(string p, Stdio.Stat s)
  {
    mapping atts = ([]);
    if(s->isreg)
    {
      string atom, value;
 //     werror("file exists: %O\n", p);
      mapping a;
      if(a = read_id3(p))
      {
        atts = atts + a;
      }
      else
      {
        array x = (Process.popen("/Users/hww3/Downloads/AtomicParsley-MacOSX-0.9.0/AtomicParsley \"" + p + "\" -t 2>&1"))/"\n";
        foreach(x;;string line)
        {
          if(sscanf(line, "Atom \"%s\" contains: %s", atom, value))
          {
            string field;
            if(field = atom_map[utf8_to_string(atom)])
              atts[field] = value;
   //         else werror("unknown atom %O\n", atom);
          }
        }
      }
      
      if(sizeof(atts))
      {  
        if(atts->track)
        {
          int tracknum, trackcount;
          sscanf(atts->track, "%d of %d", tracknum, trackcount);
          if(tracknum)
            atts->track = (string)tracknum;
          if(trackcount)
            atts->trackcount = (string)trackcount;
        }
      //  werror("metadata: %O\n", atts);
}
    }
    
    atts["path"] = p;
    if(db) db->add(atts);
  }
}

object m;

void check(string path, object db)
{
  m = mon(Filesystem.Monitor.basic.MF_RECURSE);
  m->db = db;
  m->monitor(path, Filesystem.Monitor.basic.MF_RECURSE);
  
  check_backend = Pike.Backend();
  m->set_backend(check_backend);
  Thread.Thread(run_check_thread);
  m->set_nonblocking(3);
}

void run_check_thread()
{
  while(!should_quit)
  {
    check_backend(5.0);
  }
}

Pike.Backend check_backend;
int should_quit = 0;

int main()
{
  m = mon(Filesystem.Monitor.basic.MF_RECURSE);
  m->monitor("/Users/hww3/Music/iTunes/iTunes Media/Music", Filesystem.Monitor.basic.MF_RECURSE);

  m->set_nonblocking();

  return -1;  
}
