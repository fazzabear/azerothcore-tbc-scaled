-- Identifies all creatures added in TBC that spawn in a raid zone, increases min and max level by 10

create table TBC_RAIDS as	
    select distinct entry from creature_template a join creature b on a.entry = b.id1 
		where b.map in(
		532, -- Kara
        565, -- Gruul
        544, -- Mag
		548, -- SSC 
		550, -- TK
		534, -- Hyjal
		564, -- BT
		568, -- ZA
        580 -- Sunwell
        )
or (a.exp = 1 and a.`rank` = 3) -- picks up world bosses and spawned bosses who don't have a spawn entry (e.g. kil'jaeden)
;


update creature_template 
set 
minlevel = minlevel+10,
maxlevel = maxlevel+10
where entry in(select entry from TBC_RAIDS);


-- Identifies all creature entries added in TBC that are listed as having a non-heroic version, increases min and max level by 10
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
maxlevel = maxlevel+10
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


-- Identifies TBC heroic items and epics
select * 
from acore_world.item_template
where class in (2,4) -- weapons and armor
and ((quality = 3 and ItemLevel = 115) or quality = 4) 
-- all epics, plus heroic blues. WOTLK early dungeon blues that require level 70 are a higher ilvl
-- pvp gear excluded
-- checked ilvl outliers, seems fine
and bonding = 1 -- BoP
and RequiredLevel = 70
and name not like '%gladiator%'
and name not like '%high warlord%'
and name not like '%grand marshal%'
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

where class in (2,4) -- weapons and armor
(
and 
(
((quality = 3 and ItemLevel = 115) or quality = 4) 
-- all epics, plus heroic blues. WOTLK early dungeon blues that require level 70 are a higher ilvl
-- pvp gear excluded
-- checked ilvl outliers, seems fine
and bonding = 1 -- BoP
and RequiredLevel = 70
and name not like '%gladiator%'
and name not like '%high warlord%'
and name not like '%grand marshal%'
)

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
