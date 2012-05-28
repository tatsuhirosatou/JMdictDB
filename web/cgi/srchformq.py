#!/usr/bin/env python
#######################################################################
#  This file is part of JMdictDB. 
#  Copyright (c) 2006-2010 Stuart McGraw 
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
from __future__ import print_function

__version__ = ('$Revision$'[11:-2],
	       '$Date$'[7:-11]);

import sys, cgi
sys.path.extend (['../lib','../../python/lib','../python/lib'])
import cgitbx; cgitbx.enable()
import jdb, jmcgi

def main( args, opts ):
	try: form, svc, host, cur, sid, sess, parms, cfg = jmcgi.parseform()
	except StandardError as e: jmcgi.err_page ([unicode (e)])

	qs = jmcgi.form2qs (form)
	corp = reshape (sorted ([x for x in jdb.KW.recs('SRC') if x.kw!='xxkanjidic'] , 
			        key=lambda x:x.kw.lower), 10)
	jmcgi.gen_page ("tmpl/srchformq.tal", macros='tmpl/macros.tal', 
			src=corp, parms=parms,
			svc=svc, host=host, sid=sid, session=sess, cfg=cfg, 
			method='get', output=sys.stdout, this_page='srchformq.py')

def reshape (array, ncols, default=None):
	result = []
	for i in range(0, len(array), ncols):
	    result.append (array[i:i+ncols])
	if len(result[-1]) < ncols:
	    result[-1].extend ([default]*(ncols - len(result[-1])))
	return result

if __name__ == '__main__': 
	args, opts = jmcgi.args()
	main (args, opts)
