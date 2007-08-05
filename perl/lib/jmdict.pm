#######################################################################
#   This file is part of JMdictDB. 
#   Copyright (c) 2006,2007 Stuart McGraw 
# 
#   JMdictDB is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published 
#   by the Free Software Foundation; either version 2 of the License, 
#   or (at your option) any later version.
# 
#   JMdictDB is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
# 
#   You should have received a copy of the GNU General Public License
#   along with JMdictDB; if not, write to the Free Software Foundation,
#   51 Franklin Street, Fifth Floor, Boston, MA  02110#1301, USA
#######################################################################

package jmdict;
use strict; use warnings;
use Time::HiRes ('time'); 

BEGIN {
    use Exporter(); our (@ISA, @EXPORT_OK, @EXPORT); @ISA = qw(Exporter);
    @EXPORT_OK = qw(KANA HIRAGANA KATAKANA KANJ); 
    @EXPORT = qw(dbread dbinsert Kwds kwrecs addids mktmptbl Find EntrList 
		    matchup filt jstr_classify addentr resolv_xref fmt_jitem
		    zip fmtkr dbopen setkeys add_xrefsums grp_xrefs); }

our(@VERSION) = (substr('$Revision$',11,-2), \
	         substr('$Date$',7,-11));

    sub dbread { my ($dbh, $sql, $args) = @_;
	# Read the database result set produced by executing the
	# statement, $sql, with the arguments @$args.
 	# The results are returns as an array of hash refs.  Each 
	# hash represents one row and their position in the arrray
	# reflect the order there were received in.  Each row hash's
	# keys are the names of the SELECT statement's columns.
	
	my ($sth, @rs, $r, $start);
	if (!defined ($args)) {$args = []; }
	$start = time();
	    {no warnings qw(uninitialized); 
	    if ($::Debug{prtsql}) {print "$sql (" . join(",",@$args) . ")\n";}}
	$sth = $dbh->prepare_cached ($sql);
	$sth->execute (@$args);
	while ($r = $sth->fetchrow_hashref) { push (@rs, $r); }
	return \@rs; }

    sub dbinsert { my ($dbh, $table, $cols, $hash) = @_;
	# Insert a row into a database table named by $table.
	# coumns that will be used in the INSERT statement are 
	# given in list @$cols.  The values are given in hash
	# %$hash which is ecepected to contain keys matching 
	# the columns listed in @$cols.

	my ($sql, $sth, @args, $id);
	$sql = "INSERT INTO $table(" . 
		join(",", @$cols)  . 
		") VALUES(" . join (",", split(//, "?" x scalar(@$cols))) . ")";
	@args = map ($hash->{$_}, @$cols);
	    {no warnings qw(uninitialized); 
	    if ($::Debug{prtsql}) {print "$sql (" . join(",",@args) . ")\n";}}
	$sth = $dbh->prepare_cached ($sql);
	$sth->execute (@args);
	$id = $dbh->last_insert_id (undef, undef, $table, undef);
	return $id; }

    sub Kwds { my ($dbh) = @_;
	my (%kw);
	$kw{DIAL} = $dbh->selectall_hashref("SELECT * FROM kwdial", "kw"); addids ($kw{DIAL});
	$kw{FLD}  = $dbh->selectall_hashref("SELECT * FROM kwfld",  "kw"); addids ($kw{FLD});
	$kw{FREQ} = $dbh->selectall_hashref("SELECT * FROM kwfreq", "kw"); addids ($kw{FREQ});
	$kw{GINF} = $dbh->selectall_hashref("SELECT * FROM kwginf", "kw"); addids ($kw{GINF});
	$kw{KINF} = $dbh->selectall_hashref("SELECT * FROM kwkinf", "kw"); addids ($kw{KINF});
	$kw{LANG} = $dbh->selectall_hashref("SELECT * FROM kwlang", "kw"); addids ($kw{LANG});
	$kw{MISC} = $dbh->selectall_hashref("SELECT * FROM kwmisc", "kw"); addids ($kw{MISC});
	$kw{POS}  = $dbh->selectall_hashref("SELECT * FROM kwpos",  "kw"); addids ($kw{POS});
	$kw{RINF} = $dbh->selectall_hashref("SELECT * FROM kwrinf", "kw"); addids ($kw{RINF});
	$kw{SRC}  = $dbh->selectall_hashref("SELECT * FROM kwsrc",  "kw"); addids ($kw{SRC});
	$kw{STAT} = $dbh->selectall_hashref("SELECT * FROM kwstat", "kw"); addids ($kw{STAT});
	$kw{XREF} = $dbh->selectall_hashref("SELECT * FROM kwxref", "kw"); addids ($kw{XREF});
	return \%kw; }

    sub kwrecs { my ($KW, $typ) = @_;
	return map ($KW->{$typ}{$_}, grep (!m/^[0-9]+$/, keys (%{$KW->{$typ}}))); }

    sub addids { my ($hashref) = @_;
	foreach my $v (values (%$hashref)) { $hashref->{$v->{id}} = $v; } }    

    sub mktmptbl { my ($dbh) = @_;
	my ($tmpnm, $cset, $i);
	$cset = "abcdefghijklmnopqrstuvwxyz0123456789";
	for ($i=0; $i<8; $i++) {
	    $tmpnm .= substr ($cset, rand (length($cset)), 1); }
	return "_tmp" . $tmpnm; }

    sub Find { my ($dbh, $sql, $args) = @_;
	# Locate entries that meet some criteria.
	# The criteria is given in the form of a sql statement and
	# corresponding arguments.  The sql statemenht is expected 
	# to return a set of entr.id numbers.  Those id numbers will
	# be placed in a temporary table in the same order they were
	# generated, and the name of the table returned to the caller. 
	# Because it is a temporary table, it will only be visible on
	# the same database connection as $dbh.  It will automatically
	# be deleted when that database connection is closed.
	
	my ($s, $sth, $tmpnm, $ac);
	  my $start = time();

	# Get a random name for the table.
	$tmpnm = mktmptbl ($dbh);

	# Create the temporary table.  It is given an "ord" column
	# with a SERIAL datatype which will preserve the order that
	# it received the entry id numbers in.
	$s = "CREATE TEMPORARY TABLE $tmpnm (id INT NOT NULL PRIMARY KEY, ord SERIAL);";
	$sth = $dbh->prepare_cached ($s);
	$sth->execute (); 

	# Save info for debug/development.
	$::Debug->{'Search sql'} = $sql;
	$::Debug->{'Search args'} = join(",",@$args);

	# Insert the entry id's generated by the given sql statement
	# into the temp table.
	$s = "INSERT INTO $tmpnm(id) ($sql);";
	$sth = $dbh->prepare ($s);
	$sth->execute (@$args);

	# We have to vacuum the new table, or queries based on joins
	# with it may run extrordinarily slowly.  For reasons I forgot
	# it looks AutoCommit must be on to do this, so we save and
	# restore the orginial AutoCommit settings.
	$ac = $dbh->{AutoCommit}; 
	$dbh->{AutoCommit} = 1;
	$dbh->do ("VACUUM ANALYZE $tmpnm");
	$dbh->{AutoCommit} = $ac;

	# For debug/development, get the time spent to do everything.
	$::Debug->{'Search time'} = time() - $start;

	# Return the temp table's name to the caller who will probable
	# call EntrList() with it.
	return $tmpnm; }

    sub EntrList { my ($dbh, $tmptbl) = @_;
	# $dbh -- An open database connection.
	# $tmptbl -- Name of a database table that contains at least 
	#   the columns "id" and "ord".  Column "id" holds entry id 
	#   numbers and gives the list of entry objects to be retrieved.
	#   Column "ord" can host any value and is defines the order
	#   the entries will be retived in.  Typically $tmptbl is the
	#   value returned by a call to jmdict::Find().

	  my $start = time();
	my $entr  = dbread ($dbh, "SELECT e.* FROM $tmptbl t JOIN entr  e ON e.id=t.id ORDER BY t.ord");
	my $hist  = dbread ($dbh, "SELECT x.* FROM $tmptbl t JOIN hist  x ON x.entr=t.id;");
	my $rdng  = dbread ($dbh, "SELECT r.* FROM $tmptbl t JOIN rdng  r ON r.entr=t.id ORDER BY r.entr,r.rdng;");
	my $rinf  = dbread ($dbh, "SELECT x.* FROM $tmptbl t JOIN rinf  x ON x.entr=t.id;");
	my $audio = dbread ($dbh, "SELECT x.* FROM $tmptbl t JOIN audio x ON x.entr=t.id;");
	my $kanj  = dbread ($dbh, "SELECT k.* FROM $tmptbl t JOIN kanj  k ON k.entr=t.id ORDER BY k.entr,k.kanj;");
	my $kinf  = dbread ($dbh, "SELECT x.* FROM $tmptbl t JOIN kinf  x ON x.entr=t.id;");
	my $sens  = dbread ($dbh, "SELECT s.* FROM $tmptbl t JOIN sens  s ON s.entr=t.id ORDER BY s.entr,s.sens;");
	my $gloss = dbread ($dbh, "SELECT x.* FROM $tmptbl t JOIN gloss x ON x.entr=t.id ORDER BY x.entr,x.sens,x.gloss;");
	my $misc  = dbread ($dbh, "SELECT x.* FROM $tmptbl t JOIN misc  x ON x.entr=t.id;");
	my $pos   = dbread ($dbh, "SELECT x.* FROM $tmptbl t JOIN pos   x ON x.entr=t.id;");
	my $fld   = dbread ($dbh, "SELECT x.* FROM $tmptbl t JOIN fld   x ON x.entr=t.id;");
	my $dial  = dbread ($dbh, "SELECT x.* FROM $tmptbl t JOIN dial  x ON x.entr=t.id;");
	my $lsrc  = dbread ($dbh, "SELECT x.* FROM $tmptbl t JOIN lsrc  x ON x.entr=t.id;");
	my $restr = dbread ($dbh, "SELECT x.* FROM $tmptbl t JOIN restr x ON x.entr=t.id;");
	my $stagr = dbread ($dbh, "SELECT x.* FROM $tmptbl t JOIN stagr x ON x.entr=t.id;");
	my $stagk = dbread ($dbh, "SELECT x.* FROM $tmptbl t JOIN stagk x ON x.entr=t.id;");
	my $freq  = dbread ($dbh, "SELECT x.* FROM $tmptbl t JOIN freq  x ON x.entr=t.id;");
	my $xref  = dbread ($dbh, "SELECT x.* FROM $tmptbl t JOIN xref  x ON x.entr=t.id ORDER BY x.entr,x.sens,x.xref;");
	my $xrer  = dbread ($dbh, "SELECT x.* FROM $tmptbl t JOIN xref  x ON x.xentr=t.id;");
	$::Debug->{'Obj retrieval time'} = time() - $start;  $start = time();

	matchup ("_rdng",  $entr, ["id"],  $rdng,  ["entr"]);
	matchup ("_kanj",  $entr, ["id"],  $kanj,  ["entr"]);
	matchup ("_sens",  $entr, ["id"],  $sens,  ["entr"]);
	matchup ("_hist",  $entr, ["id"],  $hist,  ["entr"]);
	matchup ("_rinf",  $rdng, ["entr","rdng"], $rinf,  ["entr","rdng"]);
	matchup ("_audio", $rdng, ["entr","rdng"], $audio, ["entr","rdng"]);
	matchup ("_kinf",  $kanj, ["entr","kanj"], $kinf,  ["entr","kanj"]);
	matchup ("_gloss", $sens, ["entr","sens"], $gloss, ["entr","sens"]);
	matchup ("_pos",   $sens, ["entr","sens"], $pos,   ["entr","sens"]);
	matchup ("_misc",  $sens, ["entr","sens"], $misc,  ["entr","sens"]);
	matchup ("_fld",   $sens, ["entr","sens"], $fld,   ["entr","sens"]);
	matchup ("_dial",  $sens, ["entr","sens"], $dial,  ["entr","sens"]);
	matchup ("_lsrc",  $sens, ["entr","sens"], $lsrc,  ["entr","sens"]);
	matchup ("_freq",  $entr, ["entr"], $freq, ["entr"]);
	matchup ("_restr", $rdng, ["entr","rdng"], $restr, ["entr","rdng"]);
	matchup ("_stagr", $sens, ["entr","sens"], $stagr, ["entr","sens"]);
	matchup ("_stagk", $sens, ["entr","sens"], $stagk, ["entr","sens"]);
	matchup ("_xref",  $sens, ["entr","sens"], $xref,  ["entr","sens"]);
	matchup ("_xrer",  $sens, ["entr","sens"], $xrer,  ["xentr","xsens"]);
	# Next two should probably be done by callers, not us.
	matchup ("_rfreq", $rdng, ["entr","rdng"], $freq,  ["entr","rdng"]);
	matchup ("_kfreq", $kanj, ["entr","kanj"], $freq,  ["entr","kanj"]);
	# Make restr et.al. info available from the entry as well
	# as from rdng, etc.  Should all other lists be available
	# from the entr too?
	matchup ("_restr", $entr, ["entr"], $restr, ["entr"]);
	matchup ("_stagr", $entr, ["entr"], $stagr, ["entr"]);
	matchup ("_stagk", $entr, ["entr"], $stagk, ["entr"]);
	$::Debug->{'Obj build time'} = time() - $start;
	return $entr; }
 
    sub matchup { my ($listattr, $parents, $pks, $children, $fks) = @_;
	# Append each element (a hash ref) in @$children to a list 
	# attached to the first element (also a hash ref) in @$parents
	# that it "matches".  The child hash will "match" a parent if
	# the values of the keys named in (list of strings) $fk are
	# "=" respectively to the values of the keys named in $pks
	# in the parent.  The list of matching children in created
	# as the value of the key $listattr on the parent element 
	# hash.
	# Matchup() is used to link database records from a foreign
	# key table to the record of the primary key table.

	my ($p, $c);
	foreach $p (@$parents) { $p->{$listattr} = (); }
	foreach $c (@$children) {
	    $p = lookup ($parents, $pks, $c, $fks);
	    if ($p) { push (@{$p->{$listattr}}, $c); } } }

    sub linkrecs { my ($listattr, $parents, $pks, $children, $fks) = @_;
	# For each parent hash in @$parents, create a key, $attrlist
	# in the parent hash that contains a list of all the children
	# hashes in @$children that match (in the $pks/$fks sense of
	# lookup()) that parent.
	my ($p, $c, $m);
	foreach $p (@$parents) { $p->{$listattr} = (); }
	foreach $c (@$children) {
	    $m = lookup ($parents, $pks, $c, $fks, 1);
	    foreach $p (@$m) {
		push (@{$p->{$listattr}}, $c); } } }

    sub filt { my ($parents, $pks, $children, $fks) = @_;
	# Return a ref to a list of all parents (each a hash) in @$parents 
	# that are not matched (in the $pks/$fks sense of lookup()) in
	# @$children.
	# One use of filt() is to invert the restr, stagr, stagk, etc,
	# lists in order to convert them from the "invalid pair" form
	# used in the database to the "valid pair" form typically needed
	# for display (and visa versa).
	# For example, if $restr contains the restr list for a single
	# reading, and $kanj is the list of kanji from the same entry,
	# then 
	#        filt ($kanj, ["kanj"], $restr, ["kanj"]);
	# will return a reference to a list of kanj hashes that do not
	# occur in @$restr.
	
	my ($p, $c, @list);
	foreach $p (@$parents) {
	    if (!lookup ($children, $fks, $p, $pks)) {
	    	push (@list, $p); } }
	return \@list; }

    sub lookup { my ($parents, $pks, $child, $fks, $multpk) = @_;
	# @$parents is a list of hashes and %$child a hash.
	# If $multpk if false, lookup will return the first
	# element of @$parents that "matches" %$child.  A match
	# occurs if the hash values of the parent element identified
	# by the keys named in list of strings @$pks are "="
	# respectively to the hash values in %$child corresponding
	# to the keys listed in list of strings @$fks. 
	# If $multpk is true, the matching is done the same way but
	# a list of matching parents is returned rather than the 
	# first match.  In either case, an empty list is returned
	# if no matches for %$child are found in @$parents.

	my ($p, $i, $found, @results);
	foreach $p (@$parents) {
	    $found = 1;
	    for ($i=0; $i<scalar(@$pks); $i++) {
		next if (($p->{$pks->[$i]} || 0) eq ($child->{$fks->[$i]} || 0)); 
		$found = 0;  }
	    if ($found) { 
		if ($multpk) { push (@results, $p); } 
		else { return $p; } } }
	if (!@results) { return (); }
	return \@results; } 

    sub add_xrefsums { my ($dbh, $tmptbl, $entrs) = @_;
	# For each xref in (each sens of) each entr in @$entrs, add a new
	# key, "ssum", the points to a single record containing a summary
	# of the sense that the xref references.  Specifically the record
	# contains fields:
	#    eid: The entry id number of target entry.
	#    sens: The sens number of the target *sense*.
	#    seq: The entry seq number of the target entry.
	#    src: The src id number of the target entry.
	#    stat: The stat id number of the target entry.
	#    rdng: The rdng summary of the target entry.
	#    kanj: The kanj summary of the target entry.
	#    gloss: The gloss summary of the target *sense*.

	my ($sql, $sqf, $ssums, $ssums1, $ssums2, $e, $s, $x);
	  my $start = time();
	$sqf = "SELECT e.id,e.sens,e.seq,e.src,e.stat,e.rdng,e.kanj,e.gloss,e.nsens ".
		"FROM %s t ".
        	"JOIN xref x ON x.%s=t.id ".
		"JOIN essum e ON (e.id=x.%s AND e.sens=x.%s) ".
		"WHERE e.id!=t.id %s ".
		"GROUP BY e.id,e.sens,e.seq,e.src,e.stat,e.rdng,e.kanj,e.gloss,e.nsens ";
	$sql = sprintf ($sqf, $tmptbl, "entr", "xentr", "xsens", "AND x.typ!=5");
	$ssums1 = dbread ($dbh, $sql); 
	$sql = sprintf ($sqf, $tmptbl, "xentr", "entr", "sens", "AND x.typ!=5");
	$ssums2 = dbread ($dbh, $sql); 
	$ssums = [(@$ssums1, @$ssums2)];
	foreach $e (@$entrs) {
	    foreach $s (@{$e->{_sens}}) {
		foreach $x (@{$s->{_xref}}) {
		    $x->{ssum} = lookup ($ssums, ["id","sens"], $x, ["xentr","xsens"], 0); }
		foreach $x (@{$s->{_xrer}}) {
		    $x->{ssum} = lookup ($ssums, ["id","sens"], $x, ["entr","sens"], 0); }}}
	$::Debug->{'Xrefsum retrieval time'} = time() - $start; }

    sub grp_xrefs { my ($xrefs, $rev) = @_;

	# Group the xrefs in list @$xrefs into groups such that xrefs
	# in each group have the same {entr}, {sens}, {typ}, {xentr},
	# and {notes} values and differ only in the values of {sens}.
	# Order is preserved to each xref will have the same relative
	# position within its group as it did in @$xrefs.
	# The grouped xrefs are returned as a (reference to) a list
	# of lists of xrefs.
	#
	# If $rev is true, the xrefs are treated as reverse xrefs
	# and grouped by {xentr},, {xsens}, {typ}, {entr}.
	#
	# This function is useful for grouping together all the senses
	# of each xref target entry when it is desired to to display
	# information for an xref entry once, even when multiple
	# target senses exist.
	# 
	# WARNING -- this function currently assumes that the input
	# list @$xrefs is already sorted by {entr}, {sens}, {typ}, 
	# {xentr}.  If that is not true then you may get duplicate
	# groups in the result list.  However, it is true for xref
	# lists read by EntrList().

	my ($x, $prev, @a, $b);
	foreach $x (@$xrefs) {
	    if ((!$rev && (!$prev 
		  || $prev->{entr}  != $x->{entr} 
		  || $prev->{sens}  != $x->{sens}
		  || $prev->{typ}   != $x->{typ} 
		  || $prev->{xentr} != $x->{xentr} 
		  || ($prev->{notes}||"") ne ($x->{notes}||""))) 
	      || ($rev && (!$prev
		  || $prev->{xentr}  != $x->{xentr} 
		  || $prev->{xsens}  != $x->{xsens}
		  || $prev->{typ}   != $x->{typ} 
		  || $prev->{entr} != $x->{entr} 
		  || ($prev->{notes}||"") ne ($x->{notes}||""))) ) {
		$b = [$x];
		push (@a, $b); } 
	    else {
		push (@$b, $x); }
	    $prev = $x; }
	return \@a; }

    sub resolv_xref { my ($dbh, $kanj, $rdng, $slist, $typ,
			   $one_entr_only, $one_sens_only) = @_;
	# $dbh -- Handle to open database connection.
	# $kanj -- Cross-ref target(s) must have this kanji text.  May be false.
	# $rdng -- Cross-ref target(s) must have this reading text.  May be false.
	# $slist -- Ref to array of sense numbers.  Resolved xrefs
	#   will be limited to these target senses. 
	# $typ -- (int) Type of reference per $::KW->{XREF}.
	# $one_entr_only -- Raise error if xref resolves to more than
	#   one entry.  Regardless of this value, it is always an error
	#   if $slist is given and the xref resolves to more than one
	#   entry.
	# $one_sens_only -- Raise error if $slist not given and any
	#   of the resolved entries have more than one sense. 
	# 
	# resolv_xref() returns a list of augmented xrefs.  Each xref item
	# is a ref to a hash matching an xref table row, except it has no
	# {entr}, {sens}, or {xref} elements, since those will be determined 
	# by the parent sense to which it is attached.  The items they do 
	# have are:
	#
	#   {typ} -- Integer id (defined in kwxref table.)
	#   {xentr} -- Id number of target entry.
	#   {xsens} -- Sens number of target sense.
	#   {ssum} -- Reference to additional sense information.
	#
	# The {ssum} element points to a hash containing additional
	# summary information about the entry to which this sense 
	# belongs.  The contents are identical to the {ssum} elements
	# added to xrefs by jmdict::add_xrefsums().  Specifically:
	#
 	#   {id} -- Entry id number.
	#   {seq} -- Entry seq. number.
	#   {src} -- Entry src id number.
	#   {stat} -- Entry status code (KW{STAT}{*}{id})
	#   {notes} -- Entry note.
	#   {srcnote} -- Entry source note.
	#   {rdng} -- Entry's reading texts coalesced into one string.
	#   {kanj} -- Entry's kanji texts coalesced into one string.
	#   {gloss} -- This sense's gloss texts coalesced into one string.
	#   {nsens} -- Total number of senses in entry.
	#
	# Prohibited conditions such as resolving to multiple
	# entries when the $one_entr_only flag is true, are 
	# signalled with die().  The caller may want to call 
	# resolv_xref() within an eval() to catch these conditions.
	
	my ($sql, $r, $ssums, @xrefs, $p, $s, $krtxt, @args, @argtxt, 
	    @nosens, $nentrs);

	$krtxt = fmt_jitem ($kanj, $rdng, $slist);
	if (!$::KW->{XREF}{$typ}) { die "Bad xref type value: $typ.\n"; }
	if (0) { }
	else {
	    if ($kanj)  { push (@args, $kanj); push (@argtxt, "k.txt=?"); }
	    if ($rdng)  { push (@args, $rdng); push (@argtxt, "r.txt=?"); }
	    if ($slist) { push (@argtxt, "sens IN(" . join (",", @$slist) . ")"); }
	    $sql = "SELECT DISTINCT id,sens,seq,src,stat,s.rdng,s.kanj,gloss,nsens " .
		  "FROM essum s " .
		  ($kanj ? "LEFT JOIN kanj k ON k.entr=id " : "") .
		  ($rdng ? "LEFT JOIN rdng r ON r.entr=id " : "") .
		  "WHERE " . join (" AND ", @argtxt) . " " .
		  "ORDER BY id,sens";
	    $ssums = dbread ($dbh, $sql, \@args); }
	foreach $r (@$ssums) { 
	    if (!$p || $p != $r->{id}) { ++$nentrs; } 
	    $p = $r->{id}; }
	if (!$nentrs) { die "No entries found for cross-reference '$krtxt'.\n"; }
	if ($nentrs > 1 and ($one_entr_only or ($slist and @$slist))) {
	    die "Multiple entries found for cross-reference '$krtxt'.\n"; }

	# For every target entry, get all it's sense numbers.  We need
	# these for two reasons: 1) If explicit senses were targeted we
	# need to check them against the actual senses. 2) If no explicit
	# target senses were given, then we need them to generate erefs 
	# to all the target senses.
	# The code currently compares actual sense numbers; if the database
	# could guarantee that sense numbers are always sequential from
	# one, this code could be simplified and speeded up.

	if ($slist && @$slist) {
	    # The submitter gave some specific senses that the xref will
	    # target, so check that they actually exist in the target entry
	    foreach $s (@$slist) {
		if (!grep ($_->{sens}==$s, @$ssums)) { push (@nosens, $s); } }
	    die "Sense(s) ".join(",",@nosens)." not in target '$krtxt'.\n" if (@nosens); } 
	else {
	    # No specific senses given, so this xref(s) should target every
	    # sense in the target entry(s), unless $one_sens_only is true
	    # in which case all the xrefs must have only one sense or we 
	    # raise an error.
	    if ($one_sens_only && grep ($_->{nsens}>1, @$ssums)) {
		die "The '$krtxt' target(s) has more than one sense.\n"; } }

	foreach $r (@$ssums) {
	    push (@xrefs, {typ=>$typ, xentr=>$r->{id}, xsens=>$r->{sens}, ssum=>$r}); }
	    
	return \@xrefs; } 

our ($KANA,$HIRAGANA,$KATAKANA,$KANJI) = (1, 2, 4, 8);

    sub jstr_classify { my ($str) = @_;
	# Returns an integer with bits set according to whether the
	# indicated type of characters are present in string $str.
	#     1 - Kana (either hiragana or katakana)
	#     2 - Hiragana
	#     4 - Katakana
	#     8 - Kanji

	my ($r, $n); $r = 0;
	foreach (split (//, $str)) {
	    $n = ord();
	    if    ($n >= 0x3040 and $n <= 0x309F) { $r |= ($HIRAGANA | $KANA); }
	    elsif ($n >= 0x30A0 and $n <= 0x30FF) { $r |= ($KATAKANA | $KANA); }
	    elsif ($n >= 0x4E00)                  { $r |= $KANJI; } }
	return $r; }

    sub setkeys { my ($e, $eid) = @_;
	# Set the foreign and primary key values in each record.
	my ($k, $r, $s, $g, $x, $nkanj, $nrdng, $nsens, $ngloss, $nhist, $nxref, $nxrsv);
	if ($eid) { $e->{id} = $eid; }
	else { $eid = $e->{id}; }
	die ("No entr.id number found or received") if (!$e->{id});
	if ($e->{_kanj}) { foreach $k (@{$e->{_kanj}}) {
	    $k->{entr} = $eid;
	    $k->{kanj} = ++$nkanj;
	    if ($k->{_kinf})  { foreach $x (@{$k->{_kinf}})  { $x->{entr} = $eid;  $x->{kanj} = $nkanj; } }
	    if ($k->{_freq})  { foreach $x (@{$k->{_freq}})  { $x->{entr} = $eid;  $x->{kanj} = $nkanj; } }
	    if ($k->{_restr}) { foreach $x (@{$k->{_restr}}) { $x->{entr} = $eid;  $x->{kanj} = $nkanj; } }
	    if ($k->{_stagk}) { foreach $x (@{$k->{_stagk}}) { $x->{entr} = $eid;  $x->{kanj} = $nkanj; } } } }
	if ($e->{_rdng}) { foreach $r (@{$e->{_rdng}}) {
	    $r->{entr} = $eid;  $r->{rdng} = ++$nrdng;
	    if ($r->{_rinf})  { foreach $x (@{$r->{_rinf}})  { $x->{entr} = $eid;  $x->{rdng} = $nrdng; } }
	    if ($r->{_audio}) { foreach $x (@{$r->{_audio}}) { $x->{entr} = $eid;  $x->{rdng} = $nrdng; } }
	    if ($r->{_freq})  { foreach $x (@{$r->{_freq}})  { $x->{entr} = $eid;  $x->{rdng} = $nrdng; } }
	    if ($r->{_restr}) { foreach $x (@{$r->{_restr}}) { $x->{entr} = $eid;  $x->{rdng} = $nrdng; } }
	    if ($r->{_stagr}) { foreach $x (@{$r->{_stagr}}) { $x->{entr} = $eid;  $x->{rdng} = $nrdng; } } } }
	if ($e->{_sens}) { foreach $s (@{$e->{_sens}}) {
	    $s->{entr} = $eid;  $s->{sens} = ++$nsens; $ngloss = $nxref = $nxrsv = 0;
	    if ($s->{_gloss}) { foreach $g (@{$s->{_gloss}}) { $g->{entr} = $eid;  $g->{sens} = $nsens;
							         $g->{gloss} = ++$ngloss; } }
	    if ($s->{_pos})   { foreach $x (@{$s->{_pos}})   { $x->{entr} = $eid;  $x->{sens} = $nsens; } }
	    if ($s->{_misc})  { foreach $x (@{$s->{_misc}})  { $x->{entr} = $eid;  $x->{sens} = $nsens; } }
	    if ($s->{_fld})   { foreach $x (@{$s->{_fld}})   { $x->{entr} = $eid;  $x->{sens} = $nsens; } }
	    if ($s->{_dial})  { foreach $x (@{$s->{_dial}})  { $x->{entr} = $eid;  $x->{sens} = $nsens; } }
	    if ($s->{_lsrc})  { foreach $x (@{$s->{_lsrc}})  { $x->{entr} = $eid;  $x->{sens} = $nsens; } }
	    if ($s->{_stagk}) { foreach $x (@{$s->{_stagk}}) { $x->{entr} = $eid;  $x->{sens} = $nsens; } }
	    if ($s->{_stagr}) { foreach $x (@{$s->{_stagr}}) { $x->{entr} = $eid;  $x->{sens} = $nsens; } }
	    if ($s->{_xrslv}) { foreach $x (@{$s->{_xrslv}}) { $x->{entr} = $eid;  $x->{sens} = $nsens;  
								 $x->{ord} = ++$nxrsv } }
	    if ($s->{_xref})  { foreach $x (@{$s->{_xref}})  { $x->{entr} = $eid;  $x->{sens} = $nsens;  
								 $x->{xref} = ++$nxref  } }
	    if ($s->{_xrer})  { foreach $x (@{$s->{_xrer}})  { $x->{xentr}= $eid;  $x->{xsens}= $nsens; } } } }
	if ($e->{_hist}) { foreach $x (@{$e->{_hist}})       { $x->{entr} = $eid;  $x->{hist} = ++$nhist; } } }

    sub addentr { my ($dbh, $entr) = @_;
	# Write the entry defined by %$entr to the database open
	# on connection $dbh.  Note the values in the primary key
	# fields of the records in $entr are ignored and regenerated.
	# Thus ordered items like the rdng records have the rndg
	# fields renumbered from 1 regardless of the values initially
	# in them.  

	my ($eid, $r, $k, $s, $g, $x, $h, $rs);
	if (!$entr->{seq}) { $entr->{seq} = undef; }
	$eid = dbinsert ($dbh, "entr", ['src','seq','stat','srcnote','notes'], $entr);
	setkeys ($entr, $eid);
	foreach $h (@{$entr->{_hist}})   {
	    dbinsert ($dbh, "hist", ['entr','hist','stat','dt','who','diff','notes'], $h); }
	foreach $k (@{$entr->{_kanj}})   {
	    dbinsert ($dbh, "kanj", ['entr','kanj','txt'], $k);
	    foreach $x (@{$k->{_kinf}})  { dbinsert ($dbh, "kinf",  ['entr','kanj','kw'], $x); } }
	foreach $r (@{$entr->{_rdng}})   {
	    dbinsert ($dbh, "rdng", ['entr','rdng','txt'], $r);
	    foreach $x (@{$r->{_rinf}})  { dbinsert ($dbh, "rinf",  ['entr','rdng','kw'], $x); }
	    foreach $x (@{$r->{_audio}}) { dbinsert ($dbh, "audio", ['entr','rdng','audio','fname','strt','leng','notes'], $x); }
	    foreach $x (@{$r->{_restr}}) { dbinsert ($dbh, "restr", ['entr','rdng','kanj'], $x); } }
	foreach $x (@{$entr->{_freq}}) {
	    dbinsert ($dbh, "freq", ['entr','rdng','kanj','kw','value'], $x); } 
	foreach $s (@{$entr->{_sens}}) {
	    dbinsert ($dbh, "sens", ['entr','sens','notes'], $s);
	    foreach $g (@{$s->{_gloss}}) { dbinsert ($dbh, "gloss", ['entr','sens','gloss','lang','ginf','txt'], $g); }
	    foreach $x (@{$s->{_pos}})   { dbinsert ($dbh, "pos",   ['entr','sens','kw'], $x); }
	    foreach $x (@{$s->{_misc}})  { dbinsert ($dbh, "misc",  ['entr','sens','kw'], $x); }
	    foreach $x (@{$s->{_fld}})   { dbinsert ($dbh, "fld",   ['entr','sens','kw'], $x); }
	    foreach $x (@{$s->{_dial}})  { dbinsert ($dbh, "dial",  ['entr','sens','kw'], $x); }
	    foreach $x (@{$s->{_lsrc}})  { dbinsert ($dbh, "lsrc",  ['entr','sens','lang','txt','part','wasei'], $x); }
	    foreach $x (@{$s->{_stagr}}) { dbinsert ($dbh, "stagr", ['entr','sens','rdng'], $x); }
	    foreach $x (@{$s->{_stagk}}) { dbinsert ($dbh, "stagk", ['entr','sens','kanj'], $x); }
	    foreach $x (@{$s->{_xref}})  { dbinsert ($dbh, "xref",  ['entr','sens','xref','typ','xentr','xsens','notes'], $x); } }
	if (!$entr->{seq}) { 
	    $rs = dbread ($dbh, "SELECT seq FROM entr WHERE id=?", [$eid]);
	    $entr->{seq} = $rs->[0]{seq}; }
	return ($eid, $entr->{seq}); }

    sub fmtkr { my ($kanj, $rdng) = @_;
	# If string $kanji is true return a string consisting
	# of $kanji . jp-left-bracket . $rdng . jp-right-bracket.
	# Other wise return just $rdng.

	my ($txt);
	if ($kanj) { $txt = "$kanj\x{3010}$rdng\x{3011}"; }
	else { $txt = $rdng; }
	return $txt; }

    sub fmt_jitem { my ($kanj, $rdng, $slist) = @_;
	# Format a textual xref descriptor printing (typically 
	# in an error message.)

	my $krtext = ($kanj || "") . (($kanj && $rdng) ? "/" : "") . ($rdng || ""); 
	if ($slist) { $krtext .= "[" . join (",", @$slist) . "]"; }
	return $krtext; }

    sub zip {
	# Takes an arbitrary number of arguments of references to arrays
	# of the same length, and creates and returns a reference to an
	# array of references to arrays where each array consists on one
	# element from each of the input arrays.  For example, given 3 
	# arguments array a, b, and c, all of length N, the output array will be
	# [[a[0],b[0],c[0]], [a[1],b[1],c[1]], [a[2],b[2],c[2]],...,[a[N-1],b[N-1],c[N-1]]]
	# Alterinatively, if you view the argument @_ as matrix (a list 
	# of equal-length lists), then this function returns its transpose.

	my ($n, $m, $x, $i, $j, @a);
	$n = scalar(@_); $m = scalar(@{$_[0]});  
	for ($j=0; $j<$m; $j++) {
	    $x = [];
	    for ($i=0; $i<$n; $i++) { push (@$x, $_[$i]->[$j]); }
	    push (@a, $x); }
	return \@a; }

    use DBI;
    sub dbopen { my ($cfgfile) = @_;
	# This function will open a database connection based on the contents
	# of a configuration file.  It is intended for the use of cgi scripts
	# where we do not want to embed the connection information (username,
	# password, etc) in the script itself, for both security and maintenance
	# reasons.

	my ($dbname, $username, $pw, $host, $dbh, $ln);
	if (!$cfgfile) { $cfgfile = "../lib/jmdict.cfg"; }
	open (F, $cfgfile) or die ("Can't open database config file\n");
	$ln = <F>;  close (F);  chomp($ln);
	($dbname, $username, $pw) = split (/ /, $ln); 
	$dbh = DBI->connect("dbi:Pg:dbname=$dbname", $username, $pw, 
			{ PrintWarn=>0, RaiseError=>1, AutoCommit=>0 } );
	$dbh->{pg_enable_utf8} = 1;
	return $dbh; }

    1;
