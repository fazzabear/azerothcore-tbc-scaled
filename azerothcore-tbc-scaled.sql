-- Identifies all creatures added in TBC that spawn in a dungeon or raid zone 

create table TBC_UPSCALE as	

select distinct a.entry
from creature_template a 
left outer join creature b on a.entry = b.id1
left outer join spell_edit.map c on b.map = c.id
left outer join creature_template d on a.entry = d.difficulty_entry_1
left outer join creature e on d.entry = e.id1
left outer join spell_edit.map f on e.map = f.id

-- filters out some odd variables for Kalimdor and Outland (Ogri'la phasing)
where 
case when b.map is not null then b.map when e.map is not null then e.map else 0 end not in
(1,530)

-- filters out some critters
and a.entry not in
(14881,4075,2110,29630,38228,13321,32258,15475,36848,16068,16030,4076,23086,23087,1412,2914,23817,24396,1420)


and 
(
-- TBC Heroics 

(d.difficulty_entry_1 is not null and d.exp in(1)

or
 -- TBC raids 
b.map in(532,565,544,548,550,534,564,568,580)
or b.zoneid in (SELECT AreaTableID FROM spell_edit.map where 
id in (532,565,544,548,550,534,564,568,580) and AreaTableID !=0)


OR
-- all TBC bosses
(exp = 1 and rank = 3)

or
-- TBC spawned raid effects (e.g. vashj spore bats)
(a.AIName = 'NullCreatureAI' and a.minlevel >= 70 and a.exp = 1) 
;


-- increases min and max level by 10
update creature_template 
set 
minlevel = minlevel+10,
maxlevel = maxlevel+10,
exp = 2
where entry in(select entry from TBC_UPSCALE);

-- Attempt to capture other entries (summoned mobs etc) 
-- Unrefined
create table TBC_MISC as
select
case when a.entry is null then d.entry else a.entry end entry,

from creature_template a 
left outer join creature b on a.entry = b.id1
left outer join spell_edit.map c on b.map = c.id
left outer join creature_template d on a.entry = d.difficulty_entry_1
left outer join creature e on d.entry = e.id1
left outer join spell_edit.map f on e.map = f.id

where 
case when a.entry is null then d.entry else a.entry end not in (select entry from TBC_RAIDS)
and 
case when a.entry is null then d.entry else a.entry end not in (select entry from TBC_HEROICS)
and

(
-- TBC Heroics 
(d.difficulty_entry_1 is not null and d.exp in(1))

or
 -- TBC raids 
b.map in(532,565,544,548,550,534,564,568,580)
or b.zoneid in (SELECT AreaTableID FROM spell_edit.map where 
id in (532,565,544,548,550,534,564,568,580) and AreaTableID !=0)

or
-- TBC spawned raid effects (e.g. vashj spore bats)
(a.AIName = 'NullCreatureAI' and a.minlevel >= 70 and a.exp = 1) 
);



update creature_template set
minlevel = minlevel+10,
maxlevel = maxlevel+10,
exp = 2
where entry in (select entry from tbc_misc);




-- Identifies all heroic creature entries added in TBC that are listed as having a non-heroic version, increases min and max level by 10
-- Reviewing the entries, looks to also hit TBC version AV and some phased mobs (ogri'la etc) 
create table TBC_HEROICS as 
select a.entry from
creature_template a 
left outer join creature_template b on a.entry = b.difficulty_entry_1
where a.exp = 1
and (b.entry is not null);

update creature_template 
set 
minlevel = minlevel+10,
maxlevel = maxlevel+10,
exp = 2
where entry in(
select entry from TBC_HEROICS);

-- could also use map IDs 558,557,556,555,269,560,547,545,546,542,543,540,552,553,554,585 with a similar method to the raid update
-- doing  would miss creatures that don't have a spawn entry, attempting to use the work-around used for bosses could have wider impact (i.e. open world spawned elites)


-- Updates the minimum, maximum, target level minimum and target level maximum for TBC heroics in the RDF
-- These changes are made to lfgdungeons.dbc in sql form, as per Stoneharry's spell editor

update spell_edit.lfgdungeons 
set 
minlevel = 80,
maxlevel = 80,
targetlevel = 80,
targetlevelmin = 80,
targetlevelmax = 80
where difficulty = 1 and expansion = 1;

-- Optionally, upscale all TBC creatures to WOTLK scaling. Has no impact for creatures under level 66 - check creature_classlevelstats for details
-- update creature_template set exp = 2 where exp = 1


-- Identifies TBC heroic items and epics
select * 
from
acore_world.item_template
where 
(class = 4 or
class = 2 and dmg_min1 > 5) -- weapons and armor, excluding weapons and odd outliers with little or no DPS that are used for appearance sets
and
(
	(((quality = 3 and ItemLevel = 115) -- heroic-level rares
	or quality = 4) -- epics
	and bonding = 1 -- BoP
	and RequiredLevel = 70
	) -- Level 70 rares and epics that BOP
or itemlevel >199) -- WOTLK items
			
and name not like '%gladiator%'
and name not like '%high warlord%'
and name not like '%grand marshal%'
and name not like 'Chancellor''s%' -- excluding PVP gear and a bunch of TBC items not available to players
and RequiredReputationFaction = 0 -- exclude rep items, doing a daily vendor check to see if a rep item has rolled well sounds horrendous
;

-- Updates lower level gear within scope. 
-- This does not make them as strong as item level 232 gear, as the formula of ilvl:stats is not linear, but it reduces the gap

update acore_world.item_template
set
dmg_min1 = (dmg_min1/itemlevel) *232
dmg_max1 = (dmg_max1/itemlevel)*232
armor = (armor/itemlevel)*232,
block = (block/itemlevel)*232,
stat_value1= (stat_value1/itemlevel)*232,
stat_value2= (stat_value2/itemlevel)*232,
stat_value3= (stat_value3/itemlevel)*232,
stat_value4= (stat_value4/itemlevel)*232,
stat_value5= (stat_value5/itemlevel)*232,
stat_value6= (stat_value6/itemlevel)*232,
stat_value7= (stat_value7/itemlevel)*232,
stat_value8= (stat_value8/itemlevel)*232,
stat_value9= (stat_value9/itemlevel)*232,
stat_value10= (stat_value10/itemlevel)*232

where 
(class = 4 or
class = 2 and dmg_min1 > 5) -- weapons and armor, excluding weapons and odd outliers with little or no DPS that are used for appearance sets
and
(
	(((quality = 3 and ItemLevel = 115) -- heroic-level rares
	or quality = 4) -- epics
	and bonding = 1 -- BoP
	and RequiredLevel = 70
	) -- Level 70 rares and epics that BOP
or (itemlevel >199 and itemlevel < 232) -- WOTLK items
			
and name not like '%gladiator%'
and name not like '%high warlord%'
and name not like '%grand marshal%'
and name not like 'Chancellor''s%' -- excluding PVP gear and a bunch of TBC items not available to players
and RequiredReputationFaction = 0 -- exclude rep items, doing a daily vendor check to see if a rep item has rolled well sounds horrendous
;

-- Optionally, upscale early WOTLK items as well
/*
OR
(
and quality in (3,4) -- rares and epics
and itemlevel > 199 -- 200+ = WOTLK level 80 gear and early raids
and itemlevel < 232 -- Heroic ICC 5mans
)
*/
)
;
