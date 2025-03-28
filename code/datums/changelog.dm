/*
(t)
(u)
(*)
(+)
*/
/datum/changelog
//	var/changelog_path = "icons/changelog.txt"
	var/html = null
/*
New auto-generated changelog:
Format:
Use (t) for the timestamp, (u) for the user, and (*)for the line to add.
Use (+) instead for minor changes (will be collapsed and grouped up at the end of the day's log).
Be sure to add a \ before a [
Examples:
Single update for a given day:
(t)mon jan 01 12
(u)Pantaloons
(*)Did a thing.
Multiple updates in a day:
(t)mon jan 01 12
(u)Pantaloons
(*)Did a thing.
(+)Fixed a bug.
(u)Nannek
(*)Also did a thing.

WIRE NOTE: You don't need to use (-) anymore (although doing so doesn't break anything)
OTHER NOTE:
(t)mon dec 1 14
returns "Monday, December 1 th, 204"
so you'll want your single-digit days to have 0s in front
*/

/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

ATTENTION: The changelog has moved into its own file: strings/changelog.txt

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

/proc/changelog_parse(var/changes, var/title, var/logclasses)
	var/list/html = list()
	var/text = changes
	if (!text)
		logDiary("Failed to load changelog.")
	else
		html += "<ul class=\"log[logclasses]\"><li class=\"title\"><i class=\"icon-bookmark\"></i> [title] as of [copytext(vcs_revision, 1, 8)]</li>" //truncate to 7 long

		var/list/collapsible_html = list()
		var/added_collapsible_author = 0
		var/added_author = 0
		var/author = null
		var/pr_num = null
		var/emoji_labels = null

		var/list/lines = splittext(text, "\n")
		for(var/line in lines)
			if (!line)
				continue

			if (copytext(line, 1, 2) == "#")
				continue

			switch(copytext(line, 1, 4))
				if("(p)")
					pr_num = copytext(line, 4, 0)
				if("(e)")
					emoji_labels = copytext(line, 4, 0)
				if("(t)")
					if(collapsible_html.len)
						html += "<li class=\"collapse-button\">Minor Changes</li><div class='collapsible'>[collapsible_html.Join()]</div>"
						collapsible_html.Cut()
						author = null
						added_collapsible_author = 0
						added_author = 0
					var/day = copytext(line, 4, 7)
					html += "<li class=\"date\">"
					switch(day)
						if("sun")
							html += "Sunday, "
						if("mon")
							html += "Monday, "
						if("tue")
							html += "Tuesday, "
						if("wed")
							html += "Wednesday, "
						if("thu")
							html += "Thursday, "
						if("fri")
							html += "Friday, "
						if("sat")
							html += "Saturday, "
						else
							html += "Whoopsday, "
					var/month = copytext(line, 8, 11)
					switch(month)
						if("jan")
							html += "January "
						if("feb")
							html += "February "
						if("mar")
							html += "March "
						if("apr")
							html += "April "
						if("may")
							html += "May "
						if("jun")
							html += "June "
						if("jul")
							html += "July "
						if("aug")
							html += "August "
						if("sep")
							html += "September "
						if("oct")
							html += "October "
						if("nov")
							html += "November "
						if("dec")
							html += "December "
						else
							html += "Whoops"
					var/date1 = copytext(line, 12, 13)
					var/date2 = copytext(line, 13, 14)
					switch(date1)
						if("0")
							html += date2
							switch(date2)
								if("1")
									html += "st, "
								if("2")
									html += "nd, "
								if("3")
									html += "rd, "
								else
									html += "th, "
						if("1")
							html += "[date1][date2]th, "
						else
							html += date1
							html += date2
							switch(date2)
								if("1")
									html += "st, "
								if("2")
									html += "nd, "
								if("3")
									html += "rd, "
								else
									html += "th, "
					html += "20[copytext(line, 15, 17)]</li>"
				if("(u)")
					#ifdef APRIL_FOOLS
					author = "CodeDude"
					#else
					author = copytext(line, 4, 0)
					#endif
					added_collapsible_author = 0
					added_author = 0
					pr_num = null
					emoji_labels = null
				if("(*)")
					if(!added_author && author)
						html += "<li class=\"admin\"><span><i class=\"icon-check\"></i> [author]</span> updated:"
						if(emoji_labels)
							var/list/emoji_parts = splittext(emoji_labels, "|")
							#ifdef APRIL_FOOLS
							var/random_em = ""
							for(var/i in 1 to rand(1, 4))
								random_em += random_emoji()
							html += "<span class='emoji'>[random_em]"
							#else
							html += "<span class='emoji'>[emoji_parts[1]]"
							#endif
							if(emoji_parts.len > 1)
								html += "<span class='tooltiptext'>[emoji_parts[2]]</span>"
							html += "</span>"
						if(pr_num)
							html += "<a target='_blank' href='https://github.com/coolstation/coolstation/pull/[pr_num]' class='pr_link'><span class='pr_number'>#[pr_num]</span>&gt;</a>"
						html += "</li>"
						added_author = 1
					html += "<li>[copytext(line, 4, 0)]</li>"
				if("(+)")
					if(!added_collapsible_author && author)
						collapsible_html += "<li class=\"admin\"><span><i class=\"icon-check\"></i> [author]</span> updated:"
						if(emoji_labels)
							var/list/emoji_parts = splittext(emoji_labels, "|")
							collapsible_html += "<span class='emoji'>[emoji_parts[1]]"
							if(emoji_parts.len > 1)
								collapsible_html += "<span class='tooltiptext'>[emoji_parts[2]]</span>"
							collapsible_html += "</span>"
						if(pr_num)
							collapsible_html += "<a target='_blank' href='https://github.com/coolstation/coolstation/pull/[pr_num]' class='pr_link'><span class='pr_number'>#[pr_num]</span>&gt;</a>"
						collapsible_html += "</li>"
						added_collapsible_author = 1
					collapsible_html += "<li>[copytext(line, 4, 0)]</li>"
				else continue

		if(collapsible_html.len)
			html += "<li class=\"collapse-button\">Minor Changes</li><div class='collapsible'>[collapsible_html.Join()]</div>"
		html += "</ul>"
		return html.Join()

/datum/changelog/New()
	..()
//<img alt="Goonstation 13" src="[resource("images/changelog/postcardsmall.jpg")]" class="postcard" />

	html = {"
<h1>Cool's tation 13 <a href="#license"><img alt="Creative Commons CC-BY-NC-SA License" src="[resource("images/changelog/88x31.png")]" /></a></h1>

<ul class="links cf">
    <li>Official Wiki<br><strong><a target="_blank" href="https://wiki.coolstation.space">https://wiki.coolstation.space</a></strong><span></span></li>
    <li>Official Forums<br><strong><a target="_blank" href="https://forum.coolstation.space">https://forum.coolstation.space</a></strong></li>
</ul>"}

#if ASS_JAM
	html += "<a id='ass_changelog' href='#' style='color:#ffffff; text-align:center; display:block' onclick='$(\".nano\").nanoScroller({ scrollTo: $(\"#main_changelog\") });'>Jump to regular changelog</a>"
	html += changelog_parse(file2text("strings/ass_changelog.txt"), "Ass Jam Changelog", " ass")
	html += "<a id='main_changelog' href='#' style='color:#ffffff; text-align:center; display:block' onclick='$(\".nano\").nanoScroller({ scrollTo: $(\"#ass_changelog\") });'>Jump to ass jam changelog</a>"
#endif
	html += changelog_parse(file2text("strings/changelog.txt"), "Changelog")
	html += {"
<h3>Coolstation 13 Development Team</h3>
<p class="team">
    <strong>Host:</strong> Warc (Also ReginaldHJ and Tamber)<br>

    <strong>Coders:</strong> lotta people (fill in asap)
		<br>
    <strong>Spriters:</strong> even more lotta people plus non-staff (thank you all)
		<br>
	not sure this even shows up in the window but anyway
</p>

<p id="license" class="lic">
    <a target="_blank" href="http://creativecommons.org/licenses/by-nc-sa/3.0/" name="license"><img alt="Creative Commons CC-BY-NC-SA License" src="[resource("images/changelog/88x31.png")]" /></a><br/>

    <em>
    	Except where otherwise noted, Coolstation 13 is licensed under a <a target="_blank" href="http://creativecommons.org/licenses/by-nc-sa/3.0/">Creative Commons Attribution-Noncommercial-Share Alike 3.0 License</a>.
    </em>
</p>"}
