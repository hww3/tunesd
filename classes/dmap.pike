//
// type definitions
//

//!
constant T_BYTE = 1;

//!
constant T_UBYTE = 2;

//!
constant T_SHORT = 3;

//!
constant T_USHORT = 4;

//!
constant T_INT = 5;

//!
constant T_UINT = 6;

//!
constant T_LONG = 7;

//!
constant T_ULONG = 8;

//!
constant T_STRING = 9;

//! date (represented as a 4 byte time_t style integer)
constant T_DATE = 10; // 

//! version (represented as either 4 single bytes, e.g. 0.1.0.0 or as two shorts, e.g. 1.0
constant T_VERSION = 11; 

//!
constant T_LIST = 12;

constant content_tags = 
([
  "dmap.mediakind": (["name": "dmap.mediakind", "type": T_INT, "code": "aeMK"]),  
"dmap.authenticationschemes": (["name": "dmap.authenticationschemes", "type": T_BYTE, "code": "msas"]),  
"dmap.dictionary": (["name": "dmap.dictionary", "type": T_LIST, "code": "mdcl" ]),
"dmap.status": (["name": "dmap.status", "type": T_INT, "code": "mstt" ]),
"dmap.itemid": (["name": "dmap.itemid", "type": T_INT, "code": "miid" ]),
"dmap.itemname": (["name": "dmap.itemname", "type": T_STRING, "code": "minm" ]),
"dmap.itemkind": (["name": "dmap.itemkind", "type": T_BYTE, "code": "mikd" ]),
"dmap.persistentid": (["name": "dmap.persistentid", "type": T_LONG, "code": "mper" ]),
"dmap.container": (["name": "dmap.container", "type": T_LIST, "code": "mcon" ]),
"dmap.containeritemid": (["name": "dmap.containeritemid", "type": T_INT, "code": "mcti" ]),
"dmap.parentcontainerid": (["name": "dmap.parentcontainerid", "type": T_INT, "code": "mpco" ]),
"dmap.statusstring": (["name": "dmap.statusstring", "type": T_STRING, "code": "msts" ]),
"dmap.itemcount": (["name": "dmap.itemcount", "type": T_INT, "code": "mimc" ]),
"dmap.returnedcount": (["name": "dmap.returnedcount", "type": T_INT, "code": "mrco" ]),
"dmap.specifiedtotalcount": (["name": "dmap.specifiedtotalcount", "type": T_INT, "code": "mtco" ]),
"dmap.containercount": (["name": "dmap.containercount", "type": T_INT, "code": "mctc"]),
"dmap.listing": (["name": "dmap.listing", "type": T_LIST, "code": "mlcl" ]),
"dmap.listingitem": (["name": "dmap.listingitem", "type": T_LIST, "code": "mlit" ]),
"dmap.bag": (["name": "dmap.bag", "type": T_LIST, "code": "mbcl" ]),
"dmap.dictionary": (["name": "dmap.dictionary", "type": T_LIST, "code": "mdcl" ]),
"dmap.serverinforesponse": (["name": "dmap.serverinforesponse", "type": T_LIST, "code": "msrv" ]),
"dmap.authenticationmethod": (["name": "dmap.authenticationmethod", "type": T_BYTE, "code": "msaud" ]),
"dmap.loginrequired": (["name": "dmap.loginrequired", "type": T_BYTE, "code": "mslr" ]),
"dmap.protocolversion": (["name": "dmap.protocolversion", "type": T_VERSION, "code": "mpro" ]),
"daap.protocolversion": (["name": "daap.protocolversion", "type": T_VERSION, "code": "apro" ]),
"dmap.supportsuatologout": (["name": "dmap.supportsuatologout", "type": T_BYTE, "code": "msal" ]),
"dmap.supportsupdate": (["name": "dmap.supportsupdate", "type": T_BYTE, "code": "msup" ]),
"dmap.supportspersistentids": (["name": "dmap.supportspersistentids", "type": T_BYTE, "code": "mspi" ]),
"dmap.supportsextensions": (["name": "dmap.supportsextensions", "type": T_BYTE, "code": "msex" ]),
"dmap.supportsbrowse": (["name": "dmap.supportsbrowse", "type": T_BYTE, "code": "msbr" ]),
"dmap.supportsquery": (["name": "dmap.supportsquery", "type": T_BYTE, "code": "msqy" ]),
"dmap.supportsindex": (["name": "dmap.supportsindex", "type": T_BYTE, "code": "msix" ]),
"dmap.supportsresolve": (["name": "dmap.supportsresolve", "type": T_BYTE, "code": "msrs" ]),
"dmap.timeoutinterval": (["name": "dmap.timeoutinterval", "type": T_INT, "code": "mstm" ]),
"dmap.databasescount": (["name": "dmap.databasescount", "type": T_INT, "code": "msdc" ]),
"dmap.contentcodesresponse": (["name": "dmap.contentcodesresponse", "type": T_LIST, "code": "mccr" ]),
"dmap.contentcodesnumber": (["name": "dmap.contentcodesnumber", "type": T_INT, "code": "mcnm" ]),
"dmap.contentcodesname": (["name": "dmap.contentcodesname", "type": T_STRING, "code": "mcna" ]),
"dmap.contentcodestype": (["name": "dmap.contentcodestype", "type": T_SHORT, "code": "mcty" ]),
"dmap.loginresponse": (["name": "dmap.loginresponse", "type": T_LIST, "code": "mlog" ]),
"dmap.sessionid": (["name": "dmap.sessionid", "type": T_INT, "code": "mlid" ]),
"dmap.updateresponse": (["name": "dmap.updateresponse", "type": T_LIST, "code": "mupd" ]),
"dmap.serverrevision": (["name": "dmap.serverrevision", "type": T_INT, "code": "musr" ]),
"dmap.updatetype": (["name": "dmap.updatetype", "type": T_BYTE, "code": "muty" ]),
"dmap.deletedidlisting": (["name": "dmap.deletedidlisting", "type": T_LIST, "code": "mudl" ]),
"daap.serverdatabases": (["name": "daap.serverdatabases", "type": T_LIST, "code": "avdb" ]),
"daap.databasebrowse": (["name": "daap.databasebrowse", "type": T_LIST, "code": "abro" ]),
"daap.browsealbumlistung": (["name": "daap.browsealbumlistung", "type": T_LIST, "code": "abal" ]),
"daap.browseartistlisting": (["name": "daap.browseartistlisting", "type": T_LIST, "code": "abar" ]),
"daap.browsecomposerlisting": (["name": "daap.browsecomposerlisting", "type": T_LIST, "code": "abcp" ]),
"daap.browsegenrelisting": (["name": "daap.browsegenrelisting", "type": T_LIST, "code": "abgn" ]),
"daap.databasesongs": (["name": "daap.databasesongs", "type": T_LIST, "code": "adbs" ]),
"daap.songalbum": (["name": "daap.songalbum", "type": T_STRING, "code": "asal" ]),
"daap.songartist": (["name": "daap.songartist", "type": T_STRING, "code": "asar" ]),
"daap.songsbeatsperminute": (["name": "daap.songsbeatsperminute", "type": T_SHORT, "code": "asbt" ]),
"daap.songbitrate": (["name": "daap.songbitrate", "type": T_SHORT, "code": "asbr" ]),
"daap.songcomment": (["name": "daap.songcomment", "type": T_STRING, "code": "ascm" ]),
"daap.songcompilation": (["name": "daap.songcompilation", "type": T_BYTE, "code": "asco" ]),
"daap.songdateadded": (["name": "daap.songdateadded", "type": T_DATE, "code": "asda" ]),
"daap.songdatemodified": (["name": "daap.songdatemodified", "type": T_DATE, "code": "asdm" ]),
"daap.songdisccount": (["name": "daap.songdisccount", "type": T_SHORT, "code": "asdc" ]),
"daap.songdiscnumber": (["name": "daap.songdiscnumber", "type": T_SHORT, "code": "asdn" ]),
"daap.songdisabled": (["name": "daap.songdisabled", "type": T_BYTE, "code": "asdb" ]),
"daap.songeqpreset": (["name": "daap.songeqpreset", "type": T_STRING, "code": "aseq" ]),
"daap.songformat": (["name": "daap.songformat", "type": T_STRING, "code": "asfm" ]),
"daap.songgenre": (["name": "daap.songgenre", "type": T_STRING, "code": "asgn" ]),
"daap.songdescription": (["name": "daap.songdescription", "type": T_STRING, "code": "asdt" ]),
"daap.songrelativevolume": (["name": "daap.songrelativevolume", "type": T_BYTE, "code": "asrv" ]),
"daap.songsamplerate": (["name": "daap.songsamplerate", "type": T_INT, "code": "assr" ]),
"daap.songsize": (["name": "daap.songsize", "type": T_INT, "code": "assz" ]),
"daap.songstarttime": (["name": "daap.songstarttime", "type": T_INT, "code": "asst" ]),
"daap.songstoptime": (["name": "daap.songstoptime", "type": T_INT, "code": "assp" ]),
"daap.songtime": (["name": "daap.songtime", "type": T_INT, "code": "astm" ]),
"daap.songtrackcount": (["name": "daap.songtrackcount", "type": T_SHORT, "code": "astc" ]),
"daap.songtracknumber": (["name": "daap.songtracknumber", "type": T_SHORT, "code": "astn" ]),
"daap.songuserrating": (["name": "daap.songuserrating", "type": T_BYTE, "code": "asur" ]),
"daap.songyear": (["name": "daap.songyear", "type": T_SHORT, "code": "asyr" ]),
"daap.songdatakind": (["name": "daap.songdatakind", "type": T_BYTE, "code": "asdk" ]),
"daap.songdataurl": (["name": "daap.songdataurl", "type": T_STRING, "code": "asul" ]),
"daap.databaseplaylists": (["name": "daap.databaseplaylists", "type": T_LIST, "code": "aply" ]),
"daap.baseplaylist": (["name": "daap.baseplaylist", "type": T_BYTE, "code": "abpl" ]),
"daap.playlistsongs": (["name": "daap.playlistsongs", "type": T_LIST, "code": "apso" ]),
"daap.resolve": (["name": "daap.resolve", "type": T_LIST, "code": "prsv" ]),
"daap.resolveinfo": (["name": "daap.resolveinfo", "type": T_LIST, "code": "arif" ]),
"com.apple.itunes.norm-volume": (["name": "com.apple.itunes.norm-volume", "type": T_INT, "code": "aeNV" ]),
"com.apple.itunes.smart-playlist": (["name": "com.apple.itunes.smart-playlist", "type": T_BYTE, "code": "aeSP" ]),
"com.apple.itunes.special-playlist": (["name": "com.apple.itunes.special-playlist", "type": T_BYTE, "code": "aePS" ]),
"com.apple.itunes.music-sharing-version": (["name": "com.apple.itunes.music-sharing-version", "type": T_INT, "code": "aeSV" ]),

]);

constant content_types =
([
"mdcl": (["name": "dmap.dictionary", "type": T_LIST, "code": "mdcl" ]),
"mstt": (["name": "dmap.status", "type": T_INT, "code": "mstt" ]),
"miid": (["name": "dmap.itemid", "type": T_INT, "code": "miid" ]),
"minm": (["name": "dmap.itemname", "type": T_STRING, "code": "minm" ]),
"mikd": (["name": "dmap.itemkind", "type": T_BYTE, "code": "mikd" ]),
"mper": (["name": "dmap.persistentid", "type": T_LONG, "code": "mper" ]),
"mcon": (["name": "dmap.container", "type": T_LIST, "code": "mcon" ]),
"mcti": (["name": "dmap.containeritemid", "type": T_INT, "code": "mcti" ]),
"mpco": (["name": "dmap.parentcontainerid", "type": T_INT, "code": "mpco" ]),
"msts": (["name": "dmap.statusstring", "type": T_STRING, "code": "msts" ]),
"mimc": (["name": "dmap.itemcount", "type": T_INT, "code": "mimc" ]),
"mrco": (["name": "dmap.returnedcount", "type": T_INT, "code": "mrco" ]),
"mtco": (["name": "dmap.specifiedtotalcount", "type": T_INT, "code": "mtco" ]),
"mctc": (["name": "dmap.containercount", "type": T_INT, "code": "mctc"]),
"mlcl": (["name": "dmap.listing", "type": T_LIST, "code": "mlcl" ]),
"mlit": (["name": "dmap.listingitem", "type": T_LIST, "code": "mlit" ]),
"mbcl": (["name": "dmap.bag", "type": T_LIST, "code": "mbcl" ]),
"mdcl": (["name": "dmap.dictionary", "type": T_LIST, "code": "mdcl" ]),
"msrv": (["name": "dmap.serverinforesponse", "type": T_LIST, "code": "msrv" ]),
"msaud": (["name": "dmap.authenticationmethod", "type": T_BYTE, "code": "msaud" ]),
"mslr": (["name": "dmap.loginrequired", "type": T_BYTE, "code": "mslr" ]),
"mpro": (["name": "dmap.protocolversion", "type": T_VERSION, "code": "mpro" ]),
"apro": (["name": "daap.protocolversion", "type": T_VERSION, "code": "apro" ]),
"msal": (["name": "dmap.supportsuatologout", "type": T_BYTE, "code": "msal" ]),
"msup": (["name": "dmap.supportsupdate", "type": T_BYTE, "code": "msup" ]),
"mspi": (["name": "dmap.supportspersistentids", "type": T_BYTE, "code": "mspi" ]),
"msex": (["name": "dmap.supportsextensions", "type": T_BYTE, "code": "msex" ]),
"msbr": (["name": "dmap.supportsbrowse", "type": T_BYTE, "code": "msbr" ]),
"msqy": (["name": "dmap.supportsquery", "type": T_BYTE, "code": "msqy" ]),
"msix": (["name": "dmap.supportsindex", "type": T_BYTE, "code": "msix" ]),
"msrs": (["name": "dmap.supportsresolve", "type": T_BYTE, "code": "msrs" ]),
"mstm": (["name": "dmap.timeoutinterval", "type": T_INT, "code": "mstm" ]),
"msdc": (["name": "dmap.databasescount", "type": T_INT, "code": "msdc" ]),
"mccr": (["name": "dmap.contentcodesresponse", "type": T_LIST, "code": "mccr" ]),
"mcnm": (["name": "dmap.contentcodesnumber", "type": T_INT, "code": "mcnm" ]),
"mcna": (["name": "dmap.contentcodesname", "type": T_STRING, "code": "mcna" ]),
"mcty": (["name": "dmap.contentcodestype", "type": T_SHORT, "code": "mcty" ]),
"mlog": (["name": "dmap.loginresponse", "type": T_LIST, "code": "mlog" ]),
"mlid": (["name": "dmap.sessionid", "type": T_INT, "code": "mlid" ]),
"mupd": (["name": "dmap.updateresponse", "type": T_LIST, "code": "mupd" ]),
"musr": (["name": "dmap.serverrevision", "type": T_INT, "code": "musr" ]),
"muty": (["name": "dmap.updatetype", "type": T_BYTE, "code": "muty" ]),
"mudl": (["name": "dmap.deletedidlisting", "type": T_LIST, "code": "mudl" ]),
"avdb": (["name": "daap.serverdatabases", "type": T_LIST, "code": "avdb" ]),
"abro": (["name": "daap.databasebrowse", "type": T_LIST, "code": "abro" ]),
"abal": (["name": "daap.browsealbumlistung", "type": T_LIST, "code": "abal" ]),
"abar": (["name": "daap.browseartistlisting", "type": T_LIST, "code": "abar" ]),
"abcp": (["name": "daap.browsecomposerlisting", "type": T_LIST, "code": "abcp" ]),
"abgn": (["name": "daap.browsegenrelisting", "type": T_LIST, "code": "abgn" ]),
"adbs": (["name": "daap.databasesongs", "type": T_LIST, "code": "adbs" ]),
"asal": (["name": "daap.songalbum", "type": T_STRING, "code": "asal" ]),
"asar": (["name": "daap.songartist", "type": T_STRING, "code": "asar" ]),
"asbt": (["name": "daap.songsbeatsperminute", "type": T_SHORT, "code": "asbt" ]),
"asbr": (["name": "daap.songbitrate", "type": T_SHORT, "code": "asbr" ]),
"ascm": (["name": "daap.songcomment", "type": T_STRING, "code": "ascm" ]),
"asco": (["name": "daap.songcompilation", "type": T_BYTE, "code": "asco" ]),
"asda": (["name": "daap.songdateadded", "type": T_DATE, "code": "asda" ]),
"asdm": (["name": "daap.songdatemodified", "type": T_DATE, "code": "asdm" ]),
"asdc": (["name": "daap.songdisccount", "type": T_SHORT, "code": "asdc" ]),
"asdn": (["name": "daap.songdiscnumber", "type": T_SHORT, "code": "asdn" ]),
"asdb": (["name": "daap.songdisabled", "type": T_BYTE, "code": "asdb" ]),
"aseq": (["name": "daap.songeqpreset", "type": T_STRING, "code": "aseq" ]),
"asfm": (["name": "daap.songformat", "type": T_STRING, "code": "asfm" ]),
"asgn": (["name": "daap.songgenre", "type": T_STRING, "code": "asgn" ]),
"asdt": (["name": "daap.songdescription", "type": T_STRING, "code": "asdt" ]),
"asrv": (["name": "daap.songrelativevolume", "type": T_BYTE, "code": "asrv" ]),
"assr": (["name": "daap.songsamplerate", "type": T_INT, "code": "assr" ]),
"assz": (["name": "daap.songsize", "type": T_INT, "code": "assz" ]),
"asst": (["name": "daap.songstarttime", "type": T_INT, "code": "asst" ]),
"assp": (["name": "daap.songstoptime", "type": T_INT, "code": "assp" ]),
"astm": (["name": "daap.songtime", "type": T_INT, "code": "astm" ]),
"astc": (["name": "daap.songtrackcount", "type": T_SHORT, "code": "astc" ]),
"astn": (["name": "daap.songtracknumber", "type": T_SHORT, "code": "astn" ]),
"asur": (["name": "daap.songuserrating", "type": T_BYTE, "code": "asur" ]),
"asyr": (["name": "daap.songyear", "type": T_SHORT, "code": "asyr" ]),
"asdk": (["name": "daap.songdatakind", "type": T_BYTE, "code": "asdk" ]),
"asul": (["name": "daap.songdataurl", "type": T_STRING, "code": "asul" ]),
"aply": (["name": "daap.databaseplaylists", "type": T_LIST, "code": "aply" ]),
"abpl": (["name": "daap.baseplaylist", "type": T_BYTE, "code": "abpl" ]),
"apso": (["name": "daap.playlistsongs", "type": T_LIST, "code": "apso" ]),
"prsv": (["name": "daap.resolve", "type": T_LIST, "code": "prsv" ]),
"arif": (["name": "daap.resolveinfo", "type": T_LIST, "code": "arif" ]),
"aeNV": (["name": "com.apple.itunes.norm-volume", "type": T_INT, "code": "aeNV" ]),
"aeSP": (["name": "com.apple.itunes.smart-playlist", "type": T_BYTE, "code": "aeSP" ]),
"aePS": (["name": "com.apple.itunes.special-playlist", "type": T_BYTE, "code": "aePS" ]),
"aeSV": (["name": "com.apple.itunes.music-sharing-version", "type": T_BYTE, "code": "aeSV" ]),

]);

/*

mdcl	list	dmap.dictionary		a dictionary entry
mstt	int	dmap.status		the response status code,
					these appear to be http status 
					codes, e.g. 200
miid	int	dmap.itemid		an item's id
minm	string	dmap.itemname		an items name
mikd	byte	dmap.itemkind		the kind of item.  So far,
					only '2' has been seen, an
					audio file?
mper	long	dmap.persistentid	a persistend id
mcon	list	dmap.container		an arbitrary container
mcti	int	dmap.containeritemid	the id of an item in its
					container
mpco	int	dmap.parentcontainerid
msts	string	dmap.statusstring
mimc	int	dmap.itemcount		number of items in a container
mrco	int	dmap.returnedcount	number of items returned in a
					request
mtco	int	dmap.specifiedtotalcount number of items in response
					to a request
mlcl	list	dmap.listing		a list
mlit	list	dmap.listingitem	a single item in said list
mbcl	list	dmap.bag
mdcl	list	dmap.dictionary

msrv	list	dmap.serverinforesponse	response to a /server-info
msaud	byte	dmap.authenticationmethod (should be self explanitory)
mslr	byte	dmap.loginrequired
mpro	version	dmap.protocolversion
apro	version	daap.protocolversion
msal	byte	dmap.supportsuatologout
msup	byte	dmap.supportsupdate
mspi	byte	dmap.supportspersistentids
msex	byte	dmap.supportsextensions
msbr	byte	dmap.supportsbrowse
msqy	byte	dmap.supportsquery
msix	byte	dmap.supportsindex
msrs	byte	dmap.supportsresolve
mstm	int	dmap.timeoutinterval
msdc	int	dmap.databasescount

mccr	list	dmap.contentcodesresponse	the response to the 
						content-codes request
mcnm	int	dmap.contentcodesnumber	the four letter code
mcna	string	dmap.contentcodesname	the full name of the code
mcty	short	dmap.contentcodestype	the type of the code (see
					appendix b for type values)

mlog	list	dmap.loginresponse	response to a /login
mlid	int	dmap.sessionid		the session id for the login session

mupd	list	dmap.updateresponse	response to a /update
msur	int	dmap.serverrevision	revision to use for requests
muty	byte	dmap.updatetype
mudl	list	dmap.deletedidlisting	used in updates?  (document soon)

avdb	list	daap.serverdatabases	response to a /databases
abro	list	daap.databasebrowse	
abal	list	daap.browsealbumlistung	  
abar	list	daap.browseartistlisting   
abcp	list	daap.browsecomposerlisting
abgn	list	daap.browsegenrelisting

adbs	list	daap.databasesongs	repsoonse to a /databases/id/items
asal	string	daap.songalbum		the song ones should be self exp.
asar	string	daap.songartist
asbt	short	daap.songsbeatsperminute
asbr	short	daap.songbitrate
ascm	string	daap.songcomment
asco	byte	daap.songcompilation
asda	date	daap.songdateadded
asdm	date	daap.songdatemodified
asdc	short	daap.songdisccount
asdn	short	daap.songdiscnumber
asdb	byte	daap.songdisabled
aseq	string	daap.songeqpreset
asfm	string	daap.songformat
asgn	string	daap.songgenre
asdt	string	daap.songdescription
asrv	byte	daap.songrelativevolume
assr	int	daap.songsamplerate
assz	int	daap.songsize
asst	int	daap.songstarttime 	(in milliseconds)	
assp	int	daap.songstoptime 	(in milliseconds)
astm	int	daap.songtime		(in milliseconds)
astc	short	daap.songtrackcount
astn	short	daap.songtracknumber
asur	byte	daap.songuserrating
asyr	short	daap.songyear
asdk	byte	daap.songdatakind
asul	string	daap.songdataurl

aply	list	daap.databaseplaylists	response to /databases/id/containers
abpl	byte	daap.baseplaylist

apso	list	daap.playlistsongs	response to 
					/databases/id/containers/id/items
prsv	list	daap.resolve
arif	list	daap.resolveinfo

aeNV	int	com.apple.itunes.norm-volume
aeSP	byte	com.apple.itunes.smart-playlist

*/

//!
string encode_dmap(array data)
{
  string tag;
  mixed val = "";
  //werror("Data: %O\n", data);
  if(sizeof(data) < 2)
  {
    throw(Error.Generic("DMAP Field must contain at least 2 entries.\n")); 
  }
  mapping t = content_tags[data[0]];
  if(!t)   if(!t) throw(Error.Generic("Unknown DMAP field " + data[0]+ "\n"));
  
  int dtype = t["type"];
  tag = t["code"];
  switch(dtype)
  {
    case T_BYTE:
      val = sprintf("%1c", data[1]);
      break;
    case T_SHORT:
      val = sprintf("%2c", data[1]);
      break;
    case T_INT:
      val = sprintf("%4c", data[1]);
      break;
    case T_LONG:
      val = sprintf("%8c", data[1]);
      break;
    case T_STRING:
      val = string_to_utf8(data[1]);
      break;
    case T_DATE:
      val = sprintf("%4c", (intp(data[1])?data[1]:data[1]->unix_timestamp()));
      break;
    case T_VERSION:
      array vs = data[1] /".";
      if(sizeof(vs) == 2) val = sprintf("%2c%1c%1c", (int)vs[0], (int)vs[1], 0);
      if(sizeof(vs) == 3) val = sprintf("%2c%1c%1c", (int)vs[0], (int)vs[1], (int)vs[2]);
      break;
    case T_LIST:
       if(!arrayp(data[1]))
         throw(Error.Generic("Cannot encode non-arrays as lists.\n"));
       foreach(data[1];; array v)
         val += encode_dmap(v);
      break;
    default:
      throw(Error.Generic("unknown datatype flag " + dtype +".\n"));
      break;
  }

  return sprintf("%4s%4c%" + sizeof(val) + "s", tag, sizeof(val), val);
}

//!
array decode_dmap(string data)
{
  return low_decode_dmap(data)[0];
}

array low_decode_dmap(string data)
{
  string tag, block;
  int length;
  int dtype;
  mixed final_data;

  [tag, length, data] = array_sscanf(data, "%4s%4c%s");
  
  if(length && sizeof(data) > length)
    [block, data] = array_sscanf(data, "%" + length + "s%s");
  else
    block = data;
 
  mapping t = content_types[tag];
  if(!t) throw(Error.Generic("Unknown DMAP tag " + tag + "\n"));

  dtype = t["type"];

  switch(dtype)
  {
    case T_BYTE:
      final_data = parse_int(block, 1);
      break;
    case T_SHORT:
      final_data = parse_int(block, 2);
      break;
    case T_INT:
      final_data = parse_int(block, 4);
      break;
    case T_LONG:
      final_data = parse_int(block, 8);
      break;
    case T_STRING:
      final_data = utf8_to_string(block);
      break;
    case T_DATE:
      final_data = Calendar.Second(parse_int(block, 4));
      break;
    case T_VERSION:
      if(length == 2) final_data = sprintf("%d.%d", @(array_sscanf(block, "%1c%1c")));
      if(length == 4) final_data = sprintf("%d.%d.%d.%d", @(array_sscanf(block, "%1c%1c%1c%1c")));
      break;
    case T_LIST:
       mixed element;
       final_data = ({  });
       do
       {
         [element, block] = low_decode_dmap(block);
         final_data += ({ element });
       } while(sizeof(block) >= 8);     
      break;
    default:
      throw(Error.Generic("unknown datatype flag " + dtype +".\n"));
      break;
  }

  return ({({t["name"], final_data}), data});  
}

int parse_int(string data, int len)
{  
   return array_sscanf(data, "%" + len + "c")[0];
}