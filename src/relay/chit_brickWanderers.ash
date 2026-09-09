// CHaracter Info Toolbox - wandering-monster brick
//
// Skills / items that force a specific monster to turn up as a wandering
// encounter while you adventure: Recall Facts: Monster Habitats, Be Gregarious,
// Digitize, romantic arrow, Enamorang, Club 'Em Into Next Week, Spooky VHS
// Tape. One row per source that currently has a monster queued, styled like an
// Effects row: monster (+ casts used today) in grey, and forced fights left or
// turns-until-it-wanders on the right. (Inventory copies you actively use are
// in the separate Summon & Copy brick.)

record wander_src {
	string label;
	string monsterPref;   // pref holding the queued monster name
	string countPref;     // forced-fights-left pref ("" = none)
	string counterLabel;  // KoLmafia counter that ticks down to the wander ("" = none)
	string castPref;      // daily-uses pref ("" = no fixed cap)
	int castCap;          // daily cast cap; 0 with a castPref means "show N used"
	string image;         // itemimages/*.gif
};

wander_src[int] wanderSources() {
	wander_src[int] s;
	s[s.count()] = new wander_src("Monster Habitats", "_monsterHabitatsMonster", "_monsterHabitatsFightsLeft", "", "_monsterHabitatsRecalled", 3, "map.gif");
	s[s.count()] = new wander_src("Be Gregarious", "beGregariousMonster", "beGregariousFightsLeft", "", "", 0, "happy.gif");
	s[s.count()] = new wander_src("Digitize", "_sourceTerminalDigitizeMonster", "", "Digitize Monster", "_sourceTerminalDigitizeUses", 0, "watch.gif");
	s[s.count()] = new wander_src("Romantic Arrow", "romanticTarget", "_romanticFightsLeft", "", "_badlyRomanticArrows", 1, "obtuseangel.gif");
	s[s.count()] = new wander_src("Enamorang", "enamorangMonster", "", "Enamorang Monster", "_enamorangs", 0, "loveboomerang.gif");
	s[s.count()] = new wander_src("Club 'Em Into Next Week", "clubEmNextWeekMonster", "", "Club 'Em Into Next Week Monster", "_clubEmNextWeekUsed", 5, "leg_club2.gif");
	s[s.count()] = new wander_src("Spooky VHS Tape", "spookyVHSTapeMonster", "", "Spooky VHS Monster", "", 0, "2002vhs.gif");
	return s;
}

// counterTurns returns how many turns until the named KoLmafia counter fires
// (the same number the Effects brick shows for these wanderers), or -1 if there
// is no such counter. Binary-searches get_counters, which only answers "is a
// matching counter due within [lo, hi] turns?".
int counterTurns(string label) {
	if(label == "" || get_counters(label, 0, 500) == "")
		return -1;
	int lo = 0;
	int hi = 500;
	while(lo < hi) {
		int mid = (lo + hi) / 2;
		if(get_counters(label, 0, mid) != "")
			hi = mid;
		else
			lo = mid + 1;
	}
	return lo;
}

// An Effects-style row: icon, label + grey sub-line, right-hand budget cell.
string monsterQueueRow(string label, string sub, string image, string budgetCell) {
	buffer b;
	b.append('<tr class="effect"><td class="icon"><img src="');
	b.append(itemimage(image));
	b.append('"></td><td class="info">');
	b.append(label);
	b.append('<br><span class="efmods">');
	b.append(sub);
	b.append('</span></td>');
	b.append(budgetCell);
	b.append('</tr>');
	return b.to_string();
}

// grey sub-line: the monster, plus today's casts as <used>/<limit> (ChIT's
// usual form) when the source has a fixed daily cap.
string wanderSub(wander_src src, string mon) {
	if(src.castPref == "") return mon;
	int used = get_property(src.castPref).to_int();
	if(src.castCap > 0)
		return mon + ' &middot; ' + used + '/' + src.castCap;
	if(used > 0)
		return mon + ' &middot; ' + used + ' used';
	return mon;
}

// right cell: forced fights left, else turns until it wanders.
string wanderBudgetCell(wander_src src) {
	if(src.countPref != "") {
		int n = get_property(src.countPref).to_int();
		if(n > 0)
			return '<td class="right" title="' + n + ' forced fight' + (n == 1 ? '' : 's') + ' left">' + n + 'x</td>';
	}
	if(src.counterLabel != "") {
		int t = counterTurns(src.counterLabel);
		if(t == 0)
			return '<td class="right" title="due to wander now">due</td>';
		if(t > 0)
			return '<td class="right" title="wanders in about ' + t + ' turn' + (t == 1 ? '' : 's') + '">' + t + 't</td>';
	}
	return '<td class="right"></td>';
}

void bakeWanderers() {
	buffer result;
	result.brickStart('Wandering Monsters', 'wanderers', '3');

	int rows = 0;
	foreach i, src in wanderSources() {
		string mon = get_property(src.monsterPref);
		if(mon == "") continue;
		result.append(monsterQueueRow(src.label, wanderSub(src, mon), src.image, wanderBudgetCell(src)));
		rows += 1;
	}

	if(rows == 0)
		result.append('<tr><td class="info" colspan="3">No monsters queued.</td></tr>');

	result.brickFinish();

	chitTools["wanderers"] = (rows == 0 ? "No queued wanderers" : "Queued wandering monsters") + "|wanderers.gif";
}
