// CHaracter Info Toolbox - summon & copy brick
//
// The monster copiers you own: what (if anything) is loaded, and how many more
// copies you can make / use today. Fax, Spooky Putty, Rain-Doh, 4-D / crappy
// cameras, print screen, ice sculpture, envyfish egg, blank Spooky VHS tapes,
// and Chest Mimic eggs. A row shows when you have a copy loaded, uses left
// today, or the consumable in inventory. (Monsters already loose as wanderers
// are in the Wandering Monsters brick.)
//
// Shares monsterQueueRow() with chit_brickWanderers.ash (imported first).

record copy_src {
	string label;
	string monsterPref;   // pref holding a loaded copied-monster name ("" = n/a)
	string stockItem;     // consumable whose inventory count is "uses left" ("" = none)
	string madePref;      // copies-made-today counter ("" = none)
	int madeCap;          // daily cap for madePref
	string usedPref;      // boolean "used today" pref ("" = none)
	string haveItem;      // owning this item means you can use this copier ("" = none)
	string image;
};

copy_src[int] copySources() {
	copy_src[int] s;
	s[s.count()] = new copy_src("Fax", "photocopyMonster", "", "", 0, "_photocopyUsed", "", "photocopy.gif");
	s[s.count()] = new copy_src("Spooky Putty", "spookyPuttyMonster", "", "spookyPuttyCopiesMade", 5, "", "Spooky Putty sheet", "sputtycopy.gif");
	s[s.count()] = new copy_src("Rain-Doh", "rainDohMonster", "", "_raindohCopiesMade", 5, "", "Rain-Doh black box", "raindohbox.gif");
	s[s.count()] = new copy_src("4-D Camera", "cameraMonster", "", "", 0, "_cameraUsed", "4-d camera", "camera.gif");
	s[s.count()] = new copy_src("Crappy Camera", "crappyCameraMonster", "", "", 0, "_crappyCameraUsed", "disposable instant camera", "camera.gif");
	s[s.count()] = new copy_src("Print Screen", "screencappedMonster", "", "", 0, "", "print screen button", "printscreen.gif");
	s[s.count()] = new copy_src("Ice Sculpture", "iceSculptureMonster", "", "", 0, "_iceSculptureUsed", "unfinished ice sculpture", "icesculpt2.gif");
	s[s.count()] = new copy_src("Envyfish Egg", "envyfishMonster", "", "", 0, "_envyfishEggUsed", "", "roe.gif");
	s[s.count()] = new copy_src("Spooky VHS Tape", "", "spooky VHS tape", "", 0, "", "", "2002vhs.gif");
	s[s.count()] = new copy_src("Mimic Egg", "", "mimic egg", "", 0, "", "", "mimicegg.gif");
	return s;
}

// how many more copies you can make / use today, as a short phrase, or "".
string copyBudget(copy_src src) {
	if(src.stockItem != "") {
		int n = item_amount(to_item(src.stockItem));
		return n + ' in inv';
	}
	if(src.madePref != "") {
		int left = src.madeCap - get_property(src.madePref).to_int();
		if(left < 0) left = 0;
		return left + ' left today';
	}
	if(src.usedPref != "")
		return get_property(src.usedPref).to_boolean() ? 'used today' : 'ready today';
	return '';
}

// show the row when you own the copier or have something loaded / planned.
boolean copyRelevant(copy_src src) {
	if(src.monsterPref != "" && get_property(src.monsterPref) != "") return true;
	if(src.stockItem != "" && item_amount(to_item(src.stockItem)) > 0) return true;
	if(src.madePref != "" && get_property(src.madePref).to_int() > 0) return true;
	if(src.usedPref != "" && get_property(src.usedPref).to_boolean()) return true;
	if(src.haveItem != "" && item_amount(to_item(src.haveItem)) > 0) return true;
	// Fax has no inventory item - detect the clan fax machine instead.
	if(src.label == "Fax" && (get_clan_lounge() contains $item[deluxe fax machine])) return true;
	return false;
}

void bakeSummonCopy() {
	buffer result;
	result.brickStart('Summon &amp; Copy', 'summoncopy', '3');

	int rows = 0;
	foreach i, src in copySources() {
		if(!copyRelevant(src)) continue;
		string mon = src.monsterPref == "" ? "" : get_property(src.monsterPref);
		string sub = mon == "" ? "&mdash;" : mon;
		string budget = copyBudget(src);
		string cell = budget == "" ? '<td class="right"></td>'
			: '<td class="right" title="copies you can still make or use today">' + budget + '</td>';
		result.append(monsterQueueRow(src.label, sub, src.image, cell));
		rows += 1;
	}

	if(rows == 0)
		result.append('<tr><td class="info" colspan="3">No copiers loaded.</td></tr>');

	result.brickFinish();

	chitTools["summoncopy"] = (rows == 0 ? "No monster copies" : "Monster copies in hand") + "|summoncopy.gif";
}
