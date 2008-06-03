#!/usr/bin/env python
#######################################################################
#  This file is part of JMdictDB. 
#  Copyright (c) 2008 Stuart McGraw 
# 
#  JMdictDB is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published 
#  by the Free Software Foundation; either version 2 of the License, 
#  or (at your option) any later version.
# 
#  JMdictDB is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
# 
#  You should have received a copy of the GNU General Public License
#  along with JMdictDB; if not, write to the Free Software Foundation,
#  51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA
#######################################################################

__version__ = ('$Revision$'[11:-2],
	       '$Date$'[7:-11]);

# To do:
# Misc/variant not processed.  Use xref?
# Skip cinf records ignore skip_misclass, skip misclass type.
#   Remember to check for error misclass that is same as main skip code.
# Better error checking for unexpeced or new elements/attributes.
# Don't die on errors, make effort to warn, skip bad data, and continue.
# Stroke counts in separate table?
# Decompose dic_ref into (numb,vol,ch,pg,other)?  Is this basis for
#   general locator scheme that can be applied in othe corpuses?

import sys, os
from xml.etree import cElementTree as ElementTree
import jdb, pgi
from kwstatic import *
jdb.KW = KW

# Remap the keywords used in the kanjidic2.xml file to
# the keywords used in the kw* tables.  Those keywords
# not mentioned below have the same text in both places.
Xml2db = jdb.Obj (
    RINF = {'nanori':'name', 'jy':'jouyou', 'ja_kun':'kun', 'ja_on':'on',
	    'kan\'you':'kanyou'},
    LANG = {},
    CINF = {'kanji_in_context':'kanji_in_ctx', 
	    'kodansha_compact':'kodansha_comp','skip_misclass':'skip_mis',
	    'stroke_count':'strokes'})

def main (args, opts):
	global Opts, Char, Lineno
	Opts = opts;  Char = '';  Lineno = 1
	if Opts.l: Opts.l = open (Opts.l, "w")
	else: Opts.l = sys.stderr
	if not Opts.o: 
	    fn = (os.path.split (args[0]))[1]
	    fn = (os.path.splitext (fn))[0]
	    Opts.o = fn + ".pgi"
	elif Opts.o  == "-":
	    Opts.o = None
	if opts.g: langs = [KW.LANG[x].id for x in opts.g.split(',')]
	else: langs = None
	workfiles = pgi.initialize (Opts.t)
	srcdate = parse_xmlfile (args[0], 4, workfiles, Opts.b, Opts.c, langs)
	srcrec = Obj (id=4, kw='kanjidic', descr='Kanjifdict2.xml', 
		      dt=srcdate, seq='seq_kanjidic')
	pgi.wrrow (srcrec, workfiles['kwsrc'])
	pgi.finalize (workfiles, Opts.o, not Opts.k)
	print >>sys.stderr, "\nDone!"

class LnFile:
      # Wrap a standard file object so as to keep track
      # of the current line number.
    def __init__(self, source):
	self.source = source;  self.lineno = 0
    def read(self, bytes):
	s = self.source.readline();  self.lineno += 1
	return s

def parse_xmlfile (infn, srcid, workfiles, start, count, langs): 

	global Lineno

	# Use the ElementTree module to parse the jmdict 
	# xml file.  This function keeps track of where
	# we are and for each parsed <entry> element, calls
	# do_entry() to actually build a runtime representation
	# of the entry, and then write_entry() to do the actual
	# writing to the database.

        inpf = LnFile(open(infn))
	context = iter(ElementTree.iterparse( inpf, ("start","end")))
	event, root = context.next()
	if start and start>1: print >>sys.stderr, "Skipping initial entries..."
	cntr = 0; 
	for event, elem in context:

	    # We get here every time a tag is opened (event 
	    # will be "start") or closed (event will be "end")
	    # "elem" is an object containg the element which 
	    # will be empty when event is "start" and will contain
	    # all the element's attributes and child elements
	    # when event is "end".  elem.tag is the name of the
	    # tag.

	    if elem.tag == "character" and event == "start":

		# When we encounter a <character> tag, save the line
		# number, and increment the entry counter "cntr".

		Lineno = inpf.lineno	# For warning messages created by warn().

		# If we are skipping entries, cntr will be 0.
		# Otherwise, break if we have processed the 
		# the number of entries requested in the -c 
		# option.

		if cntr >= count: break

	    if elem.tag == 'header' and event == 'end':
		xmldate = (elem.find ('date_of_creation')).text
		if (elem.find ('file_version')).text != '4' or \
		   (elem.find ('database_version')).text != '2006-375':
			warn ('Unexpected kanjidic file version or database version found.'
			      '\nThis program may or may not work on this file.')

	    # Otherwise we are precessing characters so we want
	    # to handle the <character> "end" events but we are 
	    # not interested in anything else.

	    if elem.tag != "character" or event != "end": continue

	    # If we haven't reached that starting line number 
	    # (given by the -b option) yet, then don't process
	    # this entry, but we still need to clear the parsed
	    # entry bofore continuing in order to avoid excessive
	    # memory consumption.

	    if Lineno >= start: 

		# If this is the first entry processed (cnt0==0) 
		# save the current entry counter value.
 
		cntr += 1
		if cntr == 1: print >>sys.stderr, "Parsing..."

		# Process and write this entry.

		entr = do_chr (elem, srcid, langs)
		jdb.setkeys (entr, cntr)
		pgi.wrentr (entr, workfiles)

		# A progress bar.  The modulo number is picked
		# to provide slightly less that 80 dots for a full
		# kanjidic2 file.

		if (cntr - 1) % 166 == 0: sys.stderr.write (".")

	    # We no longer need the parsed xml info for this
	    # item so dump it to reduce memory consumption.

	    root.clear()

	return xmldate

def do_chr (elem, srcid, langs):
	global Char
	# Process a <character> element.  The element has been
	# parse by the xml ElementTree parse and is in "elem".
	# "lineno" is the source file line number.

	chtxt = elem.find('literal').text
	Char = chtxt	# For warning messages created by warn().
	c = Obj (uni=uord(chtxt), _cinf=[])
	e = Obj (src=srcid, stat=KWSTAT_A, seq=Lineno, unap=False,
	         chr=c, _kanj=[Obj(txt=chtxt)], _rdng=[], _sens=[], _krslv=[])
	for x in elem.findall ('codepoint/cp_value'): codepoint (x, c, chtxt)
	for x in elem.findall ('radical/rad_value'): radical (x, c)

	x = None
	try: x = (elem.find ('misc/freq')).text
	except: pass
	if x: 
	    if hasattr (c,'freq'): warn ('Duplicate "freq" element ignored: %s' % x)
	    else: c.freq = int(x)

	x = None
	try: x = (elem.find ('misc/grade')).text
	except: pass
	if x: 
	    if hasattr (c,'grade'): warn ('Duplicate "grade" element ignored: %s' % x)
	    else: c.grade = int(x)

	for n,x in enumerate (elem.findall ('misc/stroke_count')): 
	    strokes (x, n, c)

	for x in elem.findall ('reading_meaning'): 
	    reading_meaning (x, e._rdng, e._sens, c._cinf, langs)

	x = elem.find ('dic_number')
	if x: dicnum (x, c._cinf)

	x = elem.find ('query_code')
	if x: qcode (x, c._cinf)

	for x in elem.findall ('misc/variant'): e._krslv.append (variant (x))

	return e

def variant (x):
	# Map the keywords used in var_type to values used
	# in the database kw* tables, where they differ.
	vmap = {
	    'njecd':'halpern_njecd', 'oneill':'oneill_names'}

	vt = x.get ('var_type')
	vt = vmap.get(vt,vt)
	kw = KW.CINF[Xml2db.CINF.get(vt,vt)].id
	return Obj (kw=kw, value=x.text)

def codepoint (x, c, chtxt):
	cinf = c._cinf
	if len (x.keys()) != 1: warn ('Expected only one cp_value attribute')
	cp_attr, cp_type = x.items()[0]
	if cp_attr != 'cp_type': warn ('Unexpected cp_value attribute', cp_attr)
	if cp_type == 'ucs': 
	    if int (x.text, 16) != jdb.uord (chtxt): 
		warn ("xml codepoint ucs value '%s' doesnt match character %s (0x%x)." \
			% (x.text, chtxt, jdb.uord (chtxt)))
	else: cinf.append( Obj( kw=KW.CINF[Xml2db.CINF.get(cp_type, cp_type)].id, value=x.text))

def radical (x, c):
	cinf = c._cinf
	if len (x.keys()) != 1: warn ('Expected only one rad_value attribute')
	rad_attr, rad_type = x.items()[0]
	if rad_attr != 'rad_type': warn ('Unexpected rad_value attribute: %s', rad_attr)
	if rad_type == 'classical': c.bushu = int(x.text)
	elif rad_type == 'nelson_c': 
	    cinf.append (Obj (kw=KWCINF_nelson_rad, value=int(x.text)))
	else: warn ("Unknown radical attribute value: %s=\"%s\"", (rad_attr, rad_type))

def strokes (x, n, c):
	cinf = c._cinf
	if n == 0: 
	     c.strokes = int(x.text)
	else: 
	    cinf.append ( Obj (kw=KWCINF_strokes, value=int(x.text)))

def reading_meaning (rm, rdng, sens, cinf, langs):
	for x in rm.findall ('rmgroup'):
	    r, g, c = rmgroup (x, langs)
	    rdng.extend (r)
	    sens.append (Obj (_gloss=g))
	  # Make a dict keyed by the readings already parsed.
	rlookup = dict ([(r.txt,r) for r in rdng])
	  # Get the nanori readings...
	for x in rm.findall ('nanori'):
	      # There may be readings nanori readings that are 
	      # the same as the on/kun readings we've already 
	      # parsed.  Lookup the nanori reading in the readings
	      # dict.  If we already have the reading, just add
	      # the nanori RINF tag to it.  Otherwise create a 
	      # new reading record.
	    try: r = rlookup[x.text]
	    except KeyError: 
		r = Obj (txt=x.text)
		rdng.append (r)
	    if not hasattr (r, '_inf'): r._inf = []
	    r._inf.append (Obj (kw=KW.RINF[Xml2db.RINF.get('nanori','nanori')].id))
	cinf.extend (c)

def rmgroup (rmg, langs=None):
	rdngs = [];  glosses = [];  cinf = []; dupchk = {}
	for x in rmg.findall ('reading'):
	    rtype = None;  rstat = None;  cinfrec = None
	    for aname,aval in x.items():
		if aname == 'r_type': rtype = aval
		if aname == 'on_type': rtype = aval
		if aname == 'r_status': rstat = aval
	    if rtype=='pinyin' or rtype=='korean_r' or rtype=='korean_h':
		if (rtype, x.text) in dupchk:
		    warn ("Duplicate reading ignored: %s, %s" % (rtype, x.text))
		    continue
		dupchk[(rtype,x.text)] = True
		cinf.append (Obj (kw=KW.CINF[rtype].id, value=x.text))
	    elif rtype=='ja_on' or rtype=='ja_kun':
		if x.text in dupchk: 
		    warn ('Duplicate reading ignored: %s' % x.text)
		    continue
		dupchk[x.text] = True
		rdng = Obj (txt=x.text, _inf=[])
		rdng._inf.append (Obj (kw=KW.RINF[Xml2db.RINF.get(aval,aval)].id))
		if rstat: rdng._inf.append (Obj (kw=KW.RINF[Xml2db.RINF.get(rstat,rstat)].id))
		rdngs.append (rdng)
	    else:
		raise KeyError ('Unkown r_type attribute: %s' % rtype)

	dupchk = {}
	for x in rmg.findall ('meaning'):
	    lang = x.get ('m_lang', 'en')
	    langkw = KW.LANG[Xml2db.LANG.get(lang,lang)].id
	    if (lang,x.text) in dupchk:
		warn ("Duplicate lang,meaning pair ignored: %s:%s" % (lang, x.text))
		continue
	    dupchk[(lang,x.text)] = True
	    if not langs or langkw in langs:
	        glosses.append (Obj (txt=x.text, lang=langkw, ginf=1))
	return rdngs, glosses, cinf

def dicnum (dic_number, cinf):
	dupchk = {}
	for x in dic_number.findall ('dic_ref'):
	    drtype = x.get ('dr_type')
	    val = x.text
	    if 'm_vol' in x: 
		    val = "%s.%s.%s" % (x.get ('m_vol'), x.get ('m_page'), x.text)
	    kw = KW.CINF[Xml2db.CINF.get(drtype,drtype)].id
	    if (kw,val) in dupchk:
		warn ('Duplicate dr_type,value pair ignored: %s, %s' % (drtype, val))
		continue
	    dupchk[(kw,val)] = True
	    cinf.append (Obj (kw=kw, value=val))

def qcode (query_code, cinf):
	dupchk = {}; saw_misclass = False;  saw_skip = False
	for x in query_code.findall ('q_code'):
	    qctype = x.get ('qc_type')
	    val = x.text
	    kw = KW.CINF[Xml2db.CINF.get(qctype,qctype)].id
	    misclass = x.get ('skip_misclass','')
	    if (kw,val) in dupchk:
		warn ('Duplicate qc_type,value pair ignored: %s,%s' % (qctype, val))
		continue
	    dupchk[(kw,val)] = True
	    if misclass:
		if qctype != "skip": raise KeyError ("'skip_misclass' attr on non-skip element")
		saw_misclass = True
	    elif qctype == 'skip':
		saw_skip = True
	    cinf.append (Obj (kw=kw, value=val, mctype=misclass))
	if saw_misclass and not saw_skip:
	    warn ("Has skip_misclass but no skip")

def warn (msg, *args):
	global Char, Lineno, Opts
	s = "%s (line %d), warning: %s" % (Char, Lineno, msg % args)
	print >>Opts.l, s.encode (Opts.e, 'backslashreplace')

   

#---------------------------------------------------------------------

from optparse import OptionParser

def parse_cmdline ():
	u = \
"""\n\t%prog [-d dbfile] xmlfile srcid
	
  %prog will extract the data from <xmlfile> (which is a JMdict
  or JMnedict file) and will load it into a database. The new
  data will be added without erasing any data already present
  in the database.

arguments:
  xmlfile          Filename of a JMdict XML file."""

	v = sys.argv[0][max (0,sys.argv[0].rfind('\\')+1):] \
	        + " Rev %s (%s)" % _VERSION_
	p = OptionParser (usage=u, version=v)
	p.add_option ("-b", "--begin",
             type="int", dest="b", default=0,
             help="Begin processing at first entry that occurs "
		"at or after line number B.")
	p.add_option ("-c", "--count", 
             type="int", dest="c", default=9999999,
             help="Stop after processing C entries."
		"If both -c and -e are given processing will stop "
		"as soon as either condition is met.")
	p.add_option ("-o", "--outfile", 
             type="str", dest="o", default=None,
             help="Write the output load data to this filename.  If "
		"not given input filename with the extension replaced "
		"by \".pgi\" will be used.")
	p.add_option ("-g", "--language", 
             type="str", dest="g", default=None,
             help="Value is a comma separated list (with no spaces) of "
		"ISO-639 two-letter language codes.  Only glosses of " 
		"languages from this list will bre extracted.  If not "
		"given, all glosses regardless of language will be extracted.")
	p.add_option ("-l", "--logfile", 
             type="str", dest="l", default=None,
             help="Write warning and errors messages to this filename. "
	        "If not given write to stderr.")
	p.add_option ("-k", "--keep", 
             action="store_true", dest="k", default=False,
             help="Do not delete the workfiles when finished.  This "
		"can be useful for debugging.")
	p.add_option ("-t", "--tempdir", 
             type="str", dest="t", default=".",
             help="Create the work files in this directory.")
	p.add_option ("-e", "--encoding",
             type="str", dest="e", default="utf-8",
             help="Write output messages using this encoding.")
	opts, args = p.parse_args ()
	if len(args) < 1: p.error("Too few arguments, expected name of kanjidic xml file." 
				"\nUse --help for more info")
	if len(args) > 1: p.error("Too many arguments, expected only name of kanjidic xml file" 
				"\nUse --help for more info")
	return args, opts

if __name__ == '__main__': 
	args, opts = parse_cmdline ()
	main (args, opts)