<cfsetting enablecfoutputonly="true">
<!---
	Name			: index.cfm
	Author			: Michael Sharman (michael[at]chapter31[dot]com)
	Created			: May 26, 2011
	Last Updated		: May 26, 2011
	History			: Initial release (mps 26/05/2011)
	Purpose			: Used to import a basic structure of content (navigation and html content) from FarCry to Mura
 --->

<cfimport taglib="./tags" prefix="tags">

<cfinclude template="inc/header.cfm">

<cfparam name="form.muraSiteID" default="">

<cfscript>
	if (NOT structKeyExists(session, "FarcryToMura"))
	{
		session.FarcryToMura = createObject("component", "FarcryToMura").init();
	}
	
	// Easy access
	oFTM = session.FarcryToMura;
	process = structNew();
	process.status = true;

	// Set the from and to DSNs for future use
	if (structKeyExists(form, "btnSubmitDSN"))
	{
		process = oFTM.setDSNs(form.farcryDSN, form.muraDSN);
		if (process.status)
		{
			process = oFTM.checkDSNs();
			if (process.status)
			{
				oFTM.locate('muraSiteID');
			}
		}
	}
	// Set the Mura siteID
	else if (structKeyExists(form, "btnSubmitMuraSiteID"))
	{
		process = oFTM.setMuraSiteID(form.muraSiteID);
		if (process.status)
		{
			oFTM.locate('checkFarCry');
		}
	}
	// Do the import
	else if (structKeyExists(form, "btnSubmitPreImport"))
	{
		process = oFTM.doImport();
		if (process.status)
		{
			oFTM.locate('complete');
		}	
	}
	
	if (process.status)
	{
		// Run validation on the current step if we don't already have an error
		validate = oFTM.validateStep(step=URL.step);
		if (NOT validate.status)
		{
			URL.step = "error";
			process = validate;
		}
	}
</cfscript>

<tags:msg data="#process#">

<cfoutput>
	<div id="step">
	<cfswitch expression="#URL.step#">
		<cfcase value="DSN">
			<form id="frmDSN" action="" method="post">
				<fieldset>
					<legend>Set DSNs</legend>
					<p>First you need to enter your DSN names (as entered in ColdFusion Administrator or your Railo Context etc)</p>
					<ul class="form tar">
						<li>
							<label for="farcryDSN">FarCry DSN:</label>
							<input type="text" id="farcryDSN" name="farcryDSN" value="#oFTM.getFromDSN()#" />
						</li>
						<li>
							<label for="muraDSN">Mura DSN: </label>
							<input type="text" id="muraDSN" name="muraDSN" value="#oFTM.getToDSN()#" />
						</li>
						<li><input type="submit" name="btnSubmitDSN" id="btnSubmitDSN" value="Choose DSNs" /></li>
					</ul>
				</fieldset>
			</form>
		</cfcase>
	
		<cfcase value="muraSiteID">
			<cfset qMuraSiteIDs = oFTM.getAvailableMuraSiteIDs()>
			<cfif qMuraSiteIDs.recordCount>
				<form id="frmSubmitMuraSiteID" action="" method="post">
					<fieldset>
						<legend>Set Mura SiteID</legend>
						<cfif qMuraSiteIDs.recordCount EQ 1>
							<p>Looks like you're running off a single Mura site, everything should be good to go. Just select the site and hit Next</p>
						<cfelse>
							<p>Looks like you're running multiple Mura sites...cool. Choose the site you'd like to import FarCry into and hit Next.</p>
						</cfif>
						<ul class="form tar">
							<cfloop query="qMuraSiteIDs">
								<li><label for="#qMuraSiteIDs.siteID#">#qMuraSiteIDs.siteID#</label>
								<input type="radio" id="#qMuraSiteIDs.siteID#" name="muraSiteID" value="#qMuraSiteIDs.siteID#"<cfif qMuraSiteIDs.siteID EQ oFTM.getMuraSiteID()> checked="checked"</cfif>></li>
							</cfloop>
						</ul>					
						<input type="submit" name="btnSubmitMuraSiteID" id="btnSubmitMuraSiteID" value="Next &raquo;" />
					</fieldset>
				</form>
			<cfelse>
				<p>I can't find any Mura siteIDs for your DSN (#oFTM.getFromDSN()#). Can you have a look and try again?</p>
			</cfif>
		</cfcase>

		<cfcase value="checkFarCry">
			<fieldset>
				<legend>Check FarCry navigation tree</legend>
				<p>The following is the navigation tree that we'll try to import into Mura. Note that anything in red is not an HTML
				page, so that content will have to be migrated manually. See <a href="index.cfm?step=help">help</a> for more.</p>
				<cfset qFC = oFTM.getFarcryTree()>
				<cfset currentLevel = 0>
				<cfset previousLevel = 0>
				<ul>
					<cfloop query="qFC">
						<cfset typeClass = "">
						<cfif qFC.typename NEQ "dmHTML">
							<cfset typeClass = "ignored">
						</cfif>
						<cfset currentLevel = qFC.nLevel>
						<cfif qFC.currentRow EQ 1>
							<cfset previousLevel = currentLevel>
						<cfelseif currentLevel EQ previousLevel>
							</li>
						<cfelseif currentLevel GT previousLevel>
							<ul>
						</cfif>
						<cfif currentLevel LT previousLevel>
							<cfloop from="1" to="#previousLevel-currentLevel#" index="i">
									</li>
								</ul>
							</li>
							</cfloop>
						</cfif>
						<li class="#typeClass#">#qFC.title#
						<cfif qFC.typename NEQ "dmHTML">
							[#qFC.typename#]
						</cfif>
						<cfset previousLevel = currentLevel>
					</cfloop>
					</li>
				</ul>
				<input type="button" name="btnCheckFarCry" id="btnCheckFarCry" value="Looks good, continue &raquo;" onclick="javascript:location.href='index.cfm?step=checkMura'" />
			</fieldset>
		</cfcase>
		
		<cfcase value="checkMura">
			<fieldset>
				<legend>Check Mura navigation tree</legend>
				<p>The following is the existing navigation tree in Mura. In most cases it will probably be quite empty, 
				double check though as we're going to append all <a href="index.cfm?step=checkFarCry">FarCry content</a> to the "root" page in Mura (probably "Home").</p>
				<p>**Note: We don't display the Mura tree hierarchically (indented).</p>
				<cfset qM = oFTM.getMuraTree()>
				<ul>
					<cfloop query="qM">
						<li>#qM.title#</li>
					</cfloop>
					</li>
				</ul>
				<input type="button" name="btnCheckMura" id="btnCheckMura" value="Looks good, continue &raquo;" onclick="javascript:location.href='index.cfm?step=preImport'" />
			</fieldset>
		</cfcase>
		
		<cfcase value="preImport">
			<form id="frmSubmitPreImport" action="" method="post">
				<fieldset>
					<legend>Import FarCry to Mura</legend>
					<p>Ok if you've gotten to here we hope you're in a good state to import, hit the button below :)</p>
					<input type="submit" name="btnSubmitPreImport" id="btnSubmitPreImport" value="Do Import!!!" />
				</fieldset>
			</form>
		</cfcase>
		
		<cfcase value="complete">
			<fieldset>
				<legend>Import complete!</legend>
				<p>The import has completed, you can <a href="index.cfm?step=checkMura">check the mura site tree</a> (non hierarchically) to check.</p>
			</fieldset>		
		</cfcase>
		
		<cfcase value="help">
			<fieldset class="help">
				<legend>General Help and TODOs</legend>
				<h4>Introduction</h4>
				<p>This script imports basic navigation and HTML data from an existing FarCry database into a Mura one.</p>
				
				<h4>Requirements</h4>
				<p>This was built on</p>
				<ul>
					<li>Railo 3.2+</li>
					<li>ColdFusion 7+</li>
					<li>FarCry 6+</li>
					<li>Mura 5.4+</li>
					<li>MySQL 5+</li>				
				</ul>
				<p>Not sure about FarCry 5, you should be ok as I don't think the v6 schema changes will effect this script</p>
				<p>To make things easier, session management must enabled</p>
				
				<h4>Installation</h4>
				<p>Probably easiest to put this folder (farcrytomura) in the webroot of an existing project/vhost,
				then call it from http://www.yourproject.com/farcrytomura/</p>
				<p>If you want, you can setup a project/vhost specifically for this, but it's not necessary.</p>
				<p>This script has its own Application.cfc to avoid scope conflict</p>
				<p>Caveat - the ColdFusion/Railo server (instance/context) that you run this from needs to have <a href="index.cfm">BOTH dsn's</a> (the FarCry and Mura ones) in the cf admin</p>
				
				<h4>FarCry content types</h4>
				<p>Currently we examine the FarCry navigation tree and bring across the entire structure underneath 'Root' (i.e. any nLevel 2+ nodes)</p>
				<p>If people want it, we can extend the functionality to import from a specific node, e.g. from 'Home'. This would be handy
				if your FarCry site has secondary/utility navigation etc that you want imported separately.</p>
				<p>Although all navigation nodes will be created in Mura, the only actual content that is imported is dmHTML, we ignore:</p>
				<ul>
					<li>dmInclude</li>
					<li>dmLink</li>
					<li>Anything but the first content object under a navigation node</li>
					<li>dmNews, dmEvent or any other "dynamic" content type</li>
					<li>Custom tree content types</li>
				</ul>
				<p>Basically we import all navigation nodes under the site tab, from "Root" down, including the HTML content.</p>
				
				<h4>FarCry homepage content</h4>
				<p>Currently we ignore the farcry homepage content because we assume there is at least a "home" page in Mura. This is a TODO</p>
				
				<h4>SES URLs</h4>
				<p>Mura ses url's are created on import based off the title of the page from FarCry. This should be the default behaviour as
				if you were created a page from within Mura admin.</p>
				<p>Currently we're NOT importing the FarCry friendly URL into Mura.</p>
				
				<h4>Rolling back</h4>
				<p>If you want to rollback the import, you'll need to:</p>
				<p><pre>DELETE FROM tcontent WHERE siteID = '[yoursite]' AND lastUpdateBy = 'farcrytomura'</pre></p>
				
				<div class="break"></div>
				
				<h4>TODOs</h4>
				<ul>
					<li>Ability to select the page template from Mura</li>
					<li>When previewing the Mura navigation tree, indent properly</li>
					<li>Import the FarCry "home" page content</li>
					<li>Handle farcry secondary/utility nav's (anything else at the same level as "home")</li>
					<li>Fix sortorder on sub items, they work fine but not as neat as they could be</li>
				</ul>
			</fieldset>		
		</cfcase>

		<cfdefaultcase></cfdefaultcase>
	</cfswitch>
	</div>
</cfoutput>

<cfinclude template="inc/footer.cfm">