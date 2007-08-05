#!/usr/bin/env perl
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

@VERSION = (substr('$Revision$',11,-2), \
	    substr('$Date$',7,-11));

use strict; use warnings;
use Cwd; use CGI; use Encode 'decode_utf8'; use DBI; 
use Petal; use Petal::Utils; use Time::HiRes('time');

BEGIN {push (@INC, "../lib");}
use jmdict; use jmdicttal;

$|=1;
binmode (STDOUT, ":utf8");

    main: {
	my ($dbh, $cgi, $tmpl, @s, @y, @t, $col, @kinf, @rinf, @fld,
	    @pos, @misc, @src, @stat, @freq, $nfval, $nfcmp, $gaval, $gacmp, 
	    $idval, $idtbl, $sql, $sql_args, $sql2, $rs, $i, $freq, @condlist);
	binmode (STDOUT, ":encoding(utf-8)");
	$cgi = new CGI;
	$dbh = dbopen ();  $::KW = Kwds ($dbh);
	
	$s[0]=$cgi->param("s1"); $y[0]=$cgi->param("y1"); $t[0]=decode_utf8($cgi->param("t1"));
	$s[1]=$cgi->param("s2"); $y[1]=$cgi->param("y2"); $t[1]=decode_utf8($cgi->param("t2"));
	$s[2]=$cgi->param("s3"); $y[2]=$cgi->param("y3"); $t[2]=decode_utf8($cgi->param("t3"));
	@pos=$cgi->param("pos");   @misc=$cgi->param("misc"); @fld=$cgi->param("fld");
	@rinf=$cgi->param("rinf"); @kinf=$cgi->param("kinf"); @freq=$cgi->param("freq");
	@src=$cgi->param("src");   @stat=$cgi->param("stat"); 
	$nfval=$cgi->param("nfval"); $nfcmp=$cgi->param("nfcmp");
	$gaval=$cgi->param("gaval"); $gacmp=$cgi->param("gacmp");
	$idval=$cgi->param("idval"); $idtbl=$cgi->param("idtyp");

	if ($idval) {	# Search for id number...
	    if ($idtbl ne "seqnum") { $col = "id"; }
	    else { $idtbl = "entr e";  $col = "seq"; }
	    ($sql, $sql_args) = build_search_sql (
		[[$idtbl, sprintf ("e.%s=?", $col), [$idval]]]); }
	else {
	    for $i (0..2) {
		if ($t[$i]) { 
		    push (@condlist, str_match_clause ($s[$i],$y[$i],$t[$i],$i)); } }
	    if (@pos)  { push (@condlist, ["pos",   getsel("pos.kw",  \@pos), []]); }
	    if (@misc) { push (@condlist, ["misc",  getsel("misc.kw", \@misc),[]]); }
	    if (@fld)  { push (@condlist, ["fld",   getsel("fld.kw",  \@fld), []]); }
	    if (@kinf) { push (@condlist, ["kinf",  getsel("kinf.kw", \@kinf),[]]); }
	    if (@rinf) { push (@condlist, ["rinf",  getsel("rinf.kw", \@rinf),[]]); }
	    if (@src)  { push (@condlist, ["entr e",getsel("e.src",   \@src), []]); }
	    if (@stat) { push (@condlist, ["entr e",getsel("e.stat",  \@stat),[]]); }
	    if (@freq) { push (@condlist, freq_srch_clause (\@freq, $nfval, $nfcmp, $gaval, $gacmp)); }
	    ($sql, $sql_args) = build_search_sql (\@condlist); }

	$::Debug->{'Search sql'} = $sql;  $::Debug->{'Search args'} = join(",", @$sql_args);
	$sql2 = sprintf ("SELECT q.* FROM esum q JOIN (%s) AS i ON i.id=q.id", $sql);
	my $start = time();
	eval { $rs = dbread ($dbh, $sql2, $sql_args); };
	$::Debug->{'Search time'} = time() - $start;
	if ($@) {
	    print "Content-type: text/html\n\n<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"/></head><body>";
	    print "<pre> $@ </pre>\n<pre>$sql2</pre>\n<pre>".join(", ", @$sql_args)."</pre></body></html>\n";
	    exit (1); }
	if (scalar (@$rs) == 1) {
	    printf ("Location: entr.pl?e=%d\n\n", $rs->[0]{id}); }
	else {
	    print "Content-type: text/html\n\n";
	    $tmpl = new Petal (file=>'../lib/tal/srchres.tal', 
			   decode_charset=>'utf-8', output=>'HTML' );
	    print $tmpl->process (results=>$rs, dbg=>$::Debug); }
	$dbh->disconnect; }

    sub str_match_clause { my ($srchin, $srchtyp, $srchtxt, $idx) = @_; 
	my ($x, $table, $alias, $whr, @args);
	if ($srchin eq "auto") {
	    $x = jstr_classify ($srchtxt);
	    if ($x & $jmdict::KANJI) { $table = "kanj";  }
	    elsif ($x & $jmdict::KANA) { $table = "rdng"; }
	    else { $table = "gloss"; } }
	else { $table = $srchin; }
	$alias = " " . {kanj=>"j", rdng=>"r", gloss=>"g"}->{$table} . "$idx";
	$srchtyp = lc ($srchtyp);
	if ($srchtyp eq "is")		{ $whr = sprintf ("%s.txt=?", $alias); }
	else				{ $whr = sprintf ("%s.txt LIKE(?)", $alias); }
	if ($srchtyp eq "is")		{ @args = ($srchtxt); }
	elsif ($srchtyp eq "starts")	{ @args = ($srchtxt."%",); }
	elsif ($srchtyp eq "contains")	{ @args = ("%".$srchtxt."%"); }
	elsif ($srchtyp eq "ends")	{ @args = ("%".$srchtxt); }
	else { die ("srchtyp = " . $srchtyp); }
	return ["$table$alias",$whr,\@args]; }

    sub getsel { my ($fqcol, $itms) = @_;
	my $s = sprintf ("%s IN (%s)", $fqcol, join(",", @$itms));
	return $s; }

    sub freq_srch_clause { my ($freq, $nfval, $nfcmp, $gaval, $gacmp) = @_;
	# Create a pair of 3-tuples (build_search_sql() "conditions")
	# that build_search_sql() will use to create a sql statement 
	# that will incorporate the freq-of-use criteria defined by
	# our parameters:
	#
	# $freq -- List of string values of a freq option checkboxes, e.g. "ichi2".
	# $nfval -- String containing an "nf" number ("1" - "48").
	# $nfcmp -- String containing one of ">=", "=", "<=".
	# gaval -- String containing a gA number.
	# gacmp -- Same as nfcmp.

	my ($f, $domain, $value, %x, $k, $v, $kwid, @whr, $whr);

	# Freq items consist of a domain (such as "ichi" or "nf")
	# and a value (such as "1" or "35").
	# Process the checkboxes by creating a hash indexed by 
	# by domain and with each value a list of freq values.

	foreach $f (@$freq) {
	    # Split into text (domain) and numeric (value) parts.
	    ($domain, $value) = ($f =~ m/(^[A-Za-z_-]+)(\d*)$/);
	    # We will handle "nfxx" and "gAxxxx" later.
	    next if ($domain eq "nf" or $domain eq "ga");
	    # If this domain not in hash yet, add it.
	    if (!defined ($x{$domain})) { $x{$domain} = []; }
	    # Append this value to the list.
	    push (@{$x{$domain}}, $value); }

	# Now process each domain and it's list of values...

	while (($k,$v) = each (%x)) {
	    # Convert the domain string to a kwfreq table id number.
	    $kwid = $::KW->{FREQ}{$k}{id};

	    # The following assumes that the range of values are 
	    # limited to 1 and 2.

	    if (scalar(@$v)==2) { push (@whr, sprintf (
		# As an optimization, if there are 2 values, they must be 1 and 2, 
		# so no need to check value in query, just see if the domain exists.
		# FIXME: The above is false, there could be two "1" values.
		# FIXME: The above assumes only 1 and 2 are allowed.  Currently
		#   true but may change in future.
		"(freq.kw=%s)", $kwid)); }
	    elsif (scalar(@$v) == 1) { push (@whr, sprintf (
		# If there is only one value we need to look for kw with
		# that value.
		"(freq.kw=%s AND freq.value=%s)", $kwid, $v->[0])); }
	    elsif (scalar(@$v) > 2) { push (@whr, sprintf (
		# If there are more than 2 values then we look for them explicitly
		# using an IN() construct.
		"(freq.kw=%s AND freq.value IN (%s))", $k, join(",",@$v))); }
	    # A 0 or negative length list should be impossible.
	    else { die; } }

	# Handle the "nfxx" items specially here.

	if (grep ($_ eq "nf", @$freq) and $nfval) {
	    # Convert the domain string to a kwfreq table id number.
	    $kwid = $::KW->{FREQ}{nf}{id};
	    # Build list of "where" clause parts using the requested comparison and value.
	    push (@whr, sprintf (
		"(freq.kw=%s AND freq.value%s%s)", $kwid, $nfcmp, $nfval)); }

	# Handle the "gAxx" items specially here.

	if (grep ($_ eq "ga", @$freq) and $gaval) {
	    # Convert the domain string to a kwfreq table id number.
	    $kwid = $::KW->{FREQ}{gA}{id};
	    # Build list of "where" clause parts using the requested comparison and value.
	    push (@whr, sprintf (
		"(freq.kw=%s AND freq.value%s%s)", $kwid, $gacmp, $gaval)); }

	# Now, @whr is a list of all the various freq ewlated conditions that 
	# were  selected.  We change it into a clause by connecting them all 
	# with " OR".
	$whr = "(" . join(" OR ", @whr) . ")";

	# If there were no freq related conditions...
	return [] if (!$whr);

	# Return two triples suitable for use by build-search_sql().  That function
	# will build sql that effectivly "AND"s all the conditions (each specified 
	# in a triple) given to it.  Our freq conditions applies to two tables 
	# (rfreq and kfreq) and we want them OR'd not AND'd.  So we cheat and use a
	# strisk in front of table name to tell build_search_sql() to use left joins
	# rather than inner joins when refering to that condition's table.  This will
	# result in the inclusion in the result set of rfreq rows that match the
	# criteria, even if there are no matching kfreq rows (and visa versa). 
	# The where clause refers to both the rfreq and kfreq tables, so need only
	# be given in one constion triple rather than in each. 
	return (["freq",$whr,[]]); }

    sub build_search_sql { my ($condlist) = @_;

	# Build a sql statement that will find the id numbers of
	# all entries matching the conditions given in <condlist>.
	# Note: This function does not provide for generating
	# arbitrary SQL statements; it is only intented to support 
	# limited search capabilities that are typically provided 
	# on a search form.
	#
	# <condlist> is a list of 3-tuples.  Each 3-tuple specifies
	# one condition:
	#   0: Name of table that contains the field being searched
	#     on.  The name may optionally be followed by a space and
	#     an alias name for the table.  It may also optionally be
	#     preceeded (no space) by an astrisk character to indicate
	#     the table should be joined with a LEFT JOIN rather than
	#     the default INNER JOIN. 
	#     Caution: if the table is "entr" it *must* have "e" as an
	#     alias, since that alias is expected by the final generated
	#     sql.
	#   1: Sql snippit that will be AND'd into the WHERE clause.
	#     Field names must be qualified by table.  When looking 
	#     for a value in a field.  A "?" may (and should) be used 
	#     where possible to denote an exectime parameter.  The value
	#     to be used when the sql is executed is is provided in
	#     the 3rd member of the tuple (see #2 next).
	#   2: A sequence of argument values for any exec-time parameters
	#     ("?") used in the second value of the tuple (see #1 above).
	#
	# Example:
	#     [("entr e","e.typ=1", ()),
	#      ("gloss", "gloss.text LIKE ?", ("'%'+but+'%'",)),
	#      ("pos","pos.kw IN (?,?,?)",(8,18,47))]
	#
	#   This will generate the SQL statement and arguments:
	#     "SELECT e.id FROM (((entr e INNER JOIN sens ON sens.entr=entr.id) 
	# 	INNER JOIN gloss ON gloss.sens=sens.id) 
	# 	INNER JOIN pos ON pos.sens=sens.id) 
	# 	WHERE e.typ=1 AND (gloss.text=?) AND (pos IN (?,?,?))"
	#     ('but',8,18,47)
	#   which will find all entries that have a gloss containing the
	#   substring "but" and a sense with a pos (part-of-speech) tagged
	#   as a conjunction (pos.kw=8), a particle (18), or an irregular
	#   verb (47).
	# 
	#   

	my ($fclause, $cnum,  @wclauses, @args, $jt, $alias,
	    $cond, $arg, $tbl, $where, $sql, $itm, $jointype);

	# $fclause will become the FROM clause of the generated sql.  Since
	# all queries will rquire "entr" to be included, we start of with 
	# that table in the clause.

	$fclause = "entr e";  $cnum = 0;

	# Go through the condition list.  For each 3-tuple we will add the
	# table name to the FROM clause, and the where and arguments items 
	# to there own arrays.

	foreach $itm (@$condlist) {

	    # extend_from() requires a number that it uses to generate 
	    # unique table aliases.  We will use $cnum for this.

	    $cnum += 1;

	    # unpack a @$condist 3-tuple.

	    ($tbl, $cond, $arg) = @$itm;

	    # The table name may be preceeded by a "*" to indicate that
	    # it is to be joinged with a LEFT JOIN rather than the usual
	    # INNER JOIN".  It may also be followed by a space and an 
	    # alias name.  Unpack these things.
 
	    ($jt, $tbl, undef, $alias) = ($tbl =~ m/^([*])?(\w+)(\s+(\w+))?$/);
	    $jointype = $jt ? "LEFT JOIN" : "JOIN";

	    # Add the table (using the desired alias if any) to the FROM 
	    # clause (except if the table is "entr" which is aleady in 
	    # the FROM clause).

	    $alias = $alias || "";
	    if ($tbl ne "entr") {
		$fclause .= sprintf (" %s %s %s ON %s.entr=e.id", 
				     $jointype, $tbl, $alias, ($alias || $tbl)); }
	    else {
		# Sanity check...
		if ($alias && !($alias eq "e")) {
		    die "table 'entr' in condition list uses alias other than 'e': $alias\n"; } }

	    # Save the cond tuple's where clause and arguments each in 
	    # their own array.

	    push (@wclauses, $cond);
	    push (@args, @$arg); }

	# AND all the where clauses together.

	$where = join (" AND ", grep ($_, @wclauses));

	# Create the sql we need to find the entr.id numbers from 
	# the tables and where conditions given in the @$condlist.

	$sql = sprintf ("SELECT DISTINCT e.id FROM %s WHERE %s", $fclause, $where);

	# Return the sql and the arguments which are now suitable
	# for execution.

	return ($sql, \@args); }
