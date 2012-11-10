
# jelparse_tab.py
# This file is automatically generated. Do not edit.
_tabversion = '3.2'

_lr_method = 'LALR'

_lr_signature = b'\x95g\xa2q)4\x92\x1e\x87\xf7C\x87\x08\xa5\xc7z'
    
_lr_action_items = {'BRKTR':([18,19,20,21,22,23,39,40,41,42,43,44,45,46,47,48,49,50,59,60,62,63,65,70,71,72,73,74,75,77,78,81,83,84,85,],[-32,-31,31,-27,-29,-30,-43,-49,-46,-33,-54,-47,-52,-51,-53,-38,-41,-28,-44,-34,-55,-56,-48,-45,81,-58,-40,-35,-39,-50,-42,-57,-36,-59,-37,]),'QTEXT':([11,30,32,57,60,64,66,83,],[18,47,18,47,73,47,47,73,]),'NL':([0,3,5,6,7,8,9,10,12,13,14,15,17,26,27,29,31,33,],[4,-7,15,-13,-14,-5,-8,-24,25,-9,-11,28,-25,-12,37,-6,-26,-10,]),'TEXT':([11,30,32,43,60,61,83,],[19,42,19,63,75,76,75,]),'NUMBER':([30,58,66,82,],[43,72,43,84,]),'SEMI':([3,5,6,7,8,9,10,12,13,14,17,26,27,29,31,33,39,40,41,43,44,45,46,47,48,49,52,53,54,59,62,63,65,67,69,70,77,78,79,80,81,],[-7,16,-13,-14,-5,-8,-24,24,-9,-11,-25,-12,24,-6,-26,-10,-43,-49,-46,-54,-47,-52,-51,-53,66,-41,-18,68,-20,-44,-55,-56,-48,-22,-21,-45,-50,-42,-23,-19,-57,]),'$end':([1,2,10,17,31,35,36,38,52,53,54,55,56,67,69,79,80,],[0,-1,-24,-25,-26,-3,-15,-4,-18,-17,-20,-16,-2,-22,-21,-23,-19,]),'SNUM':([10,17,25,28,31,35,36,37,38,52,53,54,55,56,67,69,79,80,],[-24,-25,34,34,-26,34,-15,34,34,-18,-17,-20,-16,34,-22,-21,-23,-19,]),'COMMA':([18,19,20,21,22,23,39,40,41,42,43,44,45,46,47,48,49,50,59,60,62,63,65,70,71,72,73,74,75,77,78,81,83,84,85,],[-32,-31,32,-27,-29,-30,-43,-49,-46,-33,-54,-47,-52,-51,-53,-38,-41,-28,-44,-34,-55,-56,-48,-45,82,-58,-40,-35,-39,-50,-42,-57,-36,-59,-37,]),'SLASH':([42,],[61,]),'DOT':([39,40,43,44,45,46,47,62,63,77,],[57,-49,-54,64,-52,-51,-53,-55,-56,-50,]),'KTEXT':([0,4,11,15,16,24,30,32,57,64,66,],[6,6,22,6,6,6,46,22,46,46,46,]),'COLON':([42,76,],[60,83,]),'EQL':([19,],[30,]),'BRKTL':([3,6,7,9,10,14,17,26,31,34,39,40,43,44,45,46,47,51,54,62,63,67,68,69,77,79,],[11,-13,-14,11,-24,11,-25,11,-26,11,58,-49,-54,58,-52,-51,-53,11,11,-55,-56,11,11,11,-50,11,]),'GTEXT':([10,17,31,34,51,68,],[-24,-25,-26,54,67,54,]),'HASH':([43,],[62,]),'RTEXT':([0,4,11,15,16,24,30,32,57,64,66,],[7,7,23,7,7,7,45,23,45,45,45,]),}

_lr_action = { }
for _k, _v in _lr_action_items.items():
   for _x,_y in zip(_v[0],_v[1]):
      if not _x in _lr_action:  _lr_action[_x] = { }
      _lr_action[_x][_k] = _y
del _lr_action_items

_lr_goto_items = {'entr':([0,],[1,]),'xrefnum':([30,66,],[39,39,]),'preentr':([0,],[2,]),'rdngitem':([4,15,24,],[13,13,33,]),'jitem':([30,57,66,],[41,70,41,]),'snums':([58,],[71,]),'slist':([39,44,],[59,65,]),'tagitem':([11,32,],[21,50,]),'rdngsect':([4,15,],[12,27,]),'atext':([60,83,],[74,85,]),'jrefs':([30,],[48,]),'kanjsect':([0,],[5,]),'krtext':([0,4,15,16,24,],[3,14,14,3,14,]),'jtext':([30,57,64,66,],[40,40,77,40,]),'taglist':([3,9,14,26,34,51,54,67,68,69,79,],[10,17,10,17,10,17,10,10,10,17,17,]),'tags':([11,],[20,]),'sense':([25,28,35,37,38,56,],[36,36,55,36,55,55,]),'taglists':([3,14,34,54,67,68,],[9,26,51,69,79,51,]),'gloss':([34,68,],[52,80,]),'senses':([25,28,37,],[35,38,56,]),'glosses':([34,],[53,]),'kanjitem':([0,16,],[8,29,]),'dotlist':([30,57,66,],[44,44,44,]),'jref':([30,66,],[49,78,]),}

_lr_goto = { }
for _k, _v in _lr_goto_items.items():
   for _x,_y in zip(_v[0],_v[1]):
       if not _x in _lr_goto: _lr_goto[_x] = { }
       _lr_goto[_x][_k] = _y
del _lr_goto_items
_lr_productions = [
  ("S' -> entr","S'",1,None,None,None),
  ('entr -> preentr','entr',1,'p_entr_1','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',40),
  ('preentr -> kanjsect NL rdngsect NL senses','preentr',5,'p_preentr_1','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',76),
  ('preentr -> NL rdngsect NL senses','preentr',4,'p_preentr_2','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',80),
  ('preentr -> kanjsect NL NL senses','preentr',4,'p_preentr_3','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',84),
  ('kanjsect -> kanjitem','kanjsect',1,'p_kanjsect_1','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',88),
  ('kanjsect -> kanjsect SEMI kanjitem','kanjsect',3,'p_kanjsect_2','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',92),
  ('kanjitem -> krtext','kanjitem',1,'p_kanjitem_1','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',96),
  ('kanjitem -> krtext taglists','kanjitem',2,'p_kanjitem_2','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',100),
  ('rdngsect -> rdngitem','rdngsect',1,'p_rdngsect_1','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',107),
  ('rdngsect -> rdngsect SEMI rdngitem','rdngsect',3,'p_rdngsect_2','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',111),
  ('rdngitem -> krtext','rdngitem',1,'p_rdngitem_1','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',115),
  ('rdngitem -> krtext taglists','rdngitem',2,'p_rdngitem_2','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',119),
  ('krtext -> KTEXT','krtext',1,'p_krtext_1','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',126),
  ('krtext -> RTEXT','krtext',1,'p_krtext_2','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',130),
  ('senses -> sense','senses',1,'p_senses_1','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',134),
  ('senses -> senses sense','senses',2,'p_senses_2','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',138),
  ('sense -> SNUM glosses','sense',2,'p_sense_1','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',142),
  ('glosses -> gloss','glosses',1,'p_glosses_1','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',149),
  ('glosses -> glosses SEMI gloss','glosses',3,'p_glosses_2','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',153),
  ('gloss -> GTEXT','gloss',1,'p_gloss_1','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',157),
  ('gloss -> GTEXT taglists','gloss',2,'p_gloss_2','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',161),
  ('gloss -> taglists GTEXT','gloss',2,'p_gloss_3','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',165),
  ('gloss -> taglists GTEXT taglists','gloss',3,'p_gloss_4','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',169),
  ('taglists -> taglist','taglists',1,'p_taglists_1','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',173),
  ('taglists -> taglists taglist','taglists',2,'p_taglists_2','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',177),
  ('taglist -> BRKTL tags BRKTR','taglist',3,'p_taglist_1','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',182),
  ('tags -> tagitem','tags',1,'p_tags_1','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',186),
  ('tags -> tags COMMA tagitem','tags',3,'p_tags_2','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',190),
  ('tagitem -> KTEXT','tagitem',1,'p_tagitem_1','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',195),
  ('tagitem -> RTEXT','tagitem',1,'p_tagitem_2','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',199),
  ('tagitem -> TEXT','tagitem',1,'p_tagitem_3','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',203),
  ('tagitem -> QTEXT','tagitem',1,'p_tagitem_4','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',212),
  ('tagitem -> TEXT EQL TEXT','tagitem',3,'p_tagitem_5','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',221),
  ('tagitem -> TEXT EQL TEXT COLON','tagitem',4,'p_tagitem_6','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',225),
  ('tagitem -> TEXT EQL TEXT COLON atext','tagitem',5,'p_tagitem_7','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',233),
  ('tagitem -> TEXT EQL TEXT SLASH TEXT COLON','tagitem',6,'p_tagitem_8','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',247),
  ('tagitem -> TEXT EQL TEXT SLASH TEXT COLON atext','tagitem',7,'p_tagitem_9','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',258),
  ('tagitem -> TEXT EQL jrefs','tagitem',3,'p_tagitem_10','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',269),
  ('atext -> TEXT','atext',1,'p_atext_1','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',309),
  ('atext -> QTEXT','atext',1,'p_atext_2','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',313),
  ('jrefs -> jref','jrefs',1,'p_jrefs_1','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',317),
  ('jrefs -> jrefs SEMI jref','jrefs',3,'p_jrefs_2','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',321),
  ('jref -> xrefnum','jref',1,'p_jref_1','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',325),
  ('jref -> xrefnum slist','jref',2,'p_jref_2','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',329),
  ('jref -> xrefnum DOT jitem','jref',3,'p_jref_3','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',333),
  ('jref -> jitem','jref',1,'p_jref_4','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',337),
  ('jitem -> dotlist','jitem',1,'p_jitem_1','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',341),
  ('jitem -> dotlist slist','jitem',2,'p_jitem_2','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',345),
  ('dotlist -> jtext','dotlist',1,'p_dotlist_1','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',349),
  ('dotlist -> dotlist DOT jtext','dotlist',3,'p_dotlist_2','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',353),
  ('jtext -> KTEXT','jtext',1,'p_jtext_1','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',357),
  ('jtext -> RTEXT','jtext',1,'p_jtext_2','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',361),
  ('jtext -> QTEXT','jtext',1,'p_jtext_3','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',365),
  ('xrefnum -> NUMBER','xrefnum',1,'p_xrefnum_1','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',369),
  ('xrefnum -> NUMBER HASH','xrefnum',2,'p_xrefnum_2','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',373),
  ('xrefnum -> NUMBER TEXT','xrefnum',2,'p_xrefnum_3','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',377),
  ('slist -> BRKTL snums BRKTR','slist',3,'p_slist_1','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',381),
  ('snums -> NUMBER','snums',1,'p_snums_1','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',385),
  ('snums -> snums COMMA NUMBER','snums',3,'p_snums_2','/home/stuart/devel/jdb/jb3/python/lib/jelparse.py',392),
]
